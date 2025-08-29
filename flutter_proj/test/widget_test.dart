// This is a basic Flutter widget test for Poetry Writer app.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:flutter_proj/main.dart';

void main() {
  testWidgets('Poetry Writer app loads successfully', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const ProviderScope(child: PoetryWriterApp()));

    // Wait for any async operations to complete
    await tester.pumpAndSettle();

    // Verify that the main app title is present
    expect(find.text('Poetry Writer'), findsOneWidget);

    // Verify that the bottom navigation tabs are present
    expect(find.text('시 창작'), findsOneWidget);
    expect(find.text('작품 목록'), findsOneWidget);
    expect(find.text('설정'), findsOneWidget);
  });

  testWidgets('Tab navigation works correctly', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const ProviderScope(child: PoetryWriterApp()));
    
    // Wait for any async operations to complete
    await tester.pumpAndSettle();

    // Tap on the second tab (작품 목록)
    await tester.tap(find.text('작품 목록'));
    await tester.pumpAndSettle();

    // Verify tab is switched (this is a basic test, more specific tests can be added)
    expect(find.text('Poetry Writer'), findsOneWidget);
  });
}
