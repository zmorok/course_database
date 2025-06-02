using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace DAL.Models.Views
{
    public sealed class OrderReviewsRow
    {
        [Key]
        public int Order_Id { get; set; }
        public DateTime Creation_Date { get; set; }

        public string Project_Title { get; set; } = "";

        public int Id_Customer { get; set; }
        public string Customer_Fullname { get; set; } = "";
        public int? Customer_Review_Id { get; set; }
        public string? Customer_Comment { get; set; }
        public int? Customer_Rating { get; set; }

        public int? Id_Freelancer { get; set; }
        public string? Freelancer_Fullname { get; set; }
        public int? Freelancer_Review_Id { get; set; }
        public string? Freelancer_Comment { get; set; }
        public int? Freelancer_Rating { get; set; }
    }
}
