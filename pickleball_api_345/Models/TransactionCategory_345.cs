using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace pickleball_api_345.Models;

[Table("345_TransactionCategories")]
public class TransactionCategory_345
{
    [Key]
    public int Id { get; set; }
    
    [Required]
    [MaxLength(100)]
    public string Name { get; set; } = string.Empty;
    
    [Required]
    [MaxLength(20)]
    public string Type { get; set; } = string.Empty; // "Thu" or "Chi"
    
    public bool IsActive { get; set; } = true;
}