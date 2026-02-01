using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;
using pickleball_api_345.Data;
using pickleball_api_345.Models;

namespace pickleball_api_345.Controllers;

[ApiController]
[Route("api/[controller]")]
public class TestController : ControllerBase
{
    private readonly ApplicationDbContext _context;
    private readonly UserManager<ApplicationUser> _userManager;
    private readonly RoleManager<IdentityRole> _roleManager;

    public TestController(
        ApplicationDbContext context,
        UserManager<ApplicationUser> userManager,
        RoleManager<IdentityRole> roleManager)
    {
        _context = context;
        _userManager = userManager;
        _roleManager = roleManager;
    }

    [HttpGet]
    public IActionResult Get()
    {
        return Ok(new { message = "API is working!", timestamp = DateTime.UtcNow });
    }
    
    [HttpGet("cors")]
    public IActionResult TestCors()
    {
        return Ok(new { message = "CORS is working!", origin = Request.Headers["Origin"].ToString() });
    }
    
    [HttpPost("register-test")]
    public IActionResult TestRegister([FromBody] object data)
    {
        return Ok(new { 
            message = "Register endpoint reached!", 
            data = data,
            timestamp = DateTime.UtcNow 
        });
    }

    [HttpPost("seed-data")]
    public async Task<IActionResult> SeedData()
    {
        try
        {
            // Create roles if they don't exist
            var roles = new[] { "Admin", "Member", "Referee", "Treasurer" };
            foreach (var roleName in roles)
            {
                if (!await _roleManager.RoleExistsAsync(roleName))
                {
                    await _roleManager.CreateAsync(new IdentityRole(roleName));
                }
            }

            // Create admin user
            var adminEmail = "admin@pickleball345.com";
            var adminUser = await _userManager.FindByEmailAsync(adminEmail);
            if (adminUser == null)
            {
                adminUser = new ApplicationUser
                {
                    UserName = adminEmail,
                    Email = adminEmail,
                    EmailConfirmed = true
                };
                
                var result = await _userManager.CreateAsync(adminUser, "Admin@123");
                if (result.Succeeded)
                {
                    await _userManager.AddToRoleAsync(adminUser, "Admin");
                    
                    // Create admin member profile
                    var adminMember = new Member_345
                    {
                        UserId = adminUser.Id,
                        FullName = "Administrator",
                        IsActive = true,
                        JoinDate = DateTime.UtcNow,
                        Tier = MemberTier.Diamond,
                        WalletBalance = 1000000,
                        RankLevel = 10
                    };
                    _context.Members_345.Add(adminMember);
                }
            }

            // Create test user
            var testEmail = "huy@example.com";
            var testUser = await _userManager.FindByEmailAsync(testEmail);
            if (testUser == null)
            {
                testUser = new ApplicationUser
                {
                    UserName = testEmail,
                    Email = testEmail,
                    EmailConfirmed = true
                };
                
                var result = await _userManager.CreateAsync(testUser, "Password123!");
                if (result.Succeeded)
                {
                    await _userManager.AddToRoleAsync(testUser, "Member");
                    
                    // Create test member profile
                    var testMember = new Member_345
                    {
                        UserId = testUser.Id,
                        FullName = "Huy Nguyen",
                        IsActive = true,
                        JoinDate = DateTime.UtcNow,
                        Tier = MemberTier.Standard,
                        WalletBalance = 500000, // Tăng lên 500k để đủ tiền đặt sân
                        RankLevel = 3
                    };
                    _context.Members_345.Add(testMember);
                }
            }
            else
            {
                // Update existing user's wallet balance
                var existingMember = await _context.Members_345.FirstOrDefaultAsync(m => m.UserId == testUser.Id);
                if (existingMember != null)
                {
                    existingMember.WalletBalance = 500000;
                }
            }

            // Create test courts
            if (!await _context.Courts_345.AnyAsync())
            {
                var courts = new[]
                {
                    new Court_345 { Name = "Sân 1", Description = "Sân chính", PricePerHour = 100000, IsActive = true },
                    new Court_345 { Name = "Sân 2", Description = "Sân phụ", PricePerHour = 80000, IsActive = true },
                    new Court_345 { Name = "Sân 3", Description = "Sân VIP", PricePerHour = 150000, IsActive = true }
                };
                
                _context.Courts_345.AddRange(courts);
            }

            await _context.SaveChangesAsync();

            // Create sample tournaments
            if (!await _context.Tournaments_345.AnyAsync())
            {
                var tournaments = new[]
                {
                    new Tournament_345
                    {
                        Name = "Giải Pickleball Mùa Xuân 2025",
                        Description = "Giải đấu thường niên dành cho tất cả các cấp độ",
                        StartDate = DateTime.Now.AddDays(7),
                        EndDate = DateTime.Now.AddDays(14),
                        RegistrationDeadline = DateTime.Now.AddDays(5),
                        MaxParticipants = 32,
                        EntryFee = 200000,
                        PrizePool = 5000000,
                        Status = TournamentStatus.Registering,
                        Format = TournamentFormat.Knockout,
                        IsActive = true
                    },
                    new Tournament_345
                    {
                        Name = "Giải Vô Địch Câu Lạc Bộ",
                        Description = "Giải đấu cao cấp dành cho thành viên VIP",
                        StartDate = DateTime.Now.AddDays(21),
                        EndDate = DateTime.Now.AddDays(28),
                        RegistrationDeadline = DateTime.Now.AddDays(14),
                        MaxParticipants = 16,
                        EntryFee = 500000,
                        PrizePool = 10000000,
                        Status = TournamentStatus.Open,
                        Format = TournamentFormat.Hybrid,
                        IsActive = true
                    },
                    new Tournament_345
                    {
                        Name = "Giải Giao Hữu Tháng 2",
                        Description = "Giải đấu thân thiện cho người mới bắt đầu",
                        StartDate = DateTime.Now.AddDays(3),
                        EndDate = DateTime.Now.AddDays(4),
                        RegistrationDeadline = DateTime.Now.AddDays(1),
                        MaxParticipants = 24,
                        EntryFee = 100000,
                        PrizePool = 2000000,
                        Status = TournamentStatus.Registering,
                        Format = TournamentFormat.RoundRobin,
                        IsActive = true
                    }
                };
                
                _context.Tournaments_345.AddRange(tournaments);
                await _context.SaveChangesAsync();
            }

            return Ok(new { 
                message = "Seed data created successfully!",
                adminEmail = adminEmail,
                testEmail = testEmail,
                testUserBalance = 500000,
                tournamentsCreated = await _context.Tournaments_345.CountAsync(),
                timestamp = DateTime.UtcNow 
            });
        }
        catch (Exception ex)
        {
            return BadRequest(new { error = ex.Message });
        }
    }

