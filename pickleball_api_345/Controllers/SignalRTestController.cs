using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using pickleball_api_345.Models;
using pickleball_api_345.Services;

namespace pickleball_api_345.Controllers;

[ApiController]
[Route("api/[controller]")]
[Authorize]
public class SignalRTestController : ControllerBase
{
    private readonly INotificationService _notificationService;

    public SignalRTestController(INotificationService notificationService)
    {
        _notificationService = notificationService;
    }

    [HttpPost("test-notification")]
    public async Task<IActionResult> TestNotification([FromBody] TestNotificationRequest request)
    {
        await _notificationService.SendNotificationAsync(
            request.UserId,
            request.Title,
            request.Message,
            NotificationType.Info
        );

        return Ok(new { message = "Notification sent successfully" });
    }

    [HttpPost("test-wallet-deposit")]
    public async Task<IActionResult> TestWalletDeposit([FromBody] TestWalletDepositRequest request)
    {
        await _notificationService.NotifyWalletDepositAsync(request.UserId, request.Amount);
        return Ok(new { message = "Wallet deposit notification sent successfully" });
    }

    [HttpPost("test-broadcast")]
    public async Task<IActionResult> TestBroadcast([FromBody] TestBroadcastRequest request)
    {
        await _notificationService.BroadcastToAllAsync(
            request.Title,
            request.Message,
            NotificationType.Info
        );

        return Ok(new { message = "Broadcast sent successfully" });
    }

    [HttpPost("test-match-score")]
    public async Task<IActionResult> TestMatchScore([FromBody] TestMatchScoreRequest request)
    {
        var matchData = new
        {
            MatchId = request.MatchId,
            Team1Score = request.Team1Score,
            Team2Score = request.Team2Score,
            Status = "InProgress",
            UpdatedAt = DateTime.UtcNow
        };

        await _notificationService.NotifyMatchScoreUpdateAsync(request.MatchId, matchData);
        return Ok(new { message = "Match score update sent successfully" });
    }
}

public class TestNotificationRequest
{
    public string UserId { get; set; } = string.Empty;
    public string Title { get; set; } = string.Empty;
    public string Message { get; set; } = string.Empty;
}

public class TestWalletDepositRequest
{
    public string UserId { get; set; } = string.Empty;
    public decimal Amount { get; set; }
}

public class TestBroadcastRequest
{
    public string Title { get; set; } = string.Empty;
    public string Message { get; set; } = string.Empty;
}

public class TestMatchScoreRequest
{
    public string MatchId { get; set; } = string.Empty;
    public int Team1Score { get; set; }
    public int Team2Score { get; set; }
}