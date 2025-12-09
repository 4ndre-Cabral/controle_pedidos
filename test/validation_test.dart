import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:controle_pedidos/screens/solicitar_page.dart';
import 'package:controle_pedidos/models/pedido_item.dart';
import 'package:flutter/services.dart';
import 'package:controle_pedidos/services/excel_service.dart';
import 'dart:io';

void main() {
  testWidgets('SolicitarPage validation logic test', (WidgetTester tester) async {
    // Mock Path Provider
    const MethodChannel channel = MethodChannel('plugins.flutter.io/path_provider');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, (MethodCall methodCall) async {
      return Directory.systemTemp.path;
    });

    // Init and Pre-populate Excel Service
    final service = ExcelService();
    await service.init();
    
    // Clear existing data (mock specific if needed, but here we just rely on fresh init or explicit IDs)
    // Add existing PEDIDO
    final existingPedido = PedidoItem(
        id: 'existing1', 
        code: 'VAL001', 
        description: 'Existing Item', 
        quantity: 10, 
        arrivalDate: DateTime.now()
    );
     // Add another for diff test
    final existingPedidoDiff = PedidoItem(
        id: 'existing2', 
        code: 'VAL002', 
        description: 'Diff Item', 
        quantity: 5, 
        arrivalDate: DateTime.now()
    );

    await service.savePedido(existingPedido);
    await service.savePedido(existingPedidoDiff);

    // Build App
    await tester.pumpWidget(const MaterialApp(home: SolicitarPage()));

    // --- CASE 1: BLOCKING (Qty <= Existing) ---
    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();

    await tester.enterText(find.widgetWithText(TextField, 'Código'), 'VAL001');
    await tester.enterText(find.widgetWithText(TextField, 'Descrição'), 'New Request');
    await tester.enterText(find.widgetWithText(TextField, 'Quantidade'), '5'); // Less than 10
    
    await tester.tap(find.text('Salvar'));
    await tester.pumpAndSettle();

    // Verify Error Dialog
    expect(find.text('Item já existe'), findsOneWidget);
    expect(find.textContaining('quantidade 10'), findsOneWidget);
    
    // Close Dialog
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    // Close Form
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();

    // Verify nothing added
    expect(find.text('New Request'), findsNothing);


    // --- CASE 2: DIFF (Qty > Existing) ---
    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();

    await tester.enterText(find.widgetWithText(TextField, 'Código'), 'VAL002');
    await tester.enterText(find.widgetWithText(TextField, 'Descrição'), 'Diff Request');
    await tester.enterText(find.widgetWithText(TextField, 'Quantidade'), '15'); // 15 - 5 = 10 difference
    
    await tester.tap(find.text('Salvar'));
    await tester.pumpAndSettle();

    // Verify Confirmation Dialog
    expect(find.text('Ajuste de Quantidade'), findsOneWidget);
    expect(find.textContaining('diferença (10)'), findsOneWidget);
    
    // Confirm Add Difference
    await tester.tap(find.text('Sim'));
    await tester.pumpAndSettle();

    // Verify Item Added with Qty 10
    expect(find.text('Diff Request'), findsOneWidget);
    expect(find.textContaining('10'), findsOneWidget); 
    
    // Check for Duplicate Indicator Icon
    await tester.pumpAndSettle(); // Ensure UI updates
    expect(find.byIcon(Icons.info_outline), findsOneWidget);
    expect(find.byTooltip('Item presente em Pedidos'), findsOneWidget);
  });
}
