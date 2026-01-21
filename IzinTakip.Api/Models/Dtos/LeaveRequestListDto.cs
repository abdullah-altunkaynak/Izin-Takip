namespace IzinTakip.Api.Models.Dtos
{
    public class LeaveRequestListDto
    {
        public int LeaveRequestId { get; set; }
        public string LeaveType { get; set; }
        public DateTime StartDate { get; set; }
        public DateTime EndDate { get; set; }
        public string Status { get; set; }
        public string? Description { get; set; }
        public DateTime? CreatedAt { get; set; }
    }
}
