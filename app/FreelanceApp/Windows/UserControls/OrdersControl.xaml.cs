using DAL;
using DAL.Models.Tables;
using DAL.Models.Views;
using FreelanceApp.Services;
using System.Windows;
using System.Windows.Controls;
using System.Windows.Input;

namespace FreelanceApp.Windows.UserControls
{
    public enum OrderViewType
    {
        Customer,
        Freelancer,
        Archive,
    }

    public partial class OrdersControl : UserControl
    {
        private IUnitOfWork? _uow;
        private User? _currentUser;
        private Order? _selectedOrder;
        private OrderViewType _currentOrderView = OrderViewType.Customer;

        public OrdersControl()
        {
            InitializeComponent();
            Loaded += async (_, _) => await LoadOrdersAsync();
        }

        public void Initialize(User user)
        {
            _currentUser = user;
            _uow = new UnitOfWork(DbContextFactory.CreateDbContext(_currentUser));
        }

        private async Task LoadOrdersAsync()
        {
            if (_currentUser == null || _uow == null)
                return;

            OrdersListView.ItemsSource = null;

            try
            {
                var list = _currentOrderView switch
                {
                    OrderViewType.Customer => await _uow.Orders.GetOrdersByCustomerAsync(_currentUser.Id),
                    OrderViewType.Freelancer => await _uow.Orders.GetOrdersByFreelancerAsync(_currentUser.Id),
                    OrderViewType.Archive => await _uow.Orders.GetArchiveOrdersAsync(_currentUser.Id),
                    _ => []
                };

                OrdersListView.ItemsSource = list;
            }
            catch (Exception ex)
            {
                MessageBox.Show(
                    $"Ошибка при загрузке заказов: {ex.Message}",
                    "Ошибка",
                    MessageBoxButton.OK,
                    MessageBoxImage.Error
                );
            }
        }

        private void OrderView_Changed(object sender, RoutedEventArgs e)
        {
            if (sender is RadioButton rb && IsLoaded)
            {
                _currentOrderView = rb switch
                {
                    var r when r == ShowCustomerOrdersRadio => OrderViewType.Customer,
                    var r when r == ShowFreelancerOrdersRadio => OrderViewType.Freelancer,
                    var r when r == ShowArchiveRadio => OrderViewType.Archive,
                    _ => _currentOrderView
                };

                bool isArchive = _currentOrderView == OrderViewType.Archive;

                EditButton.Visibility = isArchive ? Visibility.Collapsed : Visibility.Visible;
                DeleteButton.Visibility = isArchive ? Visibility.Collapsed : Visibility.Visible;

                
                OrdersListView.MouseDoubleClick -= OrdersListView_MouseDoubleClick;
                if (!isArchive)
                    OrdersListView.MouseDoubleClick += OrdersListView_MouseDoubleClick;
                _ = LoadOrdersAsync();
            }
        }

        private void OnEditClick(object sender, RoutedEventArgs e)
        {
            if (OrdersListView.SelectedItem is not LocalOrderDisplay row)
            {
                MessageBox.Show("Выберите заказ в списке.");
                return;
            }

            _selectedOrder = new Order { Id = row.OrderId };

            StatusComboBox.SelectedValue = row.OrderStatus;
            DeadlinePicker.SelectedDate = row.OrderDeadline;

            AddEditOrderPanel.Visibility = Visibility.Visible;
            FormTitle.Text = "Изменение заказа";
        }

        private void OrdersListView_MouseDoubleClick(object sender, MouseButtonEventArgs e)
        {
            if (_currentOrderView != OrderViewType.Archive)
                OnEditClick(sender, e);
        }

        private async void OnDeleteClick(object sender, RoutedEventArgs e)
        {
            if (_currentUser == null || _uow == null)
                return;

            if (OrdersListView.SelectedItem is not LocalOrderDisplay row)
            {
                MessageBox.Show("Выберите заказ.");
                return;
            }

            if (MessageBox.Show(
                    $"Удалить заказ №{row.OrderId}?",
                    "Подтверждение",
                    MessageBoxButton.YesNo,
                    MessageBoxImage.Question
                ) != MessageBoxResult.Yes)
                return;

            try
            {
                await _uow.Orders.DeleteOrderAsync(_currentUser.Id, row.OrderId);
                await LoadOrdersAsync();
            }
            catch (Exception ex)
            {
                MessageBox.Show(
                    $"Ошибка при удалении: {ex.Message}",
                    "Ошибка",
                    MessageBoxButton.OK,
                    MessageBoxImage.Error
                );
            }
        }

        private void OnCancelClick(object sender, RoutedEventArgs e)
        {
            ClearEditForm();
            AddEditOrderPanel.Visibility = Visibility.Collapsed;
            _selectedOrder = null;
        }

        private async void OnSaveClick(object sender, RoutedEventArgs e)
        {
            if (_currentUser == null || _uow == null || _selectedOrder == null)
                return;

            var statusItem = StatusComboBox.Items
                .OfType<ComboBoxItem>()
                .FirstOrDefault(i => i.Tag?.ToString() == _selectedOrder.Status);

            string newStatus = statusItem?.Tag?.ToString() ?? _selectedOrder.Status;

            DateTime? deadline = DeadlinePicker.SelectedDate;

            try
            {
                await _uow.Orders.UpdateOrderAsync(
                    _currentUser.Id,
                    _selectedOrder.Id,
                    newStatus,
                    deadline);

                OnCancelClick(sender, e);
                await LoadOrdersAsync();
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

        private void ClearEditForm()
        {
            StatusComboBox.SelectedIndex = -1;
            DeadlinePicker.SelectedDate = null;
        }
    }
}