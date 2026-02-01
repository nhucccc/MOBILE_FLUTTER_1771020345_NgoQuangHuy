using Microsoft.AspNetCore.Mvc;

namespace pickleball_api_345.Controllers;

[ApiController]
[Route("api/[controller]")]
public class HealthController : ControllerBase
{
    [HttpGet]
    public IActionResult Get()
    {
        return Ok(new { 
            status = "healthy", 
            timestamp = DateTime.UtcNow,
            message = "Backend API is running successfully"
        });
    }

    [HttpGet("ping")]
    public IActionResult Ping()
    {
        return Ok(new { 
            message = "pong", 
            timestamp = DateTime.UtcNow 
        });
    }
}