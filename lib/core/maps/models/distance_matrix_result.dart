import 'geo_point.dart';

enum DistanceMatrixStatus { ok, notFound, zeroResults, maxRouteLengthExceeded, error }

/// Single element representing origin-to-destination distance and duration.
class DistanceMatrixElement {
  final int originIndex;
  final int destinationIndex;
  final GeoPoint origin;
  final GeoPoint destination;
  final double distanceKm;
  final double durationMins;
  final DistanceMatrixStatus status;

  const DistanceMatrixElement({
    required this.originIndex,
    required this.destinationIndex,
    required this.origin,
    required this.destination,
    required this.distanceKm,
    required this.durationMins,
    required this.status,
  });

  Map<String, dynamic> toJson() => {
        'originIndex': originIndex,
        'destinationIndex': destinationIndex,
        'origin': origin.toJson(),
        'destination': destination.toJson(),
        'distanceKm': distanceKm,
        'durationMins': durationMins,
        'status': status.name,
      };

  factory DistanceMatrixElement.fromJson(Map<String, dynamic> json) {
    return DistanceMatrixElement(
      originIndex: (json['originIndex'] as num).toInt(),
      destinationIndex: (json['destinationIndex'] as num).toInt(),
      origin: GeoPoint.fromJson(json['origin'] as Map<String, dynamic>),
      destination: GeoPoint.fromJson(json['destination'] as Map<String, dynamic>),
      distanceKm: (json['distanceKm'] as num).toDouble(),
      durationMins: (json['durationMins'] as num).toDouble(),
      status: DistanceMatrixStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => DistanceMatrixStatus.ok,
      ),
    );
  }

  @override
  String toString() =>
      'DistanceMatrixElement($distanceKm km, $durationMins mins, $status)';
}

/// A row in the Distance Matrix containing elements for a specific origin.
class DistanceMatrixRow {
  final List<DistanceMatrixElement> elements;

  const DistanceMatrixRow({required this.elements});

  Map<String, dynamic> toJson() => {
        'elements': elements.map((e) => e.toJson()).toList(),
      };

  factory DistanceMatrixRow.fromJson(Map<String, dynamic> json) {
    return DistanceMatrixRow(
      elements: (json['elements'] as List<dynamic>)
          .map((e) => DistanceMatrixElement.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

/// Distance matrix calculation result across multiple origins and destinations.
class DistanceMatrixResult {
  final List<GeoPoint> origins;
  final List<GeoPoint> destinations;
  final List<DistanceMatrixRow> rows;

  const DistanceMatrixResult({
    required this.origins,
    required this.destinations,
    required this.rows,
  });

  /// Retrieve specific element between originIndex and destinationIndex
  DistanceMatrixElement? element(int originIndex, int destinationIndex) {
    if (originIndex >= 0 && originIndex < rows.length) {
      final row = rows[originIndex];
      if (destinationIndex >= 0 && destinationIndex < row.elements.length) {
        return row.elements[destinationIndex];
      }
    }
    return null;
  }

  Map<String, dynamic> toJson() => {
        'origins': origins.map((p) => p.toJson()).toList(),
        'destinations': destinations.map((p) => p.toJson()).toList(),
        'rows': rows.map((r) => r.toJson()).toList(),
      };

  factory DistanceMatrixResult.fromJson(Map<String, dynamic> json) {
    return DistanceMatrixResult(
      origins: (json['origins'] as List<dynamic>)
          .map((p) => GeoPoint.fromJson(p as Map<String, dynamic>))
          .toList(),
      destinations: (json['destinations'] as List<dynamic>)
          .map((p) => GeoPoint.fromJson(p as Map<String, dynamic>))
          .toList(),
      rows: (json['rows'] as List<dynamic>)
          .map((r) => DistanceMatrixRow.fromJson(r as Map<String, dynamic>))
          .toList(),
    );
  }

  @override
  String toString() =>
      'DistanceMatrixResult(${origins.length} origins x ${destinations.length} destinations)';
}
