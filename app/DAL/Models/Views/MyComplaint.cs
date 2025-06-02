using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace DAL.Models.Views
{
    public sealed class MyComplaint
    {
        [Key]
        public int Id_Complaint { get; set; }
        
        // на кого жалоба
        public int Id_User { get; set; }
        // кто подал жалобу
        public int Filed_By { get; set; }
        // на кого подана жалоба
        public string TargetName { get; set; } = ""; 
        public string Status { get; set; } = "";
        public string Description { get; set; } = "";

        [NotMapped]
        public string DescriptionPreview => Description.Length <= 50 ? Description : Description[..50] + "…";

        [NotMapped]
        public bool IsEditable => Status == "new";
    }
}
