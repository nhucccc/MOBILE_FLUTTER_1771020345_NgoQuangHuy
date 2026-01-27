using System.ComponentModel.DataAnnotations;

namespace pickleball_api_345.DTOs;

public class ChatRoomDto
{
    public int TournamentId { get; set; }
    public string TournamentName { get; set; } = string.Empty;
    public int ParticipantCount { get; set; }
    public int OnlineCount { get; set; }
    public List<ChatMessageDto> RecentMessages { get; set; } = new();
    public List<ChatParticipantDto> Participants { get; set; } = new();
}

public class ChatMessageDto
{
    public int Id { get; set; }
    public int TournamentId { get; set; }
    public int MemberId { get; set; }
    public string MemberName { get; set; } = string.Empty;
    public string MemberAvatar { get; set; } = string.Empty;
    public string Message { get; set; } = string.Empty;
    public DateTime CreatedDate { get; set; }
    public DateTime? EditedDate { get; set; }
    public string MessageType { get; set; } = "text";
    public string? AttachmentUrl { get; set; }
    public bool IsOwn { get; set; }
}

public class ChatParticipantDto
{
    public int MemberId { get; set; }
    public string MemberName { get; set; } = string.Empty;
    public string MemberAvatar { get; set; } = string.Empty;
    public bool IsOnline { get; set; }
    public DateTime LastSeen { get; set; }
}

public class SendMessageDto
{
    [Required(ErrorMessage = "ID giải đấu là bắt buộc")]
    public int TournamentId { get; set; }

    [Required(ErrorMessage = "Nội dung tin nhắn là bắt buộc")]
    [MaxLength(1000, ErrorMessage = "Tin nhắn không được vượt quá 1000 ký tự")]
    public string Message { get; set; } = string.Empty;

    public string MessageType { get; set; } = "text";
    public string? AttachmentUrl { get; set; }
}

public class EditMessageDto
{
    [Required(ErrorMessage = "ID tin nhắn là bắt buộc")]
    public int MessageId { get; set; }

    [Required(ErrorMessage = "Nội dung tin nhắn là bắt buộc")]
    [MaxLength(1000, ErrorMessage = "Tin nhắn không được vượt quá 1000 ký tự")]
    public string Message { get; set; } = string.Empty;
}