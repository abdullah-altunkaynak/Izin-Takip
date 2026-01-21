namespace IzinTakip.Api.Models
{
    public class LeaveRequest
    {
        public int LeaveRequestId { get; set; }
        public int EmployeeId { get; set; }
        public int LeaveTypeId { get; set; }
        public DateTime StartDate { get; set; }
        public DateTime EndDate { get; set; }
        public int StatusId { get; set; }
        public string? Description { get; set; }
        public string? RejectionReason { get; set; }

        public bool IsCancelled { get; set; }
        public DateTime? CancelledAt { get; set; }

        public int? ApprovedByEmployeeId { get; set; }
        public DateTime? ApprovedAt { get; set; }

        public DateTime? CreatedAt { get; set; }

        public LeaveStatus Status { get; set; } = null!;
        public LeaveType LeaveType { get; set; } = null!;
        public Employee Employee { get; set; } = null!;
    }
}
