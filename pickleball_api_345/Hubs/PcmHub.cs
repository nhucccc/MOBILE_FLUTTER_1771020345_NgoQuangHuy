using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.SignalR;
using System.Security.Claims;

namespace pickleball_api_345.Hubs;

[Authorize]
public class PcmHub : Hub
{
    public async Task JoinUserGroup()
    {
        var userId = Context.User?.FindFirst(ClaimTypes.NameIdentifier)?.Value;
        if (!string.IsNullOrEmpty(userId))
        {
            await Groups.AddToGroupAsync(Context.ConnectionId, $"User_{userId}");
        }
    }

    public async Task LeaveUserGroup()
    {
        var userId = Context.User?.FindFirst(ClaimTypes.NameIdentifier)?.Value;
        if (!string.IsNullOrEmpty(userId))
        {
            await Groups.RemoveFromGroupAsync(Context.ConnectionId, $"User_{userId}");
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

    public async Task UpdateMatchScore(string matchId, object matchData)
    {
        await Clients.Group($"Match_{matchId}").SendAsync("UpdateMatchScore", matchData);
    }

    public async Task UpdateTournamentBracket(string tournamentId, object bracketData)
    {
        await Clients.Group($"Tournament_{tournamentId}").SendAsync("UpdateTournamentBracket", bracketData);
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
}