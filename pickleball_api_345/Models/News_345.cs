using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace pickleball_api_345.Models;

[Table("345_News")]
public class News_345
{
    [Key]
    public int Id { get; set; }
    
    [Required]
    [MaxLength(200)]
    public string Title { get; set; } = string.Empty;
    
    [Required]
    public string Content { get; set; } = string.Empty;
    
    public bool IsPinned { get; set; } = false;
    
    public DateTime CreatedDate { get; set; } = DateTime.UtcNow;
    
    [MaxLength(500)]
    public string? ImageUrl { get; set; }
    
    [MaxLength(50)]
    public string? CreatedBy { get; set; }
}