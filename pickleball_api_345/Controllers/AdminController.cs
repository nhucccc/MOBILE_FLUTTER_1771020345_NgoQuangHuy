using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using pickleball_api_345.Data;
using pickleball_api_345.DTOs;
using pickleball_api_345.Models;
using pickleball_api_345.Services;

namespace pickleball_api_345.Controllers;

[ApiController]
[Route("api/[controller]")]
[Authorize(Roles = "Admin")]
public class AdminController : ControllerBase
{
    private readonly ApplicationDbContext _context;
    private readonly UserManager<ApplicationUser> _userManager;
    private readonly IWalletService _walletService;
    private readonly INotificationService _notificationService;

    public AdminController(
        ApplicationDbContext context,
        UserManager<ApplicationUser> userManager,
        IWalletService walletService,
        INotificationService notificationService)
    {
        _context = context;
        _userManager = userManager;
        _walletService = walletService;
        _notificationService = notificationService;
    }

    // Dashboard Statistics
    [HttpGet("dashboard-stats")]
    public async Task<IActionResult> GetDashboardStats()
    {
        try
        {
            var totalMembers = await _context.Members_345.CountAsync(m => m.IsActive);
            var totalCourts = await _context.Courts_345.CountAsync(c => c.IsActive);
            var pendingDeposits = await _context.WalletTransactions_345
                .CountAsync(t => t.Type == TransactionType.Deposit && t.Status == TransactionStatus.Pending);
            var todayBookings = await _context.Bookings_345
                .CountAsync(b => b.StartTime.Date == DateTime.UtcNow.Date);
            var totalRevenue = await _context.WalletTransactions_345
                .Where(t => t.Type == TransactionType.Payment && t.Status == TransactionStatus.Completed)
                .SumAsync(t => t.Amount);
            
            var totalBookings = await _context.Bookings_345.CountAsync();
            var activeTournaments = 3; // Mock data since we don't have tournaments table
            
            var monthlyRevenue = await _context.WalletTransactions_345
                .Where(t => t.Type == TransactionType.Payment && 
                           t.Status == TransactionStatus.Completed &&
                           t.CreatedDate.Month == DateTime.UtcNow.Month &&
                           t.CreatedDate.Year == DateTime.UtcNow.Year)
                .SumAsync(t => (decimal?)t.Amount) ?? 0;

            var stats = new
            {
                totalMembers,
                totalCourts,
                totalBookings,
                pendingDeposits,
                todayBookings,
                totalRevenue,
                activeTournaments,
                monthlyRevenue,
                systemHealth = "Good"
            };

            return Ok(new { success = true, data = stats });
        }
        catch (Exception ex)
        {
            return BadRequest(new { success = false, message = $"Lỗi tải thống kê: {ex.Message}" });
        }
    }

    // Member Management
    [HttpGet("members")]
    public async Task<IActionResult> GetMembers([FromQuery] int page = 1, [FromQuery] int pageSize = 20, [FromQuery] string? search = null, [FromQuery] string? tier = null, [FromQuery] bool? isActive = null)
    {
        var query = _context.Members_345.Include(m => m.User).AsQueryable();

        if (!string.IsNullOrEmpty(search))
        {
            query = query.Where(m => m.FullName.Contains(search) || m.User.Email.Contains(search) || m.User.PhoneNumber.Contains(search));
        }

        if (!string.IsNullOrEmpty(tier) && Enum.TryParse<MemberTier>(tier, out var tierEnum))
        {
            query = query.Where(m => m.Tier == tierEnum);
        }

        if (isActive.HasValue)
        {
            query = query.Where(m => m.IsActive == isActive.Value);
        }

        var totalCount = await query.CountAsync();
        var members = await query
            .OrderByDescending(m => m.JoinDate)
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .Select(m => new
            {
                m.Id,
                m.FullName,
                Email = m.User.Email,
                PhoneNumber = m.User.PhoneNumber,
                m.JoinDate,
                m.IsActive,
                m.WalletBalance,
                Tier = m.Tier.ToString(),
                m.TotalSpent,
                m.RankLevel,
                m.DuprRating,
                Role = _userManager.GetRolesAsync(m.User).Result.FirstOrDefault() ?? "Member",
                BookingCount = _context.Bookings_345.Count(b => b.MemberId == m.Id),
                LastBooking = _context.Bookings_345
                    .Where(b => b.MemberId == m.Id)
                    .OrderByDescending(b => b.StartTime)
                    .Select(b => b.StartTime)
                    .FirstOrDefault()
            })
            .ToListAsync();

        return Ok(new
        {
            success = true,
            data = new
            {
                members,
                totalCount,
                totalPages = (int)Math.Ceiling((double)totalCount / pageSize),
                currentPage = page
            }
        });
    }

