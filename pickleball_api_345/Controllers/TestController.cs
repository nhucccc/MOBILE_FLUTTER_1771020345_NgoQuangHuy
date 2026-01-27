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

            return Ok(new { 
                message = "Seed data created successfully!",
                adminEmail = adminEmail,
                testEmail = testEmail,
                testUserBalance = 500000,
                timestamp = DateTime.UtcNow 
            });
        }
        catch (Exception ex)
        {
            return BadRequest(new { error = ex.Message });
        }
    }
}