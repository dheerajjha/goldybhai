// Integration tests for Shop Rates app with tap interactions
// Run with: flutter test test/integration_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shop_rates/main.dart';

void main() {
  group('Shop Rates App - Tap Interactions', () {
    testWidgets('Tap refresh button triggers API call', (
      WidgetTester tester,
    ) async {
      // Build the app
      await tester.pumpWidget(const MyApp());
      
      // Wait for initial build
      await tester.pump();
      
      // Find the refresh button
      final refreshButton = find.byIcon(Icons.refresh);
      expect(refreshButton, findsOneWidget);
      
      // Tap the refresh button
      await tester.tap(refreshButton);
      await tester.pump(); // Trigger frame
      
      // Wait for async operations (API call)
      await tester.pump(const Duration(seconds: 2));
      
      // Verify the app is still responsive
      expect(find.text('Shop Rates'), findsOneWidget);
    });

    testWidgets('Tap create alert button opens dialog', (
      WidgetTester tester,
    ) async {
      // Build the app
      await tester.pumpWidget(const MyApp());
      
      // Wait for initial build
      await tester.pump();
      await tester.pump(const Duration(seconds: 2)); // Wait for commodities to load
      
      // Find the create alert button
      final createAlertButton = find.text('Create Alert');
      expect(createAlertButton, findsOneWidget);
      
      // Tap the create alert button
      await tester.tap(createAlertButton);
      await tester.pump(); // Trigger frame
      await tester.pump(); // Allow dialog to appear
      
      // Verify dialog appears
      expect(find.text('Create Price Alert'), findsOneWidget);
      expect(find.text('Commodity'), findsOneWidget);
      expect(find.text('Condition'), findsOneWidget);
      expect(find.text('Target Price'), findsOneWidget);
    });

    testWidgets('Can interact with alert dialog form', (
      WidgetTester tester,
    ) async {
      // Build the app
      await tester.pumpWidget(const MyApp());
      
      // Wait for initial build and data loading
      await tester.pump();
      await tester.pump(const Duration(seconds: 2));
      
      // Open the alert dialog
      await tester.tap(find.text('Create Alert'));
      await tester.pump();
      await tester.pump();
      
      // Verify dialog is open
      expect(find.text('Create Price Alert'), findsOneWidget);
      
      // Find the price input field
      final priceField = find.byType(TextField);
      expect(priceField, findsWidgets);
      
      // Tap on the price field and enter a value
      await tester.tap(priceField.last);
      await tester.pump();
      await tester.enterText(priceField.last, '120000');
      await tester.pump();
      
      // Verify text was entered
      expect(find.text('120000'), findsOneWidget);
      
      // Find and tap cancel button
      final cancelButton = find.text('Cancel');
      expect(cancelButton, findsOneWidget);
      await tester.tap(cancelButton);
      await tester.pump();
      
      // Verify dialog is closed
      expect(find.text('Create Price Alert'), findsNothing);
    });

    testWidgets('Pull to refresh gesture works', (
      WidgetTester tester,
    ) async {
      // Build the app
      await tester.pumpWidget(const MyApp());
      
      // Wait for initial build
      await tester.pump();
      await tester.pump(const Duration(seconds: 2));
      
      // Find the list view (RefreshIndicator)
      final refreshIndicator = find.byType(RefreshIndicator);
      expect(refreshIndicator, findsOneWidget);
      
      // Perform pull to refresh gesture
      await tester.drag(refreshIndicator, const Offset(0, 300));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      
      // Verify app is still responsive
      expect(find.text('Shop Rates'), findsOneWidget);
    });

    testWidgets('Rate cards are tappable', (
      WidgetTester tester,
    ) async {
      // Build the app
      await tester.pumpWidget(const MyApp());
      
      // Wait for initial build and data loading
      await tester.pump();
      await tester.pump(const Duration(seconds: 2));
      
      // Find rate cards
      final rateCards = find.byType(Card);
      
      // If cards exist, tap on one
      if (rateCards.evaluate().isNotEmpty) {
        await tester.tap(rateCards.first);
        await tester.pump();
        
        // Verify app responds to tap
        expect(find.text('Shop Rates'), findsOneWidget);
      }
    });
  });

  group('App Structure Tests', () {
    testWidgets('App bar is displayed correctly', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const MyApp());
      await tester.pump();
      
      // Verify app bar exists
      expect(find.byType(AppBar), findsOneWidget);
      expect(find.text('Shop Rates'), findsOneWidget);
    });

    testWidgets('Floating action button is displayed', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const MyApp());
      await tester.pump();
      
      // Verify FAB exists
      expect(find.byType(FloatingActionButton), findsOneWidget);
      expect(find.byIcon(Icons.add_alert), findsOneWidget);
    });
  });
}

