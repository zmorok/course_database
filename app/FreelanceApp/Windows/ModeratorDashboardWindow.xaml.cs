using System.ComponentModel.DataAnnotations;
using System.Text.Json;
using System.Windows;
using System.Windows.Controls;
using FreelanceApp.Authentication;
using DAL.Models.Tables;
using FreelanceApp.Services;
using FreelanceApp.Windows.ModeratorControls;
using Microsoft.EntityFrameworkCore;
using Microsoft.VisualBasic;

namespace FreelanceApp.Windows
{
    public class ComplaintViewModel
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


    public partial class ModeratorDashboardWindow : Window
    {
        private string _currentFilter = "new";
        private string _sortDirection = "asc";
        private readonly User _currentUser;

        public ModeratorDashboardWindow(User currentUser)
        {
            InitializeComponent();
            _currentUser = currentUser;

            Loaded += (_, _) => _ = LoadComplaints();
            Closing += (_, _) => _ = UpdateLastOnlineAsync();
        }

        private async Task UpdateLastOnlineAsync()
        {
            try
            {
                await using var context = DbContextFactory.CreateDbContext(_currentUser);
                await context.Database.ExecuteSqlInterpolatedAsync(
                    @$"CALL core.update_user_last_online({_currentUser.Id}, {_currentUser.Id})"
                );
            }
            catch
            {
                MessageBox.Show("Ошибка при обновлении времени последнего входа.");
            }
        }

        

        private async Task LoadComplaints()
        {
            try
            {
                await using var context = DbContextFactory.CreateDbContext(_currentUser);

                var sql = _currentFilter == "all"
                    ? $"SELECT * FROM core.v_mod_complaints ORDER BY id_complaint {_sortDirection}"
                    : $"SELECT * FROM core.v_mod_complaints WHERE \"Status\" = '{_currentFilter}' ORDER BY id_complaint {_sortDirection}";

                var complaints = await context.Set<ComplaintViewModel>()
                    .FromSqlRaw(sql)
                    .ToListAsync();

                ComplaintsList.ItemsSource = complaints;
            }
            catch (Exception ex)
            {
                ex = ex.InnerException ?? ex;
                MessageBox.Show($"Ошибка при загрузке жалоб: {ex.Message}");
            }
        }

        private void FilterAll_Click(object sender, RoutedEventArgs e)
        {
            _currentFilter = "all";
            _ = LoadComplaints();
        }

        private void FilterNew_Click(object sender, RoutedEventArgs e)
        {
            _currentFilter = "new";
            _ = LoadComplaints();
        }

        private void FilterInProgress_Click(object sender, RoutedEventArgs e)
        {
            _currentFilter = "in_progress";
            _ = LoadComplaints();
        }

        private void FilterResolved_Click(object sender, RoutedEventArgs e)
        {
            _currentFilter = "resolved";
            _ = LoadComplaints();
        }

        private void FilterDismissed_Click(object sender, RoutedEventArgs e)
        {
            _currentFilter = "dismissed";
            _ = LoadComplaints();
        }


        private async void ResolveComplaint_Click(object sender, RoutedEventArgs e)
        {
            if ((sender as Button)?.Tag is not ComplaintViewModel complaint)
                return;

            if (MessageBox.Show($"Решить жалобу №{complaint.Id_Complaint}?", "Подтверждение", MessageBoxButton.YesNo, MessageBoxImage.Question) != MessageBoxResult.Yes)
                return;

            try
            {
                await using var context = DbContextFactory.CreateDbContext(_currentUser);
                await context.Database.ExecuteSqlRawAsync(
                    "CALL core.mod_resolve_complaint({0}, {1}, {2}, {3})",
                    _currentUser.Id,
                    complaint.Id_Complaint,
                    _currentFilter,
                    _currentUser.Id
                );
                await LoadComplaints();
            }
            catch (Exception ex)
            {
                MessageBox.Show($"Ошибка при решении жалобы: {ex.Message}");
            }
        }

