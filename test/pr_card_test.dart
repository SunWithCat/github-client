import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ghclient/pages/repo_detail/pr_card.dart';

void main() {
  testWidgets('点击 PR 卡片会触发 onTap', (tester) async {
    var tapped = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PrCard(
            pr: {
              'title': 'Fix login',
              'number': 12,
              'state': 'open',
              'user': {'login': 'octocat'},
              'created_at': DateTime.now().toUtc().toIso8601String(),
              'head': {'ref': 'feature'},
              'base': {'ref': 'main'},
              'labels': [],
            },
            onTap: () => tapped = true,
          ),
        ),
      ),
    );

    await tester.tap(find.text('Fix login'));
    await tester.pump();

    expect(tapped, isTrue);
  });
}
