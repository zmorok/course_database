using System.ComponentModel.DataAnnotations;
using System.Text.Json;

namespace DAL.Models.Views
{
    public class ModerComplaint
    {
        [Key]
        public int Id_Complaint { get; set; }

        public int UserComId { get; set; }
        public string UserComName { get; set; } = "";

        public int FiledById { get; set; }
        public string FiledByName { get; set; } = "";

        public int? ModeratorId { get; set; }

        public string Status { get; set; } = "";
        public string Description { get; set; } = "";
        public JsonDocument? Media { get; set; }
    }
}
