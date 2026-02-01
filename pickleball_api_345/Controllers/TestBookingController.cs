using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using pickleball_api_345.Data;
using pickleball_api_345.Models;
using pickleball_api_345.DTOs;

namespace pickleball_api_345.Controllers;

[ApiController]
[Route("api/[controller]")]
public class TestBookingController : ControllerBase
{
    private readonly ApplicationDbContext _context;

    public TestBookingController(ApplicationDbContext context)
    {
        _context = context;
    }

    [HttpGet("test-courts")]
    public async Task<IActionResult> TestCourts()
    {
        try
        {
            var courts = await _context.Courts_345
                .Where(c => c.IsActive)
                .Select(c => new CourtDto
                {
                    Id = c.Id,
                    Name = c.Name,
                    IsActive = c.IsActive,
                    Description = c.Description,
                    PricePerHour = c.PricePerHour
                })
                .ToListAsync();

            return Ok(new
            {
                success = true,
                count = courts.Count,
                courts = courts,
                message = $"Found {courts.Count} active courts"
            });
        }
        catch (Exception ex)
        {
            return BadRequest(new
            {
                success = false,
                error = ex.Message,
                stackTrace = ex.StackTrace
            });
        }
    }

    [HttpGet("court-slots/{courtId}")]
    public async Task<IActionResult> GetCourtSlots(int courtId, [FromQuery] DateTime date)
    {
        try
        {
            // Validate court exists
            var court = await _context.Courts_345
                .FirstOrDefaultAsync(c => c.Id == courtId && c.IsActive);

            if (court == null)
            {
                return BadRequest(new
                {
                    success = false,
                    error = "Court not found or inactive"
                });
            }

            // Generate time slots for the day (6:00 - 22:00)
            var timeSlots = new List<object>();
            var startDate = date.Date;
            var currentTime = DateTime.Now;

            for (int hour = 6; hour < 22; hour++)
            {
                var slotStart = startDate.AddHours(hour);
                var slotEnd = slotStart.AddHours(1);
                var timeSlotText = $"{hour:D2}:00 - {(hour + 1):D2}:00";

                // Check if slot is in the past
                var isPast = slotEnd <= currentTime;

                // Check if slot is booked
                var existingBooking = await _context.Bookings_345
                    .FirstOrDefaultAsync(b => 
                        b.CourtId == courtId &&
                        b.StartTime <= slotStart &&
                        b.EndTime >= slotEnd &&
                        b.Status != BookingStatus.Cancelled);

                // Check if slot is reserved (simulate some reserved slots)
                var isReserved = (hour >= 14 && hour <= 16) && existingBooking == null && !isPast;
                var isBooked = existingBooking != null;
                var isAvailable = !isBooked && !isReserved && !isPast;

                string status;
                string? memberName = null;

                if (isPast)
                {
                    status = "past";
                    memberName = "Đã qua giờ";
                }
                else if (isBooked)
                {
                    status = "booked";
                    var member = await _context.Members_345
                        .FirstOrDefaultAsync(m => m.Id == existingBooking.MemberId);
                    memberName = member?.FullName;
                }
                else if (isReserved)
                {
                    status = "reserved";
                    memberName = "Đang giữ chỗ";
                }
                else
                {
                    status = "available";
                }

                timeSlots.Add(new
                {
                    time = timeSlotText,
                    startTime = slotStart,
                    endTime = slotEnd,
                    status = status,
                    isAvailable = isAvailable,
                    isReserved = isReserved,
                    isBooked = isBooked,
                    isPast = isPast,
                    memberName = memberName
                });
            }

            return Ok(new
            {
                success = true,
                courtId = courtId,
                courtName = court.Name,
                date = date.ToString("yyyy-MM-dd"),
                timeSlots = timeSlots
            });
        }
        catch (Exception ex)
        {
            return BadRequest(new
            {
                success = false,
                error = ex.Message,
                stackTrace = ex.StackTrace
            });
        }
    }

    [HttpGet("test-members")]
    public async Task<IActionResult> TestMembers()
    {
        try
        {
            var members = await _context.Members_345
                .Where(m => m.IsActive)
                .Take(5)
                .Select(m => new
                {
                    m.Id,
                    m.FullName,
                    m.WalletBalance,
                    m.UserId
                })
                .ToListAsync();

            return Ok(new
            {
                success = true,
                count = members.Count,
                members = members,
                message = $"Found {members.Count} active members"
            });
        }
        catch (Exception ex)
        {
            return BadRequest(new
            {
                success = false,
                error = ex.Message,
                stackTrace = ex.StackTrace
            });
        }
    }

