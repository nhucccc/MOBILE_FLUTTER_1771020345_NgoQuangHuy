using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using pickleball_api_345.Data;

namespace pickleball_api_345.Controllers;

[ApiController]
[Route("api/[controller]")]
public class TestRankingController : ControllerBase
{
    private readonly ApplicationDbContext _context;

    public TestRankingController(ApplicationDbContext context)
    {
        _context = context;
    }

    [HttpGet("test-members")]
    public async Task<IActionResult> TestMembers()
    {
        try
        {
            var members = await _context.Members_345
                .Include(m => m.User)
                .Where(m => m.IsActive)
                .OrderByDescending(m => m.DuprRating)
                .Take(5)
                .Select(m => new
                {
                    m.Id,
                    m.FullName,
                    DuprRating = m.DuprRating,
                    m.WalletBalance,
                    Tier = m.Tier.ToString()
                })
                .ToListAsync();

            return Ok(new { 
                success = true, 
                count = members.Count,
                data = members 
            });
        }
        catch (Exception ex)
        {
            return BadRequest(new { 
                success = false, 
                message = ex.Message,
                stackTrace = ex.StackTrace
            });
        }
    }
}