namespace pickleball_api_345.Models;

public enum MemberTier
{
    Standard = 0,
    Silver = 1,
    Gold = 2,
    Diamond = 3
}

public enum TransactionType
{
    Deposit = 0,
    Withdraw = 1,
    Payment = 2,
    Refund = 3,
    Reward = 4
}

public enum TransactionStatus
{
    Pending = 0,
    Completed = 1,
    Rejected = 2,
    Failed = 3
}

public enum BookingStatus
{
    PendingPayment = 0,
    Confirmed = 1,
    Cancelled = 2,
    Completed = 3
}

public enum TournamentFormat
{
    RoundRobin = 0,
    Knockout = 1,
    Hybrid = 2
}

public enum TournamentStatus
{
    Open = 0,
    Registering = 1,
    DrawCompleted = 2,
    Ongoing = 3,
    Finished = 4
}

public enum PaymentStatus
{
    Pending = 0,
    Paid = 1,
    Refunded = 2
}

public enum WinningSide
{
    Team1 = 1,
    Team2 = 2
}

public enum MatchStatus
{
    Scheduled = 0,
    InProgress = 1,
    Finished = 2
}

public enum NotificationType
{
    Info = 0,
    Success = 1,
    Warning = 2,
    Error = 3
}