import 'dart:io';
import 'dart:async';
import 'package:excel/excel.dart' as excel_pkg;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_file_dialog/flutter_file_dialog.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../services/schedule_service.dart';
import '../config/theme.dart';
import '../utils/constants.dart';
import '../utils/permissions.dart';
import '../widgets/weekly_grid_view.dart';
import 'package:screenshot/screenshot.dart';
import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class TimetableScreen extends StatefulWidget {
  const TimetableScreen({super.key});

  @override
  State<TimetableScreen> createState() => _TimetableScreenState();
}

class _TimetableScreenState extends State<TimetableScreen> {
  final ApiService _apiService = ApiService();
  List<dynamic> _entries = [];
  bool _isLoading = true;

  // View State
  String _selectedView = 'Day'; // 'Day' or 'Week'
  String _selectedDay = 'Monday';

  // Filter State
  String _dept = 'CSE';
  String _year = '1';
  String _section = 'A';

  List<String> _days = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday'
  ];

  // Default Schedule (Loaded from Service)
  List<Map<String, dynamic>> _schedule = [];
  final ScheduleService _scheduleService = ScheduleService();

  // Auto-Scroll State
  final ScrollController _dayVerticalController = ScrollController();
  final ScrollController _weekHorizontalController = ScrollController();
  final Map<String, ScrollController> _weekDayControllers = {};
  Timer? _autoScrollTimer;
  Offset? _currentDragPosition;
  final ScreenshotController _screenshotController = ScreenshotController();

  @override
  void dispose() {
    _dayVerticalController.dispose();
    _weekHorizontalController.dispose();
    for (var controller in _weekDayControllers.values) {
      controller.dispose();
    }
    _autoScrollTimer?.cancel();
    super.dispose();
  }

  void _handleDragUpdate(DragUpdateDetails details) {
    _currentDragPosition = details.globalPosition;
    if (_autoScrollTimer == null || !_autoScrollTimer!.isActive) {
      _autoScrollTimer =
          Timer.periodic(const Duration(milliseconds: 50), _checkAutoScroll);
    }
  }

  void _handleDragEnd(DraggableDetails details) {
    _autoScrollTimer?.cancel();
    _currentDragPosition = null;
  }

  void _checkAutoScroll(Timer timer) {
    if (_currentDragPosition == null) return;

    final RenderBox renderBox = context.findRenderObject() as RenderBox;
    final position = renderBox.globalToLocal(_currentDragPosition!);
    final size = renderBox.size;

    const double scrollZone = 50.0;
    const double scrollSpeed = 10.0;

    // Day View: Vertical Scroll
    if (_selectedView == 'Day') {
      if (position.dy < scrollZone) {
        if (_dayVerticalController.hasClients) {
          _dayVerticalController.jumpTo(
              (_dayVerticalController.offset - scrollSpeed)
                  .clamp(0.0, _dayVerticalController.position.maxScrollExtent));
        }
      } else if (position.dy > size.height - scrollZone) {
        if (_dayVerticalController.hasClients) {
          _dayVerticalController.jumpTo(
              (_dayVerticalController.offset + scrollSpeed)
                  .clamp(0.0, _dayVerticalController.position.maxScrollExtent));
        }
      }
    }

    // Week View Logic
    if (_selectedView == 'Week') {
      // 1. Horizontal Scroll (Change Days)
      if (position.dx < scrollZone) {
        if (_weekHorizontalController.hasClients) {
          _weekHorizontalController.jumpTo((_weekHorizontalController.offset -
                  scrollSpeed)
              .clamp(0.0, _weekHorizontalController.position.maxScrollExtent));
        }
      } else if (position.dx > size.width - scrollZone) {
        if (_weekHorizontalController.hasClients) {
          _weekHorizontalController.jumpTo((_weekHorizontalController.offset +
                  scrollSpeed)
              .clamp(0.0, _weekHorizontalController.position.maxScrollExtent));
        }
      }

      // 2. Vertical Scroll (Inside Specific Day Column)
      if (position.dy < scrollZone || position.dy > size.height - scrollZone) {
        // Calculate which day column we are over
        final double listOffset = _weekHorizontalController.hasClients
            ? _weekHorizontalController.offset
            : 0;
        final double relativeX = position.dx + listOffset;

        // Match geometry from _buildWeekView:
        // Width 280, Right Margin 16. Padding Horizontal 16.
        // First item starts at 16. Item effective width = 296 (280 + 16).

        // relativeX = scroll + position.dx
        // index = (relativeX - startPadding) / (width + margin)
        final int index = ((relativeX - 16) / 296).floor();

        if (index >= 0 && index < _days.length) {
          final day = _days[index];
          final controller = _weekDayControllers[day];

          if (controller != null && controller.hasClients) {
            if (position.dy < scrollZone) {
              controller.jumpTo((controller.offset - scrollSpeed)
                  .clamp(0.0, controller.position.maxScrollExtent));
            } else if (position.dy > size.height - scrollZone) {
              controller.jumpTo((controller.offset + scrollSpeed)
                  .clamp(0.0, controller.position.maxScrollExtent));
            }
          }
        }
      }
    }
  }

  @override
  void initState() {
    super.initState();
    // Initialize day controllers for Week View
    for (var day in _days) {
      _weekDayControllers[day] = ScrollController();
    }

    _loadScheduleStructure();

    final now = DateTime.now();
    final currentDay = _days.contains(getDayName(now.weekday))
        ? getDayName(now.weekday)
        : 'Monday';
    _selectedDay = currentDay;

    _initializeFilters();
    _loadTimetable();
  }

  Future<void> _loadScheduleStructure() async {
    final s = await _scheduleService.getSchedule(department: _dept);
    setState(() {
      _schedule = s;
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final permissions = AppPermissions(authProvider);
    final canManage = permissions.canManageTimetable;

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: canManage &&
              MediaQuery.of(context).orientation == Orientation.portrait
          ? FloatingActionButton(
              onPressed: () => _showAddEditClassDialog(),
              backgroundColor: AppTheme.primaryColor,
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppTheme.backgroundGradient,
        ),
        child: SafeArea(
          child: OrientationBuilder(
            builder: (context, orientation) {
              if (orientation == Orientation.landscape) {
                return Column(
                  children: [
                    // Modified Header to include Settings for Admin
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Toggle removed for Landscape

                          Row(
                            children: [
                              if (canManage) ...[
                                _buildActionButton(
                                  icon: Icons.edit_calendar_rounded,
                                  tooltip: 'Configure Schedule',
                                  onPressed: _showStructureEditor,
                                ),
                                const SizedBox(width: 12),
                                _buildActionButton(
                                  icon: Icons.upload_file_rounded,
                                  tooltip: 'Import CSV/Excel',
                                  onPressed: _importCSV,
                                ),
                                const SizedBox(width: 12),
                                if (authProvider.userRole?.toLowerCase() !=
                                    'admin') ...[
                                  const SizedBox(width: 12),
                                  _buildActionButton(
                                    icon: Icons.download_rounded,
                                    tooltip: 'Download as Image',
                                    onPressed: _downloadTimetableImage,
                                  ),
                                ],
                              ],
                              const SizedBox(width: 16),
                              if (permissions.canFilterTimetable)
                                GestureDetector(
                                  onTap: _showFilterDialog,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.05),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                          color: Colors.white.withOpacity(0.1)),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.tune_rounded,
                                            color: AppTheme.primaryLight,
                                            size: 16),
                                        const SizedBox(width: 8),
                                        Text(
                                          '$_dept-$_year-$_section',
                                          style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Grid
                    Expanded(
                      child: _isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : WeeklyGridView(
                              entries: _entries,
                              schedule: _schedule,
                              onCellTap: (data) {
                                if (canManage) {
                                  _showAddEditClassDialog(entry: data);
                                }
                              },
                              onClassDrop: _handleClassDrop,
                              canManage: canManage,
                            ),
                    ),
                  ],
                );
              } else {
                // Portrait View
                return Column(
                  children: [
                    _buildHeader(permissions),
                    const SizedBox(height: 16),
                    if (_selectedView == 'Day') _buildDaySelector(),
                    const SizedBox(height: 16),
                    Expanded(
                      child: _isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : _selectedView == 'Day'
                              ? _buildDayView(canManage)
                              : _buildWeekView(canManage),
                    ),
                  ],
                );
              }
            },
          ),
        ),
      ),
    );
  }

  void _showStructureEditor() {
    showDialog(
      context: context,
      builder: (context) => _ScheduleEditorDialog(
        currentSchedule: _schedule,
        currentEntries: _entries,
        currentDays: _days,
        onSaveDays: (newSourceOrder) async {
          try {
            // Bulk Reschedule Logic
            debugPrint('═══════════════════════════════════════');
            debugPrint('🔄 DAY SWAP INITIATED');
            debugPrint('📋 Source Order: $newSourceOrder');
            debugPrint('📋 Fixed Days: $_days');
            debugPrint('📋 Current Entries Count: ${_entries.length}');

            final List<Map<String, dynamic>> updatedEntries = [];
            final List<Map<String, dynamic>> batchUpdates = [];

            for (var entry in _entries) {
              final dynamic oldDay = entry['day_of_week'];
              dynamic newDayVal = oldDay;
              bool changed = false;

              // Handle Single Day (String)
              if (oldDay is String) {
                if (newSourceOrder.contains(oldDay)) {
                  final newIndex = newSourceOrder.indexOf(oldDay);
                  if (newIndex >= 0 && newIndex < _days.length) {
                    final targetDay = _days[newIndex];
                    if (oldDay != targetDay) {
                      newDayVal = targetDay;
                      changed = true;
                      debugPrint(
                          '  📝 Entry ${entry['id']}: $oldDay → $targetDay');
                    }
                  }
                }
              }
              // Handle Recurring Days (List)
              else if (oldDay is List) {
                final List<String> currentDays = List<String>.from(oldDay);
                final List<String> updatedDays = [];
                bool listChanged = false;

                for (var day in currentDays) {
                  if (newSourceOrder.contains(day)) {
                    final newIndex = newSourceOrder.indexOf(day);
                    if (newIndex >= 0 && newIndex < _days.length) {
                      final targetDay = _days[newIndex];
                      updatedDays.add(targetDay);
                      if (day != targetDay) listChanged = true;
                    } else {
                      updatedDays.add(day);
                    }
                  } else {
                    updatedDays.add(day);
                  }
                }

                if (listChanged) {
                  newDayVal = updatedDays;
                  changed = true;
                  debugPrint(
                      '  📝 Entry ${entry['id']}: $currentDays → $updatedDays');
                }
              }

              if (changed) {
                final updatedEntry = Map<String, dynamic>.from(entry);
                updatedEntry['day_of_week'] = newDayVal;
                updatedEntries.add(updatedEntry);

                batchUpdates.add({
                  'id': entry['id'],
                  'day_of_week': newDayVal,
                });
              } else {
                updatedEntries.add(entry);
              }
            }

            debugPrint('📦 Total Changes: ${batchUpdates.length}');
            debugPrint(
                '📦 Sample Batch Updates: ${batchUpdates.take(3).toList()}');

            // Persist to backend first, then reload to update UI
            if (batchUpdates.isNotEmpty) {
              debugPrint('🚀 Calling API batch_update...');
              final result =
                  await _scheduleService.batchUpdateEntries(batchUpdates);
              debugPrint('✅ API Response: $result');
              debugPrint('✅ Batch updated ${batchUpdates.length} entries');

              // Reload to update UI with persisted data
              debugPrint('🔄 Reloading timetable from backend...');
              await _loadTimetable();
              debugPrint('✅ Reload complete - UI updated');
            } else {
              debugPrint('⚠️ No changes detected, skipping API call');
            }
            debugPrint('═══════════════════════════════════════');
          } catch (e, stack) {
            debugPrint('═══════════════════════════════════════');
            debugPrint('❌ ERROR IN BULK RESCHEDULE');
            debugPrint('❌ Error: $e');
            debugPrint('❌ Stack Trace:\n$stack');
            debugPrint('═══════════════════════════════════════');
            // Revert by reloading
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                    content: Text('Failed to swap days: $e. Reloading...'),
                    backgroundColor: Colors.red),
              );
              await _loadTimetable();
            }
          }
        },
        onSave: (newSchedule) async {
          debugPrint('💾 Saving New Schedule for $_dept: $newSchedule');
          await _scheduleService.saveSchedule(newSchedule, department: _dept);
          // Reload everything because Server migrated data
          if (mounted) {
            await _loadTimetable();
          }
          setState(() {
            // Force new reference AND reset identity (original_start) to match new start
            // because the backend has successfully persisted the move.
            _schedule = newSchedule.map((e) {
              final map = Map<String, dynamic>.from(e);
              map['original_start'] = map['start'];
              return map;
            }).toList();
          });
        },
      ),
    );
  }

  Future<void> _importCSV() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv', 'xlsx'],
      );

      if (result != null && result.files.single.path != null) {
        setState(() => _isLoading = true);
        final file = File(result.files.single.path!);

        final response = await _apiService.postMultipart(
          '${AppConstants.timetableEndpoint}/import',
          {},
          file,
          fileFieldName: 'file',
        );

        setState(() => _isLoading = false);

        if (mounted) {
          final count = response['count'] ?? 0;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Successfully imported $count entries!'),
              backgroundColor: Colors.green,
            ),
          );
          _loadTimetable();
        }
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: const Color(0xFF1E293B),
            title: const Text('Import Failed',
                style: TextStyle(color: Colors.white)),
            content: Text(e.toString().replaceAll('Exception: ', ''),
                style: const TextStyle(color: Colors.white70)),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close'))
            ],
          ),
        );
      }
    }
  }

  Future<void> _showMasterPdfFilterDialog() async {
    // Default to current view state
    String? selectedDept = _dept;
    String? selectedYear = _year;
    String? selectedSection = _section;

    // Get available options from AppConstants
    final depts = AppConstants.departments;
    final years = ['All', ...AppConstants.years];
    final sections = ['All', ...AppConstants.sections];

    // Safety checks: ensure current selection is in the list
    if (!depts.contains(selectedDept))
      selectedDept = depts.first; // Default to first dept (CSE)
    if (!years.contains(selectedYear)) selectedYear = 'All';
    if (!sections.contains(selectedSection)) selectedSection = 'All';

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
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
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Download Master PDF',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Select filters to customize your download:',
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                    const SizedBox(height: 24),
                    _buildDialogDropdown(
                      label: 'Department',
                      value: selectedDept!,
                      items: depts,
                      icon: Icons.business_rounded,
                      onChanged: (val) => setState(() => selectedDept = val),
                    ),
                    const SizedBox(height: 16),
                    _buildDialogDropdown(
                      label: 'Year',
                      value: selectedYear!,
                      items: years,
                      icon: Icons.school_rounded,
                      onChanged: (val) => setState(() => selectedYear = val),
                    ),
                    const SizedBox(height: 16),
                    _buildDialogDropdown(
                      label: 'Section',
                      value: selectedSection!,
                      items: sections,
                      icon: Icons.grid_view_rounded,
                      onChanged: (val) => setState(() => selectedSection = val),
                    ),
                    const SizedBox(height: 32),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.white70,
                          ),
                          child: const Text('Cancel'),
                        ),
                        const SizedBox(width: 16),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                            _downloadMasterPdf(
                              department: selectedDept,
                              year: selectedYear == 'All' ? null : selectedYear,
                              section: selectedSection == 'All'
                                  ? null
                                  : selectedSection,
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 24, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          child: const Text('Download'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _downloadMasterPdf(
      {String? department, String? year, String? section}) async {
    setState(() => _isLoading = true);
    try {
      // 1. Build Query Parameters
      final Map<String, String> queryParams = {};
      if (department != null) queryParams['department'] = department;
      if (year != null) queryParams['year'] = year;
      if (section != null) queryParams['section'] = section;

      // 2. Fetch Data with Filters
      debugPrint('📥 Fetching timetable data with filters: $queryParams');
      final response = await _apiService.get(
        AppConstants.timetableEndpoint,
        params: queryParams.isNotEmpty ? queryParams : null,
      );
      if (response == null || response is! List) throw 'Invalid data received';

      final List<dynamic> allEntries = response;
      debugPrint('✅ Fetched ${allEntries.length} entries');

      if (allEntries.isEmpty) {
        throw 'No timetable data found for the selected filters.';
      }

      // 3. Group by Section (Dept-Year-Sec)
      final Map<String, List<dynamic>> groups = {};
      for (var entry in allEntries) {
        final key =
            '${entry['department']}-${entry['year']}-${entry['section']}';
        if (!groups.containsKey(key)) groups[key] = [];
        groups[key]!.add(entry);
      }

      // 4. Generate PDF
      final pdf = pw.Document();
      final font = await PdfGoogleFonts.openSansRegular();
      final fontBold = await PdfGoogleFonts.openSansBold();

      // Sorted Keys for consistent order
      final keys = groups.keys.toList()..sort();

      for (var key in keys) {
        final entries = groups[key]!;
        final parts = key.split('-');
        final dept = parts[0];
        final yearVal = parts[1];
        final section = parts[2];

        // Build a Page for this Section
        pdf.addPage(
          pw.Page(
            pageFormat: PdfPageFormat.a4.landscape,
            build: (pw.Context context) {
              return pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  // Simplified compact header
                  pw.Container(
                    padding: const pw.EdgeInsets.only(bottom: 8),
                    child: pw.Text(
                        'Timetable: $dept - Year $yearVal - Section $section',
                        style: pw.TextStyle(font: fontBold, fontSize: 14)),
                  ),
                  // Grid with automatic scaling to fit page
                  pw.Expanded(
                    child: _buildPdfGrid(entries, font, fontBold),
                  ),
                ],
              );
            },
          ),
        );
      }

      // 5. Save
      final directory = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final file = File('${directory.path}/TIMETABLE_MASTER_$timestamp.pdf');
      await file.writeAsBytes(await pdf.save());

      if (mounted) {
        final params = SaveFileDialogParams(sourceFilePath: file.path);
        final finalPath = await FlutterFileDialog.saveFile(params: params);

        if (finalPath != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Master PDF saved successfully!'),
                backgroundColor: Colors.green),
          );
        }
      }
    } catch (e) {
      debugPrint('PDF Export Error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Export Failed: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  pw.Widget _buildPdfGrid(
      List<dynamic> entries, pw.Font font, pw.Font fontBold) {
    debugPrint('📊 PDF Grid: Building grid for ${entries.length} entries');
    if (entries.isNotEmpty) {
      debugPrint('📊 Sample entries (first 3):');
      for (var i = 0; i < (entries.length > 3 ? 3 : entries.length); i++) {
        final e = entries[i];
        debugPrint(
            '  - ${e['day_of_week']} ${e['start_time']}-${e['end_time']}: ${e['course_name']}');
      }
    }

    const days = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday'
    ];

    // -- Helper to parse "HH:MM" to minutes --
    int toMin(String t) {
      if (t.isEmpty) return 0;
      final parts = t.split(':');
      if (parts.length < 2) return 0;
      return int.parse(parts[0]) * 60 + int.parse(parts[1]);
    }

    // -- Helper to format minutes back to "HH:MM" --
    String toTime(int m) {
      final h = (m ~/ 60).toString().padLeft(2, '0');
      final min = (m % 60).toString().padLeft(2, '0');
      return '$h:$min';
    }

    // 1. Identify all Class Slots
    final List<Map<String, dynamic>> slots = [];
    final Set<String> seen = {};

    for (var e in entries) {
      final startStr =
          (e['start_time'] ?? '').toString().split(':').take(2).join(':');
      final endStr =
          (e['end_time'] ?? '').toString().split(':').take(2).join(':');
      final key = '$startStr-$endStr';

      if (startStr.isNotEmpty && endStr.isNotEmpty && !seen.contains(key)) {
        seen.add(key);
        slots.add({
          'startStr': startStr,
          'endStr': endStr,
          'start': toMin(startStr),
          'end': toMin(endStr),
          'type': 'class'
        });
      }
    }

    // 2. Sort Class Slots
    slots.sort((a, b) => (a['start'] as int).compareTo(b['start'] as int));
    debugPrint('📊 PDF Grid: Extracted ${slots.length} unique time slots');
    debugPrint('📊 All time slots found:');
    for (var slot in slots) {
      debugPrint('   ${slot['startStr']} - ${slot['endStr']}');
    }

    // 3. Inject Gaps (Breaks)
    final List<Map<String, dynamic>> finalSlots = [];
    if (slots.isNotEmpty) {
      // Add first slot
      finalSlots.add(slots[0]);

      for (int i = 0; i < slots.length - 1; i++) {
        final currentEnd = slots[i]['end'] as int;
        final nextStart = slots[i + 1]['start'] as int;

        if (nextStart > currentEnd) {
          // Found a gap
          final gapDuration = nextStart - currentEnd;
          final type = gapDuration >= 45 ? 'Lunch' : 'Break';

          finalSlots.add({
            'startStr': toTime(currentEnd),
            'endStr': toTime(nextStart),
            'start': currentEnd,
            'end': nextStart,
            'type': type // 'Lunch' or 'Break'
          });
        }
        finalSlots.add(slots[i + 1]);
      }
    }

    debugPrint('📊 PDF Grid: Final slots (with gaps): ${finalSlots.length}');
    for (var slot in finalSlots) {
      debugPrint('  ${slot['type']}: ${slot['startStr']} - ${slot['endStr']}');
    }

    // Handle empty case
    if (finalSlots.isEmpty) {
      return pw.Center(
          child: pw.Text("No classes scheduled.",
              style: pw.TextStyle(font: font)));
    }

    // 4. Render Table (Transposed: Days = Columns, Time = Rows)
    // Define Grid Widths: Time Column + 6 Days
    final Map<int, pw.TableColumnWidth> colWidths = {
      0: const pw.FixedColumnWidth(65), // Time Column
    };
    for (int i = 0; i < days.length; i++) {
      colWidths[i + 1] = const pw.FlexColumnWidth(1); // Day Columns
    }

    print('📊 PDF Grid: Days list: $days');
    print('📊 PDF Grid: Column widths configured: ${colWidths.length} columns');

    return pw.Table(
      columnWidths: colWidths,
      border: pw.TableBorder.all(color: PdfColors.grey300),
      children: [
        // Header Row (Days)
        pw.TableRow(
            decoration: const pw.BoxDecoration(color: PdfColors.grey200),
            children: [
              pw.Padding(
                  padding: const pw.EdgeInsets.all(6),
                  child: pw.Center(
                      child: pw.Text('Time',
                          style: pw.TextStyle(font: fontBold, fontSize: 11)))),
              ...days.map((d) => pw.Padding(
                  padding: const pw.EdgeInsets.all(6),
                  child: pw.Center(
                      child: pw.Text(d.substring(0, 3), // Mon, Tue...
                          style: pw.TextStyle(font: fontBold, fontSize: 11))))),
            ]
              ..add(pw.Container()) // Debug: Force evaluation
              ..removeLast() // Remove the debug container
              ..forEach((child) => print('📊 PDF Grid: Header child added'))),

        // Data Rows (Slots)
        ...finalSlots.map((slot) {
          // If Break/Lunch, make entire row gray
          final isGap = slot['type'] != 'class';

          return pw.TableRow(
              decoration: isGap
                  ? const pw.BoxDecoration(color: PdfColors.grey100)
                  : null,
              children: [
                // Time Column
                pw.Container(
                    padding: const pw.EdgeInsets.all(6),
                    alignment: pw.Alignment.center,
                    child: pw.Column(
                        mainAxisAlignment: pw.MainAxisAlignment.center,
                        children: [
                          pw.Text(
                              isGap
                                  ? slot['type']
                                  : '${slot['startStr']}\n${slot['endStr']}',
                              textAlign: pw.TextAlign.center,
                              style: pw.TextStyle(
                                  font: fontBold,
                                  fontSize: 10,
                                  color: isGap
                                      ? PdfColors.grey600
                                      : PdfColors.black)),
                          if (isGap)
                            pw.Text('${slot['startStr']} - ${slot['endStr']}',
                                style: pw.TextStyle(
                                    font: font,
                                    fontSize: 8,
                                    color: PdfColors.grey500))
                        ])),

                // Day Columns
                ...days.map((day) {
                  if (isGap) {
                    // For gaps, just render empty gray cell (row background handles it)
                    return pw.Container();
                  }

                  // Find Entry - normalize times to HH:MM format for comparison
                  final startMatch = slot['startStr'];
                  final endMatch = slot['endStr'];

                  debugPrint('🔍 Searching for: $day $startMatch-$endMatch');

                  final entry = entries.firstWhere((e) {
                    final entryDay = e['day_of_week'];
                    final entryStart = (e['start_time'] ?? '')
                        .toString()
                        .split(':')
                        .take(2)
                        .join(':');
                    final entryEnd = (e['end_time'] ?? '')
                        .toString()
                        .split(':')
                        .take(2)
                        .join(':');

                    final matches = entryDay == day &&
                        entryStart == startMatch &&
                        entryEnd == endMatch;

                    if (matches) {
                      debugPrint('  ✅ Found: ${e['course_name']}');
                    }

                    return matches;
                  }, orElse: () => null);

                  if (entry == null) {
                    debugPrint(
                        '  ❌ No entry found for: $day $startMatch-$endMatch');
                  }

                  return pw.Padding(
                      padding: const pw.EdgeInsets.all(3),
                      child: entry != null
                          ? pw.Column(
                              crossAxisAlignment: pw.CrossAxisAlignment.start,
                              children: [
                                  pw.Text(entry['course_name'] ?? '',
                                      maxLines: 2,
                                      style: pw.TextStyle(
                                          font: fontBold, fontSize: 9)),
                                  pw.SizedBox(height: 2),
                                  pw.Text('${entry['course_code']}',
                                      style: pw.TextStyle(
                                          font: font,
                                          fontSize: 8,
                                          color: PdfColors.grey700)),
                                  pw.Text('${entry['location']}',
                                      style: pw.TextStyle(
                                          font: font,
                                          fontSize: 8,
                                          color: PdfColors.grey700)),
                                ])
                          : pw.Container());
                })
              ]);
        }),
      ],
    );
  }

  Future<void> _downloadTimetableImage() async {
    setState(() => _isLoading = true);
    try {
      // 1. Create a logical widget to capture
      // We wrap it in a Theme/Scaffold to ensure styles work
      final widgetToCapture = MaterialApp(
        theme: AppTheme.darkTheme,
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          backgroundColor: const Color(0xFF1E293B), // Match App Background
          body: Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Course Timetable',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 28,
                                fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Department: $_dept | Year: $_year | Section: $_section',
                            style: const TextStyle(
                                color: Colors.white70, fontSize: 18),
                          ),
                        ],
                      ),
                      // Logo or Branding could go here
                    ],
                  ),
                ),
                // The Grid
                SizedBox(
                  height: 800, // Fixed large height to fit schedule
                  width: 1200, // Fixed large width to avoid cramping
                  child: WeeklyGridView(
                    entries: _entries,
                    schedule: _schedule,
                    onCellTap: (_) {}, // No-op
                    onClassDrop: (_, __, ___) {}, // No-op
                    canManage: false,
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      // 2. Capture
      // targetSize: Size(1240, 900) to ensure high res
      final Uint8List imageBytes =
          await _screenshotController.captureFromWidget(
        widgetToCapture,
        delay: const Duration(milliseconds: 100), // Wait for layout
        targetSize: const Size(1240, 1000),
        context: context, // Important for inheriting fonts if needed
      );

      // 3. Save to File
      final directory = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final file = File('${directory.path}/timetable_$timestamp.png');
      await file.writeAsBytes(imageBytes);

      // 4. Prompt User to Save (Android/iOS)
      if (mounted) {
        final params = SaveFileDialogParams(sourceFilePath: file.path);
        final finalPath = await FlutterFileDialog.saveFile(params: params);

        if (finalPath != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Image saved successfully!'),
                backgroundColor: Colors.green),
          );
        }
      }
    } catch (e) {
      debugPrint('Export Error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Failed to export image: $e'),
              backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _downloadSampleExcel() async {
    try {
      var excel = excel_pkg.Excel.createExcel();
      excel_pkg.Sheet sheetObject = excel['Sheet1'];

      // Add Headers
      List<String> headers = [
        'course_code',
        'course_name',
        'day',
        'start_time',
        'end_time',
        'location',
        'department',
        'year',
        'section'
      ];
      sheetObject
          .appendRow(headers.map((e) => excel_pkg.TextCellValue(e)).toList());

      // Add Sample Rows (Full CSE Week for Year 3, Section A)
      final sampleData = [
        [
          'CS301',
          'Compiler Design',
          'Monday',
          '09:00',
          '10:00',
          'Room 303',
          'CSE',
          '3',
          'A'
        ],
        [
          'CS302',
          'Computer Networks',
          'Monday',
          '10:00',
          '11:00',
          'Room 303',
          'CSE',
          '3',
          'A'
        ],
        [
          'CS303',
          'Web Technologies',
          'Monday',
          '11:10',
          '12:10',
          'Lab 1',
          'CSE',
          '3',
          'A'
        ],
        [
          'HUM301',
          'Management',
          'Monday',
          '13:00',
          '14:00',
          'Room 303',
          'CSE',
          '3',
          'A'
        ],
        [
          'CS304',
          'Machine Learning',
          'Monday',
          '14:00',
          '15:00',
          'Room 303',
          'CSE',
          '3',
          'A'
        ],
        [
          'CS302',
          'Computer Networks',
          'Tuesday',
          '09:00',
          '10:00',
          'Room 303',
          'CSE',
          '3',
          'A'
        ],
        [
          'CS301',
          'Compiler Design',
          'Tuesday',
          '10:00',
          '11:00',
          'Room 303',
          'CSE',
          '3',
          'A'
        ],
        [
          'CS304',
          'Machine Learning',
          'Tuesday',
          '11:10',
          '12:10',
          'Room 303',
          'CSE',
          '3',
          'A'
        ],
        [
          'CS305',
          'Cloud Computing',
          'Tuesday',
          '13:00',
          '14:00',
          'Room 303',
          'CSE',
          '3',
          'A'
        ],
        [
          'CS306',
          'AI Lab',
          'Tuesday',
          '14:00',
          '15:00',
          'Lab 2',
          'CSE',
          '3',
          'A'
        ],
        [
          'CS303',
          'Web Technologies',
          'Wednesday',
          '09:00',
          '10:00',
          'Room 303',
          'CSE',
          '3',
          'A'
        ],
        [
          'CS305',
          'Cloud Computing',
          'Wednesday',
          '10:00',
          '11:00',
          'Room 303',
          'CSE',
          '3',
          'A'
        ],
        [
          'CS301',
          'Compiler Design',
          'Wednesday',
          '11:10',
          '12:10',
          'Room 303',
          'CSE',
          '3',
          'A'
        ],
        [
          'HUM301',
          'Management',
          'Wednesday',
          '13:00',
          '14:00',
          'Room 303',
          'CSE',
          '3',
          'A'
        ],
        [
          'CS307',
          'Seminar',
          'Wednesday',
          '14:00',
          '15:00',
          'Auditorium',
          'CSE',
          '3',
          'A'
        ],
        [
          'CS304',
          'Machine Learning',
          'Thursday',
          '09:00',
          '10:00',
          'Room 303',
          'CSE',
          '3',
          'A'
        ],
        [
          'CS302',
          'Computer Networks',
          'Thursday',
          '10:00',
          '11:00',
          'Room 303',
          'CSE',
          '3',
          'A'
        ],
        [
          'CS306',
          'AI Lab',
          'Thursday',
          '11:10',
          '12:10',
          'Lab 2',
          'CSE',
          '3',
          'A'
        ],
        [
          'CS303',
          'Web Technologies',
          'Thursday',
          '13:00',
          '14:00',
          'Room 303',
          'CSE',
          '3',
          'A'
        ],
        [
          'CS305',
          'Cloud Computing',
          'Thursday',
          '14:00',
          '15:00',
          'Room 303',
          'CSE',
          '3',
          'A'
        ],
        [
          'CS301',
          'Compiler Design',
          'Friday',
          '09:00',
          '10:00',
          'Room 303',
          'CSE',
          '3',
          'A'
        ],
        [
          'CS305',
          'Cloud Computing',
          'Friday',
          '10:00',
          '11:00',
          'Room 303',
          'CSE',
          '3',
          'A'
        ],
        [
          'CS302',
          'Computer Networks',
          'Friday',
          '11:10',
          '12:10',
          'Room 303',
          'CSE',
          '3',
          'A'
        ],
        [
          'CS303',
          'Web Technologies',
          'Friday',
          '13:00',
          '14:00',
          'Room 303',
          'CSE',
          '3',
          'A'
        ],
        [
          'HUM301',
          'Management',
          'Friday',
          '14:00',
          '15:00',
          'Room 303',
          'CSE',
          '3',
          'A'
        ],
        [
          'CS304',
          'Machine Learning',
          'Saturday',
          '09:00',
          '10:00',
          'Room 303',
          'CSE',
          '3',
          'A'
        ],
        [
          'CS308',
          'Project',
          'Saturday',
          '10:00',
          '11:00',
          'Lab 3',
          'CSE',
          '3',
          'A'
        ],
        [
          'CS308',
          'Project',
          'Saturday',
          '11:10',
          '12:10',
          'Lab 3',
          'CSE',
          '3',
          'A'
        ],
        [
          'CS308',
          'Project',
          'Saturday',
          '13:00',
          '14:00',
          'Lab 3',
          'CSE',
          '3',
          'A'
        ],
      ];

      for (var row in sampleData) {
        sheetObject
            .appendRow(row.map((e) => excel_pkg.TextCellValue(e)).toList());
      }

      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/sample_timetable.xlsx');
      await file.writeAsBytes(excel.encode()!);

      if (mounted) {
        final params = SaveFileDialogParams(sourceFilePath: file.path);
        final finalPath = await FlutterFileDialog.saveFile(params: params);

        if (finalPath != null && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('File saved successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Failed to save Excel file'),
              backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _downloadSampleCSV() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/sample_timetable.csv');

      const csvContent =
          'course_code,course_name,day,start_time,end_time,location,department,year,section\n'
          'CS301,Compiler Design,Monday,09:00,10:00,Room 303,CSE,3,A\n'
          'CS302,Computer Networks,Monday,10:00,11:00,Room 303,CSE,3,A\n'
          'CS303,Web Technologies,Monday,11:10,12:10,Lab 1,CSE,3,A\n'
          'HUM301,Management,Monday,13:00,14:00,Room 303,CSE,3,A\n'
          'CS304,Machine Learning,Monday,14:00,15:00,Room 303,CSE,3,A\n'
          'CS302,Computer Networks,Tuesday,09:00,10:00,Room 303,CSE,3,A\n'
          'CS301,Compiler Design,Tuesday,10:00,11:00,Room 303,CSE,3,A\n'
          'CS304,Machine Learning,Tuesday,11:10,12:10,Room 303,CSE,3,A\n'
          'CS305,Cloud Computing,Tuesday,13:00,14:00,Room 303,CSE,3,A\n'
          'CS306,AI Lab,Tuesday,14:00,15:00,Lab 2,CSE,3,A\n'
          'CS303,Web Technologies,Wednesday,09:00,10:00,Room 303,CSE,3,A\n'
          'CS305,Cloud Computing,Wednesday,10:00,11:00,Room 303,CSE,3,A\n'
          'CS301,Compiler Design,Wednesday,11:10,12:10,Room 303,CSE,3,A\n'
          'HUM301,Management,Wednesday,13:00,14:00,Room 303,CSE,3,A\n'
          'CS307,Seminar,Wednesday,14:00,15:00,Auditorium,CSE,3,A\n'
          'CS304,Machine Learning,Thursday,09:00,10:00,Room 303,CSE,3,A\n'
          'CS302,Computer Networks,Thursday,10:00,11:00,Room 303,CSE,3,A\n'
          'CS306,AI Lab,Thursday,11:10,12:10,Lab 2,CSE,3,A\n'
          'CS303,Web Technologies,Thursday,13:00,14:00,Room 303,CSE,3,A\n'
          'CS305,Cloud Computing,Thursday,14:00,15:00,Room 303,CSE,3,A\n'
          'CS301,Compiler Design,Friday,09:00,10:00,Room 303,CSE,3,A\n'
          'CS305,Cloud Computing,Friday,10:00,11:00,Room 303,CSE,3,A\n'
          'CS302,Computer Networks,Friday,11:10,12:10,Room 303,CSE,3,A\n'
          'CS303,Web Technologies,Friday,13:00,14:00,Room 303,CSE,3,A\n'
          'HUM301,Management,Friday,14:00,15:00,Room 303,CSE,3,A\n'
          'CS304,Machine Learning,Saturday,09:00,10:00,Room 303,CSE,3,A\n'
          'CS308,Project,Saturday,10:00,11:00,Lab 3,CSE,3,A\n'
          'CS308,Project,Saturday,11:10,12:10,Lab 3,CSE,3,A\n'
          'CS308,Project,Saturday,13:00,14:00,Lab 3,CSE,3,A';

      await file.writeAsString(csvContent);

      if (mounted) {
        final params = SaveFileDialogParams(sourceFilePath: file.path);
        final finalPath = await FlutterFileDialog.saveFile(params: params);

        if (finalPath != null && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('File saved successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Failed to save file'),
              backgroundColor: Colors.red),
        );
      }
    }
  }

  String getDayName(int weekday) {
    const map = {
      1: 'Monday',
      2: 'Tuesday',
      3: 'Wednesday',
      4: 'Thursday',
      5: 'Friday',
      6: 'Saturday',
      7: 'Sunday'
    };
    return map[weekday] ?? 'Monday';
  }

  void _initializeFilters() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.user;
    final permissions = AppPermissions(authProvider);

    if (user != null) {
      if (permissions.isStudent) {
        setState(() {
          _dept = user.department ?? 'CSE';
          _year = user.year ?? '1';
          _section = user.section ?? 'A';
        });
      } else if (permissions.isDepartmentLocked) {
        setState(() {
          _dept = user.department ?? 'CSE';
        });
      }
    }
  }

  Future<void> _loadTimetable() async {
    setState(() => _isLoading = true);
    try {
      final response = await _apiService.get(
        AppConstants.timetableEndpoint,
        params: {'department': _dept, 'year': _year, 'section': _section},
      );
      setState(() {
        _entries = response as List;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading timetable: $e')),
        );
      }
    }
  }

  Future<void> _showAddEditClassDialog({Map<String, dynamic>? entry}) async {
    final isEdit = entry != null;
    final codeController = TextEditingController(text: entry?['course_code']);
    final nameController = TextEditingController(text: entry?['course_name']);
    final locController = TextEditingController(text: entry?['location']);
    // State for selected days
    List<String> selectedDays = [entry?['day_of_week'] ?? _selectedDay];

    TimeOfDay startTime = const TimeOfDay(hour: 9, minute: 0);
    TimeOfDay endTime = const TimeOfDay(hour: 10, minute: 0);

    if (isEdit) {
      try {
        final start = entry['start_time'].toString().split(':');
        final end = entry['end_time'].toString().split(':');
        startTime =
            TimeOfDay(hour: int.parse(start[0]), minute: int.parse(start[1]));
        endTime = TimeOfDay(hour: int.parse(end[0]), minute: int.parse(end[1]));
      } catch (e) {}
    }

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
                BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 20),
              ],
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isEdit ? 'Edit Class' : 'Add New Class',
                    style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white),
                  ),
                  const SizedBox(height: 24),
                  _buildDialogField(codeController, 'Course Code',
                      icon: Icons.qr_code_rounded),
                  const SizedBox(height: 16),
                  _buildDialogField(nameController, 'Course Name',
                      icon: Icons.book_rounded),
                  const SizedBox(height: 16),
                  _buildDialogField(locController, 'Location',
                      icon: Icons.location_on_rounded),
                  const SizedBox(height: 16),

                  // RECURRING DAY SELECTOR
                  const Text("Repeat On",
                      style: TextStyle(color: Colors.white70, fontSize: 12)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _days.take(7).map((d) {
                      if (d == 'Sunday')
                        return const SizedBox
                            .shrink(); // Hide Sunday if usually unused
                      // Or just show standard days
                      final isSelected = selectedDays.contains(d);
                      return FilterChip(
                        label: Text(d.substring(0, 3)),
                        selected: isSelected,
                        onSelected: isEdit
                            ? null // Disable multi-select for Edit (Single Entry)
                            : (bool selected) {
                                setDialogState(() {
                                  if (selected) {
                                    selectedDays.add(d);
                                  } else {
                                    if (selectedDays.length > 1)
                                      selectedDays.remove(d);
                                  }
                                });
                              },
                        selectedColor: AppTheme.primaryColor,
                        checkmarkColor: Colors.white,
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.white : Colors.white70,
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                        backgroundColor: Colors.white.withOpacity(0.05),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                        side: BorderSide(
                            color: isSelected
                                ? AppTheme.primaryColor
                                : Colors.white12),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),

                  // Time Slot Selection (Replaces Manual Time Pickers)
                  const Text("Select Slot",
                      style: TextStyle(color: Colors.white70, fontSize: 12)),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<Map<String, dynamic>>(
                    decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.05),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none),
                        prefixIcon: const Icon(Icons.access_time_rounded,
                            color: Colors.white70)),
                    dropdownColor: const Color(0xFF1E293B),
                    style: const TextStyle(color: Colors.white),
                    value: _schedule.isNotEmpty
                        ? _schedule.firstWhere(
                            (s) =>
                                s['start'] ==
                                    '${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')}' &&
                                s['type'] == 'class',
                            orElse: () => _schedule.firstWhere(
                                (s) => s['type'] == 'class',
                                orElse: () => _schedule.first))
                        : null,
                    items: _schedule
                        .where((s) => s['type'] == 'class')
                        .map((slot) => DropdownMenuItem(
                              value: slot,
                              child: Text('${slot['start']} - ${slot['end']}',
                                  style: const TextStyle(color: Colors.white)),
                            ))
                        .toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setDialogState(() {
                          final startParts = val['start'].split(':');
                          final endParts = val['end'].split(':');
                          startTime = TimeOfDay(
                              hour: int.parse(startParts[0]),
                              minute: int.parse(startParts[1]));
                          endTime = TimeOfDay(
                              hour: int.parse(endParts[0]),
                              minute: int.parse(endParts[1]));
                        });
                      }
                    },
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
                          if (codeController.text.isEmpty ||
                              nameController.text.isEmpty) return;
                          try {
                            // Prepare Data
                            final Map<String, dynamic> data = {
                              'course_code': codeController.text,
                              'course_name': nameController.text,
                              'location': locController.text,
                              'start_time':
                                  '${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')}',
                              'end_time':
                                  '${endTime.hour.toString().padLeft(2, '0')}:${endTime.minute.toString().padLeft(2, '0')}',
                              'department': _dept,
                              'year': _year,
                              'section': _section,
                            };

                            if (isEdit) {
                              // For Edit, we stick to single day string to avoid breaking backend PUT
                              data['day_of_week'] = selectedDays.first;
                              await _apiService.put(
                                  '${AppConstants.timetableEndpoint}/${entry['id']}',
                                  data);
                            } else {
                              // For Add, we send the LIST of days
                              data['day_of_week'] = selectedDays;
                              await _apiService.post(
                                  AppConstants.timetableEndpoint, data);
                            }

                            if (mounted) {
                              Navigator.pop(context);
                              _loadTimetable();
                            }
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Error: $e')));
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 32, vertical: 12),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Save Class',
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

  Widget _buildDialogField(TextEditingController controller, String label,
      {IconData? icon}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: TextField(
        controller: controller,
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
    // Similar confirmation logic
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
                'Delete Class',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Are you sure you want to delete this class?',
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
      await _apiService.delete('${AppConstants.timetableEndpoint}/$id');
      _loadTimetable();
    }
  }

  Widget _buildHeader(AppPermissions permissions) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        mainAxisAlignment:
            MainAxisAlignment.spaceBetween, // Ensure space between
        children: [
          // Left: View Toggle
          _buildViewToggle(),

          // Right: Actions (Info, Admin, Filter)
          Row(
            children: [
              GestureDetector(
                onTap: _showLandscapeHint,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white.withOpacity(0.1)),
                  ),
                  child: const Icon(Icons.info_outline_rounded,
                      size: 20, color: Colors.white70),
                ),
              ),
              const SizedBox(width: 12),
              if (!permissions.canManageTimetable) ...[
                _buildActionButton(
                  icon: Icons.download_rounded,
                  tooltip: 'Download Image',
                  onPressed: _downloadTimetableImage,
                ),
                const SizedBox(width: 12),
              ],
              if (permissions.canManageTimetable) ...[
                _buildAdminMenu(),
                const SizedBox(width: 12),
              ],
              if (permissions.canFilterTimetable)
                GestureDetector(
                  onTap: _showFilterDialog,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withOpacity(0.1)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.tune_rounded,
                            color: AppTheme.primaryLight, size: 16),
                        const SizedBox(width: 8),
                        Text(
                          '$_dept-$_year-$_section',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  void _showFilterDialog() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userRole = authProvider.userRole?.toLowerCase();
    final canChangeDept = userRole == 'admin';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
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
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Filter Timetable',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 24),
                  _buildDialogDropdown(
                    label: 'Department',
                    value: _dept,
                    items: AppConstants.departments,
                    isEnabled: canChangeDept,
                    onChanged: (val) => setDialogState(() => _dept = val!),
                    icon: Icons.business_rounded,
                  ),
                  const SizedBox(height: 16),
                  _buildDialogDropdown(
                    label: 'Year',
                    value: _year,
                    items: AppConstants.years,
                    isEnabled: true,
                    onChanged: (val) => setDialogState(() => _year = val!),
                    icon: Icons.school_rounded,
                    itemLabelBuilder: (e) => 'Year $e',
                  ),
                  const SizedBox(height: 16),
                  _buildDialogDropdown(
                    label: 'Section',
                    value: _section,
                    items: AppConstants.sections,
                    isEnabled: true,
                    onChanged: (val) => setDialogState(() => _section = val!),
                    icon: Icons.grid_view_rounded,
                    itemLabelBuilder: (e) => 'Section $e',
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
                          Navigator.pop(context);
                          await _loadScheduleStructure(); // Reload structure for new department
                          await _loadTimetable(); // Reload entries
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 32, vertical: 12),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Apply',
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

  Widget _buildActionButton({
    required IconData icon,
    required VoidCallback onPressed,
    required String tooltip,
    Color color = Colors.white70,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius:
              BorderRadius.circular(12), // Squaricle to match general theme
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: Icon(icon, size: 20, color: color),
      ),
    );
  }

  Widget _buildAdminMenu() {
    return PopupMenuButton<String>(
      tooltip: 'Admin Options',
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.white.withOpacity(0.1)),
      ),
      color: const Color(0xFF1E293B),
      offset: const Offset(0, 40),
      onSelected: (value) {
        if (value == 'configure') _showStructureEditor();
        if (value == 'import') _importCSV();
        if (value == 'download') _downloadTimetableImage();
        if (value == 'master_pdf') _showMasterPdfFilterDialog();
      },
      itemBuilder: (context) => [
        _buildPopupItem(
            'configure', 'Configure Schedule', Icons.edit_calendar_rounded),
        _buildPopupItem(
            'import', 'Import CSV/Excel', Icons.upload_file_rounded),
        _buildPopupItem(
            'download', 'Download as Image', Icons.download_rounded),
        _buildPopupItem(
            'master_pdf', 'Download Master PDF', Icons.picture_as_pdf_rounded),
      ],
      // Custom Child to match exactly 36x36 (approx) glass square
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child:
            const Icon(Icons.settings_rounded, size: 20, color: Colors.white70),
      ),
    );
  }

  PopupMenuItem<String> _buildPopupItem(
      String value, String text, IconData icon) {
    return PopupMenuItem<String>(
      value: value,
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.white70),
          const SizedBox(width: 12),
          Text(text, style: const TextStyle(color: Colors.white)),
        ],
      ),
    );
  }

  Widget _buildDialogDropdown({
    required String label,
    required String value,
    required List<String> items,
    required Function(String?) onChanged,
    bool isEnabled = true,
    IconData? icon,
    String Function(String)? itemLabelBuilder,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style:
                TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: isEnabled
                ? Colors.white.withOpacity(0.05)
                : Colors.black.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              dropdownColor: const Color(0xFF1E293B),
              style: const TextStyle(color: Colors.white),
              icon: Icon(Icons.keyboard_arrow_down_rounded,
                  color: isEnabled ? Colors.white70 : Colors.white24),
              items: items.map((e) {
                return DropdownMenuItem(
                  value: e,
                  child: Row(
                    children: [
                      if (icon != null) ...[
                        Icon(icon,
                            size: 18,
                            color: isEnabled
                                ? AppTheme.primaryLight
                                : Colors.white24),
                        const SizedBox(width: 12),
                      ],
                      Text(
                        itemLabelBuilder != null ? itemLabelBuilder(e) : e,
                        style: TextStyle(
                            color: isEnabled ? Colors.white : Colors.white54),
                      ),
                    ],
                  ),
                );
              }).toList(),
              onChanged: isEnabled ? onChanged : null,
            ),
          ),
        ),
      ],
    );
  }

  void _showLandscapeHint() {
    final permissions =
        AppPermissions(Provider.of<AuthProvider>(context, listen: false));
    final canManage = permissions.canManageTimetable;

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24),
        child: Container(
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
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.crop_rotate_rounded,
                  size: 48, color: AppTheme.primaryLight),
              const SizedBox(height: 16),
              const Text(
                'View Full Timetable',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Rotate your device to landscape mode to view the full weekly grid schedule.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white.withOpacity(0.7),
                  height: 1.5,
                ),
              ),
              if (canManage) ...[
                const SizedBox(height: 24),
                const Divider(color: Colors.white12),
                const SizedBox(height: 16),
                const Text(
                  'Bulk Import',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'You can import classes via CSV or Excel using the upload button in the header.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white.withOpacity(0.7),
                  ),
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: _downloadSampleCSV,
                  icon: const Icon(Icons.download_rounded, size: 18),
                  label: const Text('Download Sample CSV'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.primaryLight,
                    side: const BorderSide(color: AppTheme.primaryLight),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: _downloadSampleExcel,
                  icon: const Icon(Icons.table_view_rounded, size: 18),
                  label: const Text('Download Sample Excel'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.greenAccent,
                    side: const BorderSide(color: Colors.greenAccent),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                ),
                child: const Text('Got it',
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildViewToggle() {
    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          _buildToggleButton('Day', _selectedView == 'Day'),
          _buildToggleButton('Week', _selectedView == 'Week'),
        ],
      ),
    );
  }

  Widget _buildToggleButton(String label, bool isSelected) {
    return GestureDetector(
      onTap: () => setState(() => _selectedView = label),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryColor : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.white70,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildDaySelector() {
    return SizedBox(
      height: 60,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _days.length,
        itemBuilder: (context, index) {
          final day = _days[index];
          final isSelected = day == _selectedDay;
          return GestureDetector(
            onTap: () => setState(() => _selectedDay = day),
            child: Container(
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppTheme.primaryColor
                    : Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected
                      ? AppTheme.primaryColor
                      : Colors.white.withOpacity(0.1),
                ),
              ),
              child: Center(
                child: Text(
                  day.substring(0, 3).toUpperCase(),
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.white70,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDayView(bool canManage) {
    if (_schedule.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.calendar_today_rounded,
                size: 64, color: Colors.white.withOpacity(0.2)),
            const SizedBox(height: 16),
            Text('No schedule structure found',
                style: TextStyle(color: Colors.white.withOpacity(0.5))),
          ],
        ),
      );
    }

    // Filter entries for the selected day
    final dayEntries =
        _entries.where((e) => e['day_of_week'] == _selectedDay).toList();

    return ListView.builder(
      controller: _dayVerticalController,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      itemCount: _schedule.length,
      itemBuilder: (context, index) {
        final slot = _schedule[index];
        final isBreak = slot['type'] == 'break';
        final startTime = slot['start'];

        if (isBreak) {
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withOpacity(0.05)),
            ),
            child: Center(
              child: Text(
                '${slot['label']} (${slot['start']} - ${slot['end']})',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.5),
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                  letterSpacing: 1,
                ),
              ),
            ),
          );
        } else {
          // Class Logic
          final entry = dayEntries.firstWhere(
            (e) => e['start_time'].toString().startsWith(startTime),
            orElse: () => <String, dynamic>{},
          );

          // WRAP IN DRAG TARGET (For Dropping in Day View)
          return DragTarget<Map<String, dynamic>>(
            onWillAccept: (data) =>
                canManage && data != null && data['id'] != entry['id'],
            onAccept: (data) => _handleClassDrop(data, _selectedDay, slot),
            builder: (context, candidateData, rejectedData) {
              final isHovering = candidateData.isNotEmpty;
              Widget content;

              if (entry.isNotEmpty) {
                // OCCUPIED SLOT
                final card =
                    _buildClassCard(entry, canManage, isCompact: false);

                // Make Draggable if Manageable
                if (canManage) {
                  content = LongPressDraggable<Map<String, dynamic>>(
                    data: entry,
                    hapticFeedbackOnStart: true,
                    onDragUpdate: _handleDragUpdate,
                    onDragEnd: _handleDragEnd,
                    feedback: Material(
                      color: Colors.transparent,
                      child: SizedBox(
                          width: MediaQuery.of(context).size.width - 40,
                          child:
                              _buildClassCard(entry, false, isCompact: false)),
                    ),
                    childWhenDragging: Opacity(opacity: 0.5, child: card),
                    child: card,
                  );
                } else {
                  content = card;
                }
              } else {
                // EMPTY SLOT (Visible Drop Target)
                content = Container(
                  height: 100, // Fixed height for empty slot target
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.02),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                        color: Colors.white.withOpacity(0.05),
                        style: BorderStyle.solid),
                  ),
                  child: Center(
                    child: Text(
                      "Free Slot ($startTime)",
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.2), fontSize: 12),
                    ),
                  ),
                );
              }

              // Highlight wrapper (Ring)
              return Container(
                decoration: isHovering
                    ? BoxDecoration(
                        border:
                            Border.all(color: AppTheme.primaryLight, width: 2),
                        borderRadius: BorderRadius.circular(18),
                      )
                    : null,
                child: content,
              );
            },
          );
        }
      },
    );
  }

  Future<void> _handleClassDrop(Map<String, dynamic> draggedEntry,
      String targetDay, Map<String, dynamic> targetSlot) async {
    final newStart = targetSlot['start'];
    final newEnd = targetSlot['end'];

    // Avoid self-drop
    if (draggedEntry['day_of_week'] == targetDay &&
        draggedEntry['start_time'].toString().startsWith(newStart)) {
      return;
    }

    // 1. Find Collision (Target Occupant)
    final collisionIndex = _entries.indexWhere((e) =>
        e['day_of_week'] == targetDay &&
        e['start_time'].toString().startsWith(newStart) &&
        e['id'] != draggedEntry['id']);

    if (collisionIndex != -1) {
      final targetEntry = _entries[collisionIndex];
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: const Color(0xFF1E293B), // Match AppTheme
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Row(
            children: const [
              Icon(Icons.swap_horiz_rounded, color: AppTheme.primaryLight),
              SizedBox(width: 12),
              Text('Swap Classes?',
                  style: TextStyle(color: Colors.white, fontSize: 20)),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildSwapCard(draggedEntry, "Moving", Colors.blueAccent),
                const Icon(Icons.arrow_downward_rounded,
                    color: Colors.white54, size: 24),
                _buildSwapCard(targetEntry, "Replacing",
                    Colors.redAccent.withOpacity(0.8)),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child:
                  const Text('Cancel', style: TextStyle(color: Colors.white70)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor),
              child: const Text('Confirm Swap',
                  style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );

      if (confirmed != true) return;
    }

    setState(() {
      // 2. Optimistic Swap (Re-find index in case of async shift, though local list is stable)
      // Actually, indices are stable unless another async op happened.
      if (collisionIndex != -1) {
        // Move Collision -> Source Slot
        _entries[collisionIndex]['day_of_week'] = draggedEntry['day_of_week'];
        _entries[collisionIndex]['start_time'] = draggedEntry['start_time'];
        _entries[collisionIndex]['end_time'] = draggedEntry['end_time'];
      }

      // 3. Move Dragged -> Target Slot
      final draggedIndex =
          _entries.indexWhere((e) => e['id'] == draggedEntry['id']);
      if (draggedIndex != -1) {
        _entries[draggedIndex]['day_of_week'] = targetDay;
        _entries[draggedIndex]['start_time'] = newStart;
        _entries[draggedIndex]['end_time'] = newEnd;
      }
    });

    try {
      // 4. API Call (Backend handles the actual DB Swap logic we implemented)
      final Map<String, dynamic> updateData = Map.from(draggedEntry);
      updateData['day_of_week'] = targetDay;
      updateData['start_time'] = newStart;
      updateData['end_time'] = newEnd;
      // Ensure required fields are present
      updateData['department'] = _dept; // Assuming managing own dept
      updateData['year'] = _year;
      updateData['section'] = _section;

      await _apiService.put(
        '${AppConstants.timetableEndpoint}/${draggedEntry['id']}',
        updateData,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Failed to move class: $e')));
        _loadTimetable(); // Revert on error
      }
    }
  }

  Widget _buildSwapCard(
      Map<String, dynamic> entry, String label, Color accentColor) {
    // Format time to HH:MM
    String formatTime(String time) =>
        time.length > 5 ? time.substring(0, 5) : time;

    final timeStr =
        '${formatTime(entry['start_time'])} - ${formatTime(entry['end_time'])}';
    final dayStr = entry['day_of_week'].toString().substring(0, 3);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(label.toUpperCase(),
                    style: TextStyle(
                        color: accentColor,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  children: [
                    Icon(Icons.calendar_today_rounded,
                        size: 11, color: Colors.white.withOpacity(0.7)),
                    const SizedBox(width: 6),
                    Text(
                      '$dayStr • $timeStr',
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 11,
                          fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            entry['course_name'] ?? 'Unknown Class',
            style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 15,
                letterSpacing: 0.3),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(Icons.location_on_outlined,
                  size: 13, color: Colors.white.withOpacity(0.6)),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  '${entry['course_code']} • ${entry['location']}',
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.6), fontSize: 13),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWeekView(bool canManage) {
    if (_schedule.isEmpty) {
      return const Center(child: Text("No schedule structure"));
    }

    return ListView.builder(
      controller: _weekHorizontalController, // Auto Scroll Controller
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _days.length,
      itemBuilder: (context, index) {
        final day = _days[index];
        final dayEntries =
            _entries.where((e) => e['day_of_week'] == day).toList();

        return Container(
          width: 280, // Fixed width for each day column
          margin: const EdgeInsets.only(right: 16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.03),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withOpacity(0.05)),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      day,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${dayEntries.length}',
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: Colors.white12),
              Expanded(
                child: ListView.builder(
                  controller: _weekDayControllers[day],
                  padding: const EdgeInsets.all(12),
                  itemCount: _schedule.length, // Iterate master schedule
                  itemBuilder: (context, i) {
                    final slot = _schedule[i];
                    final isBreak = slot['type'] == 'break';
                    final startTime = slot['start'];

                    if (isBreak) {
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(12),
                          border:
                              Border.all(color: Colors.white.withOpacity(0.05)),
                        ),
                        child: Center(
                          child: Text(
                            '${slot['label']} (${slot['start']} - ${slot['end']})',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.5),
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                      );
                    } else {
                      // Class Logic
                      final entry = dayEntries.firstWhere(
                        (e) => e['start_time'].toString().startsWith(startTime),
                        orElse: () => <String, dynamic>{},
                      );

                      // WRAP IN DRAG TARGET (For Dropping)
                      return DragTarget<Map<String, dynamic>>(
                        onWillAccept: (data) =>
                            canManage &&
                            data != null &&
                            data['id'] != entry['id'],
                        onAccept: (data) => _handleClassDrop(data, day, slot),
                        builder: (context, candidateData, rejectedData) {
                          final isHovering = candidateData.isNotEmpty;
                          Widget content;

                          if (entry.isNotEmpty) {
                            // OCCUPIED SLOT
                            final card = _buildClassCard(entry, canManage,
                                isCompact: true);

                            // Make Draggable if Manageable
                            if (canManage) {
                              content =
                                  LongPressDraggable<Map<String, dynamic>>(
                                data: entry,
                                hapticFeedbackOnStart: true,
                                onDragUpdate: _handleDragUpdate,
                                onDragEnd: _handleDragEnd,
                                feedback: Material(
                                  color: Colors.transparent,
                                  child: SizedBox(
                                      width: 250,
                                      child: _buildClassCard(entry, false,
                                          isCompact: true)),
                                ),
                                childWhenDragging:
                                    Opacity(opacity: 0.5, child: card),
                                child: card,
                              );
                            } else {
                              content = card;
                            }
                          } else {
                            // EMPTY SLOT
                            // Render a placeholder that can accept drops
                            content = Container(
                              height: 100, // Approximate height of a class card
                              margin: const EdgeInsets.only(bottom: 12),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.02),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                    color: Colors.white.withOpacity(0.05),
                                    style: BorderStyle.solid),
                              ),
                              child: Center(
                                child: Text(
                                  "Free Slot",
                                  style: TextStyle(
                                      color: Colors.white.withOpacity(0.2),
                                      fontSize: 12),
                                ),
                              ),
                            );
                          }

                          // Highlight wrapper (Ring)
                          return Container(
                            decoration: isHovering
                                ? BoxDecoration(
                                    border: Border.all(
                                        color: AppTheme.primaryLight, width: 2),
                                    borderRadius: BorderRadius.circular(18),
                                  )
                                : null,
                            child: content,
                          );
                        },
                      );
                    }
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildClassCard(dynamic entry, bool canManage,
      {required bool isCompact}) {
    // Generate a color based on course code hash or similar for visual variety
    // For now, use a consistent glass style
    final timeStr = '${entry['start_time']} - ${entry['end_time']}';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B).withOpacity(0.6), // Glass
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry['course_name'],
                      style: TextStyle(
                        fontSize: isCompact ? 14 : 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      entry['course_code'],
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.primaryLight,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
              if (canManage)
                PopupMenuButton<String>(
                  icon: Icon(Icons.more_vert, color: Colors.white54, size: 20),
                  color: const Color(0xFF1E293B),
                  onSelected: (val) {
                    if (val == 'edit') _showAddEditClassDialog(entry: entry);
                    if (val == 'delete') _confirmDelete(entry['id']);
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
                ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.access_time_rounded,
                  size: 14, color: Colors.white.withOpacity(0.5)),
              const SizedBox(width: 6),
              Text(
                timeStr,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white.withOpacity(0.7),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(Icons.location_on_outlined,
                  size: 14, color: Colors.white.withOpacity(0.5)),
              const SizedBox(width: 6),
              Text(
                entry['location'],
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white.withOpacity(0.7),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// New Widget for Editing Structure
class _ScheduleEditorDialog extends StatefulWidget {
  final List<Map<String, dynamic>> currentSchedule;
  final List<dynamic> currentEntries;
  final List<String> currentDays;
  final Function(List<Map<String, dynamic>>) onSave;
  final Function(List<String>) onSaveDays;

  const _ScheduleEditorDialog(
      {required this.currentSchedule,
      required this.currentEntries,
      required this.currentDays,
      required this.onSave,
      required this.onSaveDays});

  @override
  State<_ScheduleEditorDialog> createState() => _ScheduleEditorDialogState();
}

class _ScheduleEditorDialogState extends State<_ScheduleEditorDialog> {
  late List<Map<String, dynamic>> _items;
  late List<Map<String, dynamic>> _dayItems; // { 'source': 'Mon', 'count': 5 }
  bool _isDayMode = false; // Toggle State

  @override
  void initState() {
    super.initState();
    // Initialize Slots
    _items = widget.currentSchedule.map((e) {
      final map = Map<String, dynamic>.from(e);
      if (!map.containsKey('original_start')) {
        map['original_start'] = map['start'];
      }
      if (!map.containsKey('_ui_id')) {
        map['_ui_id'] = DateTime.now().microsecondsSinceEpoch.toString() +
            map['start'].toString();
      }
      return map;
    }).toList();

    // Initialize Days (Content Buckets)
    _dayItems = widget.currentDays.map((day) {
      final count =
          widget.currentEntries.where((e) => e['day_of_week'] == day).length;
      return {
        'source': day,
        'count': count,
        '_ui_id': 'day_$day',
      };
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
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
            BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 20),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Edit Structure',
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white),
                ),
                // MODE TOGGLE
                Container(
                  height: 32,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      _buildModeToggleItem('Slots', !_isDayMode),
                      _buildModeToggleItem('Days', _isDayMode),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _isDayMode
                  ? ReorderableListView(
                      onReorder: (oldIndex, newIndex) {
                        setState(() {
                          if (oldIndex < newIndex) newIndex -= 1;
                          final item = _dayItems.removeAt(oldIndex);
                          _dayItems.insert(newIndex, item);
                        });
                      },
                      children: [
                        for (int index = 0; index < _dayItems.length; index++)
                          _buildDayListItem(index, _dayItems[index]),
                      ],
                    )
                  : ReorderableListView(
                      onReorder: (oldIndex, newIndex) {
                        setState(() {
                          if (oldIndex < newIndex) newIndex -= 1;
                          final item = _items.removeAt(oldIndex);
                          _items.insert(newIndex, item);

                          // Ripple Recalculation: Update Start/End times based on order
                          // We assume the FIRST item's start time dictates the schedule start.
                          // Or we keep 09:00 as anchor? Let's use the earliest start time found as anchor.
                          // Actually, safer to just use the new first item's start time?
                          // No, usually you want to Keep the Start Time of the Schedule fixed (e.g. 9am).

                          // Let's take the Start Time of the index 0 as the Anchor.
                          // Wait, if I swapped 0 and 1, index 0 is now the old index 1.
                          // We should preserve the Schedule Start Time (e.g. 09:00).

                          // Helper to parse time string "HH:MM"
                          TimeOfDay parse(String s) {
                            final parts = s.split(':');
                            return TimeOfDay(
                                hour: int.parse(parts[0]),
                                minute: int.parse(parts[1]));
                          }

                          // Helper to format TimeOfDay
                          String fmt(TimeOfDay t) {
                            final h = t.hour.toString().padLeft(2, '0');
                            final m = t.minute.toString().padLeft(2, '0');
                            return '$h:$m';
                          }

                          // Helper to add minutes
                          TimeOfDay add(TimeOfDay t, int min) {
                            final total = t.hour * 60 + t.minute + min;
                            return TimeOfDay(
                                hour: (total ~/ 60) % 24, minute: total % 60);
                          }

                          // Calculate duration of each item BEFORE modification
                          final durations = _items.map((e) {
                            final start = parse(e['start']);
                            final end = parse(e['end']);
                            return (end.hour * 60 + end.minute) -
                                (start.hour * 60 + start.minute);
                          }).toList();

                          // Anchor Time: Try to find the earliest start time in the list to trigger 09:00
                          // Or default to 09:00 if messy.
                          // Let's assume the user wants the schedule to START at the same time as before.
                          // So we find the minimum start time in the original list.
                          // Actually, just taking the start time of the item that ended up at index 0
                          // might jump the schedule if we dragged a 10am class there.
                          // Correct approach: Find the minimum start time from the list BEFORE reorder.
                          // But we already reordered.

                          // Simplest Robust Logic: The Schedule Start Time is Fixed to whatever the First Slot WAS?
                          // Or just use 09:00? No, maybe 8:30.
                          // Let's use the 'start' time of the item that WAS at index 0 before (if we tracked it).
                          // Since we didn't, let's just pick the earliest start time present in the current items.
                          int minMinutes = 24 * 60;
                          for (var item in _items) {
                            final t = parse(item['start']);
                            final m = t.hour * 60 + t.minute;
                            if (m < minMinutes) minMinutes = m;
                          }

                          TimeOfDay cursor = TimeOfDay(
                              hour: minMinutes ~/ 60, minute: minMinutes % 60);

                          // Rebuild Times
                          for (int i = 0; i < _items.length; i++) {
                            final duration = durations[i];
                            final startStr = fmt(cursor);
                            final endT = add(cursor, duration);
                            final endStr = fmt(endT);

                            _items[i]['start'] = startStr;
                            _items[i]['end'] = endStr;

                            // NOTE: We do NOT update 'original_start' here.
                            // It remains as the Identity of the slot (e.g., "This was the 10am slot").

                            cursor = endT; // Next start is this end
                          }
                        });
                      },
                      children: [
                        for (int index = 0; index < _items.length; index++)
                          _buildListItem(index, _items[index]),
                      ],
                    ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _isDayMode
                    ? const SizedBox() // Hide Add Slot in Day Mode
                    : TextButton.icon(
                        onPressed: _addNewSlot,
                        icon:
                            const Icon(Icons.add, color: AppTheme.primaryLight),
                        label: const Text('Add Slot',
                            style: TextStyle(color: AppTheme.primaryLight)),
                      ),
                Row(
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel',
                          style: TextStyle(color: Colors.white70)),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () {
                        widget.onSave(_items);
                        widget.onSaveDays(_dayItems
                            .map((e) => e['source'] as String)
                            .toList());
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor),
                      child: const Text('Save',
                          style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModeToggleItem(String label, bool isSelected) {
    return GestureDetector(
      onTap: () => setState(() => _isDayMode = label == 'Days'),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryColor : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          label,
          style: TextStyle(
              color: isSelected ? Colors.white : Colors.white70,
              fontSize: 12,
              fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildDayListItem(int index, Map<String, dynamic> item) {
    // Label is the FIXED slot (Monday, Tuesday...)
    final fixedLabel = widget.currentDays[index];
    final sourceLabel = item['source'] as String;
    final count = item['count'];

    return Container(
      key: ValueKey(item['_ui_id']),
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          const Icon(Icons.drag_handle, color: Colors.white24),
          const SizedBox(width: 12),
          Container(
            width: 40,
            alignment: Alignment.center,
            child: Text(
              fixedLabel.substring(0, 3).toUpperCase(),
              style: const TextStyle(
                  color: Colors.white70,
                  fontWeight: FontWeight.bold,
                  fontSize: 12),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  sourceLabel == fixedLabel
                      ? '$count Classes'
                      : 'Moves here: $sourceLabel ($count Classes)',
                  style: TextStyle(
                      color: sourceLabel == fixedLabel
                          ? Colors.white
                          : AppTheme.primaryLight,
                      fontWeight: FontWeight.bold,
                      fontSize: 14),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildListItem(int index, Map<String, dynamic> item) {
    return Container(
      key: ValueKey(item['_ui_id']), // Stable Key based on ID, not content
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          const Icon(Icons.drag_handle, color: Colors.white24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${item['start']} - ${item['end']}',
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold),
                ),
                Text(
                  item['type'] == 'break'
                      ? 'Break: ${item['label']}'
                      : 'Class Slot',
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.5), fontSize: 12),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.edit, size: 20, color: Colors.white70),
            onPressed: () => _editSlot(index),
          ),
          IconButton(
            icon:
                const Icon(Icons.delete, size: 20, color: AppTheme.errorColor),
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
                          'Delete Slot',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Are you sure you want to delete this slot? This action cannot be undone.',
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
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 12),
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
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 12),
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
                setState(() {
                  _items.removeAt(index);
                });
              }
            },
          ),
        ],
      ),
    );
  }

  Future<void> _addNewSlot() async {
    // Default new slot
    String start = "09:00";
    if (_items.isNotEmpty) {
      start = _items.last['end']; // Auto-continue
    }

    // Simple util to add hour
    String end = "10:00";
    try {
      int h = int.parse(start.split(':')[0]);
      end = '${(h + 1).toString().padLeft(2, '0')}:${start.split(':')[1]}';
    } catch (e) {}

    final newSlot = {
      'start': start,
      'end': end,
      'type': 'class',
    };

    // Show Edit Dialog immediately
    await _showEditSlotDialog(newSlot, isNew: true);
  }

  Future<void> _editSlot(int index) async {
    await _showEditSlotDialog(_items[index], index: index);
  }

  Future<void> _showEditSlotDialog(Map<String, dynamic> slot,
      {bool isNew = false, int? index}) async {
    final startCtrl = TextEditingController(text: slot['start']);
    final endCtrl = TextEditingController(text: slot['end']);
    bool isBreak = slot['type'] == 'break';
    final labelCtrl = TextEditingController(text: slot['label'] ?? '');

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setConfigState) => Dialog(
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isNew ? 'Add Slot' : 'Edit Slot',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(child: _buildDialogField(startCtrl, 'Start')),
                    const SizedBox(width: 12),
                    Expanded(child: _buildDialogField(endCtrl, 'End')),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white.withOpacity(0.1)),
                  ),
                  child: Row(
                    children: [
                      Checkbox(
                        value: isBreak,
                        onChanged: (val) =>
                            setConfigState(() => isBreak = val!),
                        activeColor: AppTheme.primaryColor,
                        checkColor: Colors.white,
                        side: BorderSide(color: Colors.white.withOpacity(0.5)),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4)),
                      ),
                      const Text('Is Break?',
                          style: TextStyle(color: Colors.white)),
                    ],
                  ),
                ),
                if (isBreak) ...[
                  const SizedBox(height: 16),
                  _buildDialogField(labelCtrl, 'Break Label (e.g. Lunch)'),
                ],
                const SizedBox(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      style:
                          TextButton.styleFrom(foregroundColor: Colors.white70),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton(
                      onPressed: () {
                        final newMap = {
                          'start': startCtrl.text,
                          'end': endCtrl.text,
                          'type': isBreak ? 'break' : 'class',
                        };
                        if (isBreak) newMap['label'] = labelCtrl.text;

                        setState(() {
                          if (isNew) {
                            _items.add(newMap);
                          } else {
                            _items[index!] = newMap;
                          }
                        });
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Save',
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
    );
  }

  Widget _buildDialogField(TextEditingController controller, String label) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: TextField(
        controller: controller,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }
}
