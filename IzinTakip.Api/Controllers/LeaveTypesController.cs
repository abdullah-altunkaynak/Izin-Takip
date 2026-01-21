using IzinTakip.Api.Data;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace IzinTakip.Api.Controllers
{
    [Authorize]
    [ApiController]
    [Route("api/[controller]")]
    public class LeaveTypesController : ControllerBase
    {
        private readonly AppDbContext _context;

        public LeaveTypesController(AppDbContext context)
        {
            _context = context;
        }

        [HttpGet]
        public IActionResult GetLeaveTypes()
        {
            return Ok(
                _context.LeaveTypes
                    .Where(x => x.IsActive)
                    .Select(x => new { x.LeaveTypeId, x.LeaveTypeName })
                    .ToList()
            );
        }
    }
}
