using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Tokens;
using pickleball_api_345.Data;
using pickleball_api_345.Hubs;
using pickleball_api_345.Models;
using pickleball_api_345.Services;
using pickleball_api_345.Authorization;
using System.Text;

var builder = WebApplication.CreateBuilder(args);

// Add services to the container.
builder.Services.AddControllers();
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();

// Database
builder.Services.AddDbContext<ApplicationDbContext>(options =>
    options.UseSqlServer(builder.Configuration.GetConnectionString("DefaultConnection")));

// Identity
builder.Services.AddIdentity<ApplicationUser, IdentityRole>(options =>
{
    // Giảm yêu cầu mật khẩu cho development
    options.Password.RequireDigit = false;
    options.Password.RequireLowercase = false;
    options.Password.RequireUppercase = false;
    options.Password.RequireNonAlphanumeric = false;
    options.Password.RequiredLength = 6;
    options.Password.RequiredUniqueChars = 1;
})
    .AddEntityFrameworkStores<ApplicationDbContext>()
    .AddDefaultTokenProviders();

// JWT Authentication
builder.Services.AddAuthentication(options =>
{
    options.DefaultAuthenticateScheme = JwtBearerDefaults.AuthenticationScheme;
    options.DefaultChallengeScheme = JwtBearerDefaults.AuthenticationScheme;
})
.AddJwtBearer(options =>
{
    options.TokenValidationParameters = new TokenValidationParameters
    {
        ValidateIssuer = true,
        ValidateAudience = true,
        ValidateLifetime = true,
        ValidateIssuerSigningKey = true,
        ValidIssuer = builder.Configuration["Jwt:Issuer"],
        ValidAudience = builder.Configuration["Jwt:Audience"],
        IssuerSigningKey = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(builder.Configuration["Jwt:Key"]!))
    };
    
    // Configure JWT for SignalR
    options.Events = new JwtBearerEvents
    {
        OnMessageReceived = context =>
        {
            var accessToken = context.Request.Query["access_token"];
            var path = context.HttpContext.Request.Path;
            if (!string.IsNullOrEmpty(accessToken) && path.StartsWithSegments("/pcmhub"))
            {
                context.Token = accessToken;
            }
            return Task.CompletedTask;
        }
    };
});

// SignalR
builder.Services.AddSignalR();

// Memory Cache for slot reservations
builder.Services.AddMemoryCache();

// Services
builder.Services.AddScoped<IWalletService, WalletService>();
builder.Services.AddScoped<IWalletSyncService, WalletSyncService>();
builder.Services.AddScoped<IBookingService, BookingService>();
builder.Services.AddScoped<ISlotReservationService, SlotReservationService>();
builder.Services.AddScoped<INotificationService, NotificationService>();
builder.Services.AddScoped<IPaymentService, VnPayService>();
builder.Services.AddScoped<IReportService, ReportService>();
builder.Services.AddScoped<IConcurrencyService, ConcurrencyService>();
builder.Services.AddScoped<IChatService, ChatService>();
builder.Services.AddScoped<ITournamentSchedulerService, TournamentSchedulerService>();
builder.Services.AddScoped<ITournamentService, TournamentService>();

// Authorization Handlers
builder.Services.AddScoped<IAuthorizationHandler, TierAuthorizationHandler>();
builder.Services.AddScoped<IAuthorizationHandler, RoleAuthorizationHandler>();

// Authorization Policies
builder.Services.AddAuthorization(options =>
{
    // Role-based policies
    options.AddPolicy(PolicyConstants.RequireAdminRole, policy =>
        policy.Requirements.Add(new RoleRequirement(RoleConstants.Admin)));
    
    options.AddPolicy(PolicyConstants.RequireTreasurerRole, policy =>
        policy.Requirements.Add(new RoleRequirement(RoleConstants.Treasurer)));
    
    options.AddPolicy(PolicyConstants.RequireRefereeRole, policy =>
        policy.Requirements.Add(new RoleRequirement(RoleConstants.Referee)));
    
    options.AddPolicy(PolicyConstants.RequireMemberRole, policy =>
        policy.Requirements.Add(new RoleRequirement(RoleConstants.Member)));

    // Tier-based policies
    options.AddPolicy(PolicyConstants.RequireVipTier, policy =>
        policy.Requirements.Add(new TierRequirement(MemberTier.Silver)));
    
    options.AddPolicy(PolicyConstants.RequireGoldTier, policy =>
        policy.Requirements.Add(new TierRequirement(MemberTier.Gold)));
    
    options.AddPolicy(PolicyConstants.RequireDiamondTier, policy =>
        policy.Requirements.Add(new TierRequirement(MemberTier.Diamond)));

    // Feature-based policies
    options.AddPolicy(PolicyConstants.CanCreateRecurringBooking, policy =>
        policy.Requirements.Add(new TierRequirement(MemberTier.Gold)));
    
    options.AddPolicy(PolicyConstants.CanApproveDeposits, policy =>
        policy.RequireRole(RoleConstants.Admin, RoleConstants.Treasurer));
    
    options.AddPolicy(PolicyConstants.CanManageCourts, policy =>
        policy.RequireRole(RoleConstants.Admin));
    
    options.AddPolicy(PolicyConstants.CanManageMembers, policy =>
        policy.RequireRole(RoleConstants.Admin));
    
    options.AddPolicy(PolicyConstants.CanViewReports, policy =>
        policy.RequireRole(RoleConstants.Admin, RoleConstants.Treasurer));
    
    options.AddPolicy(PolicyConstants.CanManageTournaments, policy =>
        policy.RequireRole(RoleConstants.Admin, RoleConstants.Referee));
});

// Background Services
builder.Services.AddHostedService<pickleball_api_345.Services.BackgroundServices.BookingCleanupService>();
builder.Services.AddHostedService<pickleball_api_345.Services.BackgroundServices.TierUpdateService>();
// Temporarily disabled: builder.Services.AddHostedService<pickleball_api_345.Services.BackgroundServices.SlotCleanupService>();

// CORS
builder.Services.AddCors(options =>
{
    options.AddPolicy("AllowAll", policy =>
    {
        policy.AllowAnyOrigin()
              .AllowAnyMethod()
              .AllowAnyHeader();
    });
    
    options.AddPolicy("Development", policy =>
    {
        policy.WithOrigins("http://localhost:3000", "http://127.0.0.1:3000", "http://localhost:8080")
              .AllowAnyMethod()
              .AllowAnyHeader()
              .AllowCredentials();
    });
});

var app = builder.Build();

// Configure the HTTP request pipeline.
if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}

// Comment out HTTPS redirection for development
// app.UseHttpsRedirection();

app.UseCors("AllowAll");
app.UseAuthentication();
app.UseAuthorization();

app.MapControllers();
app.MapHub<PcmHub>("/pcmhub");

// Seed data
using (var scope = app.Services.CreateScope())
{
    await SeedData.InitializeAsync(scope.ServiceProvider);
}

app.Run();