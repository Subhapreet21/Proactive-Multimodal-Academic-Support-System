import 'dart:async';
import 'package:flutter/material.dart';

import 'package:go_router/go_router.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';
import '../config/theme.dart';

class LandingScreen extends StatelessWidget {
  const LandingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: Stack(
        children: [
          // 1. Background Gradient (RepaintBoundary optimized)
          Positioned.fill(
            child: RepaintBoundary(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: AppTheme.backgroundGradient,
                ),
              ),
            ),
          ),

          // 2. 3D Model (RepaintBoundary optimized)
          // In Landscape: Position on the Right Half
          // In Portrait: Original Positioning
          Positioned(
            top: isLandscape ? 0 : 220,
            bottom: isLandscape ? 60 : 90, // Leave space for bottom bar
            right: 0,
            left: isLandscape ? size.width * 0.5 : 0, // Landscape: Right Half
            child: const RepaintBoundary(
              child: ModelViewer(
                backgroundColor: Colors.transparent,
                src:
                    'assets/3D-model/low_poly_university_building_3d_model.glb',
                alt: '3D University Model',
                ar: false,
                autoRotate: true,
                cameraControls: true,
                disableZoom: true,
                disablePan: true,
                autoRotateDelay: 0,
                rotationPerSecond: '20deg',
                fieldOfView: "30deg",
                cameraOrbit: "45deg 75deg 95%",
                minCameraOrbit: "auto 75deg auto",
                maxCameraOrbit: "auto 75deg auto",
                interactionPrompt: InteractionPrompt.none,
                exposure: 1.2,
              ),
            ),
          ),

