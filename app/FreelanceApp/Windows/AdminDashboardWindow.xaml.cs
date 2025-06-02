using System.ComponentModel;
using System.Windows;
using FreelanceApp.Authentication;
using DAL.Models.Tables;
using FreelanceApp.Services;
using FreelanceApp.Windows.AdminControls;
using Microsoft.EntityFrameworkCore;

namespace FreelanceApp.Windows
{
    public partial class AdminDashboardWindow : Window
    {
        private readonly User _currentUser;

        public AdminDashboardWindow(User currentUser)
        {
            InitializeComponent();
            _currentUser = currentUser;
            Closing += async (_,_ ) => await UpdateLastOnlineAsync();

            ShowUsers();
        }

        private async void Window_Closing(object? sender, CancelEventArgs e) =>
            await UpdateLastOnlineAsync();

        private async Task UpdateLastOnlineAsync()
        {
            try
            {
                await using var context = DbContextFactory.CreateDbContext(_currentUser);
                await context.Database.ExecuteSqlInterpolatedAsync(
                    $"CALL core.update_user_last_online({_currentUser.Id}, {_currentUser.Id})"
                );
            }
            catch (Exception ex)
            {
                ex = ex.InnerException ?? ex;
                MessageBox.Show(
                    "Ошибка обновления статуса онлайн:\n\n" + $"{ex.Message}\n\n",
                    "Ошибка обновления статуса онлайн",
                    MessageBoxButton.OK,
                    MessageBoxImage.Warning
                );
            }
        }

        private void ShowUsers_Click(object sender, RoutedEventArgs e) => ShowUsers();

        private void ShowRoles_Click(object sender, RoutedEventArgs e) =>
            MainContent.Content = new RolesManagementControl(_currentUser);

        private void ShowAudit_Click(object sender, RoutedEventArgs e) =>
            MainContent.Content = new AuditLogsControl(_currentUser);

        private void ShowSql_Click(object sender, RoutedEventArgs e) =>
            MainContent.Content = new RawSqlControl(_currentUser);

        private void ShowImportExport_Click(object sender, RoutedEventArgs e) =>
            MainContent.Content = new ImportExportControl(_currentUser);

        private void MakeReport_Click(object sender, RoutedEventArgs e) =>
            MainContent.Content = new ReportControl(_currentUser);

        private void ShowUsers() => MainContent.Content = new UserManagementControl(_currentUser);

        private void Logout_Click(object sender, RoutedEventArgs e)
        {
            App.ResetConnection();
            new StartupWindow().Show();
            Close();
        }
    }
}
