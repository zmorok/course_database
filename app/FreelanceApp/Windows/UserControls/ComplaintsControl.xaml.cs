using DAL;
using DAL.Models.Views;
using DAL.Models.Tables;
using FreelanceApp.Services;
using System.Windows;
using System.Windows.Controls;
using System.Windows.Input;

namespace FreelanceApp.Windows.UserControls
{
    public partial class ComplaintsControl : UserControl
    {
        private User? _currentUser;
        private IUnitOfWork? _uow;
        private Counterpart? _selectedCounterpart;
        private MyComplaint? _editingComplaint;

        public ComplaintsControl()
        {
            InitializeComponent();
            Loaded += async (_, _) => await RefreshAsync();
        }

        public void Initialize(User user)
        {
            _currentUser = user;
            _uow = new UnitOfWork(DbContextFactory.CreateDbContext(_currentUser));
        }

        private async Task RefreshAsync()
        {
            if (_currentUser is null || _uow is null || !IsLoaded)
                return;

            try
            {
                var counterparts = await _uow.Complaints.GetCounterpartsAsync(_currentUser.Id);
                UsersList.ItemsSource = counterparts;

                var complaints = await _uow.Complaints.GetComplaintsAsync(_currentUser.Id);
                ComplaintsList.ItemsSource = complaints;

                _selectedCounterpart = null;
                _editingComplaint = null;
                EditPanel.Visibility = Visibility.Collapsed;
            }
            catch (Exception ex)
            {
                MessageBox.Show(
                    $"Ошибка загрузки жалоб: {ex.InnerException?.Message ?? ex.Message}",
                    "Ошибка",
                    MessageBoxButton.OK,
                    MessageBoxImage.Error);
            }
        }

        private void UsersList_DoubleClick(object? sender, MouseButtonEventArgs e)
        {
            if ((sender as ListView)?.SelectedItem is Counterpart u)
                ComplainTo(u);
        }

        private void Complain_Click(object? sender, RoutedEventArgs e)
        {
            if ((sender as Button)?.Tag is Counterpart u)
                ComplainTo(u);
        }

        private void ComplainTo(Counterpart user)
        {
            _selectedCounterpart = user;
            _editingComplaint = null;
            PanelTitle.Text = $"Жалоба на: {user.FullName}";
            ComplaintTextBox.Text = "";
            EditPanel.Visibility = Visibility.Visible;
        }

        private void EditComplaint_Click(object? sender, RoutedEventArgs e)
        {
            if ((sender as Button)?.DataContext is not MyComplaint c)
                return;

            if (!c.IsEditable)
            {
                MessageBox.Show("Редактировать можно только новые жалобы.");
                return;
            }

            _editingComplaint = c;
            _selectedCounterpart = null;
            PanelTitle.Text = "Изменить жалобу";
            ComplaintTextBox.Text = c.Description;
            EditPanel.Visibility = Visibility.Visible;
        }

        private async void DeleteComplaint_Click(object? sender, RoutedEventArgs e)
        {
            if (_currentUser is null || _uow is null)
                return;

            if ((sender as Button)?.DataContext is not MyComplaint c)
                return;

            var confirm = MessageBox.Show(
                "Удалить жалобу?",
                "Подтверждение",
                MessageBoxButton.YesNo,
                MessageBoxImage.Question);

            if (confirm != MessageBoxResult.Yes)
                return;

            try
            {
                await _uow.Complaints.DeleteComplaintAsync(
                    actorId: _currentUser.Id,
                    complaintId: c.Id_Complaint);

                await RefreshAsync();
            }
            catch (Exception ex)
            {
                MessageBox.Show(
                    $"Ошибка удаления жалобы: {ex.InnerException?.Message ?? ex.Message}",
                    "Ошибка",
                    MessageBoxButton.OK,
                    MessageBoxImage.Error);
            }
        }

        private async void SaveComplaint_Click(object? sender, RoutedEventArgs e)
        {
            if (_currentUser is null || _uow is null)
                return;

            var text = ComplaintTextBox.Text.Trim();
            if (string.IsNullOrWhiteSpace(text))
            {
                MessageBox.Show("Текст жалобы не может быть пустым.");
                return;
            }

            try
            {
                if (_editingComplaint is not null)
                {
                    await _uow.Complaints.UpdateComplaintAsync(
                        actorId: _currentUser.Id,
                        complaintId: _editingComplaint.Id_Complaint,
                        description: text);
                }
                else if (_selectedCounterpart is not null)
                {
                    await _uow.Complaints.CreateComplaintAsync(
                        actorId: _currentUser.Id,
                        filedById: _currentUser.Id,
                        targetUserId: _selectedCounterpart.Id,
                        description: text);
                }

                CancelEdit_Click(null, null);
                await RefreshAsync();
            }
            catch (Exception ex)
            {
                MessageBox.Show(
                    $"Ошибка сохранения жалобы: {ex.InnerException?.Message ?? ex.Message}",
                    "Ошибка",
                    MessageBoxButton.OK,
                    MessageBoxImage.Error);
            }
        }

        private void CancelEdit_Click(object? sender, RoutedEventArgs e)
        {
            EditPanel.Visibility = Visibility.Collapsed;
            _editingComplaint = null;
            _selectedCounterpart = null;
        }
    }
}
