using IzinTakip.Api.Data;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace IzinTakip.Api.Controllers
{
    [Authorize]
    [ApiController]
    [Route("api/[controller]")]
    public class LeaveStatusesController : ControllerBase
    {
        private readonly AppDbContext _context;

        public LeaveStatusesController(AppDbContext context)
        {
            _context = context;
        }

        [HttpGet]
        public IActionResult GetStatuses()
        {
            return Ok(
                _context.LeaveStatus
                    .Where(x => x.IsActive)
                    .Select(x => new { x.StatusId, x.StatusName })
                    .ToList()
            );
        }

    }
}
