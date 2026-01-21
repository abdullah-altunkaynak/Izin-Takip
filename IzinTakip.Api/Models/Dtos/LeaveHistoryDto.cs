namespace IzinTakip.Api.Models.Dtos
{
    public class LeaveHistoryDto
    {
        public int LeaveRequestId { get; set; }
        public string LeaveTypeName { get; set; } = null!;
        public DateTime StartDate { get; set; }
        public DateTime EndDate { get; set; }
        public string Status { get; set; } = null!;
        public string? RejectionReason { get; set; }
        public DateTime? ApprovedAt { get; set; }
    }
}
