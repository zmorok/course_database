   M S B A M L   `   `   `  ����G  CFreelanceApp, Version=1.0.0.0, Culture=neutral, PublicKeyToken=nullA%clr-namespace:FreelanceApp.ConvertersFreelanceApp.Converters  5      > :DAL, Version=1.0.0.0, Culture=neutral, PublicKeyToken=null@+clr-namespace:DAL.Models.Views;assembly=DALDAL.Models.Views 5      U/clr-namespace:FreelanceApp.Windows.UserControls!FreelanceApp.Windows.UserControls  5      9!clr-namespace:FreelanceApp.ModelsFreelanceApp.Models  5
      5    /FreelanceApp.Windows.UserControls.OrdersControl   5      W SPresentationCore, Version=9.0.0.0, Culture=neutral, PublicKeyToken=31bf3856ad364e35\ XPresentationFramework, Version=9.0.0.0, Culture=neutral, PublicKeyToken=31bf3856ad364e35e aSystem.Windows.Controls.Ribbon, Version=9.0.0.0, Culture=neutral, PublicKeyToken=b77a5c561934e089R NWindowsBase, Version=9.0.0.0, Culture=neutral, PublicKeyToken=31bf3856ad364e35F 9http://schemas.microsoft.com/winfx/2006/xaml/presentation     5      R NSystem.Xaml, Version=9.0.0.0, Culture=neutral, PublicKeyToken=b77a5c561934e089:x,http://schemas.microsoft.com/winfx/2006/xaml     5      <
converters%clr-namespace:FreelanceApp.Converters     5      @d2http://schemas.microsoft.com/expression/blend/2008     5      <data+clr-namespace:DAL.Models.Views;assembly=DAL     5      Alocal/clr-namespace:FreelanceApp.Windows.UserControls     5      Jmc;http://schemas.openxmlformats.org/markup-compatibility/2006     5	      4models!clr-namespace:FreelanceApp.Models     5
        � 	Resources  5      2   ,FreelanceApp.Converters.NullToFalseConverter   NullToFalseConverter��%   &	          5   
   6*   5      .��5      � $��10q�6    � RowDefinitions 5   
   �� 5      $
��Auto �6   �� 5      $��* �6   �� 5      $
��Auto �6   .+�5   
   ]� $��0��6   $��0,0,0,10q�6!   .+�5      �� $��Center=�5      $
��Left=�5       �� Orientation$ 
Horizontal=�5      .+�5       �� $��0,0,10,0q�5!      $��Center=�5"      $��Показать:��5#      	� 5$      -   5         	�Name$ ShowCustomerOrdersRadio��5%      $��5q�5&      $/��)Мои заказы (я заказчик)��5(       	� 	GroupName$ 	OrderView��5)       d� 	IsChecked$
 TrueY�5*      	� 5+      -   5        $ ShowFreelancerOrdersRadio��5,      $��5q�5-      $5��/Мои заказы (я исполнитель)��5/      $ 	OrderView��50      	� 51      -   5        $ ShowArchiveRadio��52      $��5q�53      $��
Архив��55      $ 	OrderView��56      57      �� 59      $��Right=�5:      $��Right=�5;      $ 
Horizontal=�5<      .+�5=      �� -   5         ��Name$ 
EditButton��5>      $	��100��5?      $��5q�5@      $2��,Изменить статус/дедлайн��5B      {�5C      ��  �� ElementName$ OrdersListView�� �� Path$ SelectedItem�	 �� 	Converter#	 [  �� 5D      -   5        $ DeleteButton��5E      $	��100��5F      $��5q�5G      $%��Отменить/Удалить��5I      {�5J      �� $ OrdersListView��$ SelectedItem�#	 [  5K      5L      �� 5N   
   -   5        
 ��Name$
 OrdersListView��5O      $��1��5P      $��Disabled=�5R       �� SelectionMode$ Single=�5S      ��5T      �� 5U       �� 
TargetType" ��6   .�5V      ��  �� Property � �� �� Value$ Stretch=�6C   5W      ��5Y      �� 5Z       �� DataType(  "DAL.Models.Views.LocalOrderDisplay"  6   .R�5[      �� $��5q�5\       �� Padding$ 10q�5]      
�������$��1q�5_       �� CornerRadius$ 5��5`      ._�5a      �  5b      �� 5c   "   $
��Auto �60   �� 5d   "   $
��Auto �60   �� 5e   "   $
��Auto �60    � ColumnDefinitions 5g      �� 5h   "   $��* �63   �� 5i   "   $
��Auto �63   .+�5m      �� $��0��5n   !   $��0��5o   !   $��0,0,10,5q�5p   !   $��14(�5q   !   $
��Bold"�5r   !   $��CharacterEllipsis=�5s   !   �� 5t   "   $�Проект:��6&    �� 5u   "   �6&   �� *ProjectTitle+ �� FallbackValue$ [Загрузка...]�� �� TargetNullValue$&  [Проект не найден]�� �� 5v   "   $�(Заказ №��6&    �� 5w   "   �6&   �� *	OrderId+ �� 5y   "   $�)��6&   5z      �� 5}      $��0��5~   !   $��1��5   !   $��Right=�5�   !   $ 
Horizontal=�5�   !   .+�5�   "   �� $��0,0,15,0q�5�   %   $��SemiBold"�5�   %   ��5�   %   �� *OrderStatus+�� 5�   "   �� 5�   &   $�Дедлайн:��6*    �� 5�   &   �6*   �� *OrderDeadline+ �� StringFormat$ 
dd.MM.yyyy��$ Не указан��$ Не указан��5�   #   5�      �� 5�      $��1��5�   !   $��0��5�   !   $��2��5�   !   $��0,3,0,3q�5�   !   .+�5�   "   �� �� 5�   &   $�Заказчик: ��6*    �� 5�   &   �6*   �� *CustomerFullName+$  ��$ ?��5�   #   �� 5�   "   �� 5�   &   $�Исполнитель: ��6*    �� 5�   &   �6*   �� *FreelancerFullName+$  ��$ ?��5�   #   5�      �� 5�      $��2��5�   !   $��0��5�   !   $��2��5�   !   $��11(�5�   !   
��������� 5�   "   $�Создан:��6&    �� 5�   "   �6&   �� *OrderCreationDate+$ dd.MM.yyyy HH:mm��5�      5�      5�      5�      5�      �� 5�   
   -   5         ��Name$ AddEditOrderPanel��5�      $��2��5�      $��0,10,0,0q�5�      $ 15q�5�      
