using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using pickleball_api_345.Data;
using pickleball_api_345.DTOs;
using pickleball_api_345.Models;
using pickleball_api_345.Services;
using System.Security.Claims;

namespace pickleball_api_345.Controllers;

[ApiController]
[Route("api/[controller]")]
[Authorize]
public class TournamentController : ControllerBase
{
    private readonly ApplicationDbContext _context;

    public TournamentController(ApplicationDbContext context)
    {
        _context = context;
    }

    [HttpGet]
    [AllowAnonymous]
    public async Task<IActionResult> GetTournaments([FromQuery] int page = 1, [FromQuery] int pageSize = 20, [FromQuery] string? status = null, [FromQuery] string? search = null)
    {
        try {
            var query = _context.Tournaments_345
                .Where(t => t.IsActive)
                .AsQueryable();

            // Filter by status
            if (!string.IsNullOrEmpty(status))
            {
                if (Enum.TryParse<TournamentStatus>(status, true, out var statusEnum))
                {
                    query = query.Where(t => t.Status == statusEnum);
                }
            }

            // Filter by search
            if (!string.IsNullOrEmpty(search))
            {
                query = query.Where(t => 
                    t.Name.Contains(search) ||
                    (t.Description != null && t.Description.Contains(search)));
            }

            var totalCount = await query.CountAsync();
            var tournaments = await query
                .OrderBy(t => t.StartDate)
                .Skip((page - 1) * pageSize)
                .Take(pageSize)
                .Select(t => new
                {
                    t.Id,
                    t.Name,
                    t.Description,
                    t.StartDate,
                    t.EndDate,
                    t.RegistrationDeadline,
                    Format = t.Format.ToString(),
                    t.EntryFee,
                    t.PrizePool,
                    t.MaxParticipants,
                    ParticipantCount = t.Participants.Count,
                    Status = t.Status.ToString(),
                    t.CreatedDate,
                    t.CreatedBy
                })
                .ToListAsync();

            return Ok(new { 
                success = true, 
                data = new
                {
                    tournaments,
                    totalCount,
                    totalPages = (int)Math.Ceiling((double)totalCount / pageSize),
                    currentPage = page
                }
            });
        }
        catch (Exception ex)
        {
            return BadRequest(new { 
                success = false, 
                message = $"Lỗi tải danh sách giải đấu: {ex.Message}" 
            });
        }
    }

    [HttpGet("{id}")]
    public async Task<IActionResult> GetTournament(int id)
    {
        try {
            // Return mock tournament detail
            var mockTournament = new {
                Id = id,
                Name = $"Giải đấu #{id}",
                Description = "Mô tả giải đấu chi tiết",
                StartDate = DateTime.Now.AddDays(7),
                EndDate = DateTime.Now.AddDays(9),
                Format = "Knockout",
                EntryFee = 200000,
                PrizePool = 5000000,
                MaxParticipants = 32,
                ParticipantCount = 12,
                Status = "Registering",
                CreatedDate = DateTime.Now.AddDays(-10),
                CreatedBy = "Admin",
                Participants = new object[0],
                Matches = new object[0],
                Rules = "Quy định giải đấu sẽ được cập nhật sau",
                RegistrationDeadline = DateTime.Now.AddDays(5)
            };

            return Ok(new { success = true, data = mockTournament });
        }
        catch (Exception ex)
        {
            return BadRequest(new { 
                success = false, 
                message = $"Lỗi tải thông tin giải đấu: {ex.Message}" 
            });
        }
    }

    [HttpPost]
    [Authorize(Roles = "Admin,Referee")]
    public async Task<IActionResult> CreateTournament([FromBody] CreateTournamentDto request)
    {
        if (!ModelState.IsValid)
            return BadRequest(new { success = false, message = "Dữ liệu không hợp lệ", errors = ModelState });

        try {
            var userId = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            if (string.IsNullOrEmpty(userId))
                return Unauthorized(new { success = false, message = "Không xác định được người dùng" });

            // Validate dates
            if (request.StartDate <= DateTime.Now)
                return BadRequest(new { success = false, message = "Ngày bắt đầu phải sau thời điểm hiện tại" });

            if (request.EndDate <= request.StartDate)
                return BadRequest(new { success = false, message = "Ngày kết thúc phải sau ngày bắt đầu" });

            // Mock tournament creation
            var newTournament = new {
                Id = new Random().Next(1000, 9999),
                request.Name,
                request.Description,
                request.StartDate,
                request.EndDate,
                request.Format,
                request.EntryFee,
                request.PrizePool,
                request.MaxParticipants,
                ParticipantCount = 0,
                Status = "Open",
                CreatedDate = DateTime.Now,
                CreatedBy = userId
            };

            return Ok(new { 
                success = true, 
                message = "Đã tạo giải đấu thành công",
                data = newTournament
            });
        }
        catch (Exception ex)
        {
            return BadRequest(new { 
                success = false, 
                message = $"Lỗi tạo giải đấu: {ex.Message}" 
            });
        }
    }

