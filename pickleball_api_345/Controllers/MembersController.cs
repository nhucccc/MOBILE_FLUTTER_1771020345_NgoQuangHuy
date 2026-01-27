using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using pickleball_api_345.Data;
using pickleball_api_345.DTOs;
using System.Security.Claims;

namespace pickleball_api_345.Controllers;

[ApiController]
[Route("api/[controller]")]
[Authorize]
public class MembersController : ControllerBase
{
    private readonly ApplicationDbContext _context;

    public MembersController(ApplicationDbContext context)
    {
        _context = context;
    }

    [HttpGet]
    public async Task<IActionResult> GetMembers([FromQuery] string? search, [FromQuery] int page = 1, [FromQuery] int pageSize = 20)
    {
        var query = _context.Members_345.Include(m => m.User).AsQueryable();

        if (!string.IsNullOrEmpty(search))
        {
            query = query.Where(m => m.FullName.Contains(search) || m.User.Email!.Contains(search));
        }

        var members = await query
            .OrderByDescending(m => m.JoinDate)
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .Select(m => new
            {
                m.Id,
                m.FullName,
                m.JoinDate,
                m.RankLevel,
                m.IsActive,
                m.WalletBalance,
                Tier = m.Tier.ToString(),
                m.TotalSpent,
                m.AvatarUrl,
                Email = m.User.Email,
                PhoneNumber = m.User.PhoneNumber
            })
            .ToListAsync();

        var totalCount = await query.CountAsync();

        return Ok(new
        {
            data = members,
            totalCount,
            page,
            pageSize,
            totalPages = (int)Math.Ceiling((double)totalCount / pageSize)
        });
    }

    [HttpGet("{id}/profile")]
    public async Task<IActionResult> GetMemberProfile(int id)
    {
        var member = await _context.Members_345
            .Include(m => m.User)
            .Include(m => m.WalletTransactions.OrderByDescending(wt => wt.CreatedDate).Take(10))
            .Include(m => m.Bookings.Where(b => b.Status != Models.BookingStatus.Cancelled).OrderByDescending(b => b.CreatedDate).Take(10))
                .ThenInclude(b => b.Court)
            .FirstOrDefaultAsync(m => m.Id == id);

        if (member == null)
            return NotFound();

        // Get match history
        var matches = await _context.Matches_345
            .Include(m => m.Tournament)
            .Include(m => m.Team1_Player1)
            .Include(m => m.Team1_Player2)
            .Include(m => m.Team2_Player1)
            .Include(m => m.Team2_Player2)
            .Where(m => m.Team1_Player1Id == id || m.Team1_Player2Id == id || 
                       m.Team2_Player1Id == id || m.Team2_Player2Id == id)
            .Where(m => m.Status == Models.MatchStatus.Finished)
            .OrderByDescending(m => m.Date)
            .Take(10)
            .ToListAsync();

        var profile = new
        {
            member.Id,
            member.FullName,
            member.JoinDate,
            member.RankLevel,
            member.IsActive,
            member.WalletBalance,
            Tier = member.Tier.ToString(),
            member.TotalSpent,
            member.AvatarUrl,
            Email = member.User.Email,
            PhoneNumber = member.User.PhoneNumber,
            RecentTransactions = member.WalletTransactions.Select(wt => new
            {
                wt.Id,
                wt.Amount,
                Type = wt.Type.ToString(),
                Status = wt.Status.ToString(),
                wt.Description,
                wt.CreatedDate
            }),
            RecentBookings = member.Bookings.Select(b => new
            {
                b.Id,
                CourtName = b.Court.Name,
                b.StartTime,
                b.EndTime,
                b.TotalPrice,
                Status = b.Status.ToString()
            }),
            MatchHistory = matches.Select(m => new
            {
                m.Id,
                TournamentName = m.Tournament?.Name,
                m.Date,
                m.StartTime,
                Team1 = $"{m.Team1_Player1.FullName}" + (m.Team1_Player2 != null ? $" & {m.Team1_Player2.FullName}" : ""),
                Team2 = $"{m.Team2_Player1.FullName}" + (m.Team2_Player2 != null ? $" & {m.Team2_Player2.FullName}" : ""),
                m.Score1,
                m.Score2,
                WinningSide = m.WinningSide?.ToString(),
                IsWinner = (m.WinningSide == Models.WinningSide.Team1 && (m.Team1_Player1Id == id || m.Team1_Player2Id == id)) ||
                          (m.WinningSide == Models.WinningSide.Team2 && (m.Team2_Player1Id == id || m.Team2_Player2Id == id))
            }),
            Stats = new
            {
                TotalMatches = matches.Count,
                Wins = matches.Count(m => 
                    (m.WinningSide == Models.WinningSide.Team1 && (m.Team1_Player1Id == id || m.Team1_Player2Id == id)) ||
                    (m.WinningSide == Models.WinningSide.Team2 && (m.Team2_Player1Id == id || m.Team2_Player2Id == id))),
                WinRate = matches.Any() ? 
                    (double)matches.Count(m => 
                        (m.WinningSide == Models.WinningSide.Team1 && (m.Team1_Player1Id == id || m.Team1_Player2Id == id)) ||
                        (m.WinningSide == Models.WinningSide.Team2 && (m.Team2_Player1Id == id || m.Team2_Player2Id == id))) / matches.Count * 100 : 0
            }
        };

        return Ok(profile);
    }

    [HttpPut("profile")]
    public async Task<IActionResult> UpdateProfile([FromBody] UpdateProfileDto request)
    {
        if (!ModelState.IsValid)
            return BadRequest(ModelState);

        var userId = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
        if (string.IsNullOrEmpty(userId))
            return Unauthorized();

        var member = await _context.Members_345
            .Include(m => m.User)
            .FirstOrDefaultAsync(m => m.UserId == userId);

        if (member == null)
            return NotFound();

        // Update member info
        member.FullName = request.FullName;
        member.AvatarUrl = request.AvatarUrl;

        // Update user info
        member.User.FullName = request.FullName;
        member.User.PhoneNumber = request.PhoneNumber;

        await _context.SaveChangesAsync();

        return Ok(new { message = "Cập nhật thông tin thành công" });
    }

    private async Task<int?> GetCurrentMemberIdAsync()
    {
        var userId = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
        if (string.IsNullOrEmpty(userId))
            return null;

        var member = await _context.Members_345.FirstOrDefaultAsync(m => m.UserId == userId);
        return member?.Id;
    }
}

public class UpdateProfileDto
{
    public string FullName { get; set; } = string.Empty;
    public string? PhoneNumber { get; set; }
    public string? AvatarUrl { get; set; }
}