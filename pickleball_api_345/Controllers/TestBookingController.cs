using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using pickleball_api_345.Data;
using pickleball_api_345.DTOs;

namespace pickleball_api_345.Controllers;

[ApiController]
[Route("api/[controller]")]
public class TestBookingController : ControllerBase
{
    private readonly ApplicationDbContext _context;

    public TestBookingController(ApplicationDbContext context)
    {
        _context = context;
    }

    [HttpGet("test-courts")]
    public async Task<IActionResult> TestCourts()
    {
        try
        {
            var courts = await _context.Courts_345
                .Where(c => c.IsActive)
                .Select(c => new CourtDto
                {
                    Id = c.Id,
                    Name = c.Name,
                    IsActive = c.IsActive,
                    Description = c.Description,
                    PricePerHour = c.PricePerHour
                })
                .ToListAsync();

            return Ok(new
            {
                success = true,
                count = courts.Count,
                courts = courts,
                message = $"Found {courts.Count} active courts"
            });
        }
        catch (Exception ex)
        {
            return BadRequest(new
            {
                success = false,
                error = ex.Message,
                stackTrace = ex.StackTrace
            });
        }
    }

    [HttpGet("test-members")]
    public async Task<IActionResult> TestMembers()
    {
        try
        {
            var members = await _context.Members_345
                .Where(m => m.IsActive)
                .Take(5)
                .Select(m => new
                {
                    m.Id,
                    m.FullName,
                    m.WalletBalance,
                    m.UserId
                })
                .ToListAsync();

            return Ok(new
            {
                success = true,
                count = members.Count,
                members = members,
                message = $"Found {members.Count} active members"
            });
        }
        catch (Exception ex)
        {
            return BadRequest(new
            {
                success = false,
                error = ex.Message,
                stackTrace = ex.StackTrace
            });
        }
    }

    [HttpPost("test-booking")]
    public async Task<IActionResult> TestBooking([FromBody] TestBookingRequest request)
    {
        try
        {
            // Find member by user ID
            var member = await _context.Members_345
                .FirstOrDefaultAsync(m => m.UserId == request.UserId);

            if (member == null)
            {
                return BadRequest(new
                {
                    success = false,
                    error = "Member not found",
                    userId = request.UserId
                });
            }

            // Find court
            var court = await _context.Courts_345
                .FirstOrDefaultAsync(c => c.Id == request.CourtId && c.IsActive);

            if (court == null)
            {
                return BadRequest(new
                {
                    success = false,
                    error = "Court not found or inactive",
                    courtId = request.CourtId
                });
            }

            // Check wallet balance
            var totalPrice = (decimal)(request.Hours * (double)court.PricePerHour);
            if (member.WalletBalance < totalPrice)
            {
                return BadRequest(new
                {
                    success = false,
                    error = "Insufficient wallet balance",
                    required = totalPrice,
                    available = member.WalletBalance
                });
            }

            return Ok(new
            {
                success = true,
                message = "Booking validation passed",
                member = new { member.Id, member.FullName, member.WalletBalance },
                court = new { court.Id, court.Name, court.PricePerHour },
                totalPrice = totalPrice,
                canBook = true
            });
        }
        catch (Exception ex)
        {
            return BadRequest(new
            {
                success = false,
                error = ex.Message,
                stackTrace = ex.StackTrace
            });
        }
    }
}

public class TestBookingRequest
{
    public string UserId { get; set; } = string.Empty;
    public int CourtId { get; set; }
    public double Hours { get; set; }
}