    [HttpPut("{id}")]
    [Authorize(Roles = "Admin,Referee")]
    public async Task<IActionResult> UpdateTournament(int id, [FromBody] UpdateTournamentDto request)
    {
        if (!ModelState.IsValid)
            return BadRequest(new { success = false, message = "Dữ liệu không hợp lệ", errors = ModelState });

        try {
            var userId = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            if (string.IsNullOrEmpty(userId))
                return Unauthorized(new { success = false, message = "Không xác định được người dùng" });

            // Validate dates
            if (request.StartDate <= DateTime.Now && request.Status == "Open")
                return BadRequest(new { success = false, message = "Không thể cập nhật ngày bắt đầu trong quá khứ cho giải đấu đang mở" });

            if (request.EndDate <= request.StartDate)
                return BadRequest(new { success = false, message = "Ngày kết thúc phải sau ngày bắt đầu" });

            // Mock tournament update
            var updatedTournament = new {
                Id = id,
                request.Name,
                request.Description,
                request.StartDate,
                request.EndDate,
                request.Format,
                request.EntryFee,
                request.PrizePool,
                request.MaxParticipants,
                request.Status,
                ParticipantCount = 12, // Mock data
                UpdatedDate = DateTime.Now,
                UpdatedBy = userId
            };

            return Ok(new { 
                success = true, 
                message = "Đã cập nhật giải đấu thành công",
                data = updatedTournament
            });
        }
        catch (Exception ex)
        {
            return BadRequest(new { 
                success = false, 
                message = $"Lỗi cập nhật giải đấu: {ex.Message}" 
            });
        }
    }

    [HttpDelete("{id}")]
    [Authorize(Roles = "Admin")]
    public async Task<IActionResult> DeleteTournament(int id)
    {
        try {
            var userId = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            if (string.IsNullOrEmpty(userId))
                return Unauthorized(new { success = false, message = "Không xác định được người dùng" });

            // Mock validation - check if tournament has participants
            var hasParticipants = id <= 3; // Mock: first 3 tournaments have participants
            if (hasParticipants)
                return BadRequest(new { success = false, message = "Không thể xóa giải đấu đã có người tham gia" });

            // Mock deletion
            await Task.Delay(100); // Simulate processing

            return Ok(new { 
                success = true, 
                message = "Đã xóa giải đấu thành công"
            });
        }
        catch (Exception ex)
        {
            return BadRequest(new { 
                success = false, 
                message = $"Lỗi xóa giải đấu: {ex.Message}" 
            });
        }
    }

    [HttpPost("{id}/cancel")]
    [Authorize(Roles = "Admin,Referee")]
    public async Task<IActionResult> CancelTournament(int id, [FromBody] CancelTournamentDto request)
    {
        try {
            var userId = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            if (string.IsNullOrEmpty(userId))
                return Unauthorized(new { success = false, message = "Không xác định được người dùng" });

            // Mock cancellation
            await Task.Delay(100); // Simulate processing

            return Ok(new { 
                success = true, 
                message = "Đã hủy giải đấu thành công",
                data = new {
                    Id = id,
                    Status = "Cancelled",
                    CancelReason = request.Reason,
                    CancelledDate = DateTime.Now,
                    CancelledBy = userId
                }
            });
        }
        catch (Exception ex)
        {
            return BadRequest(new { 
                success = false, 
                message = $"Lỗi hủy giải đấu: {ex.Message}" 
            });
        }
    }