    [HttpGet("user-bookings/{userId}")]
    public async Task<IActionResult> GetUserBookings(string userId, [FromQuery] int page = 1, [FromQuery] int pageSize = 10)
    {
        try
        {
            // Find member by user ID
            var member = await _context.Members_345
                .FirstOrDefaultAsync(m => m.UserId == userId);

            if (member == null)
            {
                return BadRequest(new
                {
                    success = false,
                    error = "Member not found",
                    userId = userId
                });
            }

            // Get user's bookings with pagination
            var query = _context.Bookings_345
                .Where(b => b.MemberId == member.Id)
                .Include(b => b.Court)
                .OrderByDescending(b => b.CreatedDate);

            var totalCount = await query.CountAsync();
            var bookings = await query
                .Skip((page - 1) * pageSize)
                .Take(pageSize)
                .Select(b => new
                {
                    id = b.Id,
                    courtId = b.CourtId,
                    courtName = b.Court.Name,
                    startTime = b.StartTime,
                    endTime = b.EndTime,
                    totalPrice = b.TotalPrice,
                    status = b.Status.ToString(),
                    createdDate = b.CreatedDate,
                    notes = b.Notes,
                    isRecurring = b.IsRecurring,
                    duration = (b.EndTime - b.StartTime).TotalHours
                })
                .ToListAsync();

            return Ok(new
            {
                success = true,
                data = bookings,
                pagination = new
                {
                    currentPage = page,
                    pageSize = pageSize,
                    totalCount = totalCount,
                    totalPages = (int)Math.Ceiling((double)totalCount / pageSize)
                },
                message = $"Found {bookings.Count} bookings for user"
            });
        }
        catch (Exception ex)
        {
            return BadRequest(new
            {
                success = false,
                error = ex.Message,
                stackTrace = ex.StackTrace
            });
        }
    }

    [HttpPost("seed-bookings")]
    public async Task<IActionResult> SeedBookings()
    {
        try
        {
            // Check if bookings already exist
            var existingBookings = await _context.Bookings_345.CountAsync();
            if (existingBookings > 0)
            {
                return Ok(new
                {
                    success = true,
                    message = $"Bookings already exist ({existingBookings} bookings found)",
                    existingCount = existingBookings
                });
            }

            var members = await _context.Members_345.Take(3).ToListAsync();
            var courts = await _context.Courts_345.Take(2).ToListAsync();
            
            if (!members.Any() || !courts.Any())
            {
                return BadRequest(new
                {
                    success = false,
                    error = "No members or courts found to create bookings"
                });
            }

            var bookings = new List<Booking_345>();
            var random = new Random();
            
            for (int i = 0; i < 15; i++)
            {
                var member = members[random.Next(members.Count)];
                var court = courts[random.Next(courts.Count)];
                var startDate = DateTime.Now.AddDays(-random.Next(60)); // Random date in last 60 days
                var startTime = startDate.Date.AddHours(6 + random.Next(16)); // 6AM to 10PM
                var endTime = startTime.AddHours(1 + random.Next(3)); // 1-3 hours duration
                
                var booking = new Booking_345
                {
                    MemberId = member.Id,
                    CourtId = court.Id,
                    StartTime = startTime,
                    EndTime = endTime,
                    TotalPrice = (decimal)((endTime - startTime).TotalHours * (double)court.PricePerHour),
                    Status = (BookingStatus)(1 + random.Next(4)), // Random status (1-4)
                    CreatedDate = startTime.AddDays(-random.Next(7)), // Created 0-7 days before start
                    Notes = i % 3 == 0 ? $"Ghi chú cho booking #{i + 1} - Đặt sân cho nhóm bạn" : null,
                    IsRecurring = false
                };
                
                bookings.Add(booking);
            }
            
            _context.Bookings_345.AddRange(bookings);
            await _context.SaveChangesAsync();

            return Ok(new
            {
                success = true,
                message = $"Successfully created {bookings.Count} sample bookings",
                bookingsCreated = bookings.Count,
                members = members.Select(m => new { m.Id, m.FullName }).ToList(),
                courts = courts.Select(c => new { c.Id, c.Name }).ToList()
            });
        }
        catch (Exception ex)
        {
            return BadRequest(new
            {
                success = false,
                error = ex.Message,
                stackTrace = ex.StackTrace
            });
        }
    }

    [HttpPost("test-booking")]
    public async Task<IActionResult> TestBooking([FromBody] TestBookingRequest request)
    {
        try
        {
            // Find member by user ID
            var member = await _context.Members_345
                .FirstOrDefaultAsync(m => m.UserId == request.UserId);

            if (member == null)
            {
                return BadRequest(new
                {
                    success = false,
                    error = "Member not found",
                    userId = request.UserId
                });
            }

            // Find court
            var court = await _context.Courts_345
                .FirstOrDefaultAsync(c => c.Id == request.CourtId && c.IsActive);

            if (court == null)
            {
                return BadRequest(new
                {
                    success = false,
                    error = "Court not found or inactive",
                    courtId = request.CourtId
                });
            }

            // Check wallet balance
            var totalPrice = (decimal)(request.Hours * (double)court.PricePerHour);
            if (member.WalletBalance < totalPrice)
            {
                return BadRequest(new
                {
                    success = false,
                    error = "Insufficient wallet balance",
                    required = totalPrice,
                    available = member.WalletBalance
                });
            }

            return Ok(new
            {
                success = true,
                message = "Booking validation passed",
                member = new { member.Id, member.FullName, member.WalletBalance },
                court = new { court.Id, court.Name, court.PricePerHour },
                totalPrice = totalPrice,
                canBook = true
            });
        }
        catch (Exception ex)
        {
            return BadRequest(new
            {
                success = false,
                error = ex.Message,
                stackTrace = ex.StackTrace
            });
        }
    }

