using DAL.Models.Tables;
using FreelanceApp.Windows.ViewModels;
using System.Windows;
using System.Windows.Controls;

namespace FreelanceApp.Windows.UserControls 
{
    public partial class ProfileControl : UserControl
    {
        public ProfileControl()
        {
            InitializeComponent();
        }

        public void Initialize(User user)
        {
            DataContext = new ProfileViewModel(user);
        }

        private void OnPasswordChanged(object sender, RoutedEventArgs e)
        {
            if (DataContext is ProfileViewModel vm && sender is PasswordBox pb)
            {
                vm.Password = pb.Password;
            }
        }
    }
};