    [HttpPost("{id}/join")]
    public async Task<IActionResult> JoinTournament(int id)
    {
        try {
            var userId = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            if (string.IsNullOrEmpty(userId))
                return Unauthorized(new { success = false, message = "Không xác định được người dùng" });

            var member = await _context.Members_345.FirstOrDefaultAsync(m => m.UserId == userId);
            if (member == null)
                return BadRequest(new { success = false, message = "Không tìm thấy thông tin thành viên" });

            // Check if tournament exists and is open for registration
            var tournament = await _context.Tournaments_345.FirstOrDefaultAsync(t => t.Id == id);
            if (tournament == null)
                return NotFound(new { success = false, message = "Không tìm thấy giải đấu" });

            if (tournament.Status != TournamentStatus.Open && tournament.Status != TournamentStatus.Registering)
                return BadRequest(new { success = false, message = "Giải đấu không mở đăng ký" });

            // Check if already joined
            var existingParticipant = await _context.TournamentParticipants_345
                .FirstOrDefaultAsync(tp => tp.TournamentId == id && tp.MemberId == member.Id);
            
            if (existingParticipant != null)
                return BadRequest(new { success = false, message = "Bạn đã tham gia giải đấu này" });

            // Check wallet balance if entry fee required
            if (tournament.EntryFee > 0)
            {
                if (member.WalletBalance < tournament.EntryFee)
                    return BadRequest(new { success = false, message = $"Số dư ví không đủ. Cần {tournament.EntryFee:N0} VND" });

                // Process payment using WalletService
                var walletService = HttpContext.RequestServices.GetRequiredService<IWalletService>();
                var paymentSuccess = await walletService.ProcessPaymentAsync(
                    member.Id,
                    tournament.EntryFee,
                    TransactionType.TournamentFee,
                    $"Phí tham gia giải đấu: {tournament.Name}",
                    id.ToString()
                );

                if (!paymentSuccess)
                    return BadRequest(new { success = false, message = "Không thể xử lý thanh toán" });
            }

            // Add participant
            var participant = new TournamentParticipant_345
            {
                TournamentId = id,
                MemberId = member.Id,
                PaymentStatus = tournament.EntryFee > 0 ? PaymentStatus.Paid : PaymentStatus.NotRequired,
                JoinedDate = DateTime.UtcNow
            };

            _context.TournamentParticipants_345.Add(participant);
            await _context.SaveChangesAsync();

            return Ok(new { 
                success = true, 
                message = "Tham gia giải đấu thành công",
                data = new {
                    TournamentId = id,
                    TournamentName = tournament.Name,
                    EntryFee = tournament.EntryFee,
                    PaymentStatus = participant.PaymentStatus.ToString(),
                    JoinedDate = participant.JoinedDate
                }
            });
        }
        catch (Exception ex)
        {
            return BadRequest(new { 
                success = false, 
                message = $"Lỗi tham gia giải đấu: {ex.Message}" 
            });
        }
    }

    [HttpPost("{id}/leave")]
    public async Task<IActionResult> LeaveTournament(int id)
    {
        try {
            var userId = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            if (string.IsNullOrEmpty(userId))
                return Unauthorized(new { success = false, message = "Không xác định được người dùng" });

            var member = await _context.Members_345.FirstOrDefaultAsync(m => m.UserId == userId);
            if (member == null)
                return BadRequest(new { success = false, message = "Không tìm thấy thông tin thành viên" });

            // Check if tournament exists
            var tournament = await _context.Tournaments_345.FirstOrDefaultAsync(t => t.Id == id);
            if (tournament == null)
                return NotFound(new { success = false, message = "Không tìm thấy giải đấu" });

            // Check if user is participant
            var participant = await _context.TournamentParticipants_345
                .FirstOrDefaultAsync(tp => tp.TournamentId == id && tp.MemberId == member.Id);
            
            if (participant == null)
                return BadRequest(new { success = false, message = "Bạn chưa tham gia giải đấu này" });

            // Check if can leave (only before draw/start)
            if (tournament.Status != TournamentStatus.Open && tournament.Status != TournamentStatus.Registering)
                return BadRequest(new { success = false, message = "Không thể rời khỏi giải đấu đã bắt đầu" });

            // Process refund if paid
            if (participant.PaymentStatus == PaymentStatus.Paid && tournament.EntryFee > 0)
            {
                var walletService = HttpContext.RequestServices.GetRequiredService<IWalletService>();
                await walletService.RefundAsync(
                    member.Id,
                    tournament.EntryFee,
                    $"Hoàn phí rời khỏi giải đấu: {tournament.Name}",
                    id.ToString()
                );
            }

            // Remove participant
            _context.TournamentParticipants_345.Remove(participant);
            await _context.SaveChangesAsync();
            
            return Ok(new { 
                success = true, 
                message = "Rời khỏi giải đấu thành công",
                data = new {
                    TournamentId = id,
                    TournamentName = tournament.Name,
                    RefundAmount = participant.PaymentStatus == PaymentStatus.Paid ? tournament.EntryFee : 0
                }
            });
        }
        catch (Exception ex)
        {
            return BadRequest(new { 
                success = false, 
                message = $"Lỗi rời khỏi giải đấu: {ex.Message}" 
            });
        }
    }

