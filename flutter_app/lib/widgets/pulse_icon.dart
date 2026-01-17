import 'package:flutter/material.dart';

class PulseIcon extends StatefulWidget {
  final Widget child;
  final bool isSelected;
  final Duration duration;

  const PulseIcon({
    super.key,
    required this.child,
    required this.isSelected,
    this.duration = const Duration(milliseconds: 400),
  });

  @override
  State<PulseIcon> createState() => _PulseIconState();
}

class _PulseIconState extends State<PulseIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );

    // Animate 1.0 -> 1.3 -> 1.0
    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 1.3)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 50,
      ),
      TweenSequenceItem(
        tween:
            Tween(begin: 1.3, end: 1.0).chain(CurveTween(curve: Curves.easeIn)),
        weight: 50,
      ),
    ]).animate(_controller);
  }

  @override
  void didUpdateWidget(PulseIcon oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isSelected && !oldWidget.isSelected) {
      _controller.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: widget.child,
    );
  }
}
