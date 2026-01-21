using IzinTakip.Api.Data;
using IzinTakip.Api.Helpers;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace IzinTakip.Api.Controllers
{
    [Authorize]
    [ApiController]
    [Route("api/[controller]")]
    public class DashboardController : ControllerBase
    {
        private readonly AppDbContext _context;
        public DashboardController(AppDbContext context) => _context = context;

        // Employee + Manager için ortak: kendi özeti
        [HttpGet("me")]
        public IActionResult Me()
        {
            var employeeIdClaim = User.FindFirst("employeeId")?.Value;
            if (string.IsNullOrWhiteSpace(employeeIdClaim) || !int.TryParse(employeeIdClaim, out var employeeId))
                return Unauthorized("employeeId claim missing/invalid");

            // Süresi geçmiş bekleyen izin taleplerini iptal et
            var today = DateTimeProvider.TodayTr();
            LeaveAutoCancel.CancelExpiredPending(_context, today);

            var year = today.Year;

            // Yıllık izin kaydı
            var annual = _context.EmployeeAnnualLeave
                .AsNoTracking()
                .FirstOrDefault(x => x.EmployeeId == employeeId && x.Year == year);

            var my = _context.LeaveRequests
                .AsNoTracking()
                .Where(lr => lr.EmployeeId == employeeId);

            var pendingCount = my.Count(lr => lr.StatusId == 1 && !lr.IsCancelled);
            var approvedCount = my.Count(lr => lr.StatusId == 2 && !lr.IsCancelled);
            var rejectedCount = my.Count(lr => lr.StatusId == 3);

            return Ok(new
            {
                year,
                totalDays = annual.TotalDays,
                usedDays = annual.UsedDays,
                remainingDays = (annual.TotalDays - annual.UsedDays),
                pendingCount,
                approvedCount,
                rejectedCount
            });
        }

        // departman özet
        [Authorize(Roles = "Manager")]
        [HttpGet("manager")]
        public IActionResult Manager()
        {
            bool isManager = bool.Parse(User.FindFirst("isManager")!.Value);
            if (!isManager) return Forbid("Sadece yöneticiler erişebilir.");

            var today = DateTimeProvider.TodayTr();

            int managerEmployeeId = int.Parse(User.FindFirst("employeeId")!.Value);

            var manager = _context.Employees
                .AsNoTracking()
                .FirstOrDefault(x => x.EmployeeId == managerEmployeeId);

            if (manager == null) return Unauthorized();

            var deptId = manager.DepartmentId;

            // bekleyen onay sayısı (departman)
            var pendingApprovalCount = _context.LeaveRequests
                .AsNoTracking()
                .Count(lr =>
                    lr.StatusId == 1 &&
                    !lr.IsCancelled &&
                    lr.Employee.DepartmentId == deptId
                );

            // bugün izinde olanlar (approved + tarih aralığı içinde)
            var onLeaveTodayCount = _context.LeaveRequests
                .AsNoTracking()
                .Count(lr =>
                    lr.StatusId == 2 &&
                    !lr.IsCancelled &&
                    lr.Employee.DepartmentId == deptId &&
                    lr.StartDate.Date <= today &&
                    lr.EndDate.Date >= today
                );

            // son 5 talep (departman) - yeni oluşturulanlara göre
            var latest5 = _context.LeaveRequests
                .AsNoTracking()
                .Where(lr => lr.Employee.DepartmentId == deptId)
                .OrderByDescending(lr => lr.CreatedAt)
                .Select(lr => new
                {
                    lr.LeaveRequestId,
                    employeeName = lr.Employee.FirstName + " " + lr.Employee.LastName,
                    leaveTypeName = lr.LeaveType.LeaveTypeName,
                    lr.StartDate,
                    lr.EndDate,
                    statusId = lr.StatusId,
                    status = lr.Status.StatusName,
                    lr.IsCancelled
                })
                .Take(5)
                .ToList();

            return Ok(new
            {
                pendingApprovalCount,
                onLeaveTodayCount,
                latest5
            });
        }
    }
}
