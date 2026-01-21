using System.ComponentModel.DataAnnotations;

public class EmployeeAnnualLeave
{
    [Key]
    public int EmployeeAnnualLeaveId { get; set; }

    public int EmployeeId { get; set; }
    public int Year { get; set; }
    public int TotalDays { get; set; } = 14;
    public int UsedDays { get; set; } = 0;

    public DateTime CreatedAt { get; set; }
    public DateTime? UpdatedAt { get; set; }
}
