namespace IzinTakip.Api.Models.Dtos
{
    public class MyLeaveRequestDto
    {
        public int LeaveRequestId { get; set; }
        public string LeaveTypeName { get; set; } = null!;
        public DateTime StartDate { get; set; }
        public DateTime EndDate { get; set; }
        public string Status { get; set; } = null!;
        public string? Description { get; set; }
        public string? RejectionReason { get; set; }
        public DateTime? ApprovedAt { get; set; }
        public int LeaveTypeId { get; set; }
        public bool IsCancelled { get; set; }
        public int? EmployeeId { get; set; }
        public string? EmployeeName { get; set; }
    }
}
