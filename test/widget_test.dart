import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mobile_app_dev_25_26/main.dart';

void main() {
  testWidgets('App launches and shows FBLA Connect', (WidgetTester tester) async {
    await tester.pumpWidget(const FBLAApp());
    await tester.pumpAndSettle();

    expect(find.text('FBLA Connect'), findsOneWidget);
  });

  testWidgets('Bottom nav switches tabs', (WidgetTester tester) async {
    await tester.pumpWidget(const FBLAApp());
    await tester.pumpAndSettle();

    expect(find.text('Events'), findsOneWidget);
    await tester.tap(find.text('Events'));
    await tester.pumpAndSettle();

    expect(find.text('UPCOMING EVENTS'), findsOneWidget);
  });

  testWidgets('Dashboard shows points', (WidgetTester tester) async {
    await tester.pumpWidget(const FBLAApp());
    await tester.pumpAndSettle();

    expect(find.textContaining('points earned this year'), findsOneWidget);
  });

  testWidgets('Profile tab shows user name', (WidgetTester tester) async {
    await tester.pumpWidget(const FBLAApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Me'));
    await tester.pumpAndSettle();

    expect(find.text('Alex Johnson'), findsWidgets);
  });

  testWidgets('Reports tab shows report list', (WidgetTester tester) async {
    await tester.pumpWidget(const FBLAApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Reports'));
    await tester.pumpAndSettle();

    expect(find.text('Block Report'), findsOneWidget);
    expect(find.text('Financial Report'), findsOneWidget);
  });
}