�������
�������$��1q�5�      $y�	Collapsed=�5�      ._�5�      �� .+�5�      �� -   5         ��Name$ 	FormTitle��5�      $��0,0,0,15q�5�      $��16(�5�      $
��Bold"�5�      $%��Изменение заказа��5�      � 5�       5�      �� 5�      $
��Auto �6+   �� 5�      $��* �6+    5�      �� 5�      $
��Auto �6(   �� 5�      $
��Auto �6(   .+�5�      �� $��0��5�      $��0��5�      $��0,0,10,5q�5�      $��Center=�5�      $��Статус:��5�      �� 5�      -	   5         ��Name$ StatusComboBox��5�      $��0��5�      $��1��5�      $��0,0,0,5q�5�       �� DisplayMemberPath$ Content��5�       �� SelectedValuePath$	 Tag��5�      .@�5�      �� $��Ожидает��6'   
 � Tag$ pending��69   �� 5�      $��В работе��6'   $ active��6:   �� 5�      $��Завершен��6'   $ 	completed��6:   �� 5�      $��Отменён��6'   $ 	cancelled��69   �� 5�      $��Спор��6'   $ disputed��66   5�      �� 5�      $��1��5�      $��0��5�      $��0,0,10,5q�5�      $��Center=�5�      $��Дедлайн:��5�      (  "System.Windows.Controls.DatePicker  5�      -
   5          Name$ DeadlinePicker��5�      $��1��5�      $��1��5�      $��0,0,0,5q�5�      5�      �� 5�      $��0,15,0,0q�5�      $��Right=�5�      $ 
Horizontal=�5�      .+�5�      �� -   5        $ 
SaveButton��5�      $	��100��5�      $��5q�5�      $��Сохранить��5�      �� 5�      -   5        $ CancelButton��5�      $	��100��5�      $��5q�5�      $��Отмена��5�      5�      5�      5�      5�      5�      