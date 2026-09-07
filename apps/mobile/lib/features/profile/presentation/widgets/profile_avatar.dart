import 'dart:io';

import 'package:flutter/material.dart';

class ProfileAvatar extends StatelessWidget {
  const ProfileAvatar({
    required this.index,
    this.photoPath,
    this.size = 64,
    super.key,
  });
  final int index;
  final String? photoPath;
  final double size;

  static const icons = [
    Icons.bolt_rounded,
    Icons.diamond_outlined,
    Icons.auto_awesome_rounded,
    Icons.blur_circular_rounded,
    Icons.change_history_rounded,
    Icons.graphic_eq_rounded,
  ];
  static const colors = [
    Color(0xFF48C7FF),
    Color(0xFF9B7BFF),
    Color(0xFFFFB24A),
    Color(0xFF54E19E),
    Color(0xFFFF6F91),
    Color(0xFFB6F13B),
  ];

  @override
  Widget build(BuildContext context) {
    final path = photoPath;
    if (path != null && File(path).existsSync()) {
      return ClipOval(
        child: Image.file(
          File(path),
          width: size,
          height: size,
          fit: BoxFit.cover,
        ),
      );
    }
    final safe = index.clamp(0, icons.length - 1);
    final color = colors[safe];
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color, Color.lerp(color, Colors.black, .55)!],
        ),
      ),
      child: Icon(icons[safe], color: Colors.black, size: size * .44),
    );
  }
}
