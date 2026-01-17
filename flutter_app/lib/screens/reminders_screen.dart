import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/reminder_model.dart';
import '../config/theme.dart';
import '../utils/constants.dart';
import '../utils/date_formatter.dart';
import 'package:intl/intl.dart';

class RemindersScreen extends StatefulWidget {
  const RemindersScreen({super.key});

  @override
  State<RemindersScreen> createState() => _RemindersScreenState();
}

class _RemindersScreenState extends State<RemindersScreen> {
  final ApiService _apiService = ApiService();
  List<ReminderModel> _reminders = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadReminders();
  }

  Future<void> _loadReminders() async {
    setState(() => _isLoading = true);

    try {
      final response = await _apiService.get(AppConstants.remindersEndpoint);
      // Ensure backend response is handled correctly even if null
      final reminders =
          (response as List?)?.map((e) => ReminderModel.fromJson(e)).toList() ??
              [];

      if (mounted) {
        setState(() {
          _reminders = reminders;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading reminders: $e')),
        );
      }
    }
  }

  Future<void> _toggleCompletion(ReminderModel reminder) async {
    // Optimistic Update
    final newState = !reminder.isCompleted;
    setState(() {
      final index = _reminders.indexWhere((r) => r.id == reminder.id);
      if (index != -1) {
        _reminders[index] = reminder.copyWith(isCompleted: newState);
      }
    });

    try {
      await _apiService.put(
        '${AppConstants.remindersEndpoint}/${reminder.id}',
        {'is_completed': newState},
      );
      // _loadReminders(); // No need to reload if optimistic update succeeds
    } catch (e) {
      // Revert if error
      setState(() {
        final index = _reminders.indexWhere((r) => r.id == reminder.id);
        if (index != -1) {
          _reminders[index] = reminder.copyWith(isCompleted: !newState);
        }
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating reminder: $e')),
        );
      }
    }
  }

  Future<void> _deleteReminder(String id) async {
    try {
      await _apiService.delete('${AppConstants.remindersEndpoint}/$id');
      setState(() {
        _reminders.removeWhere((r) => r.id == id);
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting task: $e')),
        );
      }
    }
  }

  Future<void> _showAddEditReminderDialog({ReminderModel? reminder}) async {
    final isEdit = reminder != null;
    final titleController = TextEditingController(text: reminder?.title);
    final descController = TextEditingController(text: reminder?.description);
    String category = reminder?.category ?? 'General';
    DateTime selectedDate = reminder?.dueAt ??
        DateTime.now().add(const Duration(hours: 1)); // Default to next hour

    // Ensure category is valid
    if (!['General', 'Assignment', 'Exam', 'Project'].contains(category)) {
      category = 'General';
    }

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          final dateText = DateFormat('MMM d, y • h:mm a').format(selectedDate);

          return Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              width: double.infinity,
              constraints: const BoxConstraints(maxWidth: 500),
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
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isEdit ? 'Edit Task' : 'New Task',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 24),
                    _buildDialogTextField(titleController, 'Title',
                        icon: Icons.task_alt_rounded),
                    const SizedBox(height: 16),
                    _buildDialogTextField(
                        descController, 'Description (Optional)',
                        maxLines: 3, icon: Icons.description_rounded),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: category,
                      dropdownColor: const Color(0xFF1E293B),
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                          labelText: 'Category',
                          labelStyle:
                              TextStyle(color: Colors.white.withOpacity(0.5)),
                          prefixIcon: Icon(Icons.category_rounded,
                              color: Colors.white.withOpacity(0.7), size: 20),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                  color: Colors.white.withOpacity(0.1))),
                          enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                  color: Colors.white.withOpacity(0.1))),
                          focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                  color: AppTheme.primaryColor)),
                          filled: true,
                          fillColor: Colors.white.withOpacity(0.05)),
                      items: ['General', 'Assignment', 'Exam', 'Project']
                          .map(
                              (c) => DropdownMenuItem(value: c, child: Text(c)))
                          .toList(),
                      onChanged: (val) => setDialogState(() => category = val!),
                    ),
                    const SizedBox(height: 16),
                    GestureDetector(
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: selectedDate,
                          firstDate:
                              DateTime.now().subtract(const Duration(days: 1)),
                          lastDate:
                              DateTime.now().add(const Duration(days: 365)),
                          builder: (context, child) => Theme(
                            data: ThemeData.dark().copyWith(
                              colorScheme: const ColorScheme.dark(
                                primary: AppTheme.primaryColor,
                                onPrimary: Colors.white,
                                surface: Color(0xFF1E293B),
                                onSurface: Colors.white,
                              ),
                              dialogBackgroundColor: const Color(0xFF1E293B),
                            ),
                            child: child!,
                          ),
                        );

                        if (date != null && context.mounted) {
                          final time = await showTimePicker(
                            context: context,
                            initialTime: TimeOfDay.fromDateTime(selectedDate),
                            builder: (context, child) => Theme(
                              data: ThemeData.dark().copyWith(
                                colorScheme: const ColorScheme.dark(
                                  primary: AppTheme.primaryColor,
                                  onPrimary: Colors.white,
                                  surface: Color(0xFF1E293B),
                                  onSurface: Colors.white,
                                ),
                                dialogBackgroundColor: const Color(0xFF1E293B),
                              ),
                              child: child!,
                            ),
                          );

                          if (time != null) {
                            setDialogState(() {
                              selectedDate = DateTime(date.year, date.month,
                                  date.day, time.hour, time.minute);
                            });
                          }
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(12),
                          border:
                              Border.all(color: Colors.white.withOpacity(0.1)),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.calendar_today_rounded,
                                color: Colors.white.withOpacity(0.7), size: 20),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Due Date & Time',
                                    style: TextStyle(
                                        color: Colors.white.withOpacity(0.5),
                                        fontSize: 12)),
                                Text(
                                  dateText,
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          style: TextButton.styleFrom(
                              foregroundColor: Colors.white70),
                          child: const Text('Cancel'),
                        ),
                        const SizedBox(width: 16),
                        ElevatedButton(
                          onPressed: () async {
                            if (titleController.text.isEmpty) return;

                            final data = {
                              'title': titleController.text,
                              'description': descController.text,
                              'category': category,
                              'due_at': selectedDate.toIso8601String(),
                            };

                            try {
                              if (isEdit) {
                                await _apiService.put(
                                    '${AppConstants.remindersEndpoint}/${reminder.id}',
                                    data);
                              } else {
                                await _apiService.post(
                                    AppConstants.remindersEndpoint, data);
                              }

                              if (mounted) {
                                Navigator.pop(context);
                                _loadReminders();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text('Task saved successfully')),
                                );
                              }
                            } catch (e) {
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                      content: Text('Error saving task: $e')),
                                );
                              }
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryColor,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 32, vertical: 12),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                          child: Text(isEdit ? 'Save' : 'Add',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDialogTextField(TextEditingController controller, String label,
      {int maxLines = 1, IconData? icon}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
          prefixIcon: icon != null
              ? Icon(icon, color: Colors.white.withOpacity(0.7), size: 20)
              : null,
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pendingReminders = _reminders.where((r) => !r.isCompleted).toList();
    final completedReminders = _reminders.where((r) => r.isCompleted).toList();

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddEditReminderDialog(),
        backgroundColor: AppTheme.primaryColor,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0F172A), Color(0xFF1E1B4B)],
          ),
        ),
        child: SafeArea(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                  onRefresh: _loadReminders,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      if (pendingReminders.isNotEmpty) ...[
                        const Text(
                          'Pending Tasks',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ...pendingReminders.map((reminder) => ReminderCard(
                              key: ValueKey(reminder.id),
                              reminder: reminder,
                              onToggle: () => _toggleCompletion(reminder),
                              onDelete: () => _deleteReminder(reminder.id),
                              onEdit: () => _showAddEditReminderDialog(
                                  reminder: reminder),
                            )),
                      ],
                      if (completedReminders.isNotEmpty) ...[
                        const SizedBox(height: 24),
                        const Text(
                          'Completed',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white54,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ...completedReminders.map((reminder) => ReminderCard(
                              key: ValueKey(reminder.id),
                              reminder: reminder,
                              onToggle: () => _toggleCompletion(reminder),
                              onDelete: () => _deleteReminder(reminder.id),
                              onEdit: () => _showAddEditReminderDialog(
                                  reminder: reminder),
                            )),
                      ],
                      if (_reminders.isEmpty)
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.only(top: 100),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.task_alt,
                                    size: 64,
                                    color: Colors.white.withOpacity(0.2)),
                                const SizedBox(height: 16),
                                Text('No tasks yet.',
                                    style: TextStyle(
                                        color: Colors.white.withOpacity(0.5))),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }
}

