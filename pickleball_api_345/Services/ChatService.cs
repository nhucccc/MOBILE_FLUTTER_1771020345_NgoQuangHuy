using Microsoft.AspNetCore.SignalR;
using Microsoft.EntityFrameworkCore;
using pickleball_api_345.Data;
using pickleball_api_345.DTOs;
using pickleball_api_345.Hubs;
using pickleball_api_345.Models;

namespace pickleball_api_345.Services;

public class ChatService : IChatService
{
    private readonly ApplicationDbContext _context;
    private readonly IHubContext<PcmHub> _hubContext;
    private readonly ILogger<ChatService> _logger;

    public ChatService(
        ApplicationDbContext context,
        IHubContext<PcmHub> hubContext,
        ILogger<ChatService> logger)
    {
        _context = context;
        _hubContext = hubContext;
        _logger = logger;
    }

    public async Task<ChatRoomDto> GetChatRoomAsync(int tournamentId, int memberId)
    {
        try
        {
            var tournament = await _context.Tournaments_345
                .Include(t => t.Participants)
                    .ThenInclude(p => p.Member)
                .FirstOrDefaultAsync(t => t.Id == tournamentId);

            if (tournament == null)
                throw new ArgumentException("Tournament not found");

            // Check if member can access this chat
            if (!await CanAccessChatAsync(tournamentId, memberId))
                throw new UnauthorizedAccessException("Access denied to this chat room");

            var recentMessages = await GetMessagesAsync(tournamentId, memberId, 1, 20);
            
            var participants = tournament.Participants.Select(p => new ChatParticipantDto
            {
                MemberId = p.MemberId,
                MemberName = p.Member.FullName,
                MemberAvatar = p.Member.AvatarUrl ?? "",
                IsOnline = false, // Would be determined by SignalR connection tracking
                LastSeen = DateTime.UtcNow // Would be tracked separately
            }).ToList();

            return new ChatRoomDto
            {
                TournamentId = tournamentId,
                TournamentName = tournament.Name,
                ParticipantCount = tournament.Participants.Count,
                OnlineCount = 0, // Would be tracked by SignalR
                RecentMessages = recentMessages,
                Participants = participants
            };
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, $"Error getting chat room for tournament {tournamentId}");
            throw;
        }
    }

    public async Task<List<ChatMessageDto>> GetMessagesAsync(int tournamentId, int memberId, int page = 1, int pageSize = 50)
    {
        try
        {
            if (!await CanAccessChatAsync(tournamentId, memberId))
                return new List<ChatMessageDto>();

            var messages = await _context.ChatMessages_345
                .Include(m => m.Member)
                .Where(m => m.TournamentId == tournamentId && !m.IsDeleted)
                .OrderByDescending(m => m.CreatedDate)
                .Skip((page - 1) * pageSize)
                .Take(pageSize)
                .Select(m => new ChatMessageDto
                {
                    Id = m.Id,
                    TournamentId = m.TournamentId,
                    MemberId = m.MemberId,
                    MemberName = m.Member.FullName,
                    MemberAvatar = m.Member.AvatarUrl ?? "",
                    Message = m.Message,
                    CreatedDate = m.CreatedDate,
                    EditedDate = m.EditedDate,
                    MessageType = m.MessageType,
                    AttachmentUrl = m.AttachmentUrl,
                    IsOwn = m.MemberId == memberId
                })
                .ToListAsync();

            return messages.OrderBy(m => m.CreatedDate).ToList();
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, $"Error getting messages for tournament {tournamentId}");
            return new List<ChatMessageDto>();
        }
    }

    public async Task<ChatMessageDto> SendMessageAsync(SendMessageDto request, int memberId)
    {
        try
        {
            if (!await CanAccessChatAsync(request.TournamentId, memberId))
                throw new UnauthorizedAccessException("Access denied to this chat room");

            var member = await _context.Members_345.FindAsync(memberId);
            if (member == null)
                throw new ArgumentException("Member not found");

            var chatMessage = new ChatMessage_345
            {
                TournamentId = request.TournamentId,
                MemberId = memberId,
                Message = request.Message,
                MessageType = request.MessageType,
                AttachmentUrl = request.AttachmentUrl,
                CreatedDate = DateTime.UtcNow
            };

            _context.ChatMessages_345.Add(chatMessage);
            await _context.SaveChangesAsync();

            var messageDto = new ChatMessageDto
            {
                Id = chatMessage.Id,
                TournamentId = chatMessage.TournamentId,
                MemberId = chatMessage.MemberId,
                MemberName = member.FullName,
                MemberAvatar = member.AvatarUrl ?? "",
                Message = chatMessage.Message,
                CreatedDate = chatMessage.CreatedDate,
                MessageType = chatMessage.MessageType,
                AttachmentUrl = chatMessage.AttachmentUrl,
                IsOwn = true
            };

            // Send to all participants via SignalR
            await _hubContext.Clients.Group($"Tournament_{request.TournamentId}")
                .SendAsync("ReceiveChatMessage", messageDto);

            _logger.LogInformation($"Message sent by member {memberId} to tournament {request.TournamentId}");

            return messageDto;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error sending chat message");
            throw;
        }
    }

    public async Task<bool> EditMessageAsync(EditMessageDto request, int memberId)
    {
        try
        {
            var message = await _context.ChatMessages_345
                .FirstOrDefaultAsync(m => m.Id == request.MessageId && m.MemberId == memberId);

            if (message == null)
                return false;

            // Only allow editing within 15 minutes
            if (DateTime.UtcNow - message.CreatedDate > TimeSpan.FromMinutes(15))
                return false;

            message.Message = request.Message;
            message.EditedDate = DateTime.UtcNow;

            await _context.SaveChangesAsync();

            // Notify via SignalR
            await _hubContext.Clients.Group($"Tournament_{message.TournamentId}")
                .SendAsync("MessageEdited", new { MessageId = message.Id, NewMessage = message.Message, EditedDate = message.EditedDate });

            return true;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error editing chat message");
            return false;
        }
    }

    public async Task<bool> DeleteMessageAsync(int messageId, int memberId)
    {
        try
        {
            var message = await _context.ChatMessages_345
                .FirstOrDefaultAsync(m => m.Id == messageId && m.MemberId == memberId);

            if (message == null)
                return false;

            // Only allow deleting within 15 minutes
            if (DateTime.UtcNow - message.CreatedDate > TimeSpan.FromMinutes(15))
                return false;

            message.IsDeleted = true;
            await _context.SaveChangesAsync();

            // Notify via SignalR
            await _hubContext.Clients.Group($"Tournament_{message.TournamentId}")
                .SendAsync("MessageDeleted", new { MessageId = messageId });

            return true;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error deleting chat message");
            return false;
        }
    }

    public async Task<bool> CanAccessChatAsync(int tournamentId, int memberId)
    {
        try
        {
            // Check if member is participant in the tournament
            var isParticipant = await _context.TournamentParticipants_345
                .AnyAsync(tp => tp.TournamentId == tournamentId && tp.MemberId == memberId);

            // Or check if member is admin/referee
            var member = await _context.Members_345
                .Include(m => m.User)
                .FirstOrDefaultAsync(m => m.Id == memberId);

            if (member?.User != null)
            {
                var userRoles = await _context.UserRoles
                    .Where(ur => ur.UserId == member.User.Id)
                    .Join(_context.Roles, ur => ur.RoleId, r => r.Id, (ur, r) => r.Name)
                    .ToListAsync();

                var isAdminOrReferee = userRoles.Any(role => role == "Admin" || role == "Referee");
                return isParticipant || isAdminOrReferee;
            }

            return isParticipant;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error checking chat access");
            return false;
        }
    }

    public async Task SendSystemMessageAsync(int tournamentId, string message)
    {
        try
        {
            var systemMessage = new ChatMessage_345
            {
                TournamentId = tournamentId,
                MemberId = 0, // System message
                Message = message,
                MessageType = "system",
                CreatedDate = DateTime.UtcNow
            };

            _context.ChatMessages_345.Add(systemMessage);
            await _context.SaveChangesAsync();

            var messageDto = new ChatMessageDto
            {
                Id = systemMessage.Id,
                TournamentId = systemMessage.TournamentId,
                MemberId = 0,
                MemberName = "System",
                MemberAvatar = "",
                Message = systemMessage.Message,
                CreatedDate = systemMessage.CreatedDate,
                MessageType = "system",
                IsOwn = false
            };

            // Send to all participants via SignalR
            await _hubContext.Clients.Group($"Tournament_{tournamentId}")
                .SendAsync("ReceiveChatMessage", messageDto);

            _logger.LogInformation($"System message sent to tournament {tournamentId}");
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error sending system message");
        }
    }
}