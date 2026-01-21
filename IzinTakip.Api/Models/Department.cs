namespace IzinTakip.Api.Models
{
    public class Department
    {
        public int DepartmentId { get; set; }
        public string DepartmentName { get; set; }
        public int? ManagerEmployeeId { get; set; }
        public DateTime CreatedAt { get; set; }
    }
}
