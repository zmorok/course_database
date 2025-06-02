using System.Diagnostics;
using System.IO;
using System.Text.RegularExpressions;
using System.Windows;
using System.Windows.Controls;
using DAL;
using DAL.Models.Tables;
using FreelanceApp.Services;
using Microsoft.Win32;

namespace FreelanceApp.Windows.AdminControls
{
    public partial class AuditLogsControl : UserControl
    {
        private readonly User _currentUser;
        private UnitOfWork? _uow;

        public AuditLogsControl(User user)
        {
            InitializeComponent();
            _currentUser = user;
            _uow = new UnitOfWork(DbContextFactory.CreateDbContext(_currentUser));
            LoadLogs();
        }

        private async void LoadLogs(DateTime? since = null, DateTime? until = null)
        {
            if (_uow == null) return;
            try
            {
                var logs = await _uow.AdminAudit.GetLogs(since, until, 500);
                AuditGrid.ItemsSource = logs;
            }
            catch (Exception ex)
            {
                MessageBox.Show(
                    $"Ошибка при загрузке логов: {ex.Message}",
                    "Ошибка",
                    MessageBoxButton.OK,
                    MessageBoxImage.Error
                );
            }
        }

        private void OnLoadClick(object sender, RoutedEventArgs e)
        {
            LoadLogs(SincePicker.SelectedDate, UntilPicker.SelectedDate);
        }

        private void OnExportClick(object sender, RoutedEventArgs e)
        {
            if (_uow == null) return;
            try
            {
                MessageBox.Show("Выберите путь без кириллицы.");
                var dlg = new SaveFileDialog
                {
                    Filter = "JSON files (*.json)|*.json|All files (*.*)|*.*",
                    FileName = "audit_logs.json",
                };
                if (dlg.ShowDialog() != true)
                    return;
                
                if (Regex.IsMatch(dlg.FileName, @"\p{IsCyrillic}"))
                {
                    MessageBox.Show("В вашем пути есть кириллица.");
                    return;
                }


                _uow.AdminAudit.ExportLogs(dlg.FileName, SincePicker.SelectedDate, UntilPicker.SelectedDate);

                var o = MessageBox.Show(
                    "Экспорт завершён.",
                    "Успех",
                    MessageBoxButton.YesNo,
                    MessageBoxImage.Information
                );

                if (o == MessageBoxResult.Yes) {
                    Process.Start("explorer.exe", Path.GetDirectoryName(dlg.FileName));
                }
                
            }
            catch (Exception ex)
            {
                MessageBox.Show(
                    $"Ошибка экспорта: {ex.Message}",
                    "Ошибка",
                    MessageBoxButton.OK,
                    MessageBoxImage.Error
                );
            }
        }

        private void OnImportClick(object sender, RoutedEventArgs e)
        {
            if (_uow == null) return;
            try
            {
                MessageBox.Show("Выберите путь без кириллицы.");
                var dlg = new OpenFileDialog
                {
                    Filter = "JSON files (*.json)|*.json|All files (*.*)|*.*",
                };
                if (dlg.ShowDialog() != true)
                    return;

                if (Regex.IsMatch(dlg.FileName, @"\p{IsCyrillic}"))
                {
                    MessageBox.Show("В вашем пути есть кириллица.");
                    return;
                }

                _uow.AdminAudit.ImportLogs(dlg.FileName);

                MessageBox.Show(
                    "Импорт завершён.",
                    "Успех",
                    MessageBoxButton.OK,
                    MessageBoxImage.Information
                );


                LoadLogs(SincePicker.SelectedDate, UntilPicker.SelectedDate);
            }
            catch (Exception ex)
            {
                MessageBox.Show(
                    $"Ошибка импорта: {ex.Message}",
                    "Ошибка",
                    MessageBoxButton.OK,
                    MessageBoxImage.Error
                );
            }
        }
    }
}
