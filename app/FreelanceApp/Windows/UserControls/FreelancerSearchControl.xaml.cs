using DAL;
using DAL.Models.Views;
using DAL.Models.Tables;
using System.Windows;
using System.Windows.Controls;
using System.Windows.Input;
using FreelanceApp.Services;

namespace FreelanceApp.Windows.UserControls
{
    public partial class FreelancerSearchControl : UserControl
    {
        private User? _currentUser;
        private IUnitOfWork? _uow;
        private int _currentInviteeId;

        public FreelancerSearchControl()
        {
            InitializeComponent();
            Loaded += (s, e) =>
            {
                SearchBox.Focus();
                SearchBox.SelectAll();
            };
        }


        public void Initialize(User currentUser)
        {
            _currentUser = currentUser;
            _uow = new UnitOfWork(DbContextFactory.CreateDbContext(_currentUser));
        }

        private async Task DoSearchAsync()
        {
            if (_currentUser is null || _uow is null)
                return;

            string query = SearchBox.Text.Trim();
            try
            {
                var rows = await _uow.Search.SearchFreelancersAsync(_currentUser.Id, query);
                FreelancersList.ItemsSource = rows;
            }
            catch (Exception ex)
            {
                MessageBox.Show($"Ошибка поиска: {ex.InnerException?.Message ?? ex.Message}", "Ошибка",
                                MessageBoxButton.OK, MessageBoxImage.Error);
            }
        }

        private async void Search_Click(object s, RoutedEventArgs e)
            => await DoSearchAsync();

        private async void SearchBox_KeyUp(object s, KeyEventArgs e)
        {
            if (e.Key == Key.Enter)
                await DoSearchAsync();
        }

        private async Task LoadMyOpenProjectsAsync(int freelancerId)
        {
            if (_currentUser is null || _uow is null)
                return;

            _currentInviteeId = freelancerId;
            try
            {
                var freeProjects = await _uow.Search.GetFreeProjectsAsync(_currentUser.Id, freelancerId);
                ProjectsCombo.ItemsSource = freeProjects;
                if (freeProjects.Any())
                    ProjectsCombo.SelectedIndex = 0;
            }
            catch (Exception ex)
            {
                MessageBox.Show($"Ошибка загрузки проектов: {ex.InnerException?.Message ?? ex.Message}", "Ошибка",
                                MessageBoxButton.OK, MessageBoxImage.Error);
            }
        }

        private async void FreelancersList_DoubleClick(object s, MouseButtonEventArgs e)
        {
            if (FreelancersList.SelectedItem is FreelancerRow row)
                await LoadMyOpenProjectsAsync(row.Id);
        }

        private async void Invite_Click(object s, RoutedEventArgs e)
        {
            if ((s as Button)?.Tag is FreelancerRow row)
                await LoadMyOpenProjectsAsync(row.Id);
        }

        private async void SendInvite_Click(object s, RoutedEventArgs e)
        {
            if (_currentUser is null || _uow is null)
                return;
            if (ProjectsCombo.SelectedItem is not Project p)
                return;
            if (_currentInviteeId == 0)
                return;

            try
            {
                await _uow.Search.SendProjectInviteAsync(
                    actorId: _currentUser.Id,
                    inviteeId: _currentInviteeId,
                    projectId: p.Id);

                MessageBox.Show("Приглашение отправлено", "Успех", MessageBoxButton.OK, MessageBoxImage.Information);
                ProjectsCombo.ItemsSource = null;
                await DoSearchAsync();
            }
            catch (Exception ex)
            {
                MessageBox.Show($"Ошибка отправки приглашения: {ex.InnerException?.Message ?? ex.Message}", "Ошибка",
                                MessageBoxButton.OK, MessageBoxImage.Error);
            }
        }
    }
}
