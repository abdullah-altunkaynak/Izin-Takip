using System.ComponentModel.DataAnnotations;

namespace IzinTakip.Api.Models
{
    public class Users
    {
        [Key]
        public int UserId { get; set; }
        public int EmployeeId { get; set; }
        public string Username { get; set; }
        public string PasswordHash { get; set; }
        public DateTime CreatedAt { get; set; }
    }
}
