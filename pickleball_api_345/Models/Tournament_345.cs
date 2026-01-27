using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace pickleball_api_345.Models;

[Table("345_Tournaments")]
public class Tournament_345
{
    [Key]
    public int Id { get; set; }
    
    [Required]
    [MaxLength(200)]
    public string Name { get; set; } = string.Empty;
    
    public DateTime StartDate { get; set; }
    
    public DateTime EndDate { get; set; }
    
    public DateTime RegistrationDeadline { get; set; }
    
    public TournamentFormat Format { get; set; } = TournamentFormat.RoundRobin;
    
    [Column(TypeName = "decimal(18,2)")]
    public decimal EntryFee { get; set; } = 0;
    
    [Column(TypeName = "decimal(18,2)")]
    public decimal PrizePool { get; set; } = 0;
    
    public TournamentStatus Status { get; set; } = TournamentStatus.Open;
    
    public string? Settings { get; set; } // JSON configuration
    
    public DateTime CreatedDate { get; set; } = DateTime.UtcNow;
    
    [MaxLength(50)]
    public string? CreatedBy { get; set; }
    
    [MaxLength(1000)]
    public string? Description { get; set; }
    
    public int MaxParticipants { get; set; } = 32;
    
    public bool IsActive { get; set; } = true;
    
    // Navigation properties
    public virtual ICollection<TournamentParticipant_345> Participants { get; set; } = new List<TournamentParticipant_345>();
    public virtual ICollection<Match_345> Matches { get; set; } = new List<Match_345>();
}