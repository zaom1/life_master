class AppConstants {
  static const String appName = 'LifeMaster';
  static const String appVersion = '1.0.0';
  
  static const int maxTodoCount = 10000;
  static const int maxReminderCount = 5000;
  static const int maxCalendarEventCount = 3000;
  static const int maxExpenseCount = 50000;
  static const int maxSubscriptionCount = 500;
  
  static const int storageLimitMB = 1024;
  
  static const String defaultCategory = 'General';
  
  static const List<String> defaultTodoCategories = [
    'General',
    'Work',
    'Personal',
    'Health',
    'Shopping',
    'Finance',
  ];
  
  static const List<String> defaultExpenseCategories = [
    'Food',
    'Transport',
    'Shopping',
    'Entertainment',
    'Health',
    'Education',
    'Housing',
    'Utilities',
    'Other',
  ];
  
  static const List<String> defaultSubscriptionCategories = [
    'Streaming',
    'Music',
    'Gaming',
    'Productivity',
    'Cloud Storage',
    'Fitness',
    'News',
    'Other',
  ];
}
