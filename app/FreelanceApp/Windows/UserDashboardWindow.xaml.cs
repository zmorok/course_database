using System.ComponentModel;
using System.Windows;
using System.Windows.Controls;
using System.Windows.Input;
using FreelanceApp.Authentication;
using DAL.Models.Tables;
using FreelanceApp.Services;
using FreelanceApp.Windows.UserControls;
using Microsoft.EntityFrameworkCore;

namespace FreelanceApp.Windows
{
    public partial class UserDashboardWindow : Window
    {
        private readonly User _currentUser;

        public UserDashboardWindow(User user)
        {
            InitializeComponent();
            _currentUser = user;
            Title = "Панель пользователя: " + user.FirstName + " " + user.LastName;
            Closing += async (_, _) => await UpdateLastOnlineAsync();
        }

        private readonly HashSet<string> _initializedTabs = [];

        private void TabControl_SelectionChanged(object sender, SelectionChangedEventArgs e)
        {
            if (
                e.Source is TabControl tabControl
                && tabControl.SelectedItem is TabItem selectedTab
                && selectedTab.Header is string header
                && !_initializedTabs.Contains(header)
            )
            {
                switch (header)
                {
                    case "Профиль":
                        ProfileControl.Initialize(_currentUser);
                        break;
                    case "Портфолио":
                        PortfolioControl.Initialize(_currentUser);
                        break;
                    case "Мои заказы":
                        OrdersControl.Initialize(_currentUser);
                        break;
                    case "Проекты":
                        ProjectsControl.Initialize(_currentUser);
                        break;
                    case "Отзывы":
                        ReviewsControl.Initialize(_currentUser);
                        break;
                    case "Жалобы":
                        ComplaintsControl.Initialize(_currentUser);
                        break;
                    case "Поиск исполнителя":
                        FreelancerSearchControl.Initialize(_currentUser);
                        break;
                }

                _initializedTabs.Add(header);
            }
        }

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

        private void Logout_Click(object sender, RoutedEventArgs e)
        { 
            App.ResetConnection();
            new StartupWindow().Show();
            Close();
        }

        private void TabItem_MouseLeftButtonDown(object sender, MouseButtonEventArgs e) { }
    }
}
