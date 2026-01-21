using System.ComponentModel.DataAnnotations;

namespace IzinTakip.Api.Models
{
    public class LeaveStatus
    {
        [Key]
        public int StatusId { get; set; }
        public string StatusName { get; set; }
        public bool IsActive { get; set; }
    }
}
