import 'dart:io';
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import '../models/solicitation_item.dart';
import '../models/pedido_item.dart';

class ExcelService {
  static final ExcelService _instance = ExcelService._internal();

  factory ExcelService() {
    return _instance;
  }

  ExcelService._internal();

  Excel? _excel;
  String? _filePath;

  Future<void> init() async {
    final directory = await getApplicationDocumentsDirectory();
    _filePath = '${directory.path}/controle_pedidos.xlsx';
    final file = File(_filePath!);

    if (await file.exists()) {
      var bytes = await file.readAsBytes();
      _excel = Excel.decodeBytes(bytes);
    } else {
      _excel = Excel.createExcel();
      _excel!.delete('Sheet1'); // Remove default sheet
      _excel!.updateCell('Solicitacoes', CellIndex.indexByString('A1'), TextCellValue('ID'));
      _excel!.updateCell('Solicitacoes', CellIndex.indexByString('B1'), TextCellValue('Code'));
      _excel!.updateCell('Solicitacoes', CellIndex.indexByString('C1'), TextCellValue('Description'));
      _excel!.updateCell('Solicitacoes', CellIndex.indexByString('D1'), TextCellValue('Quantity'));
      _excel!.updateCell('Solicitacoes', CellIndex.indexByString('E1'), TextCellValue('Date'));
      
      _excel!.updateCell('Pedidos', CellIndex.indexByString('A1'), TextCellValue('ID'));
      _excel!.updateCell('Pedidos', CellIndex.indexByString('B1'), TextCellValue('Code'));
      _excel!.updateCell('Pedidos', CellIndex.indexByString('C1'), TextCellValue('Description'));
      _excel!.updateCell('Pedidos', CellIndex.indexByString('D1'), TextCellValue('Quantity'));
      _excel!.updateCell('Pedidos', CellIndex.indexByString('E1'), TextCellValue('Date'));
      
      await _saveFile();
    }
  }

  Future<void> _saveFile() async {
    if (_excel != null && _filePath != null) {
      var fileBytes = _excel!.save();
      File(_filePath!)
        ..createSync(recursive: true)
        ..writeAsBytesSync(fileBytes!);
    }
  }

  // --- Solicitacoes Operations ---

  List<SolicitationItem> getSolicitacoes() {
    List<SolicitationItem> items = [];
    if (_excel != null) {
      var sheet = _excel!['Solicitacoes'];
      // Skip header row
      for (var i = 1; i < sheet.maxRows; i++) {
        var row = sheet.row(i);
        if (row.length >= 5 && row[0] != null) {
           try {
            items.add(SolicitationItem(
              id: row[0]?.value.toString() ?? '',
              code: row[1]?.value.toString() ?? '',
              description: row[2]?.value.toString() ?? '',
              quantity: int.tryParse(row[3]?.value.toString() ?? '0') ?? 0,
              date: DateTime.tryParse(row[4]?.value.toString() ?? '') ?? DateTime.now(),
            ));
           } catch (e) {
             print('Error parsing row $i: $e');
           }
        }
      }
    }
    return items;
  }

  Future<void> saveSolicitacao(SolicitationItem item) async {
    if (_excel == null) return;
    var sheet = _excel!['Solicitacoes'];
    
    // Check if item exists to update
    int? rowIndex;
    for (var i = 1; i < sheet.maxRows; i++) {
      var row = sheet.row(i);
      if (row.isNotEmpty && row[0]?.value.toString() == item.id) {
        rowIndex = i;
        break;
      }
    }

    if (rowIndex != null) {
      // Update
      sheet.updateCell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rowIndex), TextCellValue(item.code));
      sheet.updateCell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: rowIndex), TextCellValue(item.description));
      sheet.updateCell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: rowIndex), IntCellValue(item.quantity));
      sheet.updateCell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: rowIndex), TextCellValue(item.date.toIso8601String()));
    } else {
      // Add new
      sheet.appendRow([
        TextCellValue(item.id),
        TextCellValue(item.code),
        TextCellValue(item.description),
        IntCellValue(item.quantity),
        TextCellValue(item.date.toIso8601String()),
      ]);
    }
    await _saveFile();
  }

  Future<void> deleteSolicitacao(String id) async {
    if (_excel == null) return;
     var sheet = _excel!['Solicitacoes'];
     int? rowIndex;
     for (var i = 1; i < sheet.maxRows; i++) {
      var row = sheet.row(i);
      if (row.isNotEmpty && row[0]?.value.toString() == id) {
        rowIndex = i;
        break;
      }
    }

    if (rowIndex != null) {
      sheet.removeRow(rowIndex);
      await _saveFile();
    }
  }

  // --- Pedidos Operations ---

  List<PedidoItem> getPedidos() {
    List<PedidoItem> items = [];
    if (_excel != null) {
      var sheet = _excel!['Pedidos'];
      for (var i = 1; i < sheet.maxRows; i++) {
        var row = sheet.row(i);
        if (row.length >= 5 && row[0] != null) {
          try {
            items.add(PedidoItem(
              id: row[0]?.value.toString() ?? '',
              code: row[1]?.value.toString() ?? '',
              description: row[2]?.value.toString() ?? '',
              quantity: int.tryParse(row[3]?.value.toString() ?? '0') ?? 0,
              arrivalDate: DateTime.tryParse(row[4]?.value.toString() ?? '') ?? DateTime.now(),
            ));
          } catch (e) {
            print('Error parsing row $i: $e');
          }
        }
      }
    }
    return items;
  }

  Future<void> savePedido(PedidoItem item) async {
    if (_excel == null) return;
    var sheet = _excel!['Pedidos'];
    
    int? rowIndex;
    for (var i = 1; i < sheet.maxRows; i++) {
      var row = sheet.row(i);
      if (row.isNotEmpty && row[0]?.value.toString() == item.id) {
        rowIndex = i;
        break;
      }
    }

    if (rowIndex != null) {
      sheet.updateCell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rowIndex), TextCellValue(item.code));
      sheet.updateCell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: rowIndex), TextCellValue(item.description));
      sheet.updateCell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: rowIndex), IntCellValue(item.quantity));
      sheet.updateCell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: rowIndex), TextCellValue(item.arrivalDate.toIso8601String()));
    } else {
      sheet.appendRow([
        TextCellValue(item.id),
        TextCellValue(item.code),
        TextCellValue(item.description),
        IntCellValue(item.quantity),
        TextCellValue(item.arrivalDate.toIso8601String()),
      ]);
    }
    await _saveFile();
  }

  Future<void> deletePedido(String id) async {
    if (_excel == null) return;
     var sheet = _excel!['Pedidos'];
     int? rowIndex;
     for (var i = 1; i < sheet.maxRows; i++) {
      var row = sheet.row(i);
      if (row.isNotEmpty && row[0]?.value.toString() == id) {
        rowIndex = i;
        break;
      }
    }

    if (rowIndex != null) {
      sheet.removeRow(rowIndex);
      await _saveFile();
    }
  }
}
