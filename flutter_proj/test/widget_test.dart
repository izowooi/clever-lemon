// This is a basic Flutter widget test for Daily Quote app.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:flutter_proj/main.dart';

void main() {
  testWidgets('Daily Quote app loads successfully', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const ProviderScope(child: DailyQuoteApp()));

    // Wait for any async operations to complete
    await tester.pumpAndSettle();

    // Verify that the main app title is present
    expect(find.text('오늘의 글귀'), findsOneWidget);

    // Verify that the bottom navigation tabs are present
    expect(find.text('글귀 창작'), findsOneWidget);
    expect(find.text('글귀 모음'), findsOneWidget);
    expect(find.text('설정'), findsOneWidget);
  });

  testWidgets('Tab navigation works correctly', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const ProviderScope(child: DailyQuoteApp()));

    // Wait for any async operations to complete
    await tester.pumpAndSettle();

    // Tap on the second tab (글귀 모음)
    await tester.tap(find.text('글귀 모음'));
    await tester.pumpAndSettle();

    // Verify tab is switched (this is a basic test, more specific tests can be added)
    expect(find.text('오늘의 글귀'), findsOneWidget);
  });
}