    [HttpGet("members/{memberId}")]
    public async Task<IActionResult> GetMember(int memberId)
    {
        var member = await _context.Members_345
            .Include(m => m.User)
            .Where(m => m.Id == memberId)
            .Select(m => new
            {
                m.Id,
                m.FullName,
                Email = m.User.Email,
                PhoneNumber = m.User.PhoneNumber,
                m.JoinDate,
                m.IsActive,
                m.WalletBalance,
                Tier = m.Tier.ToString(),
                m.TotalSpent,
                m.RankLevel,
                m.DuprRating,
                m.AvatarUrl,
                Role = _userManager.GetRolesAsync(m.User).Result.FirstOrDefault() ?? "Member",
                BookingCount = _context.Bookings_345.Count(b => b.MemberId == m.Id),
                TotalBookingValue = _context.Bookings_345
                    .Where(b => b.MemberId == m.Id && b.Status == Models.BookingStatus.Confirmed)
                    .Sum(b => (decimal?)b.TotalPrice) ?? 0,
                RecentBookings = _context.Bookings_345
                    .Where(b => b.MemberId == m.Id)
                    .Include(b => b.Court)
                    .OrderByDescending(b => b.StartTime)
                    .Take(10)
                    .Select(b => new
                    {
                        b.Id,
                        b.StartTime,
                        b.EndTime,
                        CourtName = b.Court.Name,
                        b.TotalPrice,
                        Status = b.Status.ToString()
                    })
                    .ToList(),
                WalletTransactions = _context.WalletTransactions_345
                    .Where(t => t.MemberId == m.Id)
                    .OrderByDescending(t => t.CreatedDate)
                    .Take(10)
                    .Select(t => new
                    {
                        t.Id,
                        t.Amount,
                        Type = t.Type.ToString(),
                        Status = t.Status.ToString(),
                        t.Description,
                        t.CreatedDate
                    })
                    .ToList()
            })
            .FirstOrDefaultAsync();

        if (member == null)
            return NotFound(new { success = false, message = "Không tìm thấy thành viên" });

        return Ok(new { success = true, data = member });
    }

    [HttpPost("members")]
    public async Task<IActionResult> CreateMember([FromBody] CreateMemberDto request)
    {
        if (!ModelState.IsValid)
            return BadRequest(new { success = false, message = "Dữ liệu không hợp lệ", errors = ModelState });

        // Check if email already exists
        var existingUser = await _userManager.FindByEmailAsync(request.Email);
        if (existingUser != null)
            return BadRequest(new { success = false, message = "Email đã tồn tại" });

        // Create user account
        var user = new ApplicationUser
        {
            UserName = request.Email,
            Email = request.Email,
            PhoneNumber = request.PhoneNumber,
            EmailConfirmed = true
        };

        var result = await _userManager.CreateAsync(user, request.Password);
        if (!result.Succeeded)
        {
            var errors = string.Join(", ", result.Errors.Select(e => e.Description));
            return BadRequest(new { success = false, message = $"Lỗi tạo tài khoản: {errors}" });
        }

        // Add role
        await _userManager.AddToRoleAsync(user, request.Role ?? "Member");

        // Create member profile
        var member = new Member_345
        {
            UserId = user.Id,
            FullName = request.FullName,
            JoinDate = DateTime.UtcNow,
            IsActive = true,
            WalletBalance = 0,
            TotalSpent = 0,
            Tier = MemberTier.Standard,
            RankLevel = 1,
            DuprRating = 2.0m
        };

        _context.Members_345.Add(member);
        await _context.SaveChangesAsync();

        return Ok(new
        {
            success = true,
            message = "Đã tạo thành viên mới thành công",
            data = new
            {
                member.Id,
                member.FullName,
                Email = user.Email,
                PhoneNumber = user.PhoneNumber,
                member.JoinDate,
                member.IsActive,
                Tier = member.Tier.ToString(),
                Role = request.Role ?? "Member"
            }
        });
    }

