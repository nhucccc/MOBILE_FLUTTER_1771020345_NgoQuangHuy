using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace pickleball_api_345.Models;

[Table("345_TournamentParticipants")]
public class TournamentParticipant_345
{
    [Key]
    public int Id { get; set; }
    
    [Required]
    public int TournamentId { get; set; }
    
    [Required]
    public int MemberId { get; set; }
    
    [MaxLength(100)]
    public string? TeamName { get; set; }
    
    public PaymentStatus PaymentStatus { get; set; } = PaymentStatus.Pending;
    
    public DateTime JoinedDate { get; set; } = DateTime.UtcNow;
    
    public int? TransactionId { get; set; }
    
    [MaxLength(500)]
    public string? Notes { get; set; }
    
    // Navigation properties
    [ForeignKey("TournamentId")]
    public virtual Tournament_345 Tournament { get; set; } = null!;
    
    [ForeignKey("MemberId")]
    public virtual Member_345 Member { get; set; } = null!;
    
    [ForeignKey("TransactionId")]
    public virtual WalletTransaction_345? Transaction { get; set; }
}