    [HttpPost("create-booking")]
    public async Task<IActionResult> CreateBooking([FromBody] CreateBookingRequest request)
    {
        try
        {
            // Find member by user ID
            var member = await _context.Members_345
                .FirstOrDefaultAsync(m => m.UserId == request.UserId);

            if (member == null)
            {
                return BadRequest(new
                {
                    success = false,
                    error = "Member not found",
                    userId = request.UserId
                });
            }

            // Find court
            var court = await _context.Courts_345
                .FirstOrDefaultAsync(c => c.Id == request.CourtId && c.IsActive);

            if (court == null)
            {
                return BadRequest(new
                {
                    success = false,
                    error = "Court not found or inactive",
                    courtId = request.CourtId
                });
            }

            // Parse time slot to get start and end time
            var timeParts = request.TimeSlot.Split(" - ");
            if (timeParts.Length != 2)
            {
                return BadRequest(new
                {
                    success = false,
                    error = "Invalid time slot format",
                    timeSlot = request.TimeSlot
                });
            }

            var startTimeStr = timeParts[0];
            var endTimeStr = timeParts[1];
            
            var startTime = DateTime.Parse($"{request.Date:yyyy-MM-dd} {startTimeStr}:00");
            var endTime = DateTime.Parse($"{request.Date:yyyy-MM-dd} {endTimeStr}:00");

            // Check if trying to book in the past
            if (endTime <= DateTime.Now)
            {
                return BadRequest(new
                {
                    success = false,
                    error = "Cannot book time slots in the past",
                    requestedTime = endTime,
                    currentTime = DateTime.Now
                });
            }

            // Check if slot is already booked
            var existingBooking = await _context.Bookings_345
                .FirstOrDefaultAsync(b => 
                    b.CourtId == request.CourtId &&
                    b.StartTime <= startTime &&
                    b.EndTime >= endTime &&
                    b.Status != BookingStatus.Cancelled);

            if (existingBooking != null)
            {
                return BadRequest(new
                {
                    success = false,
                    error = "Time slot is already booked",
                    existingBookingId = existingBooking.Id
                });
            }

            // Calculate total price
            var duration = (endTime - startTime).TotalHours;
            var totalPrice = (decimal)(duration * (double)court.PricePerHour);

            // Check wallet balance
            if (member.WalletBalance < totalPrice)
            {
                return BadRequest(new
                {
                    success = false,
                    error = "Insufficient wallet balance",
                    required = totalPrice,
                    available = member.WalletBalance
                });
            }

            // Create booking
            var booking = new Booking_345
            {
                MemberId = member.Id,
                CourtId = request.CourtId,
                StartTime = startTime,
                EndTime = endTime,
                TotalPrice = totalPrice,
                Status = BookingStatus.Confirmed,
                CreatedDate = DateTime.Now,
                Notes = request.Notes,
                IsRecurring = false
            };

            _context.Bookings_345.Add(booking);

            // Deduct from wallet balance
            member.WalletBalance -= totalPrice;

            // Create wallet transaction
            var transaction = new WalletTransaction_345
            {
                MemberId = member.Id,
                Amount = -totalPrice,
                Type = TransactionType.BookingPayment,
                Status = TransactionStatus.Completed,
                Description = $"Thanh toán đặt sân {court.Name} - {startTime:dd/MM/yyyy HH:mm}",
                CreatedDate = DateTime.Now,
                ProcessedDate = DateTime.Now
            };

            _context.WalletTransactions_345.Add(transaction);

            await _context.SaveChangesAsync();

            return Ok(new
            {
                success = true,
                message = "Booking created successfully",
                booking = new
                {
                    id = booking.Id,
                    courtName = court.Name,
                    startTime = booking.StartTime,
                    endTime = booking.EndTime,
                    totalPrice = booking.TotalPrice,
                    status = booking.Status.ToString()
                },
                newWalletBalance = member.WalletBalance
            });
        }
        catch (Exception ex)
        {
            return BadRequest(new
            {
                success = false,
                error = ex.Message,
                stackTrace = ex.StackTrace
            });
        }
    }
}

public class TestBookingRequest
{
    public string UserId { get; set; } = string.Empty;
    public int CourtId { get; set; }
    public double Hours { get; set; }
}

public class CreateBookingRequest
{
    public string UserId { get; set; } = string.Empty;
    public int CourtId { get; set; }
    public DateTime Date { get; set; }
    public string TimeSlot { get; set; } = string.Empty;
    public string? Notes { get; set; }
}