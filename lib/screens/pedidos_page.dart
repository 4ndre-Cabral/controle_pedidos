import 'package:flutter/material.dart';
import '../models/pedido_item.dart';
import '../services/excel_service.dart';
import 'package:intl/intl.dart';

class PedidosPage extends StatefulWidget {
  const PedidosPage({super.key});

  @override
  State<PedidosPage> createState() => _PedidosPageState();
}

class _PedidosPageState extends State<PedidosPage> {
  final ExcelService _excelService = ExcelService();
  List<PedidoItem> _items = [];

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  void _loadItems() {
    setState(() {
      _items = _excelService.getPedidos();
    });
  }

  void _addItem(String code, String description, int quantity, DateTime arrivalDate) async {
    final item = PedidoItem(
      id: DateTime.now().toString(),
      code: code,
      description: description,
      quantity: quantity,
      arrivalDate: arrivalDate,
    );
    await _excelService.savePedido(item);
    _loadItems();
  }

  void _editItem(PedidoItem item, String code, String description, int quantity, DateTime arrivalDate) async {
    item.code = code;
    item.description = description;
    item.quantity = quantity;
    item.arrivalDate = arrivalDate;
    await _excelService.savePedido(item);
    _loadItems();
  }

  void _deleteItem(String id) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Excluir pedido?'),
          content: const Text('Tem certeza que deseja excluir este pedido?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                await _excelService.deletePedido(id);
                if (mounted) {
                  Navigator.pop(context);
                  _loadItems();
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
              child: const Text('Excluir'),
            ),
          ],
        );
      },
    );
  }

  void _showItemDialog({PedidoItem? item}) {
    final codeController = TextEditingController(text: item?.code ?? '');
    final descriptionController = TextEditingController(text: item?.description ?? '');
    final quantityController = TextEditingController(text: item?.quantity.toString() ?? '');
    DateTime selectedDate = item?.arrivalDate ?? DateTime.now();

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(item == null ? 'Novo Pedido' : 'Editar Pedido'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: codeController,
                      decoration: const InputDecoration(labelText: 'Código'),
                    ),
                    TextField(
                      controller: descriptionController,
                      decoration: const InputDecoration(labelText: 'Descrição'),
                    ),
                    TextField(
                      controller: quantityController,
                      decoration: const InputDecoration(labelText: 'Quantidade'),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Text('Chegada: ${DateFormat('dd/MM/yyyy').format(selectedDate)}'),
                        const Spacer(),
                        TextButton(
                          onPressed: () async {
                            final DateTime? picked = await showDatePicker(
                              context: context,
                              initialDate: selectedDate,
                              firstDate: DateTime(2000),
                              lastDate: DateTime(2101),
                            );
                            if (picked != null && picked != selectedDate) {
                              setState(() {
                                selectedDate = picked;
                              });
                            }
                          },
                          child: const Text('Alterar Data'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: () {
                    final code = codeController.text;
                    final description = descriptionController.text;
                    final quantity = int.tryParse(quantityController.text) ?? 0;

                    if (code.isEmpty) {
                       ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Código é obrigatório')),
                      );
                      return;
                    }

                    // Check for uniqueness in Pedidos List
                    final isDuplicate = _items.any((i) => i.code == code && i.id != (item?.id ?? ''));
                    if (isDuplicate) {
                       showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Código Inválido'),
                            content: const Text('Este código já existe na lista de Pedidos.'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('OK'),
                              ),
                            ],
                          ),
                        );
                        return;
                    }

                    if (item == null) {
                      _addItem(code, description, quantity, selectedDate);
                    } else {
                      _editItem(item, code, description, quantity, selectedDate);
                    }
                    Navigator.pop(context);
                  },
                  child: const Text('Salvar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pedidos'),
      ),
      body: _items.isEmpty
          ? const Center(child: Text('Nenhum pedido cadastrado.'))
          : ListView.builder(
              itemCount: _items.length,
              itemBuilder: (context, index) {
                final item = _items[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Code (Priority)
                        Text(
                          item.code,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Description (Flexible)
                        Expanded(
                          child: Text(
                            item.description,
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Quantity and Arrival Date
                        Text(
                          '${item.quantity}  ${DateFormat('dd/MM/yyyy').format(item.arrivalDate)}',
                          style: const TextStyle(fontSize: 14, color: Colors.grey),
                        ),
                        // Actions
                        const SizedBox(width: 24),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.green, size: 20),
                              onPressed: () => _showItemDialog(item: item),
                              tooltip: 'Editar',
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                            const SizedBox(width: 16),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                              onPressed: () => _deleteItem(item.id),
                              tooltip: 'Excluir',
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showItemDialog(),
        child: const Icon(Icons.add),
      ),
    );
  }
}
