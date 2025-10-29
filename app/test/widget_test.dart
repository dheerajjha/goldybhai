// Widget tests for Shop Rates app

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:shop_rates/main.dart';

void main() {
  testWidgets('App loads and shows Shop Rates title', (
    WidgetTester tester,
  ) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());
    await tester.pump(); // Wait for async operations

    // Verify that the app bar title is displayed
    expect(find.text('Shop Rates'), findsOneWidget);
  });

  testWidgets('App shows refresh button', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());
    await tester.pump(); // Wait for async operations

    // Verify that the refresh icon button exists
    expect(find.byIcon(Icons.refresh), findsOneWidget);
  });

  testWidgets('App shows create alert button', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());
    await tester.pump(); // Wait for async operations

    // Verify that the create alert floating action button exists
    expect(find.byIcon(Icons.add_alert), findsOneWidget);
    expect(find.text('Create Alert'), findsOneWidget);
  });
}