    [HttpPost("{id}/generate-bracket")]
    [Authorize(Roles = "Admin,Referee")]
    public async Task<IActionResult> GenerateBracket(int id)
    {
        try {
            var userId = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            if (string.IsNullOrEmpty(userId))
                return Unauthorized(new { success = false, message = "Không xác định được người dùng" });

            // Mock bracket generation
            await Task.Delay(1000); // Simulate processing time

            // Generate mock matches based on tournament format
            var mockMatches = new[]
            {
                new {
                    Id = 1,
                    TournamentId = id,
                    RoundName = "Vòng 1",
                    Team1Display = "Đội A",
                    Team2Display = "Đội B",
                    Status = "Scheduled",
                    Date = DateTime.Now.AddDays(1),
                    StartTime = DateTime.Now.AddDays(1).AddHours(9),
                    CourtName = "Sân 1"
                },
                new {
                    Id = 2,
                    TournamentId = id,
                    RoundName = "Vòng 1", 
                    Team1Display = "Đội C",
                    Team2Display = "Đội D",
                    Status = "Scheduled",
                    Date = DateTime.Now.AddDays(1),
                    StartTime = DateTime.Now.AddDays(1).AddHours(10),
                    CourtName = "Sân 2"
                },
                new {
                    Id = 3,
                    TournamentId = id,
                    RoundName = "Bán kết",
                    Team1Display = "TBD",
                    Team2Display = "TBD", 
                    Status = "Scheduled",
                    Date = DateTime.Now.AddDays(2),
                    StartTime = DateTime.Now.AddDays(2).AddHours(14),
                    CourtName = "Sân 1"
                },
                new {
                    Id = 4,
                    TournamentId = id,
                    RoundName = "Chung kết",
                    Team1Display = "TBD",
                    Team2Display = "TBD",
                    Status = "Scheduled", 
                    Date = DateTime.Now.AddDays(3),
                    StartTime = DateTime.Now.AddDays(3).AddHours(15),
                    CourtName = "Sân trung tâm"
                }
            };

            return Ok(new { 
                success = true, 
                message = "Đã tạo lịch thi đấu thành công",
                data = new {
                    TournamentId = id,
                    Status = "DrawCompleted",
                    Matches = mockMatches,
                    GeneratedDate = DateTime.Now,
                    GeneratedBy = userId
                }
            });
        }
        catch (Exception ex)
        {
            return BadRequest(new { 
                success = false, 
                message = $"Lỗi tạo lịch thi đấu: {ex.Message}" 
            });
        }
    }

    [HttpGet("{id}/matches")]
    public async Task<IActionResult> GetTournamentMatches(int id)
    {
        try {
            // Return mock matches
            var mockMatches = new object[]
            {
                new {
                    Id = 1,
                    TournamentId = id,
                    RoundName = "Vòng 1",
                    Team1Display = "Nguyễn Văn A",
                    Team2Display = "Trần Văn B",
                    Status = "Finished",
                    Score1 = 21,
                    Score2 = 18,
                    WinningSide = "Team1",
                    Date = DateTime.Now.AddDays(-1),
                    StartTime = DateTime.Now.AddDays(-1).AddHours(9),
                    CourtName = "Sân 1",
                    Details = "Trận đấu diễn ra sôi nổi"
                },
                new {
                    Id = 2,
                    TournamentId = id,
                    RoundName = "Vòng 1",
                    Team1Display = "Lê Văn C", 
                    Team2Display = "Phạm Văn D",
                    Status = "InProgress",
                    Score1 = 15,
                    Score2 = 12,
                    WinningSide = (string?)null,
                    Date = DateTime.Now,
                    StartTime = DateTime.Now.AddHours(-1),
                    CourtName = "Sân 2",
                    Details = ""
                },
                new {
                    Id = 3,
                    TournamentId = id,
                    RoundName = "Bán kết",
                    Team1Display = "Nguyễn Văn A",
                    Team2Display = "TBD",
                    Status = "Scheduled",
                    Score1 = (int?)null,
                    Score2 = (int?)null,
                    WinningSide = (string?)null,
                    Date = DateTime.Now.AddDays(1),
                    StartTime = DateTime.Now.AddDays(1).AddHours(14),
                    CourtName = "Sân 1",
                    Details = ""
                }
            };

            return Ok(new { success = true, data = mockMatches });
        }
        catch (Exception ex)
        {
            return BadRequest(new { 
                success = false, 
                message = $"Lỗi tải danh sách trận đấu: {ex.Message}" 
            });
        }
    }

