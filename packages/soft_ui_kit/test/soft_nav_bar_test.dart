import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soft_ui_kit/soft_ui_kit.dart';

void main() {
  testWidgets('SoftNavBar reports taps', (tester) async {
    var index = 0;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(AccentOption.teal.seed),
        home: Scaffold(
          body: const SizedBox.expand(),
          bottomNavigationBar: SoftNavBar(
            currentIndex: 0,
            onTap: (i) => index = i,
            items: const [
              SoftNavItem(icon: Icon(Icons.home_outlined), label: 'Home'),
              SoftNavItem(icon: Icon(Icons.history), label: 'History'),
            ],
          ),
        ),
      ),
    );

    await tester.tap(find.text('History'));
    expect(index, 1);
  });
}
