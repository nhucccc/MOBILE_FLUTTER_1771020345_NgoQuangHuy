using Microsoft.AspNetCore.Mvc;

namespace pickleball_api_345.Controllers;

[ApiController]
[Route("api/[controller]")]
public class HealthController : ControllerBase
{
    [HttpGet]
    public IActionResult Get()
    {
        return Ok(new
        {
            status = "healthy",
            timestamp = DateTime.UtcNow,
            message = "API is running"
        });
    }

    [HttpGet("cors-test")]
    public IActionResult CorsTest()
    {
        return Ok(new
        {
            message = "CORS is working",
            timestamp = DateTime.UtcNow,
            origin = Request.Headers["Origin"].FirstOrDefault()
        });
    }
}