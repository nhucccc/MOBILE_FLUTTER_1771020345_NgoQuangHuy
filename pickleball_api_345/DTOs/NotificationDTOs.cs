namespace pickleball_api_345.DTOs;

public class NotificationDto
{
    public int Id { get; set; }
    public string? Title { get; set; }
    public string Message { get; set; } = string.Empty;
    public string Type { get; set; } = string.Empty;
    public string? LinkUrl { get; set; }
    public bool IsRead { get; set; }
    public DateTime CreatedDate { get; set; }
}

public class NotificationSummaryDto
{
    public int UnreadCount { get; set; }
    public List<NotificationDto> Recent { get; set; } = new();
}