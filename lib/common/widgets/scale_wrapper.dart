import 'package:flutter/material.dart';

class ScaleWrapper extends StatefulWidget {
  final Widget child;
  final double pressedScale;
  final Duration duration;

  const ScaleWrapper({
    super.key,
    required this.child,
    this.pressedScale = 0.96,
    this.duration = const Duration(milliseconds: 100),
  });

  @override
  State<ScaleWrapper> createState() => _ScaleWrapperState();
}

class _ScaleWrapperState extends State<ScaleWrapper>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
      reverseDuration: widget.duration,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: widget.pressedScale,
    ).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) => _controller.forward(),
      onPointerUp: (_) => _controller.reverse(),
      onPointerCancel: (_) => _controller.reverse(),
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: widget.child,
      ),
    );
  }
}
