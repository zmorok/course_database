   M S B A M L   `   `   `  ����G  CFreelanceApp, Version=1.0.0.0, Culture=neutral, PublicKeyToken=nullW0clr-namespace:FreelanceApp.Windows.AdminControls"FreelanceApp.Windows.AdminControls  5      6    0FreelanceApp.Windows.AdminControls.RawSqlControl   5      W SPresentationCore, Version=9.0.0.0, Culture=neutral, PublicKeyToken=31bf3856ad364e35\ XPresentationFramework, Version=9.0.0.0, Culture=neutral, PublicKeyToken=31bf3856ad364e35e aSystem.Windows.Controls.Ribbon, Version=9.0.0.0, Culture=neutral, PublicKeyToken=b77a5c561934e089R NWindowsBase, Version=9.0.0.0, Culture=neutral, PublicKeyToken=31bf3856ad364e35F 9http://schemas.microsoft.com/winfx/2006/xaml/presentation     5      R NSystem.Xaml, Version=9.0.0.0, Culture=neutral, PublicKeyToken=b77a5c561934e089:x,http://schemas.microsoft.com/winfx/2006/xaml     5      @d2http://schemas.microsoft.com/expression/blend/2008     5      Blocal0clr-namespace:FreelanceApp.Windows.AdminControls     5      Jmc;http://schemas.openxmlformats.org/markup-compatibility/2006     5      .��5      �   � ColumnDefinitions  5   
   �� 5      $	��250 �6   �� 5      $��* �6   .+�5   
   �� $��0��6   $��0,0,10,0q�6%   .+�5      �� $��0,0,0,10q�5      $
��Bold"�5      $%��Примеры запросов��5      �� 5      -   5         ��Name$ ExamplesList��5      $	��100��5      5      �� 5      $��0,10,0,0q�6   $��SQL-запрос:��6*   �� 5      -   5         ��Name$ 
SqlTextBox��5      $	��100��5       �� AcceptsReturn$
 True��5        �� TextWrapping$
 Wrap=�5!      �� 5#      -   5        $��0,10,0,0q�5$      $��Выполнить��5&      5'      &   System.Windows.Controls.DataGrid  5*   
   -   5          Name$ 
ResultGrid��5+      $��1��5,         AutoGenerateColumns$
 True��5-         CanUserAddRows$ False��5.         
IsReadOnly$
 True��5/      50      51      