        private async void EditStatus_Click(object sender, RoutedEventArgs e)
        {
            if (sender is not Button btn || btn.Tag is not ComplaintViewModel cm)
                return;

            // 2) Спрашиваем новый статус (new, in_progress, resolved, dismissed)
            string newStatus = Interaction.InputBox(
                "Введите новый статус жалобы (new, in_progress, dismissed):",
                "Изменить статус",
                cm.Status);
            if (string.IsNullOrWhiteSpace(newStatus) || newStatus == cm.Status)
                return;

            if (MessageBox.Show(
                    $"Изменить статус жалобы №{cm.Id_Complaint} на '{newStatus}'?",
                    "Подтверждение",
                    MessageBoxButton.YesNo,
                    MessageBoxImage.Question) != MessageBoxResult.Yes)
                return;

            try
            {
                await using var ctx = DbContextFactory.CreateDbContext(_currentUser);
                await ctx.Database.ExecuteSqlInterpolatedAsync(
                    $@"CALL core.mod_update_complaint_status(
                    {_currentUser.Id},
                    {cm.Id_Complaint},
                    {newStatus},
                    {_currentUser.Id}
               )");
                await LoadComplaints();
            }
            catch (Exception ex)
            {
                MessageBox.Show($"Ошибка при изменении статуса: {ex.Message}",
                                "Ошибка", MessageBoxButton.OK, MessageBoxImage.Error);
            }
        }

        private async void DeleteComplaint_Click(object sender, RoutedEventArgs e)
        {
            if ((sender as Button)?.Tag is not ComplaintViewModel complaint)
                return;

            if (MessageBox.Show($"Удалить жалобу №{complaint.Id_Complaint}?", "Подтверждение", MessageBoxButton.YesNo, MessageBoxImage.Warning) != MessageBoxResult.Yes)
                return;

            try
            {
                await using var context = DbContextFactory.CreateDbContext(_currentUser);
                await context.Database.ExecuteSqlRawAsync(
                    "CALL core.user_delete_complaint({0}, {1})",
                    _currentUser.Id,
                    complaint.Id_Complaint
                );
                await LoadComplaints();
            }
            catch (Exception ex)
            {
                MessageBox.Show($"Ошибка при удалении жалобы: {ex.Message}");
            }
        }

        private async void IssueWarning_Click(object sender, RoutedEventArgs e)
        {
            if (sender is not Button btn || btn.Tag is not ComplaintViewModel cm)
                return;

            var dlg = new IssueWarningWindow{Owner = this};
            if (dlg.ShowDialog() != true) return;

            try
            {
                await using var ctx = DbContextFactory.CreateDbContext(_currentUser);
                await ctx.Database.ExecuteSqlInterpolatedAsync($@"
                    CALL core.mod_issue_warning(
                        {_currentUser.Id},
                        {cm.Id_Complaint},
                        {cm.UserComId},
                        {dlg.WarningMessage},
                        {dlg.ExpiresDays}
                    )");
                MessageBox.Show("Предупреждение успешно выдано.", "",
                                MessageBoxButton.OK, MessageBoxImage.Information);

                await LoadComplaints();
            }
            catch (Exception ex)
            {
                MessageBox.Show($"Ошибка при выдаче предупреждения:\n{ex.Message}",
                                "Ошибка", MessageBoxButton.OK, MessageBoxImage.Error);
            }
        }

        private void Logout_Click(object sender, RoutedEventArgs e)
        {
            App.ResetConnection(); // сбрасываем на svc_app
            new StartupWindow().Show(); // возвращаемся на стартовое окно
            Close(); // закрываем текущее
        }

        private void Refresh_Click(object sender, RoutedEventArgs e)
        {
            _ = LoadComplaints();
        }

        private void AscDesc_Click(object sender, RoutedEventArgs e)
        {
            _sortDirection = _sortDirection == "asc" ? "desc" : "asc";
            _ = LoadComplaints();
        }
    }
}
