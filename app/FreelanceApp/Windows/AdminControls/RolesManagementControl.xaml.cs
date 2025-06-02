using System.Text.Json;
using System.Windows;
using System.Windows.Controls;
using DAL;
using DAL.Models.Tables;
using DAL.Models.Views;
using FreelanceApp.Services;

namespace FreelanceApp.Windows.AdminControls
{
    public partial class RolesManagementControl : UserControl
    {
        private enum Mode
        {
            None,
            Add,
            Edit,
            Delete,
        }

        private Mode _currentMode = Mode.None;
        private readonly User _currentUser;
        private UnitOfWork? _uow;

        public RolesManagementControl(User user)
        {
            InitializeComponent();
            _currentUser = user;
            _uow = new UnitOfWork(DbContextFactory.CreateDbContext(_currentUser));
            LoadRoles();
        }

        private async void LoadRoles()
        {
            if (_uow == null) return;

            try
            {
                var list = await _uow.AdminRoles.GetRolesAsync();
                RolesGrid.ItemsSource = list;
                RolesGrid.Items.Refresh();
                ShowActionsPanel();
            }
            catch (Exception ex)
            {
                MessageBox.Show(
                    $"Ошибка при загрузке ролей: {ex.Message}",
                    "Ошибка",
                    MessageBoxButton.OK,
                    MessageBoxImage.Error
                );
            }
        }

        private void ShowActionsPanel()
        {
            _currentMode = Mode.None;
            ActionsPanel.Visibility = Visibility.Visible;
            FormPanel.Visibility = Visibility.Collapsed;
        }

        private void ShowForm(bool hideIdField)
        {
            ActionsPanel.Visibility = Visibility.Collapsed;
            FormPanel.Visibility = Visibility.Visible;
            Form_IdBox.Visibility = hideIdField ? Visibility.Collapsed : Visibility.Visible;
            // При любом показе формы освобождаем или блокируем поле названия
            Form_NameBox.IsReadOnly = (_currentMode != Mode.Add);
        }

        private void FillForm(AdminRoleView sel)
        {
            Form_IdBox.Text = sel.Id.ToString();
            Form_NameBox.Text = sel.Name;
            Form_PrivilegesBox.Text = sel.Privileges;
        }

        private void ClearForm()
        {
            Form_IdBox.Text = "";
            Form_NameBox.Text = "";
            Form_PrivilegesBox.Text = "";
        }

        private void OnAddClick(object sender, RoutedEventArgs e)
        {
            _currentMode = Mode.Add;
            ClearForm();
            ShowForm(hideIdField: true);
        }

        private void OnEditClick(object sender, RoutedEventArgs e)
        {
            if (RolesGrid.SelectedItem is not AdminRoleView sel)
            {
                MessageBox.Show(
                    "Выберите роль в таблице",
                    "Внимание",
                    MessageBoxButton.OK,
                    MessageBoxImage.Warning
                );
                return;
            }

            _currentMode = Mode.Edit;
            FillForm(sel);
            ShowForm(hideIdField: true);
        }

        private void OnDeleteClick(object sender, RoutedEventArgs e)
        {
            if (RolesGrid.SelectedItem is not AdminRoleView sel)
            {
                MessageBox.Show(
                    "Выберите роль в таблице",
                    "Внимание",
                    MessageBoxButton.OK,
                    MessageBoxImage.Warning
                );
                return;
            }

            _currentMode = Mode.Delete;
            ClearForm();
            Form_IdBox.Text = sel.Id.ToString();
            Form_NameBox.Text = sel.Name;
            Form_PrivilegesBox.Text = sel.Privileges;
            ShowForm(hideIdField: false);
        }

        private async void OnSaveClick(object sender, RoutedEventArgs e)
        {
            if (_uow is null) return;
            try
            {
                await using var context = DbContextFactory.CreateDbContext(_currentUser);

                switch (_currentMode)
                {
                    case Mode.Add:
                        await _uow.AdminRoles.CreateRole(
                            _currentUser.Id,
                            Form_NameBox.Text,
                            JsonDocument.Parse(Form_PrivilegesBox.Text).RootElement
                        );
                        break;

                    case Mode.Edit:
                        await _uow.AdminRoles.UpdateRole(
                            _currentUser.Id,
                            int.Parse(Form_IdBox.Text),
                            JsonDocument.Parse(Form_PrivilegesBox.Text).RootElement
                        );
                        break;

                    case Mode.Delete:
                        {
                            int id = int.Parse(Form_IdBox.Text);
                            var confirm = MessageBox.Show(
                                $"Удалить роль ID {id}?",
                                "Подтверждение",
                                MessageBoxButton.YesNo,
                                MessageBoxImage.Question
                            );
                            if (confirm != MessageBoxResult.Yes) return;

                            await _uow.AdminRoles.DeleteRole(_currentUser.Id, id);
                        }
                        break;
                }

                MessageBox.Show(
                    "Операция выполнена.",
                    "Успех",
                    MessageBoxButton.OK,
                    MessageBoxImage.Information
                );

                await Task.Delay(200);
                LoadRoles();
            }
            catch (Exception ex)
            {
                MessageBox.Show(
                    $"Ошибка при сохранении: {ex.Message}",
                    "Ошибка",
                    MessageBoxButton.OK,
                    MessageBoxImage.Error
                );
            }
        }

        private void OnCancelClick(object sender, RoutedEventArgs e)
        {
            ShowActionsPanel();
        }

        private void RolesGrid_SelectionChanged(object sender, SelectionChangedEventArgs e)
        {
            if (_currentMode == Mode.Edit &&
                RolesGrid.SelectedItem is AdminRoleView sel)
            {
                FillForm(sel);
            }
        }
    }
}
