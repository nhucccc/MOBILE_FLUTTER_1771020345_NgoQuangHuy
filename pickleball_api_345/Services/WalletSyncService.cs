using Microsoft.AspNetCore.SignalR;
using Microsoft.EntityFrameworkCore;
using pickleball_api_345.Data;
using pickleball_api_345.Hubs;
using pickleball_api_345.Models;
using static pickleball_api_345.Hubs.EventPayloads;
using HubNotificationType = pickleball_api_345.Hubs.NotificationType;
using ModelNotificationType = pickleball_api_345.Models.NotificationType;

namespace pickleball_api_345.Services;

public interface IWalletSyncService
{
    Task SyncWalletBalanceAsync(int memberId, string? transactionId = null);
    Task NotifyWalletUpdateAsync(int memberId, decimal amount, string transactionType, string? description = null, string? transactionId = null);
    Task BroadcastWalletUpdateToAdminsAsync(int memberId, decimal amount, string transactionType);
}

public class WalletSyncService : IWalletSyncService
{
    private readonly IHubContext<PcmHub> _hubContext;
    private readonly ApplicationDbContext _context;
    private readonly ILogger<WalletSyncService> _logger;

    public WalletSyncService(
        IHubContext<PcmHub> hubContext,
        ApplicationDbContext context,
        ILogger<WalletSyncService> logger)
    {
        _hubContext = hubContext;
        _context = context;
        _logger = logger;
    }

    public async Task SyncWalletBalanceAsync(int memberId, string? transactionId = null)
    {
        try
        {
            var member = await _context.Members_345
                .Include(m => m.User)
                .FirstOrDefaultAsync(m => m.Id == memberId);

            if (member?.User == null)
            {
                _logger.LogWarning($"Member {memberId} not found for wallet sync");
                return;
            }

            var walletUpdate = new WalletUpdatePayload
            {
                Balance = member.WalletBalance,
                MemberId = memberId,
                Timestamp = DateTime.UtcNow,
                TransactionId = transactionId
            };

            // Send to user's personal group
            await _hubContext.Clients.Group(SignalRGroups.User(member.User.Id))
                .SendAsync(SignalREvents.UpdateWalletBalance, walletUpdate);

            _logger.LogInformation($"💰 Synced wallet balance for member {memberId}: {member.WalletBalance:N0} VND");
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, $"❌ Error syncing wallet balance for member {memberId}");
        }
    }

    public async Task NotifyWalletUpdateAsync(int memberId, decimal amount, string transactionType, string? description = null, string? transactionId = null)
    {
        try
        {
            var member = await _context.Members_345
                .Include(m => m.User)
                .FirstOrDefaultAsync(m => m.Id == memberId);

            if (member?.User == null)
            {
                _logger.LogWarning($"Member {memberId} not found for wallet notification");
                return;
            }

            // Create notification based on transaction type
            var (title, message, notificationType) = GetNotificationContent(amount, transactionType, description);

            var notification = new NotificationPayload
            {
                Type = notificationType,
                Title = title,
                Message = message,
                Timestamp = DateTime.UtcNow,
                Data = new 
                { 
                    Amount = amount,
                    TransactionType = transactionType,
                    Balance = member.WalletBalance,
                    TransactionId = transactionId
                }
            };

            // Send notification
            await _hubContext.Clients.Group(SignalRGroups.User(member.User.Id))
                .SendAsync(SignalREvents.ReceiveNotification, notification);

            // Sync wallet balance
            await SyncWalletBalanceAsync(memberId, transactionId);

            _logger.LogInformation($"✅ Sent wallet notification to member {memberId}: {title}");
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, $"❌ Error sending wallet notification to member {memberId}");
        }
    }

    public async Task BroadcastWalletUpdateToAdminsAsync(int memberId, decimal amount, string transactionType)
    {
        try
        {
            var member = await _context.Members_345
                .FirstOrDefaultAsync(m => m.Id == memberId);

            if (member == null) return;

            var adminNotification = new NotificationPayload
            {
                Type = HubNotificationType.Info.ToString(),
                Title = "Cập nhật ví thành viên",
                Message = $"{member.FullName} - {transactionType}: {amount:N0} VND",
                Timestamp = DateTime.UtcNow,
                Data = new 
                { 
                    MemberId = memberId,
                    MemberName = member.FullName,
                    Amount = amount,
                    TransactionType = transactionType,
                    NewBalance = member.WalletBalance
                }
            };

            // Send to all admins
            await _hubContext.Clients.Group(SignalRGroups.AdminRole())
                .SendAsync(SignalREvents.ReceiveNotification, adminNotification);

            _logger.LogInformation($"📢 Broadcasted wallet update to admins: {member.FullName} - {transactionType}");
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, $"❌ Error broadcasting wallet update to admins");
        }
    }

    private static (string title, string message, string notificationType) GetNotificationContent(
        decimal amount, string transactionType, string? description)
    {
        return transactionType.ToLower() switch
        {
            "deposit" => (
                "💰 Nạp tiền thành công",
                $"Bạn đã nạp thành công {amount:N0} VND vào ví",
                HubNotificationType.Success.ToString()
            ),
            "payment" => (
                "💳 Thanh toán thành công", 
                description ?? $"Bạn đã thanh toán {Math.Abs(amount):N0} VND",
                HubNotificationType.Info.ToString()
            ),
            "refund" => (
                "💸 Hoàn tiền thành công",
                description ?? $"Bạn đã được hoàn {amount:N0} VND",
                HubNotificationType.Success.ToString()
            ),
            "booking" => (
                "🏟️ Đặt sân thành công",
                description ?? $"Bạn đã thanh toán {Math.Abs(amount):N0} VND cho việc đặt sân",
                HubNotificationType.Success.ToString()
            ),
            "tournament" => (
                "🏆 Tham gia giải đấu",
                description ?? $"Bạn đã thanh toán {Math.Abs(amount):N0} VND phí tham gia giải đấu",
                HubNotificationType.Success.ToString()
            ),
            _ => (
                "💰 Cập nhật ví",
                description ?? $"Số dư ví đã được cập nhật: {amount:N0} VND",
                HubNotificationType.Info.ToString()
            )
        };
    }
}