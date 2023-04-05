// ignore_for_file: library_private_types_in_public_api

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AwesomeBouncingWidget extends StatefulWidget {
  const AwesomeBouncingWidget({
    Key? key,
    required this.child,
    this.onTap,
    this.disabledOpacity = 0.3,
    this.vibrationEnabled = true,
    this.duration = const Duration(milliseconds: 100),
  }) : super(key: key);

  final Widget child;
  final VoidCallback? onTap;
  final double disabledOpacity;
  final Duration duration;
  final bool? vibrationEnabled;

  @override
  _AwesomeBouncingWidgetState createState() => _AwesomeBouncingWidgetState();
}

class _AwesomeBouncingWidgetState extends State<AwesomeBouncingWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController? _controller;
  late double _scale;

  @override
  void initState() {
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
      lowerBound: 0.0,
      upperBound: 0.1,
    )..addListener(() {
        setState(() {});
      });
    super.initState();
  }

  @override
  void dispose() {
    _controller!.stop();
    _controller!.dispose();
    _controller = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _scale = 1 - _controller!.value;

    return IgnorePointer(
      ignoring: widget.onTap == null,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: (widget.onTap != null) ? 1.0 : widget.disabledOpacity,
        child: GestureDetector(
          onTapDown: _onTapDown,
          onTapUp: _onTapUp,
          onTapCancel: _onTapCancel,
          child: Transform.scale(
            scale: _scale,
            child: widget.child,
          ),
        ),
      ),
    );
  }

  void _onTapDown(TapDownDetails details) {
    if (widget.vibrationEnabled == true) {
      HapticFeedback.selectionClick();
    }
    _controller?.forward.call();
  }

  void _onTapUp(TapUpDetails details) {
    Future.delayed(widget.duration, () {
      _controller?.reverse.call();
    });
    widget.onTap?.call();
  }

  void _onTapCancel() {
    _controller?.reverse.call();
  }
}
