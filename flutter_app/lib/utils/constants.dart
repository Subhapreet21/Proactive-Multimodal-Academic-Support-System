class AppConstants {
  // API Endpoints
  static const String authSyncEndpoint = '/api/auth/sync';
  static const String dashboardEndpoint = '/api/dashboard';
  static const String chatTextEndpoint = '/api/chat/text';
  static const String chatImageEndpoint = '/api/chat/image';
  static const String chatHistoryEndpoint = '/api/chat/history';
  static const String chatConversationsEndpoint = '/api/chat/conversations';
  static const String timetableEndpoint = '/api/timetable';
  static const String eventsEndpoint = '/api/events';
  static const String remindersEndpoint = '/api/reminders';
  static const String kbEndpoint = '/api/kb';
  static const String profileEndpoint = '/api/profile';
  static const String onboardingEndpoint = '/api/auth/role';
  static const String resetProfileEndpoint = '/api/auth/reset-profile';
  
  // Role Types
  static const String roleStudent = 'student';
  static const String roleFaculty = 'faculty';
  static const String roleAdmin = 'admin';
  
  // Storage Keys
  static const String storageKeyToken = 'auth_token';
  static const String storageKeyUserId = 'user_id';
  static const String storageKeyUserRole = 'user_role';
  
  // Department Options
  static const List<String> departments = [
    'CSE',
    'ECE',
    'EEE',
    'ME',
    'CE',
    'IT',
  ];
  
  // Year Options
  static const List<String> years = [
    '1',
    '2',
    '3',
    '4',
  ];
  
  // Section Options
  static const List<String> sections = [
    'A',
    'B',
    'C',
  ];
  
  // Reminder Categories
  static const List<String> reminderCategories = [
    'Assignment',
    'Exam',
    'Project',
    'Personal',
    'Other',
  ];
  
  // Event Categories
  static const List<String> eventCategories = [
    'Academic',
    'Cultural',
    'Sports',
    'Workshop',
    'Seminar',
    'Notice',
  ];
}
