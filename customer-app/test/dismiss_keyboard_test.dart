import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sapbaq/core/widgets/dismiss_keyboard.dart';

void main() {
  Widget harness({required FocusNode node, VoidCallback? onPressed}) {
    return MaterialApp(
      home: DismissKeyboardOnTap(
        child: Scaffold(
          body: Column(
            children: [
              TextField(focusNode: node),
              ElevatedButton(
                onPressed: onPressed ?? () {},
                child: const Text('go'),
              ),
              // Empty area: nothing here hit-tests, so only the app-wide
              // detector can pick the tap up.
              const Expanded(child: SizedBox.expand(key: Key('blank'))),
            ],
          ),
        ),
      ),
    );
  }

  FocusNode makeNode() {
    final node = FocusNode();
    addTearDown(node.dispose);
    return node;
  }

  testWidgets('tapping blank space dismisses the keyboard', (tester) async {
    final node = makeNode();
    await tester.pumpWidget(harness(node: node));

    await tester.tap(find.byType(TextField));
    await tester.pump();
    expect(node.hasFocus, isTrue, reason: 'field should focus when tapped');

    await tester.tapAt(tester.getCenter(find.byKey(const Key('blank'))));
    await tester.pump();

    expect(node.hasFocus, isFalse);
  });

  testWidgets('tapping the field itself keeps the keyboard open', (
    tester,
  ) async {
    final node = makeNode();
    await tester.pumpWidget(harness(node: node));

    await tester.tap(find.byType(TextField));
    await tester.pump();

    expect(node.hasFocus, isTrue);
  });

  testWidgets('buttons still receive their taps', (tester) async {
    final node = makeNode();
    var pressed = 0;
    await tester.pumpWidget(harness(node: node, onPressed: () => pressed++));

    await tester.tap(find.text('go'));
    await tester.pump();

    expect(pressed, 1);
  });

  testWidgets('dragging still scrolls', (tester) async {
    final controller = ScrollController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: DismissKeyboardOnTap(
          child: Scaffold(
            body: ListView(
              controller: controller,
              children: [
                for (var i = 0; i < 40; i++)
                  SizedBox(height: 60, child: Text('row $i')),
              ],
            ),
          ),
        ),
      ),
    );

    await tester.drag(find.byType(ListView), const Offset(0, -200));
    await tester.pump();

    // Not the full 200: the drag's first pixels go to touch slop.
    expect(controller.offset, greaterThan(100));
  });
}
