import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:verstobbertje/presentation/cover_screen.dart';

void main() {
  testWidgets('cover opens the app through one clear action', (tester) async {
    var entered = false;
    await tester.pumpWidget(
      MaterialApp(
        home: CoverScreen(onEnter: () => entered = true),
      ),
    );

    expect(find.text('Verstobbertje'), findsOneWidget);
    expect(find.text('Zoek. Verstop. Beweeg. Beleef.'), findsOneWidget);
    expect(find.byKey(const Key('stobbekarakter-normaal')), findsOneWidget);
    expect(find.byKey(const Key('stobbekarakter-welkom')), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 1200));

    final welcomeOpacity = tester.widget<Opacity>(
      find.byKey(const Key('stobbekarakter-welkom-opacity')),
    );
    expect(welcomeOpacity.opacity, greaterThan(0.9));

    await tester.tap(find.text('Aan de slag'));

    expect(entered, isTrue);
  });
}
