import 'package:flutter/material.dart';
import '../models/solicitation_item.dart';
import '../models/pedido_item.dart';
import '../services/excel_service.dart';
import 'package:intl/intl.dart';

class SolicitarPage extends StatefulWidget {
  const SolicitarPage({super.key});

  @override
  State<SolicitarPage> createState() => _SolicitarPageState();
}

class _SolicitarPageState extends State<SolicitarPage> {
  final ExcelService _excelService = ExcelService();
  List<SolicitationItem> _items = [];
  List<PedidoItem> _pedidos = [];

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  void _loadItems() {
    setState(() {
      _items = _excelService.getSolicitacoes();
      _pedidos = _excelService.getPedidos();
    });
  }

  void _addItem(String code, String description, int quantity) async {
    final item = SolicitationItem(
      id: DateTime.now().toString(),
      code: code,
      description: description,
      quantity: quantity,
      date: DateTime.now(),
    );
    await _excelService.saveSolicitacao(item);
    _loadItems();
  }

  void _editItem(SolicitationItem item, String code, String description, int quantity) async {
    item.code = code;
    item.description = description;
    item.quantity = quantity;
    await _excelService.saveSolicitacao(item);
    _loadItems();
  }

  void _deleteItem(String id) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Excluir item?'),
          content: const Text('Tem certeza que deseja excluir este item?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                await _excelService.deleteSolicitacao(id);
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

  void _sendItem(SolicitationItem item) {
    DateTime selectedDate = DateTime.now();

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Enviar para Pedidos?'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Selecione a data de chegada:'),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Text(DateFormat('dd/MM/yyyy').format(selectedDate)),
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
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    // Create PedidoItem
                    final pedido = PedidoItem(
                      id: DateTime.now().toString(),
                      code: item.code,
                      description: item.description,
                      quantity: item.quantity,
                      arrivalDate: selectedDate,
                    );
                    
                    // Save to Pedidos
                    await _excelService.savePedido(pedido);
                    
                    // Delete from Solicitacoes
                    await _excelService.deleteSolicitacao(item.id);
                    
                    // Update UI
                    if (mounted) {
                      Navigator.pop(context);
                      _loadItems();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Item enviado para Pedidos!')),
                      );
                    }
                  },
                  child: const Text('Confirmar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showItemDialog({SolicitationItem? item}) {
    final codeController = TextEditingController(text: item?.code ?? '');
    final descriptionController = TextEditingController(text: item?.description ?? '');
    final quantityController = TextEditingController(text: item?.quantity.toString() ?? '');

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(item == null ? 'Novo Item' : 'Editar Item'),
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

                // Check for uniqueness in Solicitar List
                final isDuplicate = _items.any((i) => i.code == code && i.id != (item?.id ?? ''));
                if (isDuplicate) {
                   showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Código Inválido'),
                        content: const Text('Este código já existe na lista de Solicitações.'),
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
                
                // Validation against Pedidos
                final pedidos = _excelService.getPedidos();
                // Find existing pedido with same code
                PedidoItem? existingPedido;
                try {
                  existingPedido = pedidos.firstWhere((p) => p.code == code);
                } catch (e) {
                  existingPedido = null;
                }

                if (existingPedido != null) {
                  final pedido = existingPedido!;
                  if (pedido.quantity >= quantity) {
                    // Case 1: Block
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Item já existe'),
                        content: Text('Este item já consta em Pedidos com quantidade ${pedido.quantity}.'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('OK'),
                          ),
                        ],
                      ),
                    );
                    return;
                  } else {
                    // Case 2: Confirm Difference
                    final diff = quantity - pedido.quantity;
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Ajuste de Quantidade'),
                        content: Text(
                            'Este item já consta em Pedidos com quantidade ${pedido.quantity}.\n\nDeseja adicionar apenas a diferença ($diff)?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Cancelar'),
                          ),
                          ElevatedButton(
                            onPressed: () {
                              Navigator.pop(context); // Close alert
                              Navigator.pop(context); // Close form
                              if (item == null) {
                                _addItem(code, description, diff);
                              } else {
                                _editItem(item, code, description, diff);
                              }
                            },
                            child: const Text('Sim'),
                          ),
                        ],
                      ),
                    );
                    return;
                  }
                }

                if (item == null) {
                  _addItem(code, description, quantity);
                } else {
                  _editItem(item, code, description, quantity);
                }
                Navigator.pop(context);
              },
              child: const Text('Salvar'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Solicitar'),
      ),
      body: _items.isEmpty
          ? const Center(child: Text('Nenhum item solicitado.'))
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
                        Row(
                          children: [
                            Text(
                              item.code,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            if (_pedidos.any((p) => p.code == item.code)) ...[
                              const SizedBox(width: 8),
                              const Tooltip(
                                message: 'Item presente em Pedidos',
                                child: Icon(Icons.info_outline, color: Colors.orange, size: 20),
                              ),
                            ],
                          ],
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
                        // Quantity and Date
                        Text(
                          '${item.quantity}  ${DateFormat('dd/MM/yyyy').format(item.date)}',
                          style: const TextStyle(fontSize: 14, color: Colors.grey),
                        ),
                        // Actions
                        const SizedBox(width: 24),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.send, color: Colors.blue, size: 20),
                              onPressed: () => _sendItem(item),
                              tooltip: 'Enviar',
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                            const SizedBox(width: 16),
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
