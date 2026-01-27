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
        var totalMembers = await _context.Members_345.CountAsync(m => m.IsActive);
        var totalCourts = await _context.Courts_345.CountAsync(c => c.IsActive);
        var pendingDeposits = await _context.WalletTransactions_345
            .CountAsync(t => t.Type == TransactionType.Deposit && t.Status == TransactionStatus.Pending);
        var todayBookings = await _context.Bookings_345
            .CountAsync(b => b.StartTime.Date == DateTime.UtcNow.Date);
        var totalRevenue = await _context.WalletTransactions_345
            .Where(t => t.Type == TransactionType.Payment && t.Status == TransactionStatus.Completed)
            .SumAsync(t => t.Amount);

        return Ok(new
        {
            totalMembers,
            totalCourts,
            pendingDeposits,
            todayBookings,
            totalRevenue
        });
    }

    // Member Management
    [HttpGet("members")]
    public async Task<IActionResult> GetMembers([FromQuery] int page = 1, [FromQuery] int pageSize = 20, [FromQuery] string? search = null)
    {
        var query = _context.Members_345.AsQueryable();

        if (!string.IsNullOrEmpty(search))
        {
            query = query.Where(m => m.FullName.Contains(search) || (m.User != null && m.User.Email.Contains(search)));
        }

        var totalCount = await query.CountAsync();
        var members = await query
            .Include(m => m.User)
            .OrderByDescending(m => m.JoinDate)
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .Select(m => new
            {
                m.Id,
                m.FullName,
                Email = m.User.Email,
                m.JoinDate,
                m.IsActive,
                m.WalletBalance,
                Tier = m.Tier.ToString(),
                m.TotalSpent,
                m.RankLevel,
                Role = _userManager.GetRolesAsync(m.User).Result.FirstOrDefault() ?? "Member"
            })
            .ToListAsync();

        return Ok(new
        {
            members,
            totalCount,
            totalPages = (int)Math.Ceiling((double)totalCount / pageSize)
        });
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
    public async Task<IActionResult> GetCourts()
    {
        var courts = await _context.Courts_345
            .OrderBy(c => c.Name)
            .Select(c => new
            {
                c.Id,
                c.Name,
                c.IsActive,
                c.Description,
                c.PricePerHour,
                BookingCount = _context.Bookings_345.Count(b => b.CourtId == c.Id)
            })
            .ToListAsync();

        return Ok(courts);
    }

    [HttpPost("courts")]
    public async Task<IActionResult> CreateCourt([FromBody] CreateCourtDto request)
    {
        var court = new Court_345
        {
            Name = request.Name,
            Description = request.Description,
            PricePerHour = request.PricePerHour,
            IsActive = true
        };

        _context.Courts_345.Add(court);
        await _context.SaveChangesAsync();

        return Ok(new { message = "Đã tạo sân mới", court });
    }

    [HttpPut("courts/{courtId}")]
    public async Task<IActionResult> UpdateCourt(int courtId, [FromBody] UpdateCourtDto request)
    {
        var court = await _context.Courts_345.FindAsync(courtId);
        if (court == null)
            return NotFound("Không tìm thấy sân");

        court.Name = request.Name;
        court.Description = request.Description;
        court.PricePerHour = request.PricePerHour;
        court.IsActive = request.IsActive;

        await _context.SaveChangesAsync();

        return Ok(new { message = "Đã cập nhật thông tin sân" });
    }

    [HttpDelete("courts/{courtId}")]
    public async Task<IActionResult> DeleteCourt(int courtId)
    {
        var court = await _context.Courts_345.FindAsync(courtId);
        if (court == null)
            return NotFound("Không tìm thấy sân");

        // Check if court has future bookings
        var hasFutureBookings = await _context.Bookings_345
            .AnyAsync(b => b.CourtId == courtId && b.StartTime > DateTime.UtcNow);

        if (hasFutureBookings)
            return BadRequest("Không thể xóa sân có lịch đặt trong tương lai");

        court.IsActive = false;
        await _context.SaveChangesAsync();

        return Ok(new { message = "Đã vô hiệu hóa sân" });
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
}