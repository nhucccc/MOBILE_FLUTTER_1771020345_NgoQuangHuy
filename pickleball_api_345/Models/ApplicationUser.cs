using Microsoft.AspNetCore.Identity;

namespace pickleball_api_345.Models;

public class ApplicationUser : IdentityUser
{
    public string? FullName { get; set; }
    public DateTime CreatedDate { get; set; } = DateTime.UtcNow;
    
    // Navigation property
    public virtual Member_345? Member { get; set; }
}