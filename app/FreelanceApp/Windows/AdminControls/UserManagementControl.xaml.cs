using DAL;
using DAL.Models.Tables;
using FreelanceApp.Services;
using System.Security.Cryptography;
using System.Text;
using System.Windows;
using System.Windows.Controls;

namespace FreelanceApp.Windows.AdminControls
{
    public partial class UserManagementControl : UserControl
    {
        private enum Mode { None, Add, Edit, Delete }
        private User? _currentUser;
        private IUnitOfWork? _uow;
        private Mode _currentMode = Mode.None;
        private List<Role> _roles = new();

        public UserManagementControl(User user)
        {
            InitializeComponent();
            _currentUser = user;
            _uow = new UnitOfWork(DbContextFactory.CreateDbContext(_currentUser));
            _ = LoadDataAsync();
        }

        private async Task LoadDataAsync()
        {
            if (_currentUser == null || _uow == null) return;

            try
            {
                var list = await _uow.AdminUsers.GetUsersAsync();
                UsersGrid.ItemsSource = list;
                UsersGrid.Items.Refresh();

                _roles = await _uow.AdminUsers.GetRolesAsync();
                Form_RoleBox.ItemsSource = _roles;

                ShowActionsPanel();
            }
            catch (Exception ex)
            {
                MessageBox.Show(
                    $"Ошибка при загрузке пользователей: {ex.Message}",
                    "Ошибка", MessageBoxButton.OK, MessageBoxImage.Error);
            }
        }

        private void ShowActionsPanel()
        {
            _currentMode = Mode.None;
            ActionsPanel.Visibility = Visibility.Visible;
            FormPanel.Visibility = Visibility.Collapsed;
        }

        private void OnAddClick(object sender, RoutedEventArgs e)
        {
            _currentMode = Mode.Add;
            ClearForm();
            ShowForm(hideIdField: true);
        }

        private void OnEditClick(object sender, RoutedEventArgs e)
        {
            if (UsersGrid.SelectedItem is not User sel)
            {
                MessageBox.Show("Выберите пользователя", "Внимание", MessageBoxButton.OK, MessageBoxImage.Warning);
                return;
            }

            _currentMode = Mode.Edit;
            FillForm(sel);
            ShowForm(hideIdField: true);
        }

        private void OnDeleteClick(object sender, RoutedEventArgs e)
        {
            if (UsersGrid.SelectedItem is not User sel)
            {
                MessageBox.Show("Выберите пользователя", "Внимание", MessageBoxButton.OK, MessageBoxImage.Warning);
                return;
            }

            _currentMode = Mode.Delete;
            ClearForm();
            Form_IdBox.Text = sel.Id.ToString();
            ShowForm(hideIdField: false);
        }

        private void ShowForm(bool hideIdField)
        {
            ActionsPanel.Visibility = Visibility.Collapsed;
            FormPanel.Visibility = Visibility.Visible;
            Form_IdBox.Visibility = hideIdField ? Visibility.Collapsed : Visibility.Visible;
        }

        private void OnCancelClick(object sender, RoutedEventArgs e) => ShowActionsPanel();

        private async void OnSaveClick(object sender, RoutedEventArgs e)
        {
            if (_currentUser == null || _uow == null) return;

            try
            {
                int? roleId = (int?)Form_RoleBox.SelectedValue;
                decimal.TryParse(Form_RatingBox.Text, out var rating);
                string? passwordHash = HashOrNull(Form_PasswordBox.Password);

                switch (_currentMode)
                {
                    case Mode.Add:
                        await _uow.AdminUsers.CreateUserAsync(
                            actorId: _currentUser.Id,
                            passwordHash: passwordHash,
                            roleId: roleId,
                            lastName: Form_LastNameBox.Text,
                            firstName: Form_FirstNameBox.Text,
                            middleName: NullIfEmpty(Form_MiddleNameBox.Text),
                            gender: (Form_GenderBox.SelectedItem as ComboBoxItem)?.Content?.ToString() ?? "Other",
                            phoneNumber: NullIfEmpty(Form_PhoneBox.Text),
                            email: Form_EmailBox.Text,
                            rating: rating);
                        break;

                    case Mode.Edit:
                        int id = int.Parse(Form_IdBox.Text);
                        await _uow.AdminUsers.UpdateUserAsync(
                            actorId: _currentUser.Id,
                            userId: id,
                            passwordHash: passwordHash,
                            roleId: roleId,
                            lastName: Form_LastNameBox.Text,
                            firstName: Form_FirstNameBox.Text,
                            middleName: NullIfEmpty(Form_MiddleNameBox.Text),
                            gender: (Form_GenderBox.SelectedItem as ComboBoxItem)?.Content?.ToString() ?? "Other",
                            phoneNumber: NullIfEmpty(Form_PhoneBox.Text),
                            email: Form_EmailBox.Text,
                            rating: rating);
                        break;

                    case Mode.Delete:
                        int delId = int.Parse(Form_IdBox.Text);
                        var confirm = MessageBox.Show(
                            $"Удалить пользователя {delId}?", "Подтверждение",
                            MessageBoxButton.YesNo, MessageBoxImage.Warning);
                        if (confirm != MessageBoxResult.Yes) return;
                        await _uow.AdminUsers.DeleteUserAsync(
                            actorId: _currentUser.Id,
                            userId: delId);
                        break;
                }

                MessageBox.Show("Операция выполнена", "Успех", MessageBoxButton.OK, MessageBoxImage.Information);
                await Task.Delay(50);
                await LoadDataAsync();
            }
            catch (Exception ex)
            {
                MessageBox.Show($"Ошибка: {ex.Message}", "Ошибка", MessageBoxButton.OK, MessageBoxImage.Error);
            }
        }

        private void UsersGrid_SelectionChanged(object sender, SelectionChangedEventArgs e)
        {
            if (_currentMode == Mode.Edit && UsersGrid.SelectedItem is User sel)
                FillForm(sel);
        }

        private void FillForm(User u)
        {
            Form_IdBox.Text = u.Id.ToString();
            Form_LastNameBox.Text = u.LastName;
            Form_FirstNameBox.Text = u.FirstName;
            Form_MiddleNameBox.Text = u.MiddleName;
            Form_GenderBox.SelectedItem = Form_GenderBox.Items
                .Cast<ComboBoxItem>()
                .FirstOrDefault(i => i.Content?.ToString() == u.Gender);
            Form_PhoneBox.Text = u.PhoneNumber;
            Form_EmailBox.Text = u.Email;
            Form_RoleBox.SelectedValue = u.RoleId;
            Form_RatingBox.Text = u.Rating.ToString();
            Form_PasswordBox.Password = "";
        }

        private void ClearForm()
        {
            Form_IdBox.Clear();
            Form_LastNameBox.Clear();
            Form_FirstNameBox.Clear();
            Form_MiddleNameBox.Clear();
            Form_GenderBox.SelectedIndex = -1;
            Form_PhoneBox.Clear();
            Form_EmailBox.Clear();
            Form_PasswordBox.Clear();
            Form_RoleBox.SelectedIndex = -1;
            Form_RatingBox.Clear();
        }

        private static string? NullIfEmpty(string? s) =>
            string.IsNullOrWhiteSpace(s) ? null : s;

        private static string? HashOrNull(string password)
        {
            if (string.IsNullOrWhiteSpace(password))
                return null;
            var hash = SHA512.HashData(Encoding.UTF8.GetBytes(password));
            return Convert.ToHexString(hash);
        }
    }
}
