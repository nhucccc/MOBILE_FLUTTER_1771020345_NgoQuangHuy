using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace pickleball_api_345.Models;

[Table("345_Courts")]
public class Court_345
{
    [Key]
    public int Id { get; set; }
    
    [Required]
    [MaxLength(100)]
    public string Name { get; set; } = string.Empty;
    
    public bool IsActive { get; set; } = true;
    
    [MaxLength(500)]
    public string? Description { get; set; }
    
    [Column(TypeName = "decimal(18,2)")]
    public decimal PricePerHour { get; set; } = 0;
    
    // Navigation properties
    public virtual ICollection<Booking_345> Bookings { get; set; } = new List<Booking_345>();
}