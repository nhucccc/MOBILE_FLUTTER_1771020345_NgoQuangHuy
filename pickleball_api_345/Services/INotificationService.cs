using pickleball_api_345.Models;

namespace pickleball_api_345.Services;

public interface INotificationService
{
    Task SendNotificationAsync(int memberId, string title, string message, NotificationType type);
    Task SendNotificationAsync(string userId, string title, string message, NotificationType type);
    Task BroadcastToAllAsync(string title, string message, NotificationType type);
    Task NotifyWalletDepositAsync(string userId, decimal amount);
    Task NotifyMatchScoreUpdateAsync(string matchId, object matchData);
    Task NotifyTournamentUpdateAsync(string tournamentId, object tournamentData);
    
    // Additional methods for notification management
    Task<List<object>> GetNotificationsAsync(int memberId, int page = 1, int pageSize = 20);
    Task<int> GetUnreadCountAsync(int memberId);
    Task<bool> MarkAsReadAsync(int notificationId, int memberId);
    Task<bool> MarkAllAsReadAsync(int memberId);
}