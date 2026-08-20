import 'package:flutter/material.dart';

/// Closes the keyboard when the user taps blank space.
///
/// Wraps the whole app (see `SapbaqAdminApp.build`) because most screens have
/// no other way to dismiss the keyboard once a field is focused. Taps on
/// fields, buttons and other widgets are unaffected: their recognizers sit
/// deeper in the tree and so win the gesture arena, and a drag (scroll) beats a
/// tap outright.
class DismissKeyboardOnTap extends StatelessWidget {
  final Widget child;

  const DismissKeyboardOnTap({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      // Blank space is often not covered by a hit-testable child; translucent
      // makes those taps reach us anyway.
      behavior: HitTestBehavior.translucent,
      // Without this the whole app becomes one big "tappable" node to
      // TalkBack/VoiceOver.
      excludeFromSemantics: true,
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: child,
    );
  }
}
