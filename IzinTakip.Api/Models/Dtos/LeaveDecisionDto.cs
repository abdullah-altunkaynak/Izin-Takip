namespace IzinTakip.Api.Models.Dtos
{
    public class LeaveDecisionDto
    {
        public bool IsApproved { get; set; }
        public string? RejectionReason { get; set; }
    }
}
