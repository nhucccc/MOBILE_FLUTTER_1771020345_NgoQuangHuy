using System.ComponentModel.DataAnnotations;

namespace pickleball_api_345.DTOs;

public class CreateBookingDto
{
    [Required(ErrorMessage = "ID sân là bắt buộc")]
    public int CourtId { get; set; }

    [Required(ErrorMessage = "Thời gian bắt đầu là bắt buộc")]
    public DateTime StartTime { get; set; }

    [Required(ErrorMessage = "Thời gian kết thúc là bắt buộc")]
    public DateTime EndTime { get; set; }
    
    public string? Notes { get; set; }
}

public class CreateRecurringBookingDto
{
    [Required(ErrorMessage = "ID sân là bắt buộc")]
    public int CourtId { get; set; }

    [Required(ErrorMessage = "Thời gian bắt đầu là bắt buộc")]
    public DateTime StartTime { get; set; }

    [Required(ErrorMessage = "Thời gian kết thúc là bắt buộc")]
    public DateTime EndTime { get; set; }

    [Required(ErrorMessage = "Quy tắc lặp là bắt buộc")]
    public string RecurrenceRule { get; set; } = string.Empty;

    [Required(ErrorMessage = "Ngày kết thúc lặp là bắt buộc")]
    public DateTime EndDate { get; set; }
}
public class CourtDto
{
    public int Id { get; set; }
    public string Name { get; set; } = string.Empty;
    public bool IsActive { get; set; }
    public string? Description { get; set; }
    public decimal PricePerHour { get; set; }
}

public class BookingDto
{
    public int Id { get; set; }
    public int CourtId { get; set; }
    public int MemberId { get; set; }
    public DateTime StartTime { get; set; }
    public DateTime EndTime { get; set; }
    public decimal TotalPrice { get; set; }
    public int? TransactionId { get; set; }
    public bool IsRecurring { get; set; }
    public string? RecurrenceRule { get; set; }
    public int? ParentBookingId { get; set; }
    public string Status { get; set; } = string.Empty;
    public CourtDto? Court { get; set; }
    public string? MemberName { get; set; }
    public string CourtName { get; set; } = string.Empty;
    public DateTime CreatedDate { get; set; }
    public string? Notes { get; set; }
}

public class CalendarBookingDto
{
    public int Id { get; set; }
    public int CourtId { get; set; }
    public string CourtName { get; set; } = string.Empty;
    public DateTime StartTime { get; set; }
    public DateTime EndTime { get; set; }
    public string Status { get; set; } = string.Empty;
    public string? MemberName { get; set; }
    public bool IsMyBooking { get; set; }
}
public class ConflictingBookingDto
{
    public int BookingId { get; set; }
    public string MemberName { get; set; } = string.Empty;
    public DateTime StartTime { get; set; }
    public DateTime EndTime { get; set; }
    public string Status { get; set; } = string.Empty;
}

public class ConcurrentBookingResultDto
{
    public bool Success { get; set; }
    public string Message { get; set; } = string.Empty;
    public BookingDto? Booking { get; set; }
    public List<ConflictingBookingDto> ConflictingBookings { get; set; } = new();
    public string ConflictType { get; set; } = string.Empty; // "TimeConflict", "ConcurrencyConflict", "None"
}