    [HttpPut("members/{memberId}")]
    public async Task<IActionResult> UpdateMember(int memberId, [FromBody] UpdateMemberDto request)
    {
        if (!ModelState.IsValid)
            return BadRequest(new { success = false, message = "Dữ liệu không hợp lệ", errors = ModelState });

        var member = await _context.Members_345.Include(m => m.User).FirstOrDefaultAsync(m => m.Id == memberId);
        if (member == null)
            return NotFound(new { success = false, message = "Không tìm thấy thành viên" });

        // Update member info
        member.FullName = request.FullName;
        member.IsActive = request.IsActive;
        member.DuprRating = (decimal)request.DuprRating;

        if (Enum.TryParse<MemberTier>(request.Tier, out var tier))
        {
            member.Tier = tier;
        }

        // Update user info
        if (request.Email != member.User.Email)
        {
            var existingUser = await _userManager.FindByEmailAsync(request.Email);
            if (existingUser != null && existingUser.Id != member.User.Id)
                return BadRequest(new { success = false, message = "Email đã tồn tại" });

            member.User.Email = request.Email;
            member.User.UserName = request.Email;
        }

        member.User.PhoneNumber = request.PhoneNumber;

        // Update role if changed
        if (!string.IsNullOrEmpty(request.Role))
        {
            var currentRoles = await _userManager.GetRolesAsync(member.User);
            await _userManager.RemoveFromRolesAsync(member.User, currentRoles);
            await _userManager.AddToRoleAsync(member.User, request.Role);
        }

        await _userManager.UpdateAsync(member.User);
        await _context.SaveChangesAsync();

        return Ok(new
        {
            success = true,
            message = "Đã cập nhật thông tin thành viên thành công",
            data = new
            {
                member.Id,
                member.FullName,
                Email = member.User.Email,
                PhoneNumber = member.User.PhoneNumber,
                member.IsActive,
                Tier = member.Tier.ToString(),
                member.DuprRating,
                Role = request.Role
            }
        });
    }

    [HttpPost("members/{memberId}/wallet/adjust")]
    public async Task<IActionResult> AdjustMemberWallet(int memberId, [FromBody] UpdateMemberWalletDto request)
    {
        if (!ModelState.IsValid)
            return BadRequest(new { success = false, message = "Dữ liệu không hợp lệ", errors = ModelState });

        var member = await _context.Members_345.Include(m => m.User).FirstOrDefaultAsync(m => m.Id == memberId);
        if (member == null)
            return NotFound(new { success = false, message = "Không tìm thấy thành viên" });

        var adminUserId = User.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier)?.Value;
        if (string.IsNullOrEmpty(adminUserId))
            return Unauthorized(new { success = false, message = "Không xác định được admin" });

        // Create wallet transaction
        var transactionType = request.Type.ToLower() == "add" ? TransactionType.Deposit : TransactionType.Payment;
        var amount = request.Type.ToLower() == "add" ? request.Amount : -request.Amount;

        var transaction = new WalletTransaction_345
        {
            MemberId = memberId,
            Amount = Math.Abs(request.Amount),
            Type = transactionType,
            Status = TransactionStatus.Completed,
            Description = request.Notes ?? $"Admin {(request.Type.ToLower() == "add" ? "thêm" : "trừ")} tiền",
            CreatedDate = DateTime.UtcNow,
            ProcessedDate = DateTime.UtcNow,
            AdminNotes = $"Điều chỉnh bởi admin: {request.Notes}"
        };