    [HttpGet("{id}/participants")]
    public async Task<IActionResult> GetTournamentParticipants(int id)
    {
        try {
            // Return mock participants
            var mockParticipants = new[]
            {
                new {
                    Id = 1,
                    TournamentId = id,
                    MemberId = 1,
                    MemberName = "Nguyễn Văn A",
                    TeamName = "Team Alpha",
                    PaymentStatus = "Paid",
                    JoinedDate = DateTime.Now.AddDays(-5),
                    DuprRating = 4.2
                },
                new {
                    Id = 2,
                    TournamentId = id,
                    MemberId = 2,
                    MemberName = "Trần Văn B",
                    TeamName = "Team Beta",
                    PaymentStatus = "Paid",
                    JoinedDate = DateTime.Now.AddDays(-4),
                    DuprRating = 3.8
                },
                new {
                    Id = 3,
                    TournamentId = id,
                    MemberId = 3,
                    MemberName = "Lê Văn C",
                    TeamName = "Team Gamma",
                    PaymentStatus = "Pending",
                    JoinedDate = DateTime.Now.AddDays(-3),
                    DuprRating = 4.5
                },
                new {
                    Id = 4,
                    TournamentId = id,
                    MemberId = 4,
                    MemberName = "Phạm Văn D",
                    TeamName = "Team Delta",
                    PaymentStatus = "Paid",
                    JoinedDate = DateTime.Now.AddDays(-2),
                    DuprRating = 3.9
                }
            };

            return Ok(new { success = true, data = mockParticipants });
        }
        catch (Exception ex)
        {
            return BadRequest(new { 
                success = false, 
                message = $"Lỗi tải danh sách thành viên: {ex.Message}" 
            });
        }
    }

    [HttpPut("{tournamentId}/match/{matchId}")]
    [Authorize(Roles = "Admin,Referee")]
    public async Task<IActionResult> UpdateMatchResult(int tournamentId, int matchId, [FromBody] UpdateMatchResultDto request)
    {
        try {
            var userId = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            if (string.IsNullOrEmpty(userId))
                return Unauthorized(new { success = false, message = "Không xác định được người dùng" });

            // Mock match update
            var updatedMatch = new {
                Id = matchId,
                TournamentId = tournamentId,
                Status = request.Status,
                Score1 = request.Score1,
                Score2 = request.Score2,
                WinningSide = request.WinningSide,
                Details = request.Details,
                UpdatedDate = DateTime.Now,
                UpdatedBy = userId
            };

            return Ok(new { 
                success = true, 
                message = "Đã cập nhật kết quả trận đấu",
                data = updatedMatch
            });
        }
        catch (Exception ex)
        {
            return BadRequest(new { 
                success = false, 
                message = $"Lỗi cập nhật kết quả: {ex.Message}" 
            });
        }
    }

    [HttpGet("{id}/statistics")]
    public async Task<IActionResult> GetTournamentStatistics(int id)
    {
        try {
            // Return mock statistics
            var mockStats = new {
                TournamentId = id,
                TotalMatches = 8,
                CompletedMatches = 3,
                UpcomingMatches = 5,
                TotalParticipants = 16,
                PaidParticipants = 14,
                PendingPayments = 2,
                AverageRating = 4.1,
                TotalPrizePool = 5000000,
                EntryFeeCollected = 2800000,
                CompletionPercentage = 37.5,
                EstimatedEndDate = DateTime.Now.AddDays(5)
            };

            return Ok(new { success = true, data = mockStats });
        }
        catch (Exception ex)
        {
            return BadRequest(new { 
                success = false, 
                message = $"Lỗi tải thống kê: {ex.Message}" 
            });
        }
    }

    [HttpGet("my-tournaments")]
    public async Task<IActionResult> GetMyTournaments()
    {
        try {
            var userId = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            if (string.IsNullOrEmpty(userId))
                return Unauthorized(new { success = false, message = "Không xác định được người dùng" });

            // Return mock user tournaments
            var mockTournaments = new[]
            {
                new {
                    Id = 1,
                    Name = "Giải Pickleball Mùa Xuân 2024",
                    Description = "Giải đấu pickleball lớn nhất mùa xuân",
                    StartDate = DateTime.Now.AddDays(7),
                    EndDate = DateTime.Now.AddDays(9),
                    Format = "Knockout",
                    EntryFee = 200000,
                    PrizePool = 5000000,
                    Status = "Registering",
                    PaymentStatus = "Paid",
                    JoinedDate = DateTime.Now.AddDays(-2)
                }
            };

            return Ok(new { success = true, data = mockTournaments });
        }
        catch (Exception ex)
        {
            return BadRequest(new { 
                success = false, 
                message = $"Lỗi tải danh sách giải đấu của bạn: {ex.Message}" 
            });
        }
    }
}