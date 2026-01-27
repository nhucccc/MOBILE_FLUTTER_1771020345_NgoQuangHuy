using pickleball_api_345.DTOs;

namespace pickleball_api_345.Services;

public interface IChatService
{
    Task<ChatRoomDto> GetChatRoomAsync(int tournamentId, int memberId);
    Task<List<ChatMessageDto>> GetMessagesAsync(int tournamentId, int memberId, int page = 1, int pageSize = 50);
    Task<ChatMessageDto> SendMessageAsync(SendMessageDto request, int memberId);
    Task<bool> EditMessageAsync(EditMessageDto request, int memberId);
    Task<bool> DeleteMessageAsync(int messageId, int memberId);
    Task<bool> CanAccessChatAsync(int tournamentId, int memberId);
    Task SendSystemMessageAsync(int tournamentId, string message);
}