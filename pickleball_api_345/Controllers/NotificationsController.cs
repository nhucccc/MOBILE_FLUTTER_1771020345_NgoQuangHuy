using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using pickleball_api_345.Data;
using pickleball_api_345.Services;
using System.Security.Claims;

namespace pickleball_api_345.Controllers;

[ApiController]
[Route("api/[controller]")]
[Authorize]
public class NotificationsController : ControllerBase
{
    private readonly INotificationService _notificationService;
    private readonly ApplicationDbContext _context;

    public NotificationsController(INotificationService notificationService, ApplicationDbContext context)
    {
        _notificationService = notificationService;
        _context = context;
    }

    [HttpGet]
    public async Task<IActionResult> GetNotifications([FromQuery] int page = 1, [FromQuery] int pageSize = 20)
    {
        var memberId = await GetCurrentMemberIdAsync();
        if (memberId == null)
            return BadRequest("Member not found");

        var notifications = await _notificationService.GetNotificationsAsync(memberId.Value, page, pageSize);
        return Ok(notifications);
    }

    [HttpGet("summary")]
    public async Task<IActionResult> GetNotificationSummary()
    {
        var memberId = await GetCurrentMemberIdAsync();
        if (memberId == null)
            return BadRequest("Member not found");

        var unreadCount = await _notificationService.GetUnreadCountAsync(memberId.Value);
        var recent = await _notificationService.GetNotificationsAsync(memberId.Value, 1, 5);

        return Ok(new
        {
            unreadCount,
            recent
        });
    }

    [HttpPut("{id}/read")]
    public async Task<IActionResult> MarkAsRead(int id)
    {
        var memberId = await GetCurrentMemberIdAsync();
        if (memberId == null)
            return BadRequest("Member not found");

        var success = await _notificationService.MarkAsReadAsync(id, memberId.Value);
        if (!success)
            return BadRequest("Không thể đánh dấu đã đọc");

        return Ok(new { message = "Đã đánh dấu đã đọc" });
    }

    [HttpPut("read-all")]
    public async Task<IActionResult> MarkAllAsRead()
    {
        var memberId = await GetCurrentMemberIdAsync();
        if (memberId == null)
            return BadRequest("Member not found");

        var success = await _notificationService.MarkAllAsReadAsync(memberId.Value);
        if (!success)
            return BadRequest("Không thể đánh dấu tất cả đã đọc");

        return Ok(new { message = "Đã đánh dấu tất cả đã đọc" });
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