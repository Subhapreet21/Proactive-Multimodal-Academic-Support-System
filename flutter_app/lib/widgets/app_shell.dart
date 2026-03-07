import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/auth_provider.dart';
import '../config/theme.dart';
import 'pulse_icon.dart';

class AppShell extends StatefulWidget {
  final Widget child;
  final String currentPath;

  const AppShell({
    super.key,
    required this.child,
    required this.currentPath,
  });

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell>
    with SingleTickerProviderStateMixin {
  int _currentIndex = 0;
  final List<String> _navigationHistory = [];
  bool _isNavigatingBack = false;

  late final AnimationController _animationController;
  late final ScrollController _scrollController;
  bool _showSwipeHint = false;
  bool _hasSeenSwipeHint = false;

  @override
  void initState() {
    super.initState();
    _navigationHistory.add(widget.currentPath);

    _scrollController = ScrollController();
    _checkSwipeHintStatus();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
  }

  Future<void> _checkSwipeHintStatus() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _hasSeenSwipeHint = prefs.getBool('has_seen_swipe_hint') ?? false;
      _showSwipeHint = !_hasSeenSwipeHint;
    });

    _scrollController.addListener(() {
      if (_hasSeenSwipeHint) return;

      if (_scrollController.offset > 20) {
        setState(() {
          _showSwipeHint = false;
          _hasSeenSwipeHint = true;
        });
        prefs.setBool('has_seen_swipe_hint', true);
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(AppShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.currentPath != oldWidget.currentPath) {
      if (_isNavigatingBack) {
        _isNavigatingBack = false;
      } else {
        _updateHistory(widget.currentPath);
      }
    }
  }

  void _updateHistory(String newPath) {
    // Only track base tab paths, so we don't pollute history with sub-routes
    // Sub-routes will be handled natively by checking context.canPop()
    final isRootTab = newPath == '/app/dashboard' ||
        newPath == '/app/chat' ||
        newPath == '/app/timetable' ||
        newPath == '/app/events-notices' ||
        newPath == '/app/knowledge-base' ||
        newPath == '/app/reminders' ||
        newPath == '/app/virtual-tour' ||
        newPath == '/app/study-planner' ||
        newPath == '/app/faculty/daily-prep' ||
        newPath == '/app/quizzes' ||
        newPath == '/app/faculty/attendance' ||
        newPath == '/app/admin/attendance' ||
        newPath == '/app/student/attendance' ||
        newPath == '/app/profile';

    if (isRootTab) {
      // Prevent consecutive duplicates
      if (_navigationHistory.isEmpty || _navigationHistory.last != newPath) {
        _navigationHistory.add(newPath);
      }
    }
  }

  final List<NavigationItem> _navItems = [
    NavigationItem(
      label: 'Dashboard',
      selectedIcon: Icons.grid_view_rounded,
      unselectedIcon: Icons.grid_view_outlined,
      path: '/app/dashboard',
    ),
    NavigationItem(
      label: 'Chat',
      selectedIcon: Icons.forum_rounded,
      unselectedIcon: Icons.chat_bubble_outline_rounded,
      path: '/app/chat',
    ),
    NavigationItem(
      label: 'Timetable',
      selectedIcon: Icons.calendar_month_rounded,
      unselectedIcon: Icons.calendar_today_outlined,
      path: '/app/timetable',
    ),
    NavigationItem(
      label: 'Events',
      selectedIcon: Icons.event_rounded,
      unselectedIcon: Icons.event_outlined,
      path: '/app/events-notices',
    ),
    NavigationItem(
      label: 'Knowledge',
      selectedIcon: Icons.auto_stories_rounded,
      unselectedIcon: Icons.library_books_outlined,
      path: '/app/knowledge-base',
    ),
    NavigationItem(
      label: 'Tasks',
      selectedIcon: Icons.check_circle_rounded,
      unselectedIcon: Icons.radio_button_unchecked,
      path: '/app/reminders',
    ),
    NavigationItem(
      label: 'Tour',
      selectedIcon: Icons.vrpano_rounded,
      unselectedIcon: Icons.vrpano_outlined,
      path: '/app/virtual-tour',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final currentPath = widget.currentPath;
    final isStudent = authProvider.userRole == 'student';
    final isFaculty = authProvider.userRole == 'faculty';

    // Specific Items
    final studyItem = NavigationItem(
      label: 'Study',
      selectedIcon: Icons.school_rounded,
      unselectedIcon: Icons.school_outlined,
      path: '/app/study-planner',
    );

    final coPilotItem = NavigationItem(
      label: 'Co-Pilot',
      selectedIcon: Icons.co_present_rounded,
      unselectedIcon: Icons.co_present_outlined,
      path: '/app/faculty/daily-prep',
    );

    final quizzesItem = NavigationItem(
      label: 'Quizzes',
      selectedIcon: Icons.note_alt_rounded,
      unselectedIcon: Icons.note_alt_outlined,
      path: '/app/quizzes',
    );

    // Create the effective list of items to display
    final effectiveItems = List<NavigationItem>.from(_navItems);

    // Add Study Planner for Students
    if (isStudent && !effectiveItems.any((i) => i.path == studyItem.path)) {
      effectiveItems.add(studyItem);
    }

    // Add Co-Pilot for Faculty (Add to end)
    if (isFaculty && !effectiveItems.any((i) => i.path == coPilotItem.path)) {
      effectiveItems.add(coPilotItem);
    }

    // Add Attendance
    final attendanceItem = NavigationItem(
      label: 'Attendance',
      selectedIcon: Icons.how_to_reg_rounded,
      unselectedIcon: Icons.how_to_reg_outlined,
      path: isFaculty
          ? '/app/faculty/attendance'
          : (authProvider.userRole == 'admin'
              ? '/app/admin/attendance'
              : '/app/student/attendance'),
    );

    if (!effectiveItems.any((i) => i.label == 'Attendance')) {
      // Insert next to Dashboard (index 1)
      effectiveItems.insert(1, attendanceItem);
    }

    if ((isStudent || isFaculty) &&
        !effectiveItems.any((i) => i.path == quizzesItem.path)) {
      effectiveItems.insert(2, quizzesItem);
    }

    // Update current index based on path
    _currentIndex = effectiveItems.indexWhere((item) {
      if (item.path == currentPath) return true;
      if (currentPath.startsWith('${item.path}/')) return true;
      return false;
    });
    // If path not found (maybe viewing study plan but role changed? unlikely), default to dashboard
    if (_currentIndex == -1) _currentIndex = 0;

    // Full-screen mode for quiz taking (student & review & faculty preview)
    final isQuizActive = currentPath.contains('/app/quizzes/active');

    return BackButtonListener(
      onBackButtonPressed: () async {
        // 1. If GoRouter has an internal sub-route (like active quiz), pop it natively
        if (context.canPop()) {
          context.pop();
          return true; // We handled it
        }

        // 2. If we are at the root of a tab, navigate to the previously visited tab
        if (_navigationHistory.length > 1) {
          _navigationHistory.removeLast();
          final previousPath = _navigationHistory.last;
          _isNavigatingBack = true;
          context.go(previousPath);
          return true; // We handled it
        } else {
          // 3. We are at the very first tab with no history left. Confirm Exit.
          final shouldExit = await showDialog<bool>(
            context: context,
            builder: (context) => Dialog(
              backgroundColor: Colors.transparent,
              insetPadding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                width: double.infinity,
                constraints: const BoxConstraints(maxWidth: 400),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
                  ),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.white.withOpacity(0.1)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.5),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.errorColor.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.logout_rounded,
                          size: 32, color: AppTheme.errorColor),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Exit Campus OS?',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Are you sure you want to exit the app?',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.7),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.white70,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            child: const Text('Cancel'),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => Navigator.pop(context, true),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.errorColor,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8)),
                            ),
                            child: const Text(
                              'Exit',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );

          if (shouldExit == true) {
            SystemNavigator.pop();
          }
          return true; // We handled it (either showed dialog or chose to stay)
        }
      },
      child: Scaffold(
        appBar: isQuizActive
            ? null
            : AppBar(
                title: Text(_getTitle(currentPath)),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.person_rounded),
                    onPressed: () => context.go('/app/profile'),
                  ),
                ],
              ),
        drawer: isQuizActive ? null : _buildDrawer(context, authProvider),
        body: widget.child,
        bottomNavigationBar: isQuizActive
            ? null
            : RepaintBoundary(
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: AppTheme.backgroundGradient,
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  child: SafeArea(
                    // Ensuring safe area for gesture pill
                    top: false,
                    bottom: true, // Respect system navigation bar
                    child: Stack(
                      clipBehavior: Clip.none,
                      alignment: Alignment.centerRight,
                      children: [
                        SingleChildScrollView(
                          controller: _scrollController,
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(),
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              minWidth: MediaQuery.of(context).size.width - 16,
                            ),
                            child: Row(
                              mainAxisAlignment: effectiveItems.length > 5
                                  ? MainAxisAlignment.start
                                  : MainAxisAlignment.spaceBetween,
                              children: effectiveItems.map((item) {
                                final isSelected =
                                    effectiveItems.indexOf(item) ==
                                        _currentIndex;
                                return Padding(
                                  padding:
                                      const EdgeInsets.symmetric(horizontal: 4),
                                  child: GestureDetector(
                                    onTap: () => context.go(item.path),
                                    behavior: HitTestBehavior.opaque,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal:
                                              8), // Touch target padding
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          AnimatedContainer(
                                            duration: const Duration(
                                                milliseconds: 400),
                                            curve: Curves.easeInOutCubic,
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 16, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: isSelected
                                                  ? AppTheme.primaryColor
                                                      .withOpacity(0.2)
                                                  : Colors.transparent,
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                            ),
                                            child: PulseIcon(
                                              isSelected: isSelected,
                                              child: Icon(
                                                isSelected
                                                    ? item.selectedIcon
                                                    : item.unselectedIcon,
                                                color: isSelected
                                                    ? AppTheme.primaryLight
                                                    : Colors.white
                                                        .withOpacity(0.5),
                                                size: 24,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            item.label,
                                            style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: isSelected
                                                  ? FontWeight.bold
                                                  : FontWeight.normal,
                                              color: isSelected
                                                  ? Colors.white
                                                  : Colors.white
                                                      .withOpacity(0.5),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                        if (_showSwipeHint && effectiveItems.length > 4)
                          Positioned(
                            right: 8,
                            child: IgnorePointer(
                              child: AnimatedBuilder(
                                animation: _animationController,
                                builder: (context, child) {
                                  return Transform.translate(
                                    offset: Offset(
                                        -12 * _animationController.value, 0),
                                    child: child,
                                  );
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.6),
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppTheme.primaryColor
                                            .withOpacity(0.3),
                                        blurRadius: 6,
                                        spreadRadius: 1,
                                      )
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.chevron_left_rounded,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildDrawer(BuildContext context, AuthProvider authProvider) {
    final user = authProvider.user;

    return Drawer(
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF1E293B), Color(0xFF2E2E5D)], // Lighter shade
          ),
        ),
        child: Column(
          children: [
            UserAccountsDrawerHeader(
              decoration: const BoxDecoration(
                color: Colors.transparent,
                border: Border(bottom: BorderSide(color: Colors.white12)),
              ),
              currentAccountPicture: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: AppTheme.primaryColor, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryColor.withOpacity(0.5),
                        blurRadius: 10,
                      )
                    ]),
                child: CircleAvatar(
                  backgroundColor: const Color(0xFF0F172A),
                  backgroundImage: user?.avatarUrl != null
                      ? NetworkImage(user!.avatarUrl!)
                      : null,
                  child: user?.avatarUrl == null
                      ? Text(
                          user?.fullName?.substring(0, 1).toUpperCase() ?? 'U',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        )
                      : null,
                ),
              ),
              accountName: Row(
                children: [
                  Flexible(
                    child: Text(
                      user?.fullName ?? 'User',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: Colors.white,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      (user?.role ?? 'Student').toUpperCase(),
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              accountEmail: Text(
                user?.email ?? '',
                style: const TextStyle(fontSize: 14, color: Colors.white70),
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 16),
                children: const [
                  // Add extra items here if needed in future
                ],
              ),
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildDrawerItem(
                      icon: Icons.person_outline_rounded,
                      label: 'Profile',
                      onTap: () {
                        context.go('/app/profile');
                        Navigator.pop(context);
                      },
                    ),
                    const SizedBox(height: 8),
                    _buildDrawerItem(
                      icon: Icons.logout_rounded,
                      label: 'Sign Out',
                      color: AppTheme.errorColor,
                      onTap: () async {
                        Navigator.pop(context); // Close drawer first
                        _confirmSignOut(context, authProvider);
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color color = Colors.white,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: ListTile(
        leading: Icon(icon, color: color),
        title: Text(
          label,
          style: TextStyle(color: color, fontWeight: FontWeight.w500),
        ),
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  String _getTitle(String path) {
    if (path.contains('/app/study-planner')) return 'AI-Study Planner';
    if (path.contains('/app/profile')) return 'Profile';
    if (path.contains('/app/events-notices')) return 'Events & Notices';
    if (path.contains('/app/knowledge-base')) return 'Knowledge Base';
    if (path.contains('/app/knowledge-base')) return 'Knowledge Base';
    if (path.contains('/app/chat')) return 'Chat Assistant';
    if (path.contains('/app/faculty/daily-prep')) return 'AI Lecture Co-Pilot';
    if (path.contains('/attendance')) return 'Attendance';
    if (path.contains('/app/quizzes')) return 'Quizzes & Assessments';

    if (path.contains('/app/virtual-tour')) return 'Campus 360° Tour';

    final index = _navItems.indexWhere((item) => item.path == path);
    if (index != -1) {
      return _navItems[index].label;
    }

    return 'Dashboard';
  }

  Future<void> _confirmSignOut(
      BuildContext context, AuthProvider authProvider) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 16),
        child: Container(
          width: double.infinity,
          constraints: const BoxConstraints(maxWidth: 400),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.5),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.errorColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.power_settings_new_rounded,
                    size: 32, color: AppTheme.errorColor),
              ),
              const SizedBox(height: 16),
              const Text(
                'Sign Out?',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Are you sure you want to sign out?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.white70,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.errorColor,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text('Sign Out',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (confirm == true) {
      await authProvider.signOut();
      if (context.mounted) {
        context.go('/');
      }
    }
  }
}

class NavigationItem {
  final String label;
  final IconData selectedIcon;
  final IconData unselectedIcon;
  final String path;

  NavigationItem({
    required this.label,
    required this.selectedIcon,
    required this.unselectedIcon,
    required this.path,
  });
}
