namespace pickleball_api_345.Authorization;

public static class PolicyConstants
{
    // Role-based policies
    public const string RequireAdminRole = "RequireAdminRole";
    public const string RequireTreasurerRole = "RequireTreasurerRole";
    public const string RequireRefereeRole = "RequireRefereeRole";
    public const string RequireMemberRole = "RequireMemberRole";
    
    // Tier-based policies
    public const string RequireVipTier = "RequireVipTier";
    public const string RequireGoldTier = "RequireGoldTier";
    public const string RequireDiamondTier = "RequireDiamondTier";
    
    // Feature-based policies
    public const string CanCreateRecurringBooking = "CanCreateRecurringBooking";
    public const string CanApproveDeposits = "CanApproveDeposits";
    public const string CanManageCourts = "CanManageCourts";
    public const string CanManageMembers = "CanManageMembers";
    public const string CanViewReports = "CanViewReports";
    public const string CanManageTournaments = "CanManageTournaments";
}

public static class RoleConstants
{
    public const string Admin = "Admin";
    public const string Treasurer = "Treasurer";
    public const string Referee = "Referee";
    public const string Member = "Member";
}

public static class TierConstants
{
    public const string Standard = "Standard";
    public const string Silver = "Silver";
    public const string Gold = "Gold";
    public const string Diamond = "Diamond";
}