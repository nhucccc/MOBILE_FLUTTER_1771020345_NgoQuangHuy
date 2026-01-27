using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace pickleball_api_345.Models;

[Table("345_Members")]
public class Member_345
{
    [Key]
    public int Id { get; set; }
    
    [Required]
    [MaxLength(100)]
    public string FullName { get; set; } = string.Empty;
    
    public DateTime JoinDate { get; set; } = DateTime.UtcNow;
    
    public double RankLevel { get; set; } = 0.0;
    
    [Column(TypeName = "decimal(3,1)")]
    public decimal DuprRating { get; set; } = 0.0m;
    
    public bool IsActive { get; set; } = true;
    
    // Foreign Key to Identity
    [Required]
    public string UserId { get; set; } = string.Empty;
    
    // Advanced properties
    [Column(TypeName = "decimal(18,2)")]
    public decimal WalletBalance { get; set; } = 0;
    
    public MemberTier Tier { get; set; } = MemberTier.Standard;
    
    [Column(TypeName = "decimal(18,2)")]
    public decimal TotalSpent { get; set; } = 0;
    
    [MaxLength(500)]
    public string? AvatarUrl { get; set; }
    
    // Navigation properties
    [ForeignKey("UserId")]
    public virtual ApplicationUser User { get; set; } = null!;
    
    public virtual ICollection<WalletTransaction_345> WalletTransactions { get; set; } = new List<WalletTransaction_345>();
    public virtual ICollection<Booking_345> Bookings { get; set; } = new List<Booking_345>();
    public virtual ICollection<TournamentParticipant_345> TournamentParticipants { get; set; } = new List<TournamentParticipant_345>();
    public virtual ICollection<Notification_345> Notifications { get; set; } = new List<Notification_345>();
}