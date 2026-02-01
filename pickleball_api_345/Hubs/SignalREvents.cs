namespace pickleball_api_345.Hubs;

/// <summary>
/// ✅ FIXED: Standardized SignalR event constants for consistent broadcasting
/// </summary>
public static class SignalREvents
{
    // Notification Events
    public const string ReceiveNotification = "ReceiveNotification";
    public const string UpdateUnreadCount = "UpdateUnreadCount";

    // Wallet Events
    public const string UpdateWalletBalance = "UpdateWalletBalance";
    public const string WalletDepositApproved = "WalletDepositApproved";
    public const string WalletDepositRejected = "WalletDepositRejected";

    // Booking Events
    public const string BookingCreated = "BookingCreated";
    public const string BookingCancelled = "BookingCancelled";
    public const string BookingUpdated = "BookingUpdated";
    public const string RefreshCalendar = "RefreshCalendar";

    // Slot Reservation Events
    public const string SlotStatusChanged = "SlotStatusChanged";
    public const string SlotReserved = "SlotReserved";
    public const string SlotReleased = "SlotReleased";
    public const string SlotExpired = "SlotExpired";

    // Tournament Events
    public const string TournamentRegistrationOpened = "TournamentRegistrationOpened";
    public const string TournamentRegistrationClosed = "TournamentRegistrationClosed";
    public const string TournamentBracketUpdated = "TournamentBracketUpdated";
    public const string TournamentMatchScheduled = "TournamentMatchScheduled";
    public const string TournamentMatchCompleted = "TournamentMatchCompleted";

    // Match Events
    public const string MatchScoreUpdated = "MatchScoreUpdated";
    public const string MatchStatusChanged = "MatchStatusChanged";
    public const string MatchStarted = "MatchStarted";
    public const string MatchCompleted = "MatchCompleted";

    // Chat Events
    public const string ReceiveMessage = "ReceiveMessage";
    public const string UserJoinedChat = "UserJoinedChat";
    public const string UserLeftChat = "UserLeftChat";
    public const string TypingIndicator = "TypingIndicator";

    // Admin Events
    public const string SystemMaintenanceNotice = "SystemMaintenanceNotice";
    public const string CourtStatusChanged = "CourtStatusChanged";
    public const string MemberTierUpdated = "MemberTierUpdated";

    // Connection Events
    public const string UserConnected = "UserConnected";
    public const string UserDisconnected = "UserDisconnected";
    public const string ForceLogout = "ForceLogout";
}

/// <summary>
/// SignalR group naming conventions
/// </summary>
public static class SignalRGroups
{
    public static string User(string userId) => $"User_{userId}";
    public static string Tournament(int tournamentId) => $"Tournament_{tournamentId}";
    public static string Match(int matchId) => $"Match_{matchId}";
    public static string Court(int courtId) => $"Court_{courtId}";
    public static string AdminUsers() => "AdminUsers";
    public static string AdminRole() => "Role_Admin";
    public static string AllUsers() => "AllUsers";
}

/// <summary>
/// Standard notification types
/// </summary>
public enum NotificationType
{
    Info,
    Success,
    Warning,
    Error,
    System
}

/// <summary>
/// Standard event payload structures
/// </summary>
public static class EventPayloads
{
    public class NotificationPayload
    {
        public string Type { get; set; } = string.Empty;
        public string Title { get; set; } = string.Empty;
        public string Message { get; set; } = string.Empty;
        public DateTime Timestamp { get; set; } = DateTime.UtcNow;
        public object? Data { get; set; }
    }

    public class WalletUpdatePayload
    {
        public decimal Balance { get; set; }
        public decimal Amount { get; set; }
        public string TransactionType { get; set; } = string.Empty;
        public int MemberId { get; set; }
        public string? TransactionId { get; set; }
        public DateTime Timestamp { get; set; } = DateTime.UtcNow;
    }

    public class BookingPayload
    {
        public int BookingId { get; set; }
        public int CourtId { get; set; }
        public string CourtName { get; set; } = string.Empty;
        public DateTime StartTime { get; set; }
        public DateTime EndTime { get; set; }
        public string Status { get; set; } = string.Empty;
        public int MemberId { get; set; }
        public string MemberName { get; set; } = string.Empty;
        public DateTime Timestamp { get; set; } = DateTime.UtcNow;
    }

    public class SlotStatusPayload
    {
        public int CourtId { get; set; }
        public DateTime StartTime { get; set; }
        public DateTime EndTime { get; set; }
        public string Status { get; set; } = string.Empty; // Available, Reserved, Booked
        public int? MemberId { get; set; }
        public DateTime? ExpiresAt { get; set; }
        public DateTime Timestamp { get; set; } = DateTime.UtcNow;
    }

    public class MatchScorePayload
    {
        public int MatchId { get; set; }
        public int TournamentId { get; set; }
        public string RoundName { get; set; } = string.Empty;
        public int Team1Score { get; set; }
        public int Team2Score { get; set; }
        public string Status { get; set; } = string.Empty;
        public DateTime Timestamp { get; set; } = DateTime.UtcNow;
    }
}