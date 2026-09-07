import 'package:flutter/material.dart';

/// The camera, as the one raised action on the screen — Lens is the gesture
/// the whole product is named for, so it does not queue up next to Link and
/// Search in a row of equals.
class LensFab extends StatelessWidget {
  const LensFab({required this.onTap, super.key});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Tooltip(
    message: 'Open Lens',
    child: GestureDetector(
      onTap: onTap,
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: .5),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: const Icon(
          Icons.center_focus_strong_rounded,
          color: Colors.black,
          size: 26,
        ),
      ),
    ),
  );
}
