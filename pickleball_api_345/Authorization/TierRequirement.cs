using Microsoft.AspNetCore.Authorization;
using Microsoft.EntityFrameworkCore;
using pickleball_api_345.Data;
using pickleball_api_345.Models;
using System.Security.Claims;

namespace pickleball_api_345.Authorization;

public class TierRequirement : IAuthorizationRequirement
{
    public MemberTier RequiredTier { get; }

    public TierRequirement(MemberTier requiredTier)
    {
        RequiredTier = requiredTier;
    }
}

public class TierAuthorizationHandler : AuthorizationHandler<TierRequirement>
{
    private readonly ApplicationDbContext _context;

    public TierAuthorizationHandler(ApplicationDbContext context)
    {
        _context = context;
    }

    protected override async Task HandleRequirementAsync(
        AuthorizationHandlerContext context,
        TierRequirement requirement)
    {
        var userId = context.User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
        if (string.IsNullOrEmpty(userId))
        {
            context.Fail();
            return;
        }

        var member = await _context.Members_345
            .FirstOrDefaultAsync(m => m.UserId == userId);

        if (member == null)
        {
            context.Fail();
            return;
        }

        // Check if member's tier meets the requirement
        if (member.Tier >= requirement.RequiredTier)
        {
            context.Succeed(requirement);
        }
        else
        {
            context.Fail();
        }
    }
}

public class RoleRequirement : IAuthorizationRequirement
{
    public string RequiredRole { get; }

    public RoleRequirement(string requiredRole)
    {
        RequiredRole = requiredRole;
    }
}

public class RoleAuthorizationHandler : AuthorizationHandler<RoleRequirement>
{
    protected override Task HandleRequirementAsync(
        AuthorizationHandlerContext context,
        RoleRequirement requirement)
    {
        if (context.User.IsInRole(requirement.RequiredRole))
        {
            context.Succeed(requirement);
        }
        else
        {
            context.Fail();
        }

        return Task.CompletedTask;
    }
}