          // 3. Top Scrim (Gradient) - Adjusted for layout
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: isLandscape ? 150 : 300,
            child: IgnorePointer(
              child: RepaintBoundary(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        AppTheme.backgroundColor.withValues(alpha: 0.95),
                        AppTheme.backgroundColor.withValues(alpha: 0.0),
                      ],
                      stops: const [0.0, 1.0],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // 4. Bottom Scrim (Gradient)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: 200,
            child: IgnorePointer(
              child: RepaintBoundary(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        AppTheme.backgroundColor.withValues(alpha: 0.95),
                        AppTheme.backgroundColor.withValues(alpha: 0.0),
                      ],
                      stops: const [0.0, 1.0],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // 5. Main Content
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Content Column (Left Side in Landscape)
                      Expanded(
                        flex: isLandscape
                            ? 1
                            : 1, // Full width in portrait? No, need logic
                        child: SingleChildScrollView(
                          // Allow scrolling if height issues
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 24.0, vertical: 16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Header
                                Row(
                                  children: [
                                    _buildLogo(),
                                    const SizedBox(width: 12),
                                    const Text(
                                      'Campus OS',
                                      style: TextStyle(
                                        fontSize: 30,
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.textPrimary,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: isLandscape ? 12 : 24),

                                // Custom Backspace Typewriter
                                RepaintBoundary(
                                  child: SizedBox(
                                    height: isLandscape ? 80 : 100,
                                    child: _BackspaceTypewriter(
                                      phrases: const [
                                        'Experience University\nLike Never Before',
                                        'Navigate Campus\nWith Ease',
                                        'Manage Schedules\nEffortlessly',
                                      ],
                                      textStyle: TextStyle(
                                        fontSize: isLandscape
                                            ? 28
                                            : 36, // Smaller in LS
                                        height: 1,
                                        fontWeight: FontWeight.w900,
                                        color: AppTheme.textPrimary,
                                        fontFamily: 'Inter',
                                      ),
                                    ),
                                  ),
                                ),

                                // Subtitle
                                const Text(
                                  'Your AI-powered companion for navigation, scheduling, and academic success.',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.white70,
                                    height: 1.5,
                                  ),
                                ),

                                SizedBox(height: isLandscape ? 16 : 24),

                                // Feature Icon Infinite Carousel
                                const _ScrollingIconRow(
                                  children: [
                                    _FeatureIcon(
                                      icon: Icons.chat_bubble_outline,
                                      label: 'AI Chat',
                                      color: Color(0xFFEF4444), // Red
                                    ),
                                    _FeatureIcon(
                                      icon: Icons.calendar_today_outlined,
                                      label: 'Timetable',
                                      color: Color(0xFFF59E0B), // Orange
                                    ),
                                    _FeatureIcon(
                                      icon: Icons.event_available_outlined,
                                      label: 'Events',
                                      color: Color(0xFFFACC15), // Yellow
                                    ),
                                    _FeatureIcon(
                                      icon: Icons.vrpano_outlined,
                                      label: 'Tour',
                                      color: Color(0xFF10B981), // Green
                                    ),
                                    _FeatureIcon(
                                      icon: Icons.library_books_outlined,
                                      label: 'Knowledge',
                                      color: Color(0xFF06B6D4), // Cyan
                                    ),
                                    _FeatureIcon(
                                      icon: Icons.notifications_outlined,
                                      label: 'Reminders',
                                      color: Color(0xFF3B82F6), // Blue
                                    ),
                                    _FeatureIcon(
                                      icon: Icons.auto_stories_outlined,
                                      label: 'Study',
                                      color: AppTheme.primaryColor, // Indigo
                                    ),
                                    _FeatureIcon(
                                      icon: Icons.co_present_outlined,
                                      label: 'Co-Pilot',
                                      color: AppTheme.secondaryColor, // Violet
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      // Spacer for Right Side in Landscape (where model is)
                      if (isLandscape)
                        const Expanded(
                          flex: 1,
                          child: SizedBox(), // Transparent space for 3D model
                        ),
                    ],
                  ),
                ),

                // Bottom Section (Button)
                Padding(
                  padding: EdgeInsets.only(bottom: isLandscape ? 12.0 : 48.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24.0),
                        child: Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.primaryColor
                                    .withValues(alpha: 0.4),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: ElevatedButton(
                            onPressed: () => context.push('/auth'),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 20),
                              backgroundColor: AppTheme.primaryColor,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Get Started',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(width: 8),
                                Icon(Icons.arrow_forward_rounded, size: 20),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogo() {
    return Container(
      padding: const EdgeInsets.all(12), // Increased padding (was 8)
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B).withValues(alpha: 0.5),
        shape: BoxShape.circle,
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: const Icon(
        Icons.school,
        color: AppTheme.primaryLight,
        size: 28, // Increased size (was 20)
      ),
    );
  }
}

class _FeatureIcon extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _FeatureIcon({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: label,
      triggerMode: TooltipTriggerMode.longPress,
      preferBelow: false,
      child: Container(
        width: 64, // Occupies 64 width in the list
        alignment: Alignment.center, // Vertically centers the square
        child: Container(
          width: 64, // Explicit square size
          height: 64,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius:
                BorderRadius.circular(18), // Slightly squarer (was 20)
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Icon(icon, color: color, size: 32),
        ),
      ),
    );
  }
}

// Custom Widget for Type -> Pause -> Backspace -> Next
class _BackspaceTypewriter extends StatefulWidget {
  final List<String> phrases;
  final TextStyle textStyle;

  const _BackspaceTypewriter({
    required this.phrases,
    required this.textStyle,
  });

  @override
  State<_BackspaceTypewriter> createState() => _BackspaceTypewriterState();
}

class _BackspaceTypewriterState extends State<_BackspaceTypewriter> {
  String _currentText = "";
  int _phraseIndex = 0;
  int _charIndex = 0;
  bool _isBackspacing = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTyping();
  }

  void _startTyping() {
    const typeSpeed = Duration(milliseconds: 80);
    const backspaceSpeed = Duration(milliseconds: 50);
    const pauseAtEnd = Duration(milliseconds: 2000);

    _timer = Timer.periodic(typeSpeed, (timer) {
      if (!mounted) return;

      final currentPhrase = widget.phrases[_phraseIndex];

      setState(() {
        if (!_isBackspacing) {
          // Typing Forward
          if (_charIndex < currentPhrase.length) {
            _charIndex++;
            _currentText = currentPhrase.substring(0, _charIndex);
          } else {
            // Finished typing, pause then switch to backspace
            _timer?.cancel();
            Future.delayed(pauseAtEnd, () {
              if (mounted) {
                _isBackspacing = true;
                _startBackspacing(backspaceSpeed);
              }
            });
          }
        }
      });
    });
  }

  void _startBackspacing(Duration speed) {
    _timer = Timer.periodic(speed, (timer) {
      if (!mounted) return;

      setState(() {
        if (_charIndex > 0) {
          _charIndex--;
          final currentPhrase = widget.phrases[_phraseIndex];
          _currentText = currentPhrase.substring(0, _charIndex);
        } else {
          // Finished backspacing, move to next phrase
          _timer?.cancel();
          _isBackspacing = false;
          _phraseIndex = (_phraseIndex + 1) % widget.phrases.length;
          // Short pause before typing next
          Future.delayed(const Duration(milliseconds: 300), () {
            if (mounted) _startTyping();
          });
        }
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      "$_currentText|",
      style: widget.textStyle,
    );
  }
}

// Custom Widget for Infinite Scrolling Icons
class _ScrollingIconRow extends StatefulWidget {
  final List<Widget> children;
  const _ScrollingIconRow({required this.children});

  @override
  State<_ScrollingIconRow> createState() => _ScrollingIconRowState();
}

class _ScrollingIconRowState extends State<_ScrollingIconRow> {
  late final ScrollController _scrollController;
  Timer? _timer;
  double _scrollOffset = 0.0;

  // Speed: Pixels per 16ms frame. 1.0 is moderate speed.
  final double _scrollSpeed = 1.0;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    // Start scrolling after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startAutoScroll();
    });
  }

  void _startAutoScroll() {
    _timer = Timer.periodic(const Duration(milliseconds: 16), (timer) {
      if (!mounted) return;
      if (_scrollController.hasClients) {
        _scrollOffset += _scrollSpeed;
        _scrollController.jumpTo(_scrollOffset);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 80, // Increased height to accommodate bigger icons
      child: ListView.builder(
        controller: _scrollController,
        scrollDirection: Axis.horizontal,
        physics: const NeverScrollableScrollPhysics(),
        itemBuilder: (context, index) {
          final realIndex = index % widget.children.length;
          return Padding(
            padding: const EdgeInsets.only(
                right: 32.0), // Increased spacing (was 16)
            child: widget.children[realIndex],
          );
        },
      ),
    );
  }
}
