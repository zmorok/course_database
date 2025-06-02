using System.ComponentModel.DataAnnotations;
using DAL.Extensions;

namespace DAL.Models.Views
{
    public sealed class OrderWithMyReview
    {
        [Key]
        public int OrderId { get; set; }

        public string ProjectTitle { get; set; } = "";
        public string OtherSideName { get; set; } = "";

        public int? ReviewId { get; set; }
        public string? MyComment { get; set; }
        public int? MyRating { get; set; }
        public string MyCommentPreview => ReviewId is null ? "[отзыва ещё нет]" : (MyComment ?? "").Truncate(50);

        public string? OppComment { get; set; }
        public int? OppRating { get; set; }
        public string OppCommentPreview => OppComment is null ? "[отзыва ещё нет]" : OppComment.Truncate(50);

        
        // вспомогательное
        public string EditButtonText => ReviewId is null ? "Добавить" : "Изменить";
        public bool DeleteButtonVisibility => ReviewId is not null;
    }
}
