using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace pickleball_api_345.Models;

[Table("345_WalletTransactions")]
public class WalletTransaction_345
{
    [Key]
    public int Id { get; set; }
    
    [Required]
    public int MemberId { get; set; }
    
    [Column(TypeName = "decimal(18,2)")]
    public decimal Amount { get; set; }
    
    public TransactionType Type { get; set; }
    
    public TransactionStatus Status { get; set; } = TransactionStatus.Pending;
    
    [MaxLength(50)]
    public string? RelatedId { get; set; }
    
    [MaxLength(500)]
    public string? Description { get; set; }
    
    public DateTime CreatedDate { get; set; } = DateTime.UtcNow;
    
    [MaxLength(500)]
    public string? ProofImageUrl { get; set; }
    
    public DateTime? ProcessedDate { get; set; }
    
    [MaxLength(50)]
    public string? ProcessedBy { get; set; }
    
    [MaxLength(1000)]
    public string? AdminNotes { get; set; }
    
    // Navigation property
    [ForeignKey("MemberId")]
    public virtual Member_345 Member { get; set; } = null!;
}