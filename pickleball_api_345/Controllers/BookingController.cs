using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using pickleball_api_345.Data;
using pickleball_api_345.DTOs;
using pickleball_api_345.Services;
using System.Security.Claims;

namespace pickleball_api_345.Controllers;

[ApiController]
[Route("api/[controller]")]
[Authorize]
public class BookingController : ControllerBase
{
    private readonly IBookingService _bookingService;
    private readonly ApplicationDbContext _context;

    public BookingController(IBookingService bookingService, ApplicationDbContext context)
    {
        _bookingService = bookingService;
        _context = context;
    }

    [HttpGet("courts")]
    public async Task<IActionResult> GetCourts()
    {
        var courts = await _bookingService.GetCourtsAsync();
        return Ok(courts);
    }

    [HttpGet("calendar")]
    public async Task<IActionResult> GetCalendarBookings([FromQuery] DateTime from, [FromQuery] DateTime to)
    {
        var memberId = await GetCurrentMemberIdAsync();
        var bookings = await _bookingService.GetCalendarBookingsAsync(from, to, memberId);
        return Ok(bookings);
    }

    [HttpPost]
    public async Task<IActionResult> CreateBooking([FromBody] CreateBookingDto request)
    {
        if (!ModelState.IsValid)
        {
            var errors = ModelState.Values.SelectMany(v => v.Errors).Select(e => e.ErrorMessage);
            return BadRequest(new { message = "Dữ liệu không hợp lệ", errors });
        }

        var memberId = await GetCurrentMemberIdAsync();
        if (memberId == null)
            return BadRequest(new { message = "Member not found" });

        // Log request data for debugging
        Console.WriteLine($"CreateBooking Request - CourtId: {request.CourtId}, StartTime: {request.StartTime}, EndTime: {request.EndTime}");
        Console.WriteLine($"UTC StartTime: {request.StartTime:yyyy-MM-dd HH:mm:ss}, Local StartTime: {request.StartTime.ToLocalTime():yyyy-MM-dd HH:mm:ss}");

        // Validate booking time
        if (request.StartTime >= request.EndTime)
            return BadRequest(new { message = "Thời gian kết thúc phải sau thời gian bắt đầu" });

        // Convert UTC time to local time for validation
        var localStartTime = request.StartTime.ToLocalTime();
        var localNow = DateTime.Now;
        
        // Allow booking at least 30 minutes in advance (using local time)
        var minimumBookingTime = localNow.AddMinutes(30);
        if (localStartTime <= minimumBookingTime)
            return BadRequest(new { message = $"Không thể đặt sân trong quá khứ hoặc quá gần hiện tại. Vui lòng đặt ít nhất 30 phút trước. Hiện tại: {localNow:yyyy-MM-dd HH:mm}, Thời gian đặt: {localStartTime:yyyy-MM-dd HH:mm}" });

        var booking = await _bookingService.CreateBookingAsync(memberId.Value, request);
        if (booking == null)
            return BadRequest(new { message = "Không thể đặt sân. Vui lòng kiểm tra số dư ví hoặc tình trạng sân" });

        return Ok(new { message = "Đặt sân thành công", booking });
    }

    [HttpPost("recurring")]
    public async Task<IActionResult> CreateRecurringBooking([FromBody] CreateRecurringBookingDto request)
    {
        if (!ModelState.IsValid)
            return BadRequest(ModelState);

        var memberId = await GetCurrentMemberIdAsync();
        if (memberId == null)
            return BadRequest("Member not found");

        // Check if member has VIP tier (Gold or Diamond)
        var member = await _context.Members_345.FindAsync(memberId.Value);
        if (member == null || (member.Tier != Models.MemberTier.Gold && member.Tier != Models.MemberTier.Diamond))
            return BadRequest("Chỉ thành viên Gold và Diamond mới có thể đặt sân định kỳ");

        var bookings = await _bookingService.CreateRecurringBookingAsync(memberId.Value, request);
        if (!bookings.Any())
            return BadRequest("Không thể tạo lịch đặt sân định kỳ");

        return Ok(new { 
            message = $"Đã tạo {bookings.Count} lịch đặt sân định kỳ", 
            bookings = bookings.Take(5) // Return first 5 for preview
        });
    }

    [HttpPost("cancel/{bookingId}")]
    public async Task<IActionResult> CancelBooking(int bookingId)
    {
        var memberId = await GetCurrentMemberIdAsync();
        if (memberId == null)
            return BadRequest("Member not found");

        var success = await _bookingService.CancelBookingAsync(bookingId, memberId.Value);
        if (!success)
            return BadRequest("Không thể hủy đặt sân");

        return Ok(new { message = "Hủy đặt sân thành công" });
    }

    [HttpGet("my-bookings")]
    public async Task<IActionResult> GetMyBookings([FromQuery] int page = 1, [FromQuery] int pageSize = 20)
    {
        var memberId = await GetCurrentMemberIdAsync();
        if (memberId == null)
            return BadRequest("Member not found");

        var bookings = await _bookingService.GetMyBookingsAsync(memberId.Value, page, pageSize);
        return Ok(bookings);
    }

    [HttpGet("check-availability")]
    public async Task<IActionResult> CheckAvailability([FromQuery] int courtId, [FromQuery] DateTime startTime, [FromQuery] DateTime endTime)
    {
        var isAvailable = await _bookingService.IsCourtAvailableAsync(courtId, startTime, endTime);
        return Ok(new { isAvailable });
    }

    private async Task<int?> GetCurrentMemberIdAsync()
    {
        var userId = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
        if (string.IsNullOrEmpty(userId))
            return null;

        var member = await _context.Members_345.FirstOrDefaultAsync(m => m.UserId == userId);
        return member?.Id;
    }
}