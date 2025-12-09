class PedidoItem {
  String id;
  String code;
  String description;
  int quantity;
  DateTime arrivalDate;

  PedidoItem({
    required this.id,
    required this.code,
    required this.description,
    required this.quantity,
    required this.arrivalDate,
  });
}
