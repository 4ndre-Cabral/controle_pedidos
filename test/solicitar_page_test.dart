import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:controle_pedidos/screens/solicitar_page.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import 'package:controle_pedidos/services/excel_service.dart';
import 'dart:io';

void main() {
  testWidgets('SolicitarPage item management and send smoke test', (WidgetTester tester) async {
    // Mock Path Provider
    const MethodChannel channel = MethodChannel('plugins.flutter.io/path_provider');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, (MethodCall methodCall) async {
      return Directory.systemTemp.path;
    });

    // Init Excel Service
    await ExcelService().init();

    // Build our app and trigger a frame.
    await tester.pumpWidget(const MaterialApp(home: SolicitarPage()));

    // Add Item
    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();

    await tester.enterText(find.widgetWithText(TextField, 'Código'), 'SEND001');
    await tester.enterText(find.widgetWithText(TextField, 'Descrição'), 'Send Item');
    await tester.enterText(find.widgetWithText(TextField, 'Quantidade'), '20');
    
    await tester.tap(find.text('Salvar'));
    await tester.pumpAndSettle();

    // Verify item added
    expect(find.text('Send Item'), findsOneWidget);

    // Click Send
    await tester.tap(find.byIcon(Icons.send));
    await tester.pumpAndSettle();

    // Verify Dialog
    expect(find.text('Enviar para Pedidos?'), findsOneWidget);
    expect(find.text('Alterar Data'), findsOneWidget);

    // Confirm
    await tester.tap(find.text('Confirmar'));
    await tester.pumpAndSettle();

    // Verify item removed (Moved)
    expect(find.text('Send Item'), findsNothing);
    expect(find.text('Item enviado para Pedidos!'), findsOneWidget);

    // Add another item for DELETE test
    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextField, 'Código'), 'DEL001');
    await tester.enterText(find.widgetWithText(TextField, 'Descrição'), 'Delete Me');
    await tester.enterText(find.widgetWithText(TextField, 'Quantidade'), '5');
    await tester.tap(find.text('Salvar'));
    await tester.pumpAndSettle();

    // Delete Item
    await tester.tap(find.byIcon(Icons.delete));
    await tester.pumpAndSettle();

    // Verify Delete Dialog
    expect(find.text('Excluir item?'), findsOneWidget);
    
    // Confirm Delete
    await tester.tap(find.text('Excluir'));
    await tester.pumpAndSettle();

    expect(find.text('Delete Me'), findsNothing);
  });
}
