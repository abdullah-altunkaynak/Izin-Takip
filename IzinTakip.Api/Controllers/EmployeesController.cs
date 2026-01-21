using IzinTakip.Api.Data;
using IzinTakip.Api.Models.Dtos;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace IzinTakip.Api.Controllers
{
    [Authorize]
    [ApiController]
    [Route("api/[controller]")]
    public class EmployeesController : ControllerBase
    {
        private readonly AppDbContext _context;
        public EmployeesController(AppDbContext context)
        {
            _context = context;
        }

        [HttpGet]
        public IActionResult GetAllEmployees()
        {
            var employees = _context.Employees.ToList();
            return Ok(employees);
        }


        // yöneticinin departmanındaki personeller
        [Authorize(Roles = "Manager")]
        [HttpGet("manager/myemployees")]
        public IActionResult GetMyEmployees() {

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

            var myEmployees = _context.Employees.AsNoTracking()
               .Where(x => x.IsActive && x.DepartmentId == manager.DepartmentId &&
                           x.EmployeeId != manager.EmployeeId)
               .OrderBy(x => x.FirstName).ThenBy(x => x.LastName)
               .Select(x => new ManagerEmployeeDto
               {
                   EmployeeId = x.EmployeeId,
                   FullName = x.FirstName + " " + x.LastName,
                   Email = x.Email,
                   IsDepartmentManager = x.IsDepartmentManager,
                   IsActive = x.IsActive
               })
               .ToList();

            return Ok(myEmployees);
        }
    }
}
