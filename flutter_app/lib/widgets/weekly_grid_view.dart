import 'package:flutter/material.dart';
import 'dart:async';
import '../../config/theme.dart';

class WeeklyGridView extends StatefulWidget {
  final List<dynamic> entries;
  final List<Map<String, dynamic>> schedule;
  final Function(Map<String, dynamic>?) onCellTap;
  final Function(Map<String, dynamic>, String, Map<String, dynamic>)
      onClassDrop;
  final bool canManage;

  const WeeklyGridView({
    super.key,
    required this.entries,
    required this.schedule,
    required this.onCellTap,
    required this.onClassDrop,
    required this.canManage,
  });

  @override
  State<WeeklyGridView> createState() => _WeeklyGridViewState();
}

class _WeeklyGridViewState extends State<WeeklyGridView> {
  // Use widget.schedule instead

  final List<String> _days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];

  final ScrollController _horizontalController = ScrollController();
  final ScrollController _verticalController = ScrollController();
  Timer? _autoScrollTimer;
  Offset? _currentDragPosition;

  @override
  void dispose() {
    _horizontalController.dispose();
    _verticalController.dispose();
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

    // Horizontal Scroll
    if (position.dx < scrollZone) {
      if (_horizontalController.hasClients) {
        _horizontalController.jumpTo(
            (_horizontalController.offset - scrollSpeed)
                .clamp(0.0, _horizontalController.position.maxScrollExtent));
      }
    } else if (position.dx > size.width - scrollZone) {
      if (_horizontalController.hasClients) {
        _horizontalController.jumpTo(
            (_horizontalController.offset + scrollSpeed)
                .clamp(0.0, _horizontalController.position.maxScrollExtent));
      }
    }

    // Vertical Scroll
    if (position.dy < scrollZone) {
      if (_verticalController.hasClients) {
        _verticalController.jumpTo((_verticalController.offset - scrollSpeed)
            .clamp(0.0, _verticalController.position.maxScrollExtent));
      }
    } else if (position.dy > size.height - scrollZone) {
      if (_verticalController.hasClients) {
        _verticalController.jumpTo((_verticalController.offset + scrollSpeed)
            .clamp(0.0, _verticalController.position.maxScrollExtent));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Width of time column (Widened to fit 09:00 - 10:00)
        const double timeColWidth = 80;
        // Remaining width for days
        final double dayColWidth =
            (constraints.maxWidth - timeColWidth) / _days.length;
        // Make sure it's at least 80px wide, else scroll
        final double actualDayColWidth = dayColWidth < 80 ? 80 : dayColWidth;

        final double totalWidth =
            timeColWidth + (actualDayColWidth * _days.length);

        return SingleChildScrollView(
          controller: _horizontalController,
          scrollDirection: Axis.horizontal,
          child: SizedBox(
            width: totalWidth,
            child: SingleChildScrollView(
              controller: _verticalController,
              scrollDirection: Axis.vertical,
              child: Column(
                children: [
                  // HEADER ROW
                  _buildHeaderRow(timeColWidth, actualDayColWidth),

                  // GRID ROWS
                  ...widget.schedule.map((slot) =>
                      _buildTimeRow(slot, timeColWidth, actualDayColWidth)),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeaderRow(double timeWidth, double dayWidth) {
    return Container(
      height: 40,
      color: Colors.white.withOpacity(0.1),
      child: Row(
        children: [
          SizedBox(
              width: timeWidth,
              child: const Center(
                  child: Icon(Icons.access_time,
                      size: 16, color: Colors.white70))),
          ..._days.map((day) => Container(
                width: dayWidth,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                    border: Border(
                        left:
                            BorderSide(color: Colors.white.withOpacity(0.1)))),
                child: Text(day,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, color: Colors.white)),
              )),
        ],
      ),
    );
  }

  Widget _buildTimeRow(
      Map<String, dynamic> slot, double timeWidth, double dayWidth) {
    final isBreak = slot['type'] == 'break';
    // Adjust height for short break
    final double rowHeight = slot['label'] == 'Short Break' ? 40.0 : 80.0;

    return SizedBox(
      height: rowHeight,
      child: Row(
        children: [
          // Time Label
          Container(
            width: timeWidth,
            // Changed from topCenter to center for Vertical Alignment
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              '${slot['start']} - ${slot['end']}',
              style: const TextStyle(color: Colors.white70, fontSize: 10),
              textAlign: TextAlign.center,
            ),
          ),

          // Day Cells (or Break Row)
          if (isBreak)
            Expanded(
              child: Container(
                alignment: Alignment.center,
                decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    border: Border(
                      left: BorderSide(color: Colors.white.withOpacity(0.1)),
                      bottom: BorderSide(color: Colors.white.withOpacity(0.1)),
                    )),
                child: Text(
                  slot['label'],
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.5),
                      letterSpacing: 2,
                      fontWeight: FontWeight.bold,
                      fontSize: 12),
                ),
              ),
            )
          else
            ..._days.map((day) => _buildCell(day, slot, dayWidth)),
        ],
      ),
    );
  }

  Widget _buildCell(String dayShort, Map<String, dynamic> slot, double width) {
    final fullDay = _mapDay(dayShort);
    final timeStart = slot['start'];

    // Find entry matching Day + StartTime
    final entry = widget.entries.firstWhere(
        (e) =>
            e['day_of_week'] == fullDay &&
            e['start_time'].toString().startsWith(timeStart),
        orElse: () => null);

    // Build the content widget (used by both admin and non-admin)
    Widget buildContent({bool isHovering = false}) {
      return GestureDetector(
        onTap: () {
          if (entry != null) {
            widget.onCellTap(entry);
          } else {
            widget.onCellTap({
              'day_of_week': fullDay,
              'start_time': timeStart,
              'end_time': slot['end']
            });
          }
        },
        child: Container(
          width: width,
          decoration: BoxDecoration(
            border: Border(
              left: BorderSide(color: Colors.white.withOpacity(0.1)),
              bottom: BorderSide(color: Colors.white.withOpacity(0.1)),
            ),
            color: isHovering
                ? AppTheme.primaryColor.withOpacity(0.4)
                : (entry != null
                    ? AppTheme.primaryColor.withOpacity(0.2)
                    : Colors.transparent),
          ),
          padding: const EdgeInsets.all(4),
          child: entry != null
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      entry['course_name'] ?? '',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          fontSize: 12),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 2,
                    ),
                    Text(
                      '${entry['course_code']} • ${entry['location'] ?? ''}',
                      style:
                          const TextStyle(color: Colors.white70, fontSize: 10),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                )
              : null,
        ),
      );
    }

    // Only enable DragTarget for admin users
    if (!widget.canManage) {
      return buildContent();
    }

    return DragTarget<Map<String, dynamic>>(
      onWillAccept: (data) =>
          data != null && (entry == null || data['id'] != entry['id']),
      onAccept: (data) => widget.onClassDrop(data, fullDay, slot),
      builder: (context, candidateData, rejectedData) {
        final isHovering = candidateData.isNotEmpty;
        final content = buildContent(isHovering: isHovering);

        // Only enable dragging for admin users with entries
        if (entry != null) {
          return LongPressDraggable<Map<String, dynamic>>(
            data: entry,
            hapticFeedbackOnStart: true,
            onDragUpdate: _handleDragUpdate,
            onDragEnd: _handleDragEnd,
            feedback: Material(
              color: Colors.transparent,
              child: Container(
                width: width,
                height: 60,
                decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(color: Colors.black26, blurRadius: 10)
                    ]),
                padding: const EdgeInsets.all(8),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry['course_name'] ?? '',
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
            childWhenDragging: Opacity(opacity: 0.5, child: content),
            child: content,
          );
        } else {
          return content;
        }
      },
    );
  }

  String _mapDay(String short) {
    const map = {
      'Mon': 'Monday',
      'Tue': 'Tuesday',
      'Wed': 'Wednesday',
      'Thu': 'Thursday',
      'Fri': 'Friday',
      'Sat': 'Saturday'
    };
    return map[short] ?? 'Monday';
  }

  // Removed _calculateEndTime as it is no longer needed
}
