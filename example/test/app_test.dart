import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nerve_example/main.dart';

void main() {
  testWidgets('example renders the Nerve launcher', (tester) async {
    await tester.pumpWidget(const NerveExampleApp());

    expect(find.text('Nerve Example'), findsOneWidget);
    expect(find.byIcon(Icons.bolt_rounded), findsOneWidget);
  });

  testWidgets('example exposes editable debug settings', (tester) async {
    await tester.pumpWidget(const NerveExampleApp());

    await tester.tap(find.byIcon(Icons.bolt_rounded));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.arrow_back_ios_new_rounded));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();

    expect(find.text('Environment'), findsOneWidget);
    expect(find.text('Force review mode'), findsOneWidget);
    expect(find.text('API host'), findsOneWidget);
  });
}
