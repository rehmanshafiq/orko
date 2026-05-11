/// Charger port row — label, price, and availability for hub detail.
class ChargerPortModel {
  const ChargerPortModel({
    required this.label,
    required this.price,
    required this.available,
  });

  final String label;
  final String price;
  final bool available;
}
