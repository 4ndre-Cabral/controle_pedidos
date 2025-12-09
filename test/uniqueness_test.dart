import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:controle_pedidos/screens/solicitar_page.dart';
import 'package:controle_pedidos/screens/pedidos_page.dart';
import 'package:controle_pedidos/models/solicitation_item.dart';
import 'package:controle_pedidos/models/pedido_item.dart';
import 'package:flutter/services.dart';
import 'package:controle_pedidos/services/excel_service.dart';
import 'dart:io';

void main() {
  setUp(() async {
      // Mock Path Provider
    const MethodChannel channel = MethodChannel('plugins.flutter.io/path_provider');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, (MethodCall methodCall) async {
      return Directory.systemTemp.path;
    });
    
    // Reset Excel Service
    final service = ExcelService();
    await service.init();
    
    // Manually clear (mock doesnt support explicit clear, but new runs usually clean if using temp)
    // For this test we assume start empty/clean or IDs wont collide unless intended
    // Actually, persistence in tests might persist across tests if using same file. 
    // Best to clean manually if we could, but here we will use Safe unique codes for the test run.
  });

  testWidgets('SolicitarPage uniqueness test', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: SolicitarPage()));
    final service = ExcelService();

    // 1. Add Item A
    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextField, 'Código'), 'UNIQ01');
    await tester.enterText(find.widgetWithText(TextField, 'Descrição'), 'Unique 1');
    await tester.enterText(find.widgetWithText(TextField, 'Quantidade'), '10');
    await tester.tap(find.text('Salvar'));
    await tester.pumpAndSettle();
    
    // Verify Added
    expect(find.text('UNIQ01'), findsOneWidget);

    // 2. Try Add Item A again
    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextField, 'Código'), 'UNIQ01');
    await tester.enterText(find.widgetWithText(TextField, 'Descrição'), 'Duplicate');
    await tester.enterText(find.widgetWithText(TextField, 'Quantidade'), '10');
    await tester.tap(find.text('Salvar'));
    await tester.pumpAndSettle();

    // Verify Error Dialog
    expect(find.text('Código Inválido'), findsOneWidget);
    expect(find.text('Este código já existe na lista de Solicitações.'), findsOneWidget);
    
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();
  });

  testWidgets('PedidosPage uniqueness test', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: PedidosPage()));
    
    // 1. Add Item B
    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextField, 'Código'), 'UNIQ02');
    await tester.enterText(find.widgetWithText(TextField, 'Descrição'), 'Unique 2');
    await tester.enterText(find.widgetWithText(TextField, 'Quantidade'), '10');
    // Date picker is handled automatically/default
    await tester.tap(find.text('Salvar'));
    await tester.pumpAndSettle();
    
    // Verify Added
    expect(find.text('UNIQ02'), findsOneWidget);

    // 2. Try Add Item B again
    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextField, 'Código'), 'UNIQ02');
    await tester.enterText(find.widgetWithText(TextField, 'Descrição'), 'Duplicate');
    await tester.enterText(find.widgetWithText(TextField, 'Quantidade'), '10');
    await tester.tap(find.text('Salvar'));
    await tester.pumpAndSettle();

    // Verify Error Dialog
    expect(find.text('Código Inválido'), findsOneWidget);
    expect(find.text('Este código já existe na lista de Pedidos.'), findsOneWidget);
    
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();
  });
}
