using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.SignalR;
using System.Security.Claims;

namespace pickleball_api_345.Hubs;

[Authorize]
public class PcmHub : Hub
{
    // Heartbeat method for connection health check
    public async Task Ping()
    {
        await Clients.Caller.SendAsync("Pong");
    }

    public async Task JoinUserGroup(string userId = null)
    {
        var actualUserId = userId ?? Context.User?.FindFirst(ClaimTypes.NameIdentifier)?.Value;
        if (!string.IsNullOrEmpty(actualUserId))
        {
            await Groups.AddToGroupAsync(Context.ConnectionId, $"User_{actualUserId}");
        }
    }

    public async Task LeaveUserGroup(string userId = null)
    {
        var actualUserId = userId ?? Context.User?.FindFirst(ClaimTypes.NameIdentifier)?.Value;
        if (!string.IsNullOrEmpty(actualUserId))
        {
            await Groups.RemoveFromGroupAsync(Context.ConnectionId, $"User_{actualUserId}");
        }
    }

    public async Task JoinTournamentGroup(string tournamentId)
    {
        await Groups.AddToGroupAsync(Context.ConnectionId, $"Tournament_{tournamentId}");
    }

    public async Task LeaveTournamentGroup(string tournamentId)
    {
        await Groups.RemoveFromGroupAsync(Context.ConnectionId, $"Tournament_{tournamentId}");
    }

    public async Task JoinCourtGroup(string courtId)
    {
        await Groups.AddToGroupAsync(Context.ConnectionId, $"Court_{courtId}");
    }

    public async Task LeaveCourtGroup(string courtId)
    {
        await Groups.RemoveFromGroupAsync(Context.ConnectionId, $"Court_{courtId}");
    }

    public async Task JoinMatchGroup(string matchId)
    {
        await Groups.AddToGroupAsync(Context.ConnectionId, $"Match_{matchId}");
    }

    public async Task LeaveMatchGroup(string matchId)
    {
        await Groups.RemoveFromGroupAsync(Context.ConnectionId, $"Match_{matchId}");
    }

    public async Task JoinChatRoom(string tournamentId)
    {
        await Groups.AddToGroupAsync(Context.ConnectionId, $"Tournament_{tournamentId}");
    }

    public async Task LeaveChatRoom(string tournamentId)
    {
        await Groups.RemoveFromGroupAsync(Context.ConnectionId, $"Tournament_{tournamentId}");
    }

    // Typing indicator for chat
    public async Task SendTypingIndicator(int tournamentId, bool isTyping)
    {
        var userId = Context.User?.FindFirst(ClaimTypes.NameIdentifier)?.Value;
        var userName = Context.User?.FindFirst(ClaimTypes.Name)?.Value ?? "Unknown";
        
        await Clients.GroupExcept($"Tournament_{tournamentId}", Context.ConnectionId)
            .SendAsync("TypingIndicator", new { userId, userName, isTyping });
    }

    public override async Task OnConnectedAsync()
    {
        await JoinUserGroup();
        await base.OnConnectedAsync();
    }

    public override async Task OnDisconnectedAsync(Exception? exception)
    {
        await LeaveUserGroup();
        await base.OnDisconnectedAsync(exception);
    }

    // Client methods to be called from server
    public async Task ReceiveNotification(object notification)
    {
        await Clients.Caller.SendAsync("ReceiveNotification", notification);
    }

    public async Task UpdateCalendar(object calendarData)
    {
        await Clients.All.SendAsync("UpdateCalendar", calendarData);
    }

    public async Task RefreshCalendar()
    {
        await Clients.All.SendAsync("RefreshCalendar");
    }

    public async Task UpdateMatchScore(string matchId, object matchData)
    {
        await Clients.Group($"Match_{matchId}").SendAsync("MatchScoreUpdated", matchData);
    }

    public async Task UpdateTournamentBracket(string tournamentId, object bracketData)
    {
        await Clients.Group($"Tournament_{tournamentId}").SendAsync("TournamentBracketUpdated", bracketData);
    }

    public async Task UpdateWalletBalance(object walletData)
    {
        await Clients.Caller.SendAsync("UpdateWalletBalance", walletData);
    }

    public async Task NotifyWalletDeposit(string userId, object depositData)
    {
        await Clients.Group($"User_{userId}").SendAsync("ReceiveNotification", new
        {
            Type = "Success",
            Title = "Nạp tiền thành công",
            Message = $"Bạn đã nạp thành công {depositData}",
            Timestamp = DateTime.UtcNow
        });
    }

    // Slot reservation events
    public async Task NotifySlotStatusChanged(int courtId, string status, object slotData)
    {
        await Clients.Group($"Court_{courtId}").SendAsync("SlotStatusChanged", new
        {
            courtId,
            status,
            data = slotData
        });
    }

    public async Task NotifySlotReserved(int courtId, object slotData)
    {
        await Clients.Group($"Court_{courtId}").SendAsync("SlotReserved", new
        {
            courtId,
            data = slotData
        });
    }

    public async Task NotifySlotReleased(int courtId, object slotData)
    {
        await Clients.Group($"Court_{courtId}").SendAsync("SlotReleased", new
        {
            courtId,
            data = slotData
        });
    }

    public async Task NotifySlotExpired(int courtId, object slotData)
    {
        await Clients.Group($"Court_{courtId}").SendAsync("SlotExpired", new
        {
            courtId,
            data = slotData
        });
    }

    // Booking events
    public async Task NotifyBookingCreated(object bookingData)
    {
        await Clients.All.SendAsync("BookingCreated", bookingData);
    }

    public async Task NotifyBookingCancelled(object bookingData)
    {
        await Clients.All.SendAsync("BookingCancelled", bookingData);
    }

    // Tournament events
    public async Task NotifyTournamentRegistrationOpened(object tournamentData)
    {
        await Clients.All.SendAsync("TournamentRegistrationOpened", tournamentData);
    }

    // Wallet events
    public async Task NotifyWalletDepositApproved(string userId, object depositData)
    {
        await Clients.Group($"User_{userId}").SendAsync("WalletDepositApproved", depositData);
    }

    public async Task NotifyWalletDepositRejected(string userId, object depositData)
    {
        await Clients.Group($"User_{userId}").SendAsync("WalletDepositRejected", depositData);
    }
}