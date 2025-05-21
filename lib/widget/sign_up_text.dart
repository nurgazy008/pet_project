import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import 'package:flutter_application_3/screens/sign_up_screen.dart';

class SignupText extends StatelessWidget {
  const SignupText({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: RichText(
        text: TextSpan(
          text: "Don't have an account? ",
          style: const TextStyle(color: Colors.black),
          children: [
            TextSpan(
              text: 'Sign Up',
              style: const TextStyle(
                color: Colors.blue,
                decoration: TextDecoration.underline,
                fontWeight: FontWeight.bold,
              ),
              recognizer: TapGestureRecognizer()
                ..onTap = () {
                  Navigator.push(context, MaterialPageRoute(
                    builder: (context) {
                      return SignUpScreen();
                    },
                  ));
                },
            ),
          ],
        ),
      ),
    );
  }
}
