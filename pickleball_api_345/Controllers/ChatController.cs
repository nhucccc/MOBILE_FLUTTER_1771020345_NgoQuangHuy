using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using pickleball_api_345.DTOs;
using pickleball_api_345.Services;
using System.Security.Claims;

namespace pickleball_api_345.Controllers;

[ApiController]
[Route("api/[controller]")]
[Authorize]
public class ChatController : ControllerBase
{
    private readonly IChatService _chatService;
    private readonly ILogger<ChatController> _logger;

    public ChatController(IChatService chatService, ILogger<ChatController> logger)
    {
        _chatService = chatService;
        _logger = logger;
    }

    [HttpGet("room/{tournamentId}")]
    public async Task<ActionResult<ChatRoomDto>> GetChatRoom(int tournamentId)
    {
        try
        {
            var memberId = GetCurrentMemberId();
            var chatRoom = await _chatService.GetChatRoomAsync(tournamentId, memberId);
            return Ok(chatRoom);
        }
        catch (UnauthorizedAccessException)
        {
            return Forbid("Bạn không có quyền truy cập phòng chat này");
        }
        catch (ArgumentException ex)
        {
            return NotFound(ex.Message);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, $"Error getting chat room for tournament {tournamentId}");
            return StatusCode(500, new { message = "Có lỗi xảy ra khi tải phòng chat" });
        }
    }

    [HttpGet("messages/{tournamentId}")]
    public async Task<ActionResult<List<ChatMessageDto>>> GetMessages(
        int tournamentId,
        [FromQuery] int page = 1,
        [FromQuery] int pageSize = 50)
    {
        try
        {
            var memberId = GetCurrentMemberId();
            var messages = await _chatService.GetMessagesAsync(tournamentId, memberId, page, pageSize);
            return Ok(messages);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, $"Error getting messages for tournament {tournamentId}");
            return StatusCode(500, new { message = "Có lỗi xảy ra khi tải tin nhắn" });
        }
    }

    [HttpPost("send")]
    public async Task<ActionResult<ChatMessageDto>> SendMessage([FromBody] SendMessageDto request)
    {
        try
        {
            var memberId = GetCurrentMemberId();
            var message = await _chatService.SendMessageAsync(request, memberId);
            return Ok(message);
        }
        catch (UnauthorizedAccessException)
        {
            return Forbid("Bạn không có quyền gửi tin nhắn trong phòng chat này");
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error sending chat message");
            return StatusCode(500, new { message = "Có lỗi xảy ra khi gửi tin nhắn" });
        }
    }

    [HttpPut("edit")]
    public async Task<IActionResult> EditMessage([FromBody] EditMessageDto request)
    {
        try
        {
            var memberId = GetCurrentMemberId();
            var success = await _chatService.EditMessageAsync(request, memberId);
            
            if (success)
                return Ok(new { message = "Chỉnh sửa tin nhắn thành công" });
            else
                return BadRequest(new { message = "Không thể chỉnh sửa tin nhắn này" });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error editing chat message");
            return StatusCode(500, new { message = "Có lỗi xảy ra khi chỉnh sửa tin nhắn" });
        }
    }

    [HttpDelete("{messageId}")]
    public async Task<IActionResult> DeleteMessage(int messageId)
    {
        try
        {
            var memberId = GetCurrentMemberId();
            var success = await _chatService.DeleteMessageAsync(messageId, memberId);
            
            if (success)
                return Ok(new { message = "Xóa tin nhắn thành công" });
            else
                return BadRequest(new { message = "Không thể xóa tin nhắn này" });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error deleting chat message");
            return StatusCode(500, new { message = "Có lỗi xảy ra khi xóa tin nhắn" });
        }
    }

    [HttpPost("system/{tournamentId}")]
    [Authorize(Roles = "Admin,Referee")]
    public async Task<IActionResult> SendSystemMessage(int tournamentId, [FromBody] string message)
    {
        try
        {
            await _chatService.SendSystemMessageAsync(tournamentId, message);
            return Ok(new { message = "Gửi thông báo hệ thống thành công" });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error sending system message");
            return StatusCode(500, new { message = "Có lỗi xảy ra khi gửi thông báo hệ thống" });
        }
    }

    private int GetCurrentMemberId()
    {
        var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
        if (string.IsNullOrEmpty(userIdClaim))
            throw new UnauthorizedAccessException("User not authenticated");

        // Get member ID from user ID (you might need to implement this lookup)
        // For now, assuming member ID is stored in a custom claim
        var memberIdClaim = User.FindFirst("MemberId")?.Value;
        if (string.IsNullOrEmpty(memberIdClaim) || !int.TryParse(memberIdClaim, out int memberId))
            throw new UnauthorizedAccessException("Member ID not found");

        return memberId;
    }
}