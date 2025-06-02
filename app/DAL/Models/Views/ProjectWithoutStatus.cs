using System.ComponentModel.DataAnnotations;
using System.Text.Json;

namespace DAL.Models.Views
{
    public class ProjectWithoutStatus
    {
        [Key]
        public int Id_Project { get; set; }
        public int Id_Customer { get; set; }
        public string Title { get; set; }
        public string Description { get; set; }
        public JsonDocument Media { get; set; }
    }
}
