import 'package:flutter/material.dart';

class TickerlessWordmark extends StatelessWidget {
  const TickerlessWordmark({super.key, this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) => Text(
    'T I C K E R L E S S',
    style: TextStyle(
      fontSize: compact ? 11 : 13,
      fontWeight: FontWeight.w700,
      letterSpacing: compact ? 1.6 : 2.2,
    ),
  );
}
