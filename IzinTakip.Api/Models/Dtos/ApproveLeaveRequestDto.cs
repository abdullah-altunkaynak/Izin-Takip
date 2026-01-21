using System.ComponentModel.DataAnnotations;

namespace IzinTakip.Api.Models.Dtos
{
    public class ApproveLeaveRequestDto
    {
        [Required]
        public int ManagerEmployeeId { get; set; }
    }
}
