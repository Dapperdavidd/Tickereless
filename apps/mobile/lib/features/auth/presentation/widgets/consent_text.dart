import 'package:flutter/material.dart';

class ConsentText extends StatelessWidget {
  const ConsentText({super.key});

  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.fromLTRB(28, 0, 28, 11),
    child: Text.rich(
      TextSpan(
        text: 'By continuing, you agree to our ',
        children: [
          TextSpan(
            text: 'Terms & Conditions',
            style: TextStyle(
              color: Color(0xFFD7E3E9),
              decoration: TextDecoration.underline,
              decorationColor: Color(0xFFD7E3E9),
            ),
          ),
          TextSpan(text: '.'),
        ],
      ),
      textAlign: TextAlign.center,
      style: TextStyle(color: Color(0xFF71808A), fontSize: 10, height: 1.35),
    ),
  );
}
