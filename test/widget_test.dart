// Basic Flutter widget test for GhClient app
//
// This is a smoke test to verify the app can be built and rendered.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ghclient/common/utils/date_formatter.dart';
import 'package:ghclient/common/widgets/empty_state.dart';
import 'package:ghclient/common/widgets/skeleton_loader.dart';

void main() {
  group('DateFormatter', () {
    test('format returns correct format for valid ISO date', () {
      // Using a fixed UTC date to avoid timezone issues in tests
      final result = DateFormatter.format('2024-12-22T10:30:45Z');
      // Should contain date parts
      expect(result.contains('2024'), isTrue);
      expect(result.contains('12'), isTrue);
      expect(result.contains('22'), isTrue);
    });

    test('format returns original string for invalid date', () {
      final result = DateFormatter.format('invalid-date');
      expect(result, equals('invalid-date'));
    });

    test('dateOnly returns correct format', () {
      final result = DateFormatter.dateOnly('2024-12-22T10:30:45Z');
      // Should contain date parts only
      expect(result.contains('2024'), isTrue);
      expect(result.contains('12'), isTrue);
      expect(result.contains('22'), isTrue);
      // Should not contain time separator
      expect(result.contains(':'), isFalse);
    });

    test('relative returns relative time string', () {
      // Test with a date from the past
      final pastDate = DateTime.now().subtract(const Duration(hours: 2));
      final result = DateFormatter.relative(pastDate.toIso8601String());
      expect(result.contains('小时前'), isTrue);
    });
  });

  group('EmptyState Widget', () {
    testWidgets('renders with required properties', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: EmptyState(
              icon: Icons.inbox,
              title: 'No Items',
              message: 'There are no items to display',
            ),
          ),
        ),
      );

      expect(find.text('No Items'), findsOneWidget);
      expect(find.text('There are no items to display'), findsOneWidget);
      expect(find.byIcon(Icons.inbox), findsOneWidget);
    });

    testWidgets('renders action button when provided', (WidgetTester tester) async {
      bool actionCalled = false;
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EmptyState(
              icon: Icons.inbox,
              title: 'No Items',
              message: 'There are no items to display',
              actionLabel: 'Add Item',
              onAction: () => actionCalled = true,
            ),
          ),
        ),
      );

      expect(find.text('Add Item'), findsOneWidget);
      
      await tester.tap(find.text('Add Item'));
      expect(actionCalled, isTrue);
    });
  });

  group('SkeletonLoader Widget', () {
    testWidgets('renders overview skeleton', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SkeletonLoader(type: SkeletonType.overview),
          ),
        ),
      );

      // Should render without errors
      expect(find.byType(SkeletonLoader), findsOneWidget);
    });

    testWidgets('renders list skeleton with items', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SkeletonLoader(type: SkeletonType.list, itemCount: 3),
          ),
        ),
      );

      expect(find.byType(SkeletonLoader), findsOneWidget);
    });

    testWidgets('renders card skeleton', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SkeletonLoader(type: SkeletonType.card),
          ),
        ),
      );

      expect(find.byType(SkeletonLoader), findsOneWidget);
    });
  });
}
