import 'package:flutter/material.dart';

/// The plain titled scaffold every secondary flow screen sits in.
class FlowScaffold extends StatelessWidget {
  const FlowScaffold({required this.title, required this.child, super.key});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(title)),
    body: child,
  );
}
