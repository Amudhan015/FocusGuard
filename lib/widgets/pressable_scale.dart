import 'package:flutter/material.dart';

/// Wraps any tappable content with immediate, physical-feeling press
/// feedback: scales down the instant the finger touches down
/// (onTapDown), not when it lifts - per the design skill's "response"
/// principle, latency between touch and feedback is what makes an
/// interface feel like a computer instead of a direct extension of the
/// hand. Respects MediaQuery.disableAnimations (reduced motion) by
/// skipping the scale and keeping just the tap behavior.
///
/// Used anywhere a card/row is a single, un-nested tap target (template
/// cards, filter chips-adjacent controls). Not used on rows containing
/// their own nested interactive children (switches, icon buttons) to
/// avoid gesture-arena conflicts.
class PressableScale extends StatefulWidget {
  const PressableScale({
    super.key,
    required this.child,
    required this.onTap,
    this.pressedScale = 0.97,
  });

  final Widget child;
  final VoidCallback onTap;
  final double pressedScale;

  @override
  State<PressableScale> createState() => _PressableScaleState();
}

class _PressableScaleState extends State<PressableScale> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed == value) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.of(context).disableAnimations;

    return GestureDetector(
      onTapDown: (_) => _setPressed(true),
      onTapCancel: () => _setPressed(false),
      onTapUp: (_) => _setPressed(false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: (_pressed && !reduceMotion) ? widget.pressedScale : 1.0,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}
