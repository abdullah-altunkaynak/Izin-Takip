namespace IzinTakip.Api.Models.Dtos
{
    public class ManagerEmployeeDto
    {
        public int EmployeeId { get; set; }
        public string FullName { get; set; } = null!;
        public string Email { get; set; } = null!;
        public bool IsDepartmentManager { get; set; }
        public bool IsActive { get; set; }
    }

}
