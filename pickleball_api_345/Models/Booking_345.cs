using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace pickleball_api_345.Models;

[Table("345_Bookings")]
public class Booking_345
{
    [Key]
    public int Id { get; set; }
    
    [Required]
    public int CourtId { get; set; }
    
    [Required]
    public int MemberId { get; set; }
    
    public DateTime StartTime { get; set; }
    
    public DateTime EndTime { get; set; }
    
    [Column(TypeName = "decimal(18,2)")]
    public decimal TotalPrice { get; set; }
    
    public int? TransactionId { get; set; }
    
    // Advanced properties
    public bool IsRecurring { get; set; } = false;
    
    [MaxLength(200)]
    public string? RecurrenceRule { get; set; }
    
    public int? ParentBookingId { get; set; }
    
    public BookingStatus Status { get; set; } = BookingStatus.PendingPayment;
    
    public DateTime CreatedDate { get; set; } = DateTime.UtcNow;
    
    [MaxLength(500)]
    public string? Notes { get; set; }
    
    // Background service fields
    public bool ReminderSent { get; set; } = false;
    
    public DateTime? CancelledDate { get; set; }
    
    [MaxLength(200)]
    public string? CancelReason { get; set; }
    
    // Optimistic concurrency control
    [Timestamp]
    public byte[] RowVersion { get; set; } = new byte[0];
    
    // Navigation properties
    [ForeignKey("CourtId")]
    public virtual Court_345 Court { get; set; } = null!;
    
    [ForeignKey("MemberId")]
    public virtual Member_345 Member { get; set; } = null!;
    
    [ForeignKey("TransactionId")]
    public virtual WalletTransaction_345? Transaction { get; set; }
    
    [ForeignKey("ParentBookingId")]
    public virtual Booking_345? ParentBooking { get; set; }
    
    public virtual ICollection<Booking_345> ChildBookings { get; set; } = new List<Booking_345>();
}