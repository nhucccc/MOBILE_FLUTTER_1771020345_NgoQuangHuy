using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Tokens;
using pickleball_api_345.Data;
using pickleball_api_345.DTOs;
using pickleball_api_345.Models;
using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Text;

namespace pickleball_api_345.Controllers;

[ApiController]
[Route("api/[controller]")]
public class AuthController : ControllerBase
{
    private readonly UserManager<ApplicationUser> _userManager;
    private readonly SignInManager<ApplicationUser> _signInManager;
    private readonly ApplicationDbContext _context;
    private readonly IConfiguration _configuration;

    public AuthController(
        UserManager<ApplicationUser> userManager,
        SignInManager<ApplicationUser> signInManager,
        ApplicationDbContext context,
        IConfiguration configuration)
    {
        _userManager = userManager;
        _signInManager = signInManager;
        _context = context;
        _configuration = configuration;
    }

    [HttpPost("register")]
    public async Task<IActionResult> Register([FromBody] RegisterRequestDto request)
    {
        try
        {
            if (!ModelState.IsValid)
                return BadRequest(ModelState);

            var user = new ApplicationUser
            {
                UserName = request.Email,
                Email = request.Email,
                FullName = request.FullName,
                PhoneNumber = request.PhoneNumber,
                CreatedDate = DateTime.UtcNow
            };

            var result = await _userManager.CreateAsync(user, request.Password);
            if (!result.Succeeded)
            {
                foreach (var error in result.Errors)
                {
                    ModelState.AddModelError(string.Empty, error.Description);
                }
                return BadRequest(ModelState);
            }

            // Create Member profile
            var member = new Member_345
            {
                UserId = user.Id,
                FullName = request.FullName,
                JoinDate = DateTime.UtcNow,
                IsActive = true
            };

            _context.Members_345.Add(member);
            await _context.SaveChangesAsync();

            return Ok(new { message = "Đăng ký thành công!" });
        }
        catch (Exception ex)
        {
            return BadRequest(new { message = "Lỗi server: " + ex.Message });
        }
    }

    [HttpPost("login")]
    public async Task<IActionResult> Login([FromBody] LoginRequestDto request)
    {
        if (!ModelState.IsValid)
            return BadRequest(ModelState);

        var user = await _userManager.FindByEmailAsync(request.Email);
        if (user == null)
            return Unauthorized(new { message = "Email hoặc mật khẩu không đúng" });

        var result = await _signInManager.CheckPasswordSignInAsync(user, request.Password, false);
        if (!result.Succeeded)
            return Unauthorized(new { message = "Email hoặc mật khẩu không đúng" });

        var token = await GenerateJwtToken(user);
        var member = await _context.Members_345.FirstOrDefaultAsync(m => m.UserId == user.Id);
        var roles = await _userManager.GetRolesAsync(user);
        var role = roles.FirstOrDefault() ?? "Member";

        var response = new LoginResponseDto
        {
            Token = token,
            Expires = DateTime.UtcNow.AddDays(_configuration.GetValue<int>("Jwt:ExpireDays")),
            User = new UserInfoDto
            {
                Id = user.Id,
                Email = user.Email!,
                FullName = user.FullName ?? "",
                PhoneNumber = user.PhoneNumber,
                Role = role, // Thêm role vào response
                AvatarUrl = member?.AvatarUrl,
                Member = member != null ? new MemberInfoDto
                {
                    Id = member.Id,
                    FullName = member.FullName,
                    JoinDate = member.JoinDate,
                    RankLevel = member.RankLevel,
                    IsActive = member.IsActive,
                    WalletBalance = member.WalletBalance,
                    Tier = member.Tier.ToString(),
                    TotalSpent = member.TotalSpent,
                    AvatarUrl = member.AvatarUrl
                } : null
            }
        };

        return Ok(response);
    }

    [HttpGet("me")]
    [Authorize]
    public async Task<IActionResult> GetCurrentUser()
    {
        var userId = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
        if (string.IsNullOrEmpty(userId))
            return Unauthorized();

        var user = await _userManager.FindByIdAsync(userId);
        if (user == null)
            return NotFound();

        var member = await _context.Members_345.FirstOrDefaultAsync(m => m.UserId == userId);
        var roles = await _userManager.GetRolesAsync(user);
        var role = roles.FirstOrDefault() ?? "Member";

        var userInfo = new UserInfoDto
        {
            Id = user.Id,
            Email = user.Email!,
            FullName = user.FullName ?? "",
            PhoneNumber = user.PhoneNumber,
            Role = role,
            AvatarUrl = member?.AvatarUrl,
            Member = member != null ? new MemberInfoDto
            {
                Id = member.Id,
                FullName = member.FullName,
                JoinDate = member.JoinDate,
                RankLevel = member.RankLevel,
                IsActive = member.IsActive,
                WalletBalance = member.WalletBalance,
                Tier = member.Tier.ToString(),
                TotalSpent = member.TotalSpent,
                AvatarUrl = member.AvatarUrl
            } : null
        };

        return Ok(userInfo);
    }

    private async Task<string> GenerateJwtToken(ApplicationUser user)
    {
        var claims = new List<Claim>
        {
            new(ClaimTypes.NameIdentifier, user.Id),
            new(ClaimTypes.Name, user.UserName!),
            new(ClaimTypes.Email, user.Email!),
            new("FullName", user.FullName ?? "")
        };

        var roles = await _userManager.GetRolesAsync(user);
        foreach (var role in roles)
        {
            claims.Add(new Claim(ClaimTypes.Role, role));
        }

        var key = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(_configuration["Jwt:Key"]!));
        var creds = new SigningCredentials(key, SecurityAlgorithms.HmacSha256);
        var expires = DateTime.UtcNow.AddDays(_configuration.GetValue<int>("Jwt:ExpireDays"));

        var token = new JwtSecurityToken(
            _configuration["Jwt:Issuer"],
            _configuration["Jwt:Audience"],
            claims,
            expires: expires,
            signingCredentials: creds
        );

        return new JwtSecurityTokenHandler().WriteToken(token);
    }
}