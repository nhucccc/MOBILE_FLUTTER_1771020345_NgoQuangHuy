using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace pickleball_api_345.Models;

[Table("345_Notifications")]
public class Notification_345
{
    [Key]
    public int Id { get; set; }
    
    [Required]
    public int ReceiverId { get; set; }
    
    [Required]
    [MaxLength(500)]
    public string Message { get; set; } = string.Empty;
    
    public NotificationType Type { get; set; } = NotificationType.Info;
    
    [MaxLength(500)]
    public string? LinkUrl { get; set; }
    
    public bool IsRead { get; set; } = false;
    
    public DateTime CreatedDate { get; set; } = DateTime.UtcNow;
    
    [MaxLength(100)]
    public string? Title { get; set; }
    
    // Navigation property
    [ForeignKey("ReceiverId")]
    public virtual Member_345 Receiver { get; set; } = null!;
}