    [HttpGet("test-admin-courts")]
    public async Task<IActionResult> TestAdminCourts()
    {
        try
        {
            var courts = await _context.Courts_345
                .Select(c => new
                {
                    id = c.Id,
                    name = c.Name,
                    description = c.Description,
                    pricePerHour = c.PricePerHour,
                    isActive = c.IsActive,
                    bookingCount = _context.Bookings_345.Count(b => b.CourtId == c.Id)
                })
                .OrderBy(c => c.id)
                .ToListAsync();

            return Ok(new
            {
                success = true,
                data = courts,
                count = courts.Count
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
    public async Task<IActionResult> SeedCourts()
    {
        try
        {
            // Check if courts already exist
            var existingCourts = await _context.Courts_345.CountAsync();
            if (existingCourts > 0)
            {
                return Ok(new
                {
                    success = true,
                    message = $"Courts already exist ({existingCourts} courts found)",
                    existingCount = existingCourts
                });
            }

            var courts = new List<Court_345>
            {
                new Court_345
                {
                    Name = "Sân A",
                    Description = "Sân chính với ánh sáng tốt, phù hợp cho thi đấu",
                    PricePerHour = 150000,
                    IsActive = true
                },
                new Court_345
                {
                    Name = "Sân B", 
                    Description = "Sân phụ với không gian rộng rãi",
                    PricePerHour = 120000,
                    IsActive = true
                },
                new Court_345
                {
                    Name = "Sân C",
                    Description = "Sân tập luyện cho người mới bắt đầu",
                    PricePerHour = 100000,
                    IsActive = true
                },
                new Court_345
                {
                    Name = "Sân VIP",
                    Description = "Sân cao cấp với đầy đủ tiện nghi",
                    PricePerHour = 200000,
                    IsActive = true
                }
            };

            _context.Courts_345.AddRange(courts);
            await _context.SaveChangesAsync();

            return Ok(new
            {
                success = true,
                message = $"Successfully created {courts.Count} courts",
                courtsCreated = courts.Count,
                courts = courts.Select(c => new { c.Id, c.Name, c.PricePerHour }).ToList()
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

    [HttpPost("test-create-court")]
    public async Task<IActionResult> TestCreateCourt([FromBody] CreateCourtTestDto request)
    {
        try
        {
            // Check if court name already exists
            var existingCourt = await _context.Courts_345.FirstOrDefaultAsync(c => c.Name == request.Name);
            if (existingCourt != null)
            {
                return BadRequest(new { success = false, message = "Tên sân đã tồn tại" });
            }

            var court = new Court_345
            {
                Name = request.Name,
                Description = request.Description,
                PricePerHour = request.PricePerHour,
                IsActive = true
            };

            _context.Courts_345.Add(court);
            await _context.SaveChangesAsync();

            return Ok(new
            {
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
        catch (Exception ex)
        {
            return BadRequest(new
            {
                success = false,
                message = $"Lỗi tạo sân: {ex.Message}",
                error = ex.Message
            });
        }
    }

    [HttpGet("test-admin-members")]
    public async Task<IActionResult> TestAdminMembers([FromQuery] int page = 1, [FromQuery] int pageSize = 20, [FromQuery] string? search = null)
    {
        try
        {
            var query = _context.Members_345.Include(m => m.User).AsQueryable();

            if (!string.IsNullOrEmpty(search))
            {
                query = query.Where(m => m.FullName.Contains(search) || m.User.Email.Contains(search));
            }

            var totalCount = await query.CountAsync();
            var members = await query
                .OrderByDescending(m => m.JoinDate)
                .Skip((page - 1) * pageSize)
                .Take(pageSize)
                .Select(m => new
                {
                    id = m.Id,
                    fullName = m.FullName,
                    email = m.User.Email,
                    phoneNumber = m.User.PhoneNumber,
                    joinDate = m.JoinDate,
                    isActive = m.IsActive,
                    walletBalance = m.WalletBalance,
                    tier = m.Tier.ToString(),
                    totalSpent = m.TotalSpent,
                    rankLevel = m.RankLevel,
                    duprRating = m.DuprRating,
                    role = _userManager.GetRolesAsync(m.User).Result.FirstOrDefault() ?? "Member",
                    bookingCount = _context.Bookings_345.Count(b => b.MemberId == m.Id),
                    lastBooking = _context.Bookings_345
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

    [HttpPost("test-create-member")]
    public async Task<IActionResult> TestCreateMember([FromBody] CreateMemberTestDto request)
    {
        try
        {
            // Check if email already exists
            var existingUser = await _userManager.FindByEmailAsync(request.Email);
            if (existingUser != null)
            {
                return BadRequest(new { success = false, message = "Email đã tồn tại" });
            }

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
        catch (Exception ex)
        {
            return BadRequest(new
            {
                success = false,
                message = $"Lỗi tạo thành viên: {ex.Message}",
                error = ex.Message
            });
        }
    }

    [HttpPut("test-update-member-status/{memberId}")]
    public async Task<IActionResult> TestUpdateMemberStatus(int memberId, [FromBody] UpdateMemberStatusTestDto request)
    {
        try
        {
            var member = await _context.Members_345.FindAsync(memberId);
            if (member == null)
            {
                return NotFound(new { success = false, message = "Không tìm thấy thành viên" });
            }

            member.IsActive = request.IsActive;
            await _context.SaveChangesAsync();

            return Ok(new
            {
                success = true,
                message = request.IsActive ? "Đã kích hoạt thành viên" : "Đã vô hiệu hóa thành viên"
            });
        }
        catch (Exception ex)
        {
            return BadRequest(new
            {
                success = false,
                message = $"Lỗi cập nhật trạng thái: {ex.Message}",
                error = ex.Message
            });
        }
    }

    [HttpPut("test-update-member-tier/{memberId}")]
    public async Task<IActionResult> TestUpdateMemberTier(int memberId, [FromBody] UpdateMemberTierTestDto request)
    {
        try
        {
            var member = await _context.Members_345.FindAsync(memberId);
            if (member == null)
            {
                return NotFound(new { success = false, message = "Không tìm thấy thành viên" });
            }

            if (!Enum.TryParse<MemberTier>(request.Tier, out var tier))
            {
                return BadRequest(new { success = false, message = "Tier không hợp lệ" });
            }

            member.Tier = tier;
            await _context.SaveChangesAsync();

            return Ok(new
            {
                success = true,
                message = "Đã cập nhật tier thành viên"
            });
        }
        catch (Exception ex)
        {
            return BadRequest(new
            {
                success = false,
                message = $"Lỗi cập nhật tier: {ex.Message}",
                error = ex.Message
            });
        }
    }

    [HttpPost("test-adjust-member-wallet/{memberId}")]
    public async Task<IActionResult> TestAdjustMemberWallet(int memberId, [FromBody] AdjustMemberWalletTestDto request)
    {
        try
        {
            var member = await _context.Members_345.Include(m => m.User).FirstOrDefaultAsync(m => m.Id == memberId);
            if (member == null)
            {
                return NotFound(new { success = false, message = "Không tìm thấy thành viên" });
            }

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
        catch (Exception ex)
        {
            return BadRequest(new
            {
                success = false,
                message = $"Lỗi điều chỉnh ví: {ex.Message}",
                error = ex.Message
            });
        }
    }

    [HttpGet("test-tournaments")]
    public async Task<IActionResult> TestTournaments()
    {
        try
        {
            var tournaments = await _context.Tournaments_345
                .Select(t => new
                {
                    id = t.Id,
                    name = t.Name,
                    description = t.Description,
                    startDate = t.StartDate,
                    endDate = t.EndDate,
                    registrationDeadline = t.RegistrationDeadline,
                    format = t.Format.ToString(),
                    maxParticipants = t.MaxParticipants,
                    entryFee = t.EntryFee,
                    prizePool = t.PrizePool,
                    status = t.Status.ToString(),
                    isActive = t.IsActive,
                    createdDate = t.CreatedDate,
                    createdBy = t.CreatedBy,
                    participantCount = _context.TournamentParticipants_345.Count(p => p.TournamentId == t.Id)
                })
                .OrderByDescending(t => t.createdDate)
                .ToListAsync();

            return Ok(new
            {
                success = true,
                data = tournaments,
                count = tournaments.Count
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

    [HttpPost("test-tournaments")]
    public async Task<IActionResult> TestCreateTournament([FromBody] CreateTournamentTestDto request)
    {
        try
        {
            // Check if tournament name already exists
            var existingTournament = await _context.Tournaments_345.FirstOrDefaultAsync(t => t.Name == request.Name);
            if (existingTournament != null)
            {
                return BadRequest(new { success = false, message = "Tên giải đấu đã tồn tại" });
            }

            // Parse format enum
            if (!Enum.TryParse<TournamentFormat>(request.Format, out var format))
            {
                return BadRequest(new { success = false, message = "Format giải đấu không hợp lệ" });
            }

            var tournament = new Tournament_345
            {
                Name = request.Name,
                Description = request.Description,
                StartDate = request.StartDate,
                EndDate = request.EndDate,
                RegistrationDeadline = request.RegistrationDeadline,
                Format = format,
                MaxParticipants = request.MaxParticipants,
                EntryFee = request.EntryFee,
                PrizePool = request.PrizePool,
                Status = TournamentStatus.Registering,
                IsActive = true,
                CreatedDate = DateTime.UtcNow,
                CreatedBy = "Admin" // Since this is test endpoint
            };

            _context.Tournaments_345.Add(tournament);
            await _context.SaveChangesAsync();

            return Ok(new
            {
                success = true,
                message = "Đã tạo giải đấu mới thành công",
                data = new
                {
                    tournament.Id,
                    tournament.Name,
                    tournament.Description,
                    tournament.StartDate,
                    tournament.EndDate,
                    tournament.RegistrationDeadline,
                    Format = tournament.Format.ToString(),
                    tournament.MaxParticipants,
                    tournament.EntryFee,
                    tournament.PrizePool,
                    Status = tournament.Status.ToString(),
                    tournament.IsActive,
                    tournament.CreatedDate,
                    tournament.CreatedBy
                }
            });
        }
        catch (Exception ex)
        {
            return BadRequest(new
            {
                success = false,
                message = $"Lỗi tạo giải đấu: {ex.Message}",
                error = ex.Message
            });
        }
    }

    [HttpPut("test-tournaments/{tournamentId}")]
    public async Task<IActionResult> TestUpdateTournament(int tournamentId, [FromBody] UpdateTournamentTestDto request)
    {
        try
        {
            var tournament = await _context.Tournaments_345.FindAsync(tournamentId);
            if (tournament == null)
            {
                return NotFound(new { success = false, message = "Không tìm thấy giải đấu" });
            }

            // Check if new name conflicts with existing tournament
            if (request.Name != tournament.Name)
            {
                var existingTournament = await _context.Tournaments_345.FirstOrDefaultAsync(t => t.Name == request.Name && t.Id != tournamentId);
                if (existingTournament != null)
                {
                    return BadRequest(new { success = false, message = "Tên giải đấu đã tồn tại" });
                }
            }

            // Parse format enum
            if (!Enum.TryParse<TournamentFormat>(request.Format, out var format))
            {
                return BadRequest(new { success = false, message = "Format giải đấu không hợp lệ" });
            }

            // Parse status enum
            if (!Enum.TryParse<TournamentStatus>(request.Status, out var status))
            {
                return BadRequest(new { success = false, message = "Trạng thái giải đấu không hợp lệ" });
            }

            tournament.Name = request.Name;
            tournament.Description = request.Description;
            tournament.StartDate = request.StartDate;
            tournament.EndDate = request.EndDate;
            tournament.RegistrationDeadline = request.RegistrationDeadline;
            tournament.Format = format;
            tournament.MaxParticipants = request.MaxParticipants;
            tournament.EntryFee = request.EntryFee;
            tournament.PrizePool = request.PrizePool;
            tournament.Status = status;

            await _context.SaveChangesAsync();

            return Ok(new
            {
                success = true,
                message = "Đã cập nhật giải đấu thành công",
                data = new
                {
                    tournament.Id,
                    tournament.Name,
                    tournament.Description,
                    tournament.StartDate,
                    tournament.EndDate,
                    tournament.RegistrationDeadline,
                    Format = tournament.Format.ToString(),
                    tournament.MaxParticipants,
                    tournament.EntryFee,
                    tournament.PrizePool,
                    Status = tournament.Status.ToString(),
                    tournament.IsActive,
                    tournament.CreatedDate,
                    tournament.CreatedBy
                }
            });
        }
        catch (Exception ex)
        {
            return BadRequest(new
            {
                success = false,
                message = $"Lỗi cập nhật giải đấu: {ex.Message}",
                error = ex.Message
            });
        }
    }

    [HttpPost("test-tournaments/{tournamentId}/cancel")]
    public async Task<IActionResult> TestCancelTournament(int tournamentId, [FromBody] CancelTournamentTestDto request)
    {
        try
        {
            var tournament = await _context.Tournaments_345.FindAsync(tournamentId);
            if (tournament == null)
            {
                return NotFound(new { success = false, message = "Không tìm thấy giải đấu" });
            }

            tournament.Status = TournamentStatus.Finished;
            tournament.IsActive = false;
            // Note: In a real implementation, you might want to add a CancelReason field to the Tournament model

            await _context.SaveChangesAsync();

            return Ok(new
            {
                success = true,
                message = "Đã hủy giải đấu thành công"
            });
        }
        catch (Exception ex)
        {
            return BadRequest(new
            {
                success = false,
                message = $"Lỗi hủy giải đấu: {ex.Message}",
                error = ex.Message
            });
        }
    }
}

public class CreateCourtTestDto
{
    public string Name { get; set; } = string.Empty;
    public string? Description { get; set; }
    public decimal PricePerHour { get; set; }
}

public class CreateMemberTestDto
{
    public string FullName { get; set; } = string.Empty;
    public string Email { get; set; } = string.Empty;
    public string? PhoneNumber { get; set; }
    public string Password { get; set; } = string.Empty;
    public string? Role { get; set; } = "Member";
}

public class UpdateMemberStatusTestDto
{
    public bool IsActive { get; set; }
}

public class UpdateMemberTierTestDto
{
    public string Tier { get; set; } = string.Empty;
}

public class AdjustMemberWalletTestDto
{
    public decimal Amount { get; set; }
    public string Type { get; set; } = string.Empty; // "Add" or "Subtract"
    public string? Notes { get; set; }
}

public class CreateTournamentTestDto
{
    public string Name { get; set; } = string.Empty;
    public string? Description { get; set; }
    public DateTime StartDate { get; set; }
    public DateTime EndDate { get; set; }
    public DateTime RegistrationDeadline { get; set; }
    public string Format { get; set; } = "Knockout";
    public int MaxParticipants { get; set; } = 16;
    public decimal EntryFee { get; set; } = 0;
    public decimal PrizePool { get; set; } = 0;
}

public class UpdateTournamentTestDto
{
    public string Name { get; set; } = string.Empty;
    public string? Description { get; set; }
    public DateTime StartDate { get; set; }
    public DateTime EndDate { get; set; }
    public DateTime RegistrationDeadline { get; set; }
    public string Format { get; set; } = "Knockout";
    public int MaxParticipants { get; set; } = 16;
    public decimal EntryFee { get; set; } = 0;
    public decimal PrizePool { get; set; } = 0;
    public string Status { get; set; } = "Registering";
}

public class CancelTournamentTestDto
{
    public string Reason { get; set; } = string.Empty;
}