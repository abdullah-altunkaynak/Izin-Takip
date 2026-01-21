using System.ComponentModel.DataAnnotations;

namespace IzinTakip.Api.Models.Dtos
{
    public class CreateLeaveRequestDto
    {
        [Required]
        public int LeaveTypeId { get; set; }

        [Required]
        public DateTime StartDate { get; set; }

        [Required]
        public DateTime EndDate { get; set; }

        public string? Description { get; set; }


    }
}
