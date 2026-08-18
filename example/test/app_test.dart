import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nerve_example/main.dart';

void main() {
  testWidgets('example renders the Nerve launcher', (tester) async {
    await tester.pumpWidget(const NerveExampleApp());

    expect(find.text('Nerve Example'), findsOneWidget);
    expect(find.byIcon(Icons.bolt_rounded), findsOneWidget);
  });
}
