using DAL;
using DAL.Models.Tables;
using DAL.Models.Views;
using FreelanceApp.Services;
using System.Windows;
using System.Windows.Controls;
using System.Windows.Input;

namespace FreelanceApp.Windows.UserControls
{
    public partial class ReviewsControl : UserControl
    {
        private User? _currentUser;
        private IUnitOfWork? _uow;
        private OrderWithMyReview? _currentRow;

        public ReviewsControl()
        {
            InitializeComponent();
        }

        public void Initialize(User currentUser)
        {
            _currentUser = currentUser;
            _uow = new UnitOfWork(DbContextFactory.CreateDbContext(_currentUser));
            _ = RefreshAsync();
        }

        private async Task RefreshAsync()
        {
            if (_currentUser == null || _uow == null || !IsLoaded)
                return;

            try
            {
                bool asCustomer = AsCustomerRadio.IsChecked == true;
                var rows = await _uow.Reviews.GetOrderReviewsAsync(_currentUser.Id, asCustomer);

                var list = rows.Select(r =>
                {
                    bool iAmCustomer = _currentUser!.Id == r.Id_Customer;
                    string otherName = iAmCustomer
                        ? (r.Freelancer_Fullname ?? "[удалён]")
                        : r.Customer_Fullname;
                    var myComment = iAmCustomer ? r.Customer_Comment : r.Freelancer_Comment;
                    var myRating = iAmCustomer ? r.Customer_Rating : r.Freelancer_Rating;
                    var myId = iAmCustomer ? r.Customer_Review_Id : r.Freelancer_Review_Id;
                    var opComment = !iAmCustomer ? r.Customer_Comment : r.Freelancer_Comment;
                    var opRating = !iAmCustomer ? r.Customer_Rating : r.Freelancer_Rating;

                    return new OrderWithMyReview
                    {
                        OrderId = r.Order_Id,
                        ProjectTitle = r.Project_Title,
                        OtherSideName = otherName,
                        ReviewId = myId,
                        MyComment = myComment,
                        MyRating = myRating,
                        OppComment = opComment,
                        OppRating = opRating,
                    };
                }).ToList();

                ArchiveList.ItemsSource = list;
                _currentRow = null;
                EditPanel.Visibility = Visibility.Collapsed;
            }
            catch (Exception ex)
            {
                MessageBox.Show($"Ошибка загрузки отзывов: {ex.Message}", "Ошибка", MessageBoxButton.OK, MessageBoxImage.Error);
            }
        }

        private void HideForm(object sender, RoutedEventArgs e)
        {
            if (IsLoaded)
            {
                _currentRow = null;
                PanelTitle.Text = "";
                CommentBox.Clear();
                RatingBox.SelectedIndex = -1;
                EditPanel.Visibility = Visibility.Collapsed;
            }
            
        }

        private void ViewChanged(object sender, RoutedEventArgs e)
        {
            HideForm(sender, e);
            _ = RefreshAsync();
        }

        private void AddEdit_Click(object sender, RoutedEventArgs e)
        {
            if ((sender as Button)?.DataContext is not OrderWithMyReview row)
                return;

            _currentRow = row;
            PanelTitle.Text = row.ReviewId is null ? "Новый отзыв" : "Изменить отзыв";
            CommentBox.Text = row.MyComment ?? "";
            RatingBox.SelectedIndex = (row.MyRating ?? 5) - 1;
            EditPanel.Visibility = Visibility.Visible;
        }

        private async void Save_Click(object sender, RoutedEventArgs e)
        {
            if (_currentUser == null || _uow == null || _currentRow == null)
                return;

            var comment = CommentBox.Text.Trim();
            if (string.IsNullOrWhiteSpace(comment))
            {
                MessageBox.Show("Комментарий не может быть пустым", "Внимание", MessageBoxButton.OK, MessageBoxImage.Warning);
                return;
            }
            int rating = RatingBox.SelectedIndex + 1;

            try
            {
                if (_currentRow.ReviewId is null)
                {
                    await _uow.Reviews.CreateReviewAsync(
                        actorId: _currentUser.Id,
                        orderId: _currentRow.OrderId,
                        reviewerId: _currentUser.Id,
                        comment: comment,
                        rating: rating);
                }
                else
                {
                    await _uow.Reviews.UpdateReviewAsync(
                        actorId: _currentUser.Id,
                        reviewId: _currentRow.ReviewId.Value,
                        reviewerId: _currentUser.Id,
                        comment: comment,
                        rating: rating);
                }

                EditPanel.Visibility = Visibility.Collapsed;
                _ = RefreshAsync();
            }
            catch (Exception ex)
            {
                MessageBox.Show($"Ошибка сохранения: {ex.Message}", "Ошибка", MessageBoxButton.OK, MessageBoxImage.Error);
            }
        }

        private async void Delete_Click(object sender, RoutedEventArgs e)
        {
            if (_currentUser == null || _uow == null)
                return;

            if ((sender as Button)?.DataContext is not OrderWithMyReview row || row.ReviewId is null)
                return;

            var result = MessageBox.Show(
                $"Удалить отзыв для заказа №{row.OrderId}?",
                "Подтверждение",
                MessageBoxButton.YesNo,
                MessageBoxImage.Question);

            if (result != MessageBoxResult.Yes)
                return;

            try
            {
                await _uow.Reviews.DeleteReviewAsync(
                    actorId: _currentUser.Id,
                    reviewId: row.ReviewId.Value,
                    reviewerId: _currentUser.Id);
                _ = RefreshAsync();
            }
            catch (Exception ex)
            {
                MessageBox.Show($"Ошибка удаления: {ex.Message}", "Ошибка", MessageBoxButton.OK, MessageBoxImage.Error);
            }
        }

        private void ArchiveList_DoubleClick(object sender, MouseButtonEventArgs e)
        {
            if (_currentRow?.ReviewId is not null)
                AddEdit_Click(sender, e);
        }

        private void Cancel_Click(object sender, RoutedEventArgs e)
        {
            if (IsLoaded) EditPanel.Visibility = Visibility.Collapsed;
        }
    }
}
