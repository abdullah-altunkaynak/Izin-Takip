using IzinTakip.Api.Data;
using IzinTakip.Api.Helpers;
using IzinTakip.Api.Models;
using IzinTakip.Api.Models.Dtos;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace IzinTakip.Api.Controllers
{
    [Authorize]
    [ApiController]
    [Route("api/[controller]")]
    public class LeaveRequestsController : ControllerBase
    {
        private readonly AppDbContext _context;
        public LeaveRequestsController(AppDbContext context)
        {
            _context = context;
        }

        // Kullanıcı yeni izin talepi oluşturma
        [HttpPost]
        public IActionResult Create(CreateLeaveRequestDto dto)
        {
            var today = DateTimeProvider.TodayTr();

            if (dto.StartDate.Date < today)
                return BadRequest("Geçmiş tarih için izin talebi oluşturulamaz.");

            if (dto.EndDate.Date < dto.StartDate.Date)
                return BadRequest("Bitiş tarihi başlangıçtan önce olamaz.");

            if (dto.StartDate > dto.EndDate)
                return BadRequest("Başlangıç tarihi bitişten büyük olamaz.");


            int employeeId = int.Parse(
                User.FindFirst("employeeId")!.Value
            );

            var s = dto.StartDate.Date;
            var e = dto.EndDate.Date;

            var hasOverlap = _context.LeaveRequests
              .AsNoTracking()
              .Any(lr =>
                 lr.EmployeeId == employeeId &&
                 !lr.IsCancelled &&
                 (lr.StatusId == 1 || lr.StatusId == 2) &&
                 lr.StartDate.Date <= e &&
                 lr.EndDate.Date >= s
              );

            if (hasOverlap)
            {
                return BadRequest(new
                {
                    message = "Bu tarih aralığında zaten bekleyen veya onaylanmış bir izin talebiniz var."
                });
            }


            var leaveDays = LeaveDayCalculator.CountDaysExcludingSundays(dto.StartDate, dto.EndDate);
            if (leaveDays <= 0)
                return BadRequest("İzin gün sayısı hesaplanamadı.");

            var year = dto.StartDate.Year;

            var annual = _context.EmployeeAnnualLeave
                .FirstOrDefault(x => x.EmployeeId == employeeId && x.Year == year);

            if (annual == null)
            {
                annual = new EmployeeAnnualLeave
                {
                    EmployeeId = employeeId,
                    Year = year,
                    TotalDays = 14,
                    UsedDays = 0
                };
                _context.EmployeeAnnualLeave.Add(annual);
                _context.SaveChanges();
            }

            var remaining = annual.TotalDays - annual.UsedDays;

            if (leaveDays > remaining)
            {
                return BadRequest(new
                {
                    message = "Yeterli yıllık izin hakkınız yok.",
                    remainingDays = remaining,
                    requestedDays = leaveDays
                });
            }

            var leaveType = _context.LeaveTypes
                .FirstOrDefault(x => x.LeaveTypeId == dto.LeaveTypeId && x.IsActive);

            if (leaveType == null)
                return BadRequest("Geçersiz veya pasif izin tipi.");

            int pendingStatusId = 1; // default 1 bekleme durumunda

            var leaveRequest = new LeaveRequest
            {
                EmployeeId = employeeId,
                LeaveTypeId = dto.LeaveTypeId,
                StartDate = dto.StartDate,
                EndDate = dto.EndDate,
                StatusId = pendingStatusId,
                Description = dto.Description,
                CreatedAt = DateTime.UtcNow
            };

            _context.LeaveRequests.Add(leaveRequest);
            _context.SaveChanges();

            return Ok(leaveRequest);
        }

        [Authorize]
        [HttpPut("{id}")]
        public IActionResult UpdateLeaveRequest(int id, UpdateLeaveRequestDto dto)
        {

            var today = DateTimeProvider.TodayTr();

            if (dto.StartDate.Date < today)
                return BadRequest("Geçmiş tarih için güncelleme yapılamaz.");

            if (dto.EndDate.Date < dto.StartDate.Date)
                return BadRequest("Bitiş tarihi başlangıçtan önce olamaz.");

            int employeeId = int.Parse(User.FindFirst("employeeId")!.Value);

            var leaveRequest = _context.LeaveRequests
                .FirstOrDefault(x =>
                    x.LeaveRequestId == id &&
                    x.EmployeeId == employeeId
                );

            if (leaveRequest == null)
                return NotFound("İzin talebi bulunamadı.");

            if (leaveRequest.StatusId != 1)
                return BadRequest("Sadece beklemedeki izinler güncellenebilir.");

            var s = dto.StartDate.Date;
            var e = dto.EndDate.Date;

            var hasOverlap = _context.LeaveRequests
              .AsNoTracking()
              .Any(lr =>
                 lr.LeaveRequestId != id &&
                 lr.EmployeeId == employeeId &&
                 !lr.IsCancelled &&
                 (lr.StatusId == 1 || lr.StatusId == 2) &&
                 lr.StartDate.Date <= e &&
                 lr.EndDate.Date >= s
              );

            if (hasOverlap)
            {
                return BadRequest(new
                {
                    message = "Bu tarih aralığında zaten bekleyen veya onaylanmış bir izin talebiniz var."
                });
            }

            var leaveDays = LeaveDayCalculator.CountDaysExcludingSundays(dto.StartDate, dto.EndDate);
            if (leaveDays <= 0)
                return BadRequest("İzin gün sayısı hesaplanamadı.");

            var year = dto.StartDate.Year;

            var annual = _context.EmployeeAnnualLeave
                .FirstOrDefault(x => x.EmployeeId == leaveRequest.EmployeeId && x.Year == year);

            if (annual == null)
            {
                annual = new EmployeeAnnualLeave
                {
                    EmployeeId = leaveRequest.EmployeeId,
                    Year = year,
                    TotalDays = 14,
                    UsedDays = 0
                };
                _context.EmployeeAnnualLeave.Add(annual);
                _context.SaveChanges();
            }

            var remaining = annual.TotalDays - annual.UsedDays;

            // pending olduğu için eski günleri geri alma yok
            if (leaveDays > remaining)
            {
                return BadRequest(new
                {
                    message = "Yeterli yıllık izin hakkınız yok.",
                    remainingDays = remaining,
                    requestedDays = leaveDays
                });
            }

            leaveRequest.LeaveTypeId = dto.LeaveTypeId;
            leaveRequest.StartDate = dto.StartDate;
            leaveRequest.EndDate = dto.EndDate;
            leaveRequest.Description = dto.Description;

            _context.SaveChanges();

            return Ok(new { message = "İzin talebi güncellendi." });
        }

        // İzin onaylama veya reddetme
        [Authorize(Roles = "Manager")]
        [HttpPost("{id}/decision")]
        public IActionResult DecideLeaveRequest(int id, LeaveDecisionDto dto)
        {
            bool isManager = bool.Parse(User.FindFirst("isManager")!.Value);
            if (!isManager)
                return Forbid("Sadece yöneticiler onay verebilir.");

            var leaveRequest = _context.LeaveRequests
                .FirstOrDefault(x => x.LeaveRequestId == id);

            if (leaveRequest == null)
                return NotFound("İzin talebi bulunamadı.");

            if (leaveRequest.StatusId != 1)
                return BadRequest("Bu izin daha önce karara bağlanmış.");

            if (!dto.IsApproved && string.IsNullOrWhiteSpace(dto.RejectionReason))
                return BadRequest("Red için açıklama zorunludur.");

            int managerEmployeeId = int.Parse(User.FindFirst("employeeId")!.Value);

            // onaylarken yıllık izin hakkı kontrolü
            if (dto.IsApproved)
            {
                var leaveDays = LeaveDayCalculator.CountDaysExcludingSundays(leaveRequest.StartDate, leaveRequest.EndDate);
                if (leaveDays <= 0)
                    return BadRequest("İzin gün sayısı hesaplanamadı.");

                var year = leaveRequest.StartDate.Year; 

                
                var annual = _context.EmployeeAnnualLeave
                    .FirstOrDefault(x => x.EmployeeId == leaveRequest.EmployeeId && x.Year == year);

                // Eğer personel için kayıt yoksa oluştur
                if (annual == null)
                {
                    annual = new EmployeeAnnualLeave
                    {
                        EmployeeId = leaveRequest.EmployeeId,
                        Year = year,
                        TotalDays = 14,
                        UsedDays = 0
                    };
                    _context.EmployeeAnnualLeave.Add(annual);
                    _context.SaveChanges();
                }

                var remaining = annual.TotalDays - annual.UsedDays;

                if (leaveDays > remaining)
                {
                    return BadRequest(new
                    {
                        message = "Yeterli yıllık izin hakkı yok.",
                        remainingDays = remaining,
                        requestedDays = leaveDays
                    });
                }

                annual.UsedDays += leaveDays;
                annual.UpdatedAt = DateTime.UtcNow;
            }

            
            leaveRequest.StatusId = dto.IsApproved ? 2 : 3;
            leaveRequest.RejectionReason = dto.IsApproved ? null : dto.RejectionReason;
            leaveRequest.ApprovedByEmployeeId = managerEmployeeId;
            leaveRequest.ApprovedAt = DateTime.UtcNow;

            _context.SaveChanges();

            return Ok(dto.IsApproved
                ? new { message = "İzin onaylandı." }
                : new { message = "İzin reddedildi." });
        }


        [Authorize(Roles = "Manager")]
        [HttpGet("pending")]
        public IActionResult GetPendingLeaveRequests()
        {
            var today = DateTimeProvider.TodayTr();
            LeaveAutoCancel.CancelExpiredPending(_context, today);

            bool isManager = bool.Parse(
                User.FindFirst("isManager")!.Value
            );

            if (!isManager)
                return Forbid("Sadece yöneticiler bu listeyi görebilir.");

            int managerEmployeeId = int.Parse(
                User.FindFirst("employeeId")!.Value
            );

            var manager = _context.Employees
                .FirstOrDefault(x => x.EmployeeId == managerEmployeeId);

            if (manager == null)
                return Unauthorized();
            var pendingRequests = _context.LeaveRequests
                .Where(lr =>
                    lr.StatusId == 1 && 
                    !lr.IsCancelled &&
                    lr.Employee.DepartmentId == manager.DepartmentId
                )
                .Select(lr => new PendingLeaveRequestDto
                {
                    LeaveRequestId = lr.LeaveRequestId,
                    EmployeeId = lr.EmployeeId,
                    EmployeeName = lr.Employee.FirstName + " " + lr.Employee.LastName,
                    LeaveTypeName = lr.LeaveType.LeaveTypeName,
                    StartDate = lr.StartDate,
                    EndDate = lr.EndDate,
                    Description = lr.Description
                })
                .ToList();

            return Ok(pendingRequests);
        }

        // Kullanıcının onaylanmış veya reddedilmiş yani karara bağlanmış izin talepleri ve tüm izin talepleri
        // pending gönderilirse sadece beklemedeki izin talepleri
        // history gönderilirse onaylanmış veya reddedilmiş izin talepleri
        [Authorize]
        [HttpGet("my")]
        public IActionResult GetMyLeaveRequests([FromQuery] string? status)
        {
            // Her istek geldiğinde süresi geçmiş beklemedeki izin taleplerini iptal et
            var today = DateTimeProvider.TodayTr();
            LeaveAutoCancel.CancelExpiredPending(_context, today);

            var employeeIdClaim = User.FindFirst("employeeId")?.Value;
            if (string.IsNullOrWhiteSpace(employeeIdClaim) || !int.TryParse(employeeIdClaim, out var employeeId))
                return Unauthorized("employeeId claim missing/invalid");

            var query = _context.LeaveRequests
                .AsNoTracking()
                .Include(lr => lr.LeaveType)
                .Include(lr => lr.Status)
                .Where(lr => lr.EmployeeId == employeeId);

            if (!string.IsNullOrWhiteSpace(status))
            {
                status = status.ToLowerInvariant();
                if (status == "pending")
                    query = query.Where(lr => lr.StatusId == 1 && !lr.IsCancelled);
                else if (status == "history")
                    query = query.Where(lr => lr.StatusId != 1);
            }

            var result = query
                .OrderByDescending(lr => lr.CreatedAt)
                .Select(lr => new MyLeaveRequestDto
                {
                    LeaveRequestId = lr.LeaveRequestId,
                    LeaveTypeName = lr.LeaveType != null ? lr.LeaveType.LeaveTypeName : null,
                    StartDate = lr.StartDate,
                    EndDate = lr.EndDate,
                    Status = lr.Status != null ? lr.Status.StatusName : null,
                    Description = lr.Description,
                    RejectionReason = lr.RejectionReason,
                    ApprovedAt = lr.ApprovedAt,
                    LeaveTypeId = lr.LeaveTypeId,
                    IsCancelled = lr.IsCancelled
                })
                .ToList();

            return Ok(result);
        }


        // Yöneticinin kendi departmanındaki çalışanların onaylanmış veya reddedilmiş izin talepleri
        [Authorize(Roles = "Manager")]
        [HttpGet("manager/history")]
        public IActionResult GetDepartmentLeaveHistory()
        {
            bool isManager = bool.Parse(
                User.FindFirst("isManager")!.Value
            );

            if (!isManager)
                return Forbid("Sadece yöneticiler erişebilir.");

            int managerEmployeeId = int.Parse(
                User.FindFirst("employeeId")!.Value
            );

            var manager = _context.Employees
                .FirstOrDefault(x => x.EmployeeId == managerEmployeeId);

            if (manager == null)
                return Unauthorized();

            var history = _context.LeaveRequests
                .Where(lr =>
                    lr.StatusId != 1 &&
                    lr.Employee.DepartmentId == manager.DepartmentId
                )
                .OrderByDescending(lr => lr.ApprovedAt)
                .Select(lr => new ManagerLeaveHistoryDto
                {
                    LeaveRequestId = lr.LeaveRequestId,
                    EmployeeName = lr.Employee.FirstName + " " + lr.Employee.LastName,
                    LeaveTypeName = lr.LeaveType.LeaveTypeName,
                    StartDate = lr.StartDate,
                    EndDate = lr.EndDate,
                    Status = lr.Status.StatusName,
                    RejectionReason = lr.RejectionReason,
                    ApprovedAt = lr.ApprovedAt
                })
                .ToList();

            return Ok(history);
        }


        // İzni veritabanından tamamen silmiyoruz sadece iptal ediyoruz
        [Authorize]
        [HttpPost("{id}/cancel")]
        public IActionResult CancelLeaveRequest(int id)
        {
            int employeeId = int.Parse(
                User.FindFirst("employeeId")!.Value
            );

            var leaveRequest = _context.LeaveRequests
                .FirstOrDefault(x =>
                    x.LeaveRequestId == id &&
                    x.EmployeeId == employeeId
                );

            if (leaveRequest == null)
                return NotFound("İzin talebi bulunamadı.");

            if (leaveRequest.StatusId != 1)
                return BadRequest("Sadece beklemedeki izinler iptal edilebilir.");

            if (leaveRequest.IsCancelled)
                return BadRequest("Bu izin zaten iptal edilmiş.");

            leaveRequest.IsCancelled = true;
            leaveRequest.CancelledAt = DateTime.UtcNow;

            _context.SaveChanges();

            return Ok(new { message = "İzin talebi iptal edildi." });
        }

        [Authorize]
        [HttpGet("{id}")]
        public IActionResult GetMyLeaveRequestDetail(int id)
        {
            var isManagerClaim = User.FindFirst("isManager")?.Value;
            if (string.IsNullOrWhiteSpace(isManagerClaim) || !bool.TryParse(isManagerClaim, out var isManager))
                return Unauthorized("isManager claim missing/invalid");

            var employeeIdClaim = User.FindFirst("employeeId")?.Value;
            if (string.IsNullOrWhiteSpace(employeeIdClaim) || !int.TryParse(employeeIdClaim, out var employeeId))
                return Unauthorized("employeeId claim missing/invalid");

            var lr = _context.LeaveRequests
                .AsNoTracking()
                .Include(x => x.Employee)
                .Include(x => x.LeaveType)
                .Include(x => x.Status)
                .FirstOrDefault(x => x.LeaveRequestId == id);

            if (lr == null)
                return NotFound();

            if (!isManager)
            {
                // normal user sadece kendi talebini görür
                if (lr.EmployeeId != employeeId)
                    return NotFound(); // güvenlik için 404
            }
            else
            {
                // manager sadece kendi departmanındakileri görür
                var manager = _context.Employees
                    .AsNoTracking()
                    .FirstOrDefault(e => e.EmployeeId == employeeId);

                if (manager == null)
                    return Unauthorized();

                if (lr.Employee.DepartmentId != manager.DepartmentId)
                    return NotFound(); // departman dışı -> yokmuş gibi
            }

            return Ok(new MyLeaveRequestDto
            {
                LeaveRequestId = lr.LeaveRequestId,
                LeaveTypeName = lr.LeaveType.LeaveTypeName,
                StartDate = lr.StartDate,
                EndDate = lr.EndDate,
                Status = lr.Status.StatusName,
                Description = lr.Description,
                RejectionReason = lr.RejectionReason,
                ApprovedAt = lr.ApprovedAt,
                IsCancelled = lr.IsCancelled,
                LeaveTypeId = lr.LeaveTypeId,
                EmployeeId = isManager ? lr.EmployeeId : null,
                EmployeeName = isManager ? (lr.Employee.FirstName + " " + lr.Employee.LastName) : null
            });
        }


    }
}
