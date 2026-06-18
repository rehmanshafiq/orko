import 'package:orko_hubco/features/booking/domain/entities/charger_details_entity.dart';

class PortPriceModel extends PortPriceEntity {
  const PortPriceModel({
    required super.pricingMode,
    required super.currency,
    required super.price,
  });

  factory PortPriceModel.fromJson(Map<String, dynamic> json) {
    return PortPriceModel(
      pricingMode: (json['pricing_mode'] ?? '').toString(),
      currency: (json['currency'] ?? '').toString(),
      price: _asDouble(json['price']),
    );
  }

  static double _asDouble(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0;
    return 0;
  }
}

class ChargerPortModel extends ChargerPortEntity {
  const ChargerPortModel({
    required super.id,
    required super.name,
    required super.connectorType,
    required super.connectorState,
    super.price,
  });

  factory ChargerPortModel.fromJson(Map<String, dynamic> json) {
    final rawPrice = json['price'];
    return ChargerPortModel(
      id: _asInt(json['id']),
      name: (json['name'] ?? '').toString(),
      connectorType: (json['connector_type'] ?? '').toString(),
      connectorState: (json['connector_state'] ?? '').toString(),
      price: rawPrice is Map
          ? PortPriceModel.fromJson(Map<String, dynamic>.from(rawPrice))
          : null,
    );
  }

  static int _asInt(dynamic value) {
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }
}

class ChargerDetailsModel extends ChargerDetailsEntity {
  const ChargerDetailsModel({
    required super.stationName,
    required super.stationAddress,
    required super.ports,
  });

  factory ChargerDetailsModel.fromJson(Map<String, dynamic> json) {
    final rawPorts = json['charger_ports'];
    final ports = (rawPorts is List)
        ? rawPorts
            .whereType<Map>()
            .map((e) => ChargerPortModel.fromJson(Map<String, dynamic>.from(e)))
            .toList(growable: false)
        : const <ChargerPortModel>[];

    return ChargerDetailsModel(
      stationName: (json['station_name'] ?? '').toString(),
      stationAddress: (json['station_address'] ?? '').toString(),
      ports: ports,
    );
  }
}
