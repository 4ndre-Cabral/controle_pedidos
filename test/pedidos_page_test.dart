import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:controle_pedidos/screens/pedidos_page.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import 'package:controle_pedidos/services/excel_service.dart';
import 'dart:io';

void main() {
  testWidgets('PedidosPage item management smoke test', (WidgetTester tester) async {
    // Mock Path Provider
    const MethodChannel channel = MethodChannel('plugins.flutter.io/path_provider');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, (MethodCall methodCall) async {
      return Directory.systemTemp.path;
    });

    // Init Excel Service
    await ExcelService().init();

    // Build our app and trigger a frame.
    await tester.pumpWidget(const MaterialApp(home: PedidosPage()));

    // Verify empty state.
    expect(find.text('Nenhum pedido cadastrado.'), findsOneWidget);

    // Add Item
    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();

    await tester.enterText(find.widgetWithText(TextField, 'Código'), 'PED001');
    await tester.enterText(find.widgetWithText(TextField, 'Descrição'), 'Test Pedido');
    await tester.enterText(find.widgetWithText(TextField, 'Quantidade'), '5');
    
    // Verify Date Picker trigger (simplified check)
    expect(find.text('Alterar Data'), findsOneWidget);

    await tester.tap(find.text('Salvar'));
    await tester.pumpAndSettle();

    // Verify item added
    expect(find.text('Test Pedido'), findsOneWidget);
    expect(find.text('PED001'), findsOneWidget);
    // Check formatted date string - using current date as default
    expect(find.text('5  ${DateFormat('dd/MM/yyyy').format(DateTime.now())}'), findsOneWidget);

    // Verify NO Send button
    expect(find.byIcon(Icons.send), findsNothing);
    // Verify Edit and Delete buttons exist
    expect(find.byIcon(Icons.edit), findsOneWidget);
    expect(find.byIcon(Icons.delete), findsOneWidget);

    // Delete Item
    await tester.tap(find.byIcon(Icons.delete));
    await tester.pumpAndSettle();

    // Verify confirmation dialog
    expect(find.text('Excluir pedido?'), findsOneWidget);

    // Confirm
    await tester.tap(find.text('Excluir'));
    await tester.pumpAndSettle();

    expect(find.text('Nenhum pedido cadastrado.'), findsOneWidget);
  });
}
