using IzinTakip.Api.Models;
using Microsoft.EntityFrameworkCore;

namespace IzinTakip.Api.Data
{
    public class AppDbContext : DbContext
    {
        public AppDbContext(DbContextOptions<AppDbContext> options) : base(options)
        {
        }

        public DbSet<Employee> Employees { get; set; }
        public DbSet<Department> Departments { get; set; }
        public DbSet<LeaveRequest> LeaveRequests { get; set; }
        public DbSet<Users> Users { get; set; }
        public DbSet<LeaveType> LeaveTypes { get; set; }
        public DbSet<LeaveStatus> LeaveStatus { get; set; }
        public DbSet<EmployeeAnnualLeave> EmployeeAnnualLeave { get; set; } = null!;
    }
}
