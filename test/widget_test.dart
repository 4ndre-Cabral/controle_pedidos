import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:controle_pedidos/main.dart';

void main() {
  testWidgets('Drawer navigation smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());

    // Verify that we are on the home page.
    expect(find.text('Menu Inicial'), findsOneWidget);
    expect(find.text('Solicitar'), findsNothing); // Should be in drawer

    // Open the drawer.
    await tester.tap(find.byIcon(Icons.menu));
    await tester.pumpAndSettle();

    // Verify Drawer items are visible.
    expect(find.text('Solicitar'), findsOneWidget);
    expect(find.text('Pedidos'), findsOneWidget);

    // Tap 'Solicitar'.
    await tester.tap(find.text('Solicitar'));
    await tester.pumpAndSettle();

    // Verify we are on Solicitar page.
    expect(find.text('Nenhum item solicitado.'), findsOneWidget);
  });
}
