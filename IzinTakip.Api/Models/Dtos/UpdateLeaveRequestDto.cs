namespace IzinTakip.Api.Models.Dtos
{
    public class UpdateLeaveRequestDto
    {
        // sadece güncellenebilir alanlar
        public int LeaveTypeId { get; set; }
        public DateTime StartDate { get; set; }
        public DateTime EndDate { get; set; }
        public string? Description { get; set; }
    }
}
