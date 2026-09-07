import 'package:flutter/material.dart';

/// Page indicator: the active dot stretches into a bar.
class PageDots extends StatelessWidget {
  const PageDots({required this.page, required this.count, super.key});

  final int page;
  final int count;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: List.generate(
      count,
      (index) => AnimatedContainer(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
        width: index == page ? 24 : 5,
        height: 5,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: index == page ? Colors.white : const Color(0xFF31414A),
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    ),
  );
}
