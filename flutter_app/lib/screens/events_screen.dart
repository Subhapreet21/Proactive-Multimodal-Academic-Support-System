import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../models/event_model.dart';
import '../config/theme.dart';
import '../utils/constants.dart';
import '../utils/date_formatter.dart';
import '../utils/permissions.dart';

class EventsScreen extends StatefulWidget {
  const EventsScreen({super.key});

  @override
  State<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends State<EventsScreen> {
  final ApiService _apiService = ApiService();
  List<EventModel> _events = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  Future<void> _loadEvents() async {
    setState(() => _isLoading = true);

    try {
      final response = await _apiService.get(AppConstants.eventsEndpoint);
      final events =
          (response as List?)?.map((e) => EventModel.fromJson(e)).toList() ??
              [];

      setState(() {
        _events = events;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading events: $e')),
        );
      }
    }
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'cultural':
        return const Color(0xFF8B5CF6); // Violet
      case 'sports':
        return const Color(0xFFF59E0B); // Amber
      case 'workshop':
        return const Color(0xFF10B981); // Emerald
      case 'academic':
        return const Color(0xFF3B82F6); // Blue
      case 'general':
        return const Color(0xFF06B6D4); // Cyan
      default:
        return const Color(0xFF06B6D4); // Cyan (Default)
    }
  }

  Future<void> _showCreateEditEventDialog({EventModel? event}) async {
    final isEdit = event != null;
    final titleController = TextEditingController(text: event?.title);
    final descController = TextEditingController(text: event?.description);
    final locController = TextEditingController(text: event?.location);
    String category = event?.category ?? 'General';
    DateTime selectedDate =
        event?.eventDate ?? DateTime.now().add(const Duration(days: 7));

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
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
                    isEdit ? 'Edit Event' : 'Create New Event',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 24),
                  _buildDialogTextField(titleController, 'Title',
                      icon: Icons.title_rounded),
                  const SizedBox(height: 16),
                  _buildDialogTextField(descController, 'Description',
                      maxLines: 3, icon: Icons.description_rounded),
                  const SizedBox(height: 16),
                  _buildDialogTextField(locController, 'Location (Optional)',
                      icon: Icons.location_on_rounded),
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
                            borderSide:
                                const BorderSide(color: AppTheme.primaryColor)),
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.05)),
                    items: [
                      'General',
                      'Workshop',
                      'Cultural',
                      'Sports',
                      'Academic'
                    ]
                        .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                        .toList(),
                    onChanged: (val) => setDialogState(() => category = val!),
                  ),
                  const SizedBox(height: 16),
                  GestureDetector(
                    onTap: () async {
                      final picked = await showDatePicker(
                          context: context,
                          initialDate: selectedDate,
                          firstDate: DateTime.now(),
                          lastDate:
                              DateTime.now().add(const Duration(days: 365)),
                          builder: (context, child) {
                            return Theme(
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
                            );
                          });
                      if (picked != null) {
                        setDialogState(() => selectedDate = picked);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
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
                              Text('Event Date',
                                  style: TextStyle(
                                      color: Colors.white.withOpacity(0.5),
                                      fontSize: 12)),
                              Text(
                                DateFormatter.formatDate(selectedDate),
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
                          try {
                            final data = {
                              'title': titleController.text,
                              'description': descController.text,
                              'location': locController.text,
                              'category': category,
                              'event_date': selectedDate.toIso8601String(),
                            };

                            if (isEdit) {
                              await _apiService.put(
                                  '${AppConstants.eventsEndpoint}/${event!.id}',
                                  data);
                            } else {
                              await _apiService.post(
                                  AppConstants.eventsEndpoint, data);
                            }

                            if (mounted) {
                              Navigator.pop(context);
                              _loadEvents();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                    content: Text(isEdit
                                        ? 'Event updated'
                                        : 'Event created successfully')),
                              );
                            }
                          } catch (e) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                    content: Text('Error saving event: $e')),
                              );
                            }
                          }
                        },
                        style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryColor,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 32, vertical: 12),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12))),
                        child: const Text('Save Event',
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
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

  Future<void> _confirmDelete(String id) async {
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
                child: const Icon(Icons.delete_rounded,
                    size: 32, color: AppTheme.errorColor),
              ),
              const SizedBox(height: 16),
              const Text(
                'Delete Event',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Are you sure you want to delete this event?',
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
      try {
        await _apiService.delete('${AppConstants.eventsEndpoint}/$id');
        _loadEvents();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Event deleted')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error deleting event: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final permissions = AppPermissions(Provider.of<AuthProvider>(context));
    // Check permissions directly here as well to pass to cards if needed,
    final canManage = permissions.canManageEvents;

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: canManage
          ? FloatingActionButton(
              onPressed: () => _showCreateEditEventDialog(),
              backgroundColor: AppTheme.primaryColor,
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0F172A), Color(0xFF1E1B4B)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : RefreshIndicator(
                        onRefresh: _loadEvents,
                        child: _events.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.event_busy_rounded,
                                        size: 60,
                                        color: Colors.white.withOpacity(0.2)),
                                    const SizedBox(height: 16),
                                    Text(
                                      'No events or notices yet.',
                                      style: TextStyle(
                                          color: Colors.white.withOpacity(0.5)),
                                    ),
                                  ],
                                ),
                              )
                            : ListView.builder(
                                padding: const EdgeInsets.all(20),
                                itemCount: _events.length,
                                itemBuilder: (context, index) {
                                  return _buildEventCard(
                                      _events[index], canManage);
                                },
                              ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEventCard(EventModel event, bool canManage) {
    final categoryColor = _getCategoryColor(event.category);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05), // Glassmorphism
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: categoryColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: categoryColor.withOpacity(0.3)),
                ),
                child: Text(
                  event.category,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: categoryColor,
                  ),
                ),
              ),
              if (canManage)
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert,
                      color: Colors.white54, size: 20),
                  color: const Color(0xFF1E293B),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  onSelected: (val) {
                    if (val == 'edit') _showCreateEditEventDialog(event: event);
                    if (val == 'delete') _confirmDelete(event.id);
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                        value: 'edit',
                        child: Text('Edit',
                            style: TextStyle(color: Colors.white))),
                    const PopupMenuItem(
                        value: 'delete',
                        child: Text('Delete',
                            style: TextStyle(color: AppTheme.errorColor))),
                  ],
                )
              else
                Text(
                  DateFormatter.formatRelativeDate(event.createdAt),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.4),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            event.title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            event.description,
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withOpacity(0.7),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.calendar_today_rounded,
                            size: 16, color: Colors.white70),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Date',
                              style: TextStyle(
                                  color: Colors.white.withOpacity(0.5),
                                  fontSize: 11)),
                          const SizedBox(height: 2),
                          Text(
                            event.eventDate != null
                                ? DateFormatter.formatDate(event.eventDate!)
                                : 'TBA',
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 13),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (event.location != null && event.location!.isNotEmpty) ...[
                  Container(
                      width: 1,
                      height: 30,
                      color: Colors.white.withOpacity(0.1)),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(left: 12),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.location_on_rounded,
                                size: 16, color: Colors.white70),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Location',
                                    style: TextStyle(
                                        color: Colors.white.withOpacity(0.5),
                                        fontSize: 11)),
                                const SizedBox(height: 2),
                                Text(
                                  event.location!,
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