        // Update member wallet balance
        member.WalletBalance += amount;
        if (member.WalletBalance < 0)
            member.WalletBalance = 0;

        _context.WalletTransactions_345.Add(transaction);
        await _context.SaveChangesAsync();

        // Send notification
        await _notificationService.SendNotificationAsync(
            member.UserId,
            "Số dư ví được cập nhật",
            $"Admin đã {(request.Type.ToLower() == "add" ? "thêm" : "trừ")} {request.Amount:N0}đ vào ví của bạn",
            NotificationType.Info
        );

        return Ok(new
        {
            success = true,
            message = $"Đã {(request.Type.ToLower() == "add" ? "thêm" : "trừ")} {request.Amount:N0}đ {(request.Type.ToLower() == "add" ? "vào" : "từ")} ví thành viên",
            data = new
            {
                member.Id,
                member.FullName,
                OldBalance = member.WalletBalance - amount,
                NewBalance = member.WalletBalance,
                TransactionId = transaction.Id
            }
        });
    }

    [HttpDelete("members/{memberId}")]
    public async Task<IActionResult> DeleteMember(int memberId)
    {
        var member = await _context.Members_345.Include(m => m.User).FirstOrDefaultAsync(m => m.Id == memberId);
        if (member == null)
            return NotFound(new { success = false, message = "Không tìm thấy thành viên" });

        // Check if member has future bookings
        var hasFutureBookings = await _context.Bookings_345
            .AnyAsync(b => b.MemberId == memberId && b.StartTime > DateTime.UtcNow);

        if (hasFutureBookings)
            return BadRequest(new { success = false, message = "Không thể xóa thành viên có lịch đặt sân trong tương lai" });

        // Check if member has pending transactions
        var hasPendingTransactions = await _context.WalletTransactions_345
            .AnyAsync(t => t.MemberId == memberId && t.Status == TransactionStatus.Pending);

        if (hasPendingTransactions)
            return BadRequest(new { success = false, message = "Không thể xóa thành viên có giao dịch đang chờ xử lý" });

        // Soft delete - just deactivate
        member.IsActive = false;
        await _context.SaveChangesAsync();

        return Ok(new { success = true, message = "Đã vô hiệu hóa thành viên thành công" });
    }

    [HttpPut("members/{memberId}/status")]
    public async Task<IActionResult> UpdateMemberStatus(int memberId, [FromBody] UpdateMemberStatusDto request)
    {
        var member = await _context.Members_345.FindAsync(memberId);
        if (member == null)
            return NotFound("Không tìm thấy thành viên");

        member.IsActive = request.IsActive;
        await _context.SaveChangesAsync();

        return Ok(new { message = request.IsActive ? "Đã kích hoạt thành viên" : "Đã vô hiệu hóa thành viên" });
    }

    [HttpPut("members/{memberId}/tier")]
    public async Task<IActionResult> UpdateMemberTier(int memberId, [FromBody] UpdateMemberTierDto request)
    {
        var member = await _context.Members_345.FindAsync(memberId);
        if (member == null)
            return NotFound("Không tìm thấy thành viên");

        if (!Enum.TryParse<MemberTier>(request.Tier, out var tier))
            return BadRequest("Tier không hợp lệ");

        member.Tier = tier;
        await _context.SaveChangesAsync();

        return Ok(new { message = "Đã cập nhật tier thành viên" });
    }

    // Deposit Approval
    [HttpGet("pending-deposits")]
    public async Task<IActionResult> GetPendingDeposits([FromQuery] int page = 1, [FromQuery] int pageSize = 20)
    {
        var totalCount = await _context.WalletTransactions_345
            .CountAsync(t => t.Type == TransactionType.Deposit && t.Status == TransactionStatus.Pending);

        var deposits = await _context.WalletTransactions_345
            .Include(t => t.Member)
            .Where(t => t.Type == TransactionType.Deposit && t.Status == TransactionStatus.Pending)
            .OrderByDescending(t => t.CreatedDate)
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .Select(t => new
            {
                t.Id,
                MemberName = t.Member.FullName,
                t.Amount,
                t.Description,
                t.CreatedDate,
                t.ProofImageUrl,
                MemberId = t.Member.Id
            })
            .ToListAsync();

        return Ok(new
        {
            deposits,
            totalCount,
            totalPages = (int)Math.Ceiling((double)totalCount / pageSize)
        });
    }

    [HttpPost("deposits/{transactionId}/approve")]
    public async Task<IActionResult> ApproveDeposit(int transactionId, [FromBody] ApproveDepositDto request)
    {
        var transaction = await _context.WalletTransactions_345
            .Include(t => t.Member)
            .ThenInclude(m => m.User)
            .FirstOrDefaultAsync(t => t.Id == transactionId);

        if (transaction?.Member?.User == null)
            return NotFound("Không tìm thấy giao dịch hoặc thành viên");

        if (transaction.Status != TransactionStatus.Pending)
            return BadRequest("Giao dịch đã được xử lý");

        transaction.Status = TransactionStatus.Completed;
        transaction.ProcessedDate = DateTime.UtcNow;
        transaction.AdminNotes = request.AdminNotes;

        // Update member wallet balance
        transaction.Member.WalletBalance += transaction.Amount;

        await _context.SaveChangesAsync();

        // Send notification
        await _notificationService.SendNotificationAsync(
            transaction.Member.UserId,
            "Nạp tiền thành công",
            $"Yêu cầu nạp {transaction.Amount:N0}đ đã được duyệt",
            NotificationType.Success
        );

        return Ok(new { message = "Đã duyệt yêu cầu nạp tiền" });
    }

    [HttpPost("deposits/{transactionId}/reject")]
    public async Task<IActionResult> RejectDeposit(int transactionId, [FromBody] RejectDepositDto request)
    {
        var transaction = await _context.WalletTransactions_345
            .Include(t => t.Member)
            .ThenInclude(m => m.User)
            .FirstOrDefaultAsync(t => t.Id == transactionId);

        if (transaction?.Member?.User == null)
            return NotFound("Không tìm thấy giao dịch hoặc thành viên");

        if (transaction.Status != TransactionStatus.Pending)
            return BadRequest("Giao dịch đã được xử lý");

        transaction.Status = TransactionStatus.Failed;
        transaction.ProcessedDate = DateTime.UtcNow;
        transaction.AdminNotes = request.Reason;

        await _context.SaveChangesAsync();

        // Send notification
        await _notificationService.SendNotificationAsync(
            transaction.Member.UserId,
            "Nạp tiền bị từ chối",
            $"Yêu cầu nạp {transaction.Amount:N0}đ bị từ chối: {request.Reason}",
            NotificationType.Error
        );

        return Ok(new { message = "Đã từ chối yêu cầu nạp tiền" });
    }

    // Court Management
    [HttpGet("courts")]
    public async Task<IActionResult> GetCourts([FromQuery] int page = 1, [FromQuery] int pageSize = 20, [FromQuery] string? search = null)
    {
        var query = _context.Courts_345.AsQueryable();

        if (!string.IsNullOrEmpty(search))
        {
            query = query.Where(c => c.Name.Contains(search) || c.Description.Contains(search));
        }

        var totalCount = await query.CountAsync();
        var courts = await query
            .OrderBy(c => c.Name)
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .Select(c => new
            {
                c.Id,
                c.Name,
                c.IsActive,
                c.Description,
                c.PricePerHour,
                BookingCount = _context.Bookings_345.Count(b => b.CourtId == c.Id),
                TotalRevenue = _context.Bookings_345
                    .Where(b => b.CourtId == c.Id && b.Status == Models.BookingStatus.Confirmed)
                    .Sum(b => (decimal?)b.TotalPrice) ?? 0,
                LastBooking = _context.Bookings_345
                    .Where(b => b.CourtId == c.Id)
                    .OrderByDescending(b => b.StartTime)
                    .Select(b => b.StartTime)
                    .FirstOrDefault()
            })
            .ToListAsync();

        return Ok(new
        {
            success = true,
            data = new
            {
                courts,
                totalCount,
                totalPages = (int)Math.Ceiling((double)totalCount / pageSize),
                currentPage = page
            }
        });
    }

    [HttpGet("courts/{courtId}")]
    public async Task<IActionResult> GetCourt(int courtId)
    {
        var court = await _context.Courts_345
            .Where(c => c.Id == courtId)
            .Select(c => new
            {
                c.Id,
                c.Name,
                c.IsActive,
                c.Description,
                c.PricePerHour,
                BookingCount = _context.Bookings_345.Count(b => b.CourtId == c.Id),
                TotalRevenue = _context.Bookings_345
                    .Where(b => b.CourtId == c.Id && b.Status == Models.BookingStatus.Confirmed)
                    .Sum(b => (decimal?)b.TotalPrice) ?? 0,
                RecentBookings = _context.Bookings_345
                    .Where(b => b.CourtId == c.Id)
                    .Include(b => b.Member)
                    .OrderByDescending(b => b.StartTime)
                    .Take(10)
                    .Select(b => new
                    {
                        b.Id,
                        b.StartTime,
                        b.EndTime,
                        MemberName = b.Member.FullName,
                        b.TotalPrice,
                        Status = b.Status.ToString()
                    })
                    .ToList()
            })
            .FirstOrDefaultAsync();

        if (court == null)
            return NotFound(new { success = false, message = "Không tìm thấy sân" });

        return Ok(new { success = true, data = court });
    }

    [HttpPost("courts")]
    public async Task<IActionResult> CreateCourt([FromBody] CreateCourtDto request)
    {
        if (!ModelState.IsValid)
            return BadRequest(new { success = false, message = "Dữ liệu không hợp lệ", errors = ModelState });

        // Check if court name already exists
        var existingCourt = await _context.Courts_345.FirstOrDefaultAsync(c => c.Name == request.Name);
        if (existingCourt != null)
            return BadRequest(new { success = false, message = "Tên sân đã tồn tại" });

        var court = new Court_345
        {
            Name = request.Name,
            Description = request.Description,
            PricePerHour = request.PricePerHour,
            IsActive = true
        };

        _context.Courts_345.Add(court);
        await _context.SaveChangesAsync();

        return Ok(new { 
            success = true, 
            message = "Đã tạo sân mới thành công", 
            data = new
            {
                court.Id,
                court.Name,
                court.Description,
                court.PricePerHour,
                court.IsActive
            }
        });
    }

    [HttpPut("courts/{courtId}")]
    public async Task<IActionResult> UpdateCourt(int courtId, [FromBody] UpdateCourtDto request)
    {
        if (!ModelState.IsValid)
            return BadRequest(new { success = false, message = "Dữ liệu không hợp lệ", errors = ModelState });

        var court = await _context.Courts_345.FindAsync(courtId);
        if (court == null)
            return NotFound(new { success = false, message = "Không tìm thấy sân" });

        // Check if new name conflicts with existing court
        if (request.Name != court.Name)
        {
            var existingCourt = await _context.Courts_345.FirstOrDefaultAsync(c => c.Name == request.Name && c.Id != courtId);
            if (existingCourt != null)
                return BadRequest(new { success = false, message = "Tên sân đã tồn tại" });
        }

        court.Name = request.Name;
        court.Description = request.Description;
        court.PricePerHour = request.PricePerHour;
        court.IsActive = request.IsActive;

        await _context.SaveChangesAsync();

        return Ok(new { 
            success = true, 
            message = "Đã cập nhật thông tin sân thành công",
            data = new
            {
                court.Id,
                court.Name,
                court.Description,
                court.PricePerHour,
                court.IsActive
            }
        });
    }

    [HttpDelete("courts/{courtId}")]
    public async Task<IActionResult> DeleteCourt(int courtId)
    {
        var court = await _context.Courts_345.FindAsync(courtId);
        if (court == null)
            return NotFound(new { success = false, message = "Không tìm thấy sân" });

        // Check if court has future bookings
        var hasFutureBookings = await _context.Bookings_345
            .AnyAsync(b => b.CourtId == courtId && b.StartTime > DateTime.UtcNow);

        if (hasFutureBookings)
            return BadRequest(new { success = false, message = "Không thể xóa sân có lịch đặt trong tương lai" });

        // Soft delete - just deactivate
        court.IsActive = false;
        await _context.SaveChangesAsync();

        return Ok(new { success = true, message = "Đã vô hiệu hóa sân thành công" });
    }

    [HttpPost("courts/{courtId}/activate")]
    public async Task<IActionResult> ActivateCourt(int courtId)
    {
        var court = await _context.Courts_345.FindAsync(courtId);
        if (court == null)
            return NotFound(new { success = false, message = "Không tìm thấy sân" });

        court.IsActive = true;
        await _context.SaveChangesAsync();

        return Ok(new { success = true, message = "Đã kích hoạt sân thành công" });
    }

    // System Settings
    [HttpGet("system-settings")]
    public async Task<IActionResult> GetSystemSettings()
    {
        // This would typically come from a settings table
        return Ok(new
        {
            bookingAdvanceDays = 30,
            cancellationHours = 24,
            autoCleanupEnabled = true,
            reminderHours = 2,
            maxRecurringBookings = 10
        });
    }

    [HttpPut("system-settings")]
    public async Task<IActionResult> UpdateSystemSettings([FromBody] SystemSettingsDto request)
    {
        // Update system settings
        // This would typically update a settings table
        return Ok(new { message = "Đã cập nhật cài đặt hệ thống" });
    }

    // Reports
    [HttpGet("reports/revenue")]
    public async Task<IActionResult> GetRevenueReport([FromQuery] DateTime? from, [FromQuery] DateTime? to)
    {
        from ??= DateTime.UtcNow.AddDays(-30);
        to ??= DateTime.UtcNow;

        var revenue = await _context.WalletTransactions_345
            .Where(t => t.Type == TransactionType.Payment && 
                       t.Status == TransactionStatus.Completed &&
                       t.CreatedDate >= from && t.CreatedDate <= to)
            .GroupBy(t => t.CreatedDate.Date)
            .Select(g => new
            {
                Date = g.Key,
                Amount = g.Sum(t => t.Amount),
                Count = g.Count()
            })
            .OrderBy(x => x.Date)
            .ToListAsync();

        return Ok(revenue);
    }

    [HttpGet("reports/bookings")]
    public async Task<IActionResult> GetBookingReport([FromQuery] DateTime? from, [FromQuery] DateTime? to)
    {
        from ??= DateTime.UtcNow.AddDays(-30);
        to ??= DateTime.UtcNow;

        var bookings = await _context.Bookings_345
            .Include(b => b.Court)
            .Where(b => b.StartTime >= from && b.StartTime <= to)
            .GroupBy(b => new { b.CourtId, b.Court.Name })
            .Select(g => new
            {
                CourtId = g.Key.CourtId,
                CourtName = g.Key.Name,
                BookingCount = g.Count(),
                Revenue = g.Sum(b => b.TotalPrice),
                UtilizationRate = g.Count() * 100.0 / 30 // Simplified calculation
            })
            .ToListAsync();

        return Ok(bookings);
    }

    // Top Members Ranking
    [HttpGet("top-members")]
    [AllowAnonymous] // Allow access for dashboard
    public async Task<IActionResult> GetTopMembers()
    {
        try
        {
            var topMembers = await _context.Members_345
                .Include(m => m.User)
                .Where(m => m.IsActive)
                .OrderByDescending(m => m.DuprRating)
                .ThenByDescending(m => m.TotalSpent)
                .Take(10)
                .Select(m => new
                {
                    m.Id,
                    m.FullName,
                    DuprRating = m.DuprRating,
                    Tier = m.Tier.ToString(),
                    m.AvatarUrl,
                    Role = _userManager.GetRolesAsync(m.User).Result.FirstOrDefault() ?? "Member"
                })
                .ToListAsync();

            return Ok(new { success = true, data = topMembers });
        }
        catch (Exception ex)
        {
            return BadRequest(new { success = false, message = ex.Message });
        }
    }
}