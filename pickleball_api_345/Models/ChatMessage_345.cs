using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace pickleball_api_345.Models;

[Table("345_ChatMessages")]
public class ChatMessage_345
{
    [Key]
    public int Id { get; set; }
    
    [Required]
    public int TournamentId { get; set; }
    
    [Required]
    public int MemberId { get; set; }
    
    [Required]
    [MaxLength(1000)]
    public string Message { get; set; } = string.Empty;
    
    public DateTime CreatedDate { get; set; } = DateTime.UtcNow;
    
    public bool IsDeleted { get; set; } = false;
    
    public DateTime? EditedDate { get; set; }
    
    [MaxLength(50)]
    public string MessageType { get; set; } = "text"; // text, image, system
    
    [MaxLength(500)]
    public string? AttachmentUrl { get; set; }
    
    // Navigation properties
    [ForeignKey("TournamentId")]
    public virtual Tournament_345 Tournament { get; set; } = null!;
    
    [ForeignKey("MemberId")]
    public virtual Member_345 Member { get; set; } = null!;
}