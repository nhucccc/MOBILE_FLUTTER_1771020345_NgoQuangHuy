using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;
using pickleball_api_345.Models;

namespace pickleball_api_345.Data;

public static class SeedData
{
    public static async Task InitializeAsync(IServiceProvider serviceProvider)
    {
        using var scope = serviceProvider.CreateScope();
        var context = scope.ServiceProvider.GetRequiredService<ApplicationDbContext>();
        var userManager = scope.ServiceProvider.GetRequiredService<UserManager<ApplicationUser>>();
        var roleManager = scope.ServiceProvider.GetRequiredService<RoleManager<IdentityRole>>();

        // Ensure database is created
        await context.Database.EnsureCreatedAsync();

        // Seed Roles
        await SeedRolesAsync(roleManager);

        // Seed Admin Users
        await SeedAdminUsersAsync(userManager, context);

        // Seed Courts
        await SeedCourtsAsync(context);

        // Seed Sample Members
        await SeedSampleMembersAsync(userManager, context);

        // Seed Sample Data
        await SeedSampleDataAsync(context);

        // Seed Tournaments
        await SeedTournamentsAsync(context);
    }

    private static async Task SeedRolesAsync(RoleManager<IdentityRole> roleManager)
    {
        string[] roles = { "Admin", "Member", "Treasurer", "Referee" };

        foreach (var role in roles)
        {
            if (!await roleManager.RoleExistsAsync(role))
            {
                await roleManager.CreateAsync(new IdentityRole(role));
            }
        }
    }

    private static async Task SeedAdminUsersAsync(UserManager<ApplicationUser> userManager, ApplicationDbContext context)
    {
        // Admin User
        await CreateUserIfNotExists(userManager, context, new
        {
            Email = "admin@pickleball345.com",
            Password = "Admin@123",
            FullName = "System Administrator",
            Role = "Admin",
            WalletBalance = 1000000m,
            Tier = MemberTier.Diamond,
            DuprRating = 4.5
        });

        // Treasurer User
        await CreateUserIfNotExists(userManager, context, new
        {
            Email = "treasurer@pickleball345.com",
            Password = "Treasurer@123",
            FullName = "Nguyễn Văn Kế Toán",
            Role = "Treasurer",
            WalletBalance = 500000m,
            Tier = MemberTier.Gold,
            DuprRating = 3.8
        });

        // Referee User
        await CreateUserIfNotExists(userManager, context, new
        {
            Email = "referee@pickleball345.com",
            Password = "Referee@123",
            FullName = "Trần Thị Trọng Tài",
            Role = "Referee",
            WalletBalance = 300000m,
            Tier = MemberTier.Silver,
            DuprRating = 3.5
        });
    }

    private static async Task SeedSampleMembersAsync(UserManager<ApplicationUser> userManager, ApplicationDbContext context)
    {
        var sampleMembers = new[]
        {
            new { Email = "member1@gmail.com", FullName = "Nguyễn Văn An", WalletBalance = 2000000m, Tier = MemberTier.Diamond, DuprRating = 4.5 },
            new { Email = "member2@gmail.com", FullName = "Trần Thị Bình", WalletBalance = 3500000m, Tier = MemberTier.Gold, DuprRating = 4.2 },
            new { Email = "member3@gmail.com", FullName = "Lê Văn Cường", WalletBalance = 1800000m, Tier = MemberTier.Silver, DuprRating = 3.8 },
            new { Email = "member4@gmail.com", FullName = "Phạm Thị Dung", WalletBalance = 4200000m, Tier = MemberTier.Diamond, DuprRating = 4.7 },
            new { Email = "member5@gmail.com", FullName = "Hoàng Văn Em", WalletBalance = 2800000m, Tier = MemberTier.Gold, DuprRating = 4.0 },
            new { Email = "member6@gmail.com", FullName = "Vũ Thị Phương", WalletBalance = 3200000m, Tier = MemberTier.Gold, DuprRating = 4.1 },
            new { Email = "member7@gmail.com", FullName = "Đỗ Văn Giang", WalletBalance = 1500000m, Tier = MemberTier.Silver, DuprRating = 3.5 },
            new { Email = "member8@gmail.com", FullName = "Bùi Thị Hoa", WalletBalance = 5000000m, Tier = MemberTier.Diamond, DuprRating = 4.9 },
            new { Email = "member9@gmail.com", FullName = "Ngô Văn Inh", WalletBalance = 2200000m, Tier = MemberTier.Silver, DuprRating = 3.7 },
            new { Email = "member10@gmail.com", FullName = "Lý Thị Kim", WalletBalance = 3800000m, Tier = MemberTier.Gold, DuprRating = 4.3 },
            new { Email = "member11@gmail.com", FullName = "Trương Văn Long", WalletBalance = 2600000m, Tier = MemberTier.Silver, DuprRating = 3.9 },
            new { Email = "member12@gmail.com", FullName = "Đinh Thị Mai", WalletBalance = 4500000m, Tier = MemberTier.Diamond, DuprRating = 4.6 },
            new { Email = "member13@gmail.com", FullName = "Võ Văn Nam", WalletBalance = 1900000m, Tier = MemberTier.Silver, DuprRating = 3.6 },
            new { Email = "member14@gmail.com", FullName = "Đặng Thị Oanh", WalletBalance = 3100000m, Tier = MemberTier.Gold, DuprRating = 4.1 },
            new { Email = "member15@gmail.com", FullName = "Phan Văn Phúc", WalletBalance = 2400000m, Tier = MemberTier.Silver, DuprRating = 3.8 },
            new { Email = "member16@gmail.com", FullName = "Lưu Thị Quỳnh", WalletBalance = 6000000m, Tier = MemberTier.Diamond, DuprRating = 5.0 },
            new { Email = "member17@gmail.com", FullName = "Tô Văn Rồng", WalletBalance = 2700000m, Tier = MemberTier.Gold, DuprRating = 4.0 },
            new { Email = "member18@gmail.com", FullName = "Chu Thị Sương", WalletBalance = 3400000m, Tier = MemberTier.Gold, DuprRating = 4.2 },
            new { Email = "member19@gmail.com", FullName = "Dương Văn Tài", WalletBalance = 2100000m, Tier = MemberTier.Silver, DuprRating = 3.7 },
            new { Email = "member20@gmail.com", FullName = "Hồ Thị Uyên", WalletBalance = 10000000m, Tier = MemberTier.Diamond, DuprRating = 5.2 }
        };

        foreach (var member in sampleMembers)
        {
            await CreateUserIfNotExists(userManager, context, new
            {
                Email = member.Email,
                Password = "Member@123",
                FullName = member.FullName,
                Role = "Member",
                WalletBalance = member.WalletBalance,
                Tier = member.Tier,
                DuprRating = member.DuprRating
            });
        }
    }

    private static async Task CreateUserIfNotExists(UserManager<ApplicationUser> userManager, ApplicationDbContext context, dynamic userData)
    {
        var existingUser = await userManager.FindByEmailAsync(userData.Email);
        if (existingUser == null)
        {
            var user = new ApplicationUser
            {
                UserName = userData.Email,
                Email = userData.Email,
                FullName = userData.FullName,
                EmailConfirmed = true,
                CreatedDate = DateTime.UtcNow
            };

            var result = await userManager.CreateAsync(user, userData.Password);
            if (result.Succeeded)
            {
                await userManager.AddToRoleAsync(user, userData.Role);

                // Create Member profile
                var member = new Member_345
                {
                    UserId = user.Id,
                    FullName = userData.FullName,
                    JoinDate = DateTime.UtcNow.AddDays(-Random.Shared.Next(30, 365)),
                    IsActive = true,
                    Tier = userData.Tier,
                    WalletBalance = userData.WalletBalance,
                    DuprRating = (decimal)(userData.DuprRating ?? 0.0)
                };

                context.Members_345.Add(member);
                await context.SaveChangesAsync();

                // Create initial wallet transaction
                var transaction = new WalletTransaction_345
                {
                    MemberId = member.Id,
                    Amount = userData.WalletBalance,
                    Type = TransactionType.Deposit,
                    Status = TransactionStatus.Completed,
                    Description = "Số dư ban đầu",
                    CreatedDate = member.JoinDate.AddMinutes(30)
                };

                context.WalletTransactions_345.Add(transaction);
                await context.SaveChangesAsync();
            }
        }
    }

    private static async Task SeedCourtsAsync(ApplicationDbContext context)
    {
        if (!await context.Courts_345.AnyAsync())
        {
            var courts = new List<Court_345>
            {
                new() { Name = "Sân 1", IsActive = true, Description = "Sân chính - Có mái che", PricePerHour = 100000 },
                new() { Name = "Sân 2", IsActive = true, Description = "Sân phụ - Ngoài trời", PricePerHour = 80000 },
                new() { Name = "Sân 3", IsActive = true, Description = "Sân VIP - Có điều hòa", PricePerHour = 150000 },
                new() { Name = "Sân 4", IsActive = true, Description = "Sân tập luyện", PricePerHour = 60000 }
            };

            context.Courts_345.AddRange(courts);
            await context.SaveChangesAsync();
        }
    }

    private static async Task SeedSampleDataAsync(ApplicationDbContext context)
    {
        // Seed Transaction Categories
        if (!await context.TransactionCategories_345.AnyAsync())
        {
            var categories = new List<TransactionCategory_345>
            {
                new() { Name = "Nạp tiền", Type = "Thu", IsActive = true },
                new() { Name = "Thanh toán sân", Type = "Chi", IsActive = true },
                new() { Name = "Phí tham gia giải", Type = "Chi", IsActive = true },
                new() { Name = "Thưởng giải đấu", Type = "Thu", IsActive = true },
                new() { Name = "Hoàn tiền", Type = "Thu", IsActive = true }
            };

            context.TransactionCategories_345.AddRange(categories);
            await context.SaveChangesAsync();
        }

        // Seed News
        if (!await context.News_345.AnyAsync())
        {
            var news = new List<News_345>
            {
                new()
                {
                    Title = "Chào mừng đến với Pickleball Club 345!",
                    Content = "Chúng tôi rất vui mừng chào đón bạn đến với câu lạc bộ pickleball hiện đại nhất. Hãy tham gia các hoạt động thú vị và kết nối với cộng đồng yêu thích pickleball!",
                    IsPinned = true,
                    CreatedDate = DateTime.UtcNow,
                    CreatedBy = "System"
                },
                new()
                {
                    Title = "Giải đấu mùa xuân 2026 sắp diễn ra",
                    Content = "Đăng ký tham gia giải đấu pickleball mùa xuân với tổng giải thưởng lên đến 50 triệu VND. Thời gian đăng ký từ ngày 1/2 đến 28/2/2026.",
                    IsPinned = false,
                    CreatedDate = DateTime.UtcNow.AddDays(-1),
                    CreatedBy = "Admin"
                },
                new()
                {
                    Title = "Cập nhật giờ hoạt động mới",
                    Content = "Từ ngày 1/2/2026, câu lạc bộ sẽ mở cửa từ 5:00 - 22:00 hàng ngày để phục vụ tốt hơn nhu cầu của các thành viên.",
                    IsPinned = false,
                    CreatedDate = DateTime.UtcNow.AddDays(-3),
                    CreatedBy = "Admin"
                }
            };

            context.News_345.AddRange(news);
            await context.SaveChangesAsync();
        }
    }

    private static async Task SeedTournamentsAsync(ApplicationDbContext context)
    {
        if (!await context.Tournaments_345.AnyAsync())
        {
            var tournaments = new List<Tournament_345>
            {
                // Giải đã kết thúc
                new()
                {
                    Name = "Summer Open 2026",
                    Description = "Giải đấu mùa hè dành cho tất cả các thành viên",
                    StartDate = DateTime.UtcNow.AddDays(-60),
                    EndDate = DateTime.UtcNow.AddDays(-30),
                    RegistrationDeadline = DateTime.UtcNow.AddDays(-70),
                    MaxParticipants = 32,
                    EntryFee = 200000,
                    PrizePool = 5000000,
                    Format = TournamentFormat.Knockout,
                    Status = TournamentStatus.Finished,
                    IsActive = true,
                    CreatedDate = DateTime.UtcNow.AddDays(-80)
                },
                // Giải đang mở đăng ký
                new()
                {
                    Name = "Winter Cup 2026",
                    Description = "Giải đấu mùa đông với format mới - Round Robin + Knockout",
                    StartDate = DateTime.UtcNow.AddDays(30),
                    EndDate = DateTime.UtcNow.AddDays(32),
                    RegistrationDeadline = DateTime.UtcNow.AddDays(20),
                    MaxParticipants = 24,
                    EntryFee = 300000,
                    PrizePool = 8000000,
                    Format = TournamentFormat.Hybrid,
                    Status = TournamentStatus.Registering,
                    IsActive = true,
                    CreatedDate = DateTime.UtcNow.AddDays(-5)
                }
            };

            context.Tournaments_345.AddRange(tournaments);
            await context.SaveChangesAsync();
        }
    }
}