class ReminderCard extends StatefulWidget {
  final ReminderModel reminder;
  final VoidCallback onToggle;
  final VoidCallback onDelete;
  final VoidCallback onEdit;

  const ReminderCard({
    super.key,
    required this.reminder,
    required this.onToggle,
    required this.onDelete,
    required this.onEdit,
  });

  @override
  State<ReminderCard> createState() => _ReminderCardState();
}

class _ReminderCardState extends State<ReminderCard> {
  late bool _isCompleted;

  @override
  void initState() {
    super.initState();
    _isCompleted = widget.reminder.isCompleted;
  }

  @override
  void didUpdateWidget(ReminderCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.reminder.isCompleted != widget.reminder.isCompleted) {
      _isCompleted = widget.reminder.isCompleted;
    }
  }

  void _handleToggle() async {
    setState(() {
      _isCompleted = !_isCompleted;
    });

    // Wait for animation
    await Future.delayed(const Duration(milliseconds: 500));

    if (mounted) {
      widget.onToggle();
    }
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Exam':
        return AppTheme.errorColor;
      case 'Assignment':
        return AppTheme.warningColor;
      case 'Project':
        return AppTheme.primaryColor;
      default:
        return AppTheme.successColor;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onEdit,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: _isCompleted
              ? Colors.white.withOpacity(0.02)
              : Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: _isCompleted
                  ? Colors.white.withOpacity(0.05)
                  : Colors.white.withOpacity(0.1)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(_isCompleted ? 0.05 : 0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Custom Animated Checkbox
            GestureDetector(
              onTap: _handleToggle,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutBack,
                width: 28,
                height: 28,
                alignment: Alignment.center,
                margin: const EdgeInsets.only(top: 2),
                decoration: BoxDecoration(
                  color:
                      _isCompleted ? AppTheme.successColor : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: _isCompleted
                        ? AppTheme.successColor
                        : Colors.white.withOpacity(0.3),
                    width: 2,
                  ),
                ),
                child: _isCompleted
                    ? const Icon(
                        Icons.check_rounded,
                        color: Colors.white,
                        size: 18,
                      )
                    : null,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 300),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: _isCompleted ? Colors.white38 : Colors.white,
                      decoration: _isCompleted
                          ? TextDecoration.lineThrough
                          : TextDecoration.none,
                      decorationColor: Colors.white38,
                      fontFamily: 'Inter', // Ensuring font consistency
                    ),
                    child: Text(widget.reminder.title),
                  ),
                  if (widget.reminder.description != null &&
                      widget.reminder.description!.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 300),
                      style: TextStyle(
                        fontSize: 14,
                        color: _isCompleted
                            ? Colors.white24
                            : Colors.white.withOpacity(0.6),
                        fontFamily: 'Inter',
                      ),
                      child: Text(
                        widget.reminder.description!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: _getCategoryColor(widget.reminder.category)
                              .withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: _getCategoryColor(widget.reminder.category)
                                .withOpacity(0.3),
                          ),
                        ),
                        child: Text(
                          widget.reminder.category,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: _getCategoryColor(widget.reminder.category),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Row(
                        children: [
                          Icon(Icons.calendar_today_rounded,
                              size: 14, color: Colors.white.withOpacity(0.4)),
                          const SizedBox(width: 4),
                          Text(
                            DateFormatter.formatRelativeDate(
                                widget.reminder.dueAt),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.white.withOpacity(0.5),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: () async {
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
                        border:
                            Border.all(color: Colors.white.withOpacity(0.1)),
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
                            child: const Icon(Icons.delete_rounded,
                                size: 32, color: AppTheme.errorColor),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Delete Task',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Are you sure you want to delete this task?',
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
                                  onPressed: () =>
                                      Navigator.pop(context, false),
                                  style: TextButton.styleFrom(
                                    foregroundColor: Colors.white70,
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 12),
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
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 12),
                                    shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8)),
                                  ),
                                  child: const Text('Delete',
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
                  widget.onDelete();
                }
              },
              icon: Icon(Icons.delete_outline_rounded,
                  color: AppTheme.errorColor.withOpacity(0.7), size: 20),
            ),
          ],
        ),
      ),
    );
  }
}
