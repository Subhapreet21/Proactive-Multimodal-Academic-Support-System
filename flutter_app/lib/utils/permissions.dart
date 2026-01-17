import '../providers/auth_provider.dart';
import '../utils/constants.dart';

class AppPermissions {
  final AuthProvider authProvider;

  AppPermissions(this.authProvider);

  String? get role => authProvider.userRole;

  // Timetable Permissions
  bool get canManageTimetable =>
      role == AppConstants.roleFaculty || role == AppConstants.roleAdmin;

  // Only Admin can filter freely. Faculty is restricted to their dept. Student is restricted to their class.
  // Admin can filter freely. Faculty can filter (restricted dept). Student is restricted to their class.
  bool get canFilterTimetable =>
      role == AppConstants.roleAdmin || role == AppConstants.roleFaculty;

  // Faculty is locked to their registered department (unless admin)
  bool get isDepartmentLocked => role == AppConstants.roleFaculty;

  // Student is locked to their registered departmentClass (unless admin)
  bool get isClassLocked => role == AppConstants.roleStudent;

  // Events Permissions
  // Only Admin can create/manage events (as per user request: Faculty View Only)
  bool get canManageEvents => role == AppConstants.roleAdmin;

  // Knowledge Base Permissions
  // Faculty and Admin can manage KB
  bool get canManageKB =>
      role == AppConstants.roleFaculty || role == AppConstants.roleAdmin;

  // Admin Features
  bool get isAdmin => role == AppConstants.roleAdmin;
  bool get isFaculty => role == AppConstants.roleFaculty;
  bool get isStudent => role == AppConstants.roleStudent;

  // For data filtering
  String? get department => authProvider.user?.department;
  String? get year => authProvider.user?.year;
  String? get section => authProvider.user?.section;
}
