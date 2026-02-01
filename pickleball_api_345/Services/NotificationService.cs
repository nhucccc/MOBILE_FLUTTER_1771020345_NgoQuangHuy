using Microsoft.AspNetCore.SignalR;
using Microsoft.EntityFrameworkCore;
using pickleball_api_345.Data;
using pickleball_api_345.Hubs;
using pickleball_api_345.Models;
using static pickleball_api_345.Hubs.EventPayloads;
using NotificationType = pickleball_api_345.Models.NotificationType;

namespace pickleball_api_345.Services;

public class NotificationService : INotificationService
{
    private readonly IHubContext<PcmHub> _hubContext;
    private readonly ApplicationDbContext _context;
    private readonly ILogger<NotificationService> _logger;

    public NotificationService(
        IHubContext<PcmHub> hubContext,
        ApplicationDbContext context,
        ILogger<NotificationService> logger)
    {
        _hubContext = hubContext;
        _context = context;
        _logger = logger;
    }

    public async Task SendNotificationAsync(int memberId, string title, string message, NotificationType type)
    {
        try
        {
            var member = await _context.Members_345
                .Include(m => m.User)
                .FirstOrDefaultAsync(m => m.Id == memberId);

            if (member?.User != null)
            {
                await SendNotificationAsync(member.User.Id, title, message, type);
            }
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, $"Error sending notification to member {memberId}");
        }
    }

    public async Task SendNotificationAsync(string userId, string title, string message, NotificationType type)
    {
        try
        {
            var notification = new NotificationPayload
            {
                Type = type.ToString(),
                Title = title,
                Message = message,
                Timestamp = DateTime.UtcNow
            };

            await _hubContext.Clients.Group(SignalRGroups.User(userId))
                .SendAsync(SignalREvents.ReceiveNotification, notification);

            _logger.LogInformation($"✅ Sent notification to user {userId}: {title}");
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, $"❌ Error sending notification to user {userId}");
        }
    }

    public async Task BroadcastToAllAsync(string title, string message, NotificationType type)
    {
        try
        {
            var notification = new NotificationPayload
            {
                Type = type.ToString(),
                Title = title,
                Message = message,
                Timestamp = DateTime.UtcNow
            };

            await _hubContext.Clients.All.SendAsync(SignalREvents.ReceiveNotification, notification);
            _logger.LogInformation($"✅ Broadcasted notification: {title}");
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, $"❌ Error broadcasting notification: {title}");
        }
    }

    public async Task NotifyWalletDepositAsync(string userId, decimal amount)
    {
        try
        {
            var notification = new NotificationPayload
            {
                Type = NotificationType.Success.ToString(),
                Title = "Nạp tiền thành công",
                Message = $"Bạn đã nạp thành công {amount:N0} VND vào ví",
                Timestamp = DateTime.UtcNow,
                Data = new { Amount = amount }
            };

            await _hubContext.Clients.Group(SignalRGroups.User(userId))
                .SendAsync(SignalREvents.ReceiveNotification, notification);

            // ✅ FIXED: Also update wallet balance in real-time with standardized event
            var member = await _context.Members_345
                .FirstOrDefaultAsync(m => m.UserId == userId);

            if (member != null)
            {
                var walletUpdate = new WalletUpdatePayload
                {
                    Balance = member.WalletBalance,
                    Amount = amount,
                    TransactionType = "Deposit",
                    Timestamp = DateTime.UtcNow
                };

                await _hubContext.Clients.Group(SignalRGroups.User(userId))
                    .SendAsync(SignalREvents.UpdateWalletBalance, walletUpdate);
            }

            _logger.LogInformation($"✅ Sent wallet deposit notification to user {userId}: {amount:N0} VND");
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, $"❌ Error sending wallet deposit notification to user {userId}");
        }
    }

    public async Task NotifyMatchScoreUpdateAsync(string matchId, object matchData)
    {
        try
        {
            await _hubContext.Clients.Group(SignalRGroups.Match(int.Parse(matchId)))
                .SendAsync(SignalREvents.MatchScoreUpdated, matchData);

            _logger.LogInformation($"✅ Sent match score update for match {matchId}");
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, $"❌ Error sending match score update for match {matchId}");
        }
    }

    public async Task NotifyTournamentUpdateAsync(string tournamentId, object tournamentData)
    {
        try
        {
            await _hubContext.Clients.Group(SignalRGroups.Tournament(int.Parse(tournamentId)))
                .SendAsync(SignalREvents.TournamentBracketUpdated, tournamentData);

            _logger.LogInformation($"✅ Sent tournament update for tournament {tournamentId}");
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, $"❌ Error sending tournament update for tournament {tournamentId}");
        }
    }

    public async Task<List<object>> GetNotificationsAsync(int memberId, int page = 1, int pageSize = 20)
    {
        // For now, return empty list as we don't have persistent notifications
        // In a real app, you'd query from database
        return new List<object>();
    }

    public async Task<int> GetUnreadCountAsync(int memberId)
    {
        // For now, return 0 as we don't have persistent notifications
        // In a real app, you'd query from database
        return await Task.FromResult(0);
    }

    public async Task<bool> MarkAsReadAsync(int notificationId, int memberId)
    {
        // For now, return true as we don't have persistent notifications
        // In a real app, you'd update database
        return await Task.FromResult(true);
    }

    public async Task<bool> MarkAllAsReadAsync(int memberId)
    {
        // For now, return true as we don't have persistent notifications
        // In a real app, you'd update database
        return await Task.FromResult(true);
    }
}