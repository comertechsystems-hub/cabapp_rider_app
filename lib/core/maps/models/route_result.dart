import 'geo_bounds.dart';
import 'geo_point.dart';

enum RouteTravelMode { driving, walking, bicycling, transit }

/// Single turn-by-turn navigation maneuver step.
class RouteStep {
  final String instruction;
  final double distanceKm;
  final double durationMins;
  final String? maneuver;
  final GeoPoint startPoint;
  final GeoPoint endPoint;

  const RouteStep({
    required this.instruction,
    required this.distanceKm,
    required this.durationMins,
    this.maneuver,
    required this.startPoint,
    required this.endPoint,
  });

  Map<String, dynamic> toJson() => {
        'instruction': instruction,
        'distanceKm': distanceKm,
        'durationMins': durationMins,
        if (maneuver != null) 'maneuver': maneuver,
        'startPoint': startPoint.toJson(),
        'endPoint': endPoint.toJson(),
      };

  factory RouteStep.fromJson(Map<String, dynamic> json) {
    return RouteStep(
      instruction: json['instruction'] as String,
      distanceKm: (json['distanceKm'] as num).toDouble(),
      durationMins: (json['durationMins'] as num).toDouble(),
      maneuver: json['maneuver'] as String?,
      startPoint: GeoPoint.fromJson(json['startPoint'] as Map<String, dynamic>),
      endPoint: GeoPoint.fromJson(json['endPoint'] as Map<String, dynamic>),
    );
  }

  @override
  String toString() => 'RouteStep($instruction, $distanceKm km)';
}

/// Comprehensive vendor-agnostic route calculation result.
class RouteResult {
  final String routeId;
  final double distanceKm;
  final double durationMins;
  final List<GeoPoint> polylinePoints;
  final String? encodedPolyline;
  final GeoBounds? bounds;
  final String? summary;
  final List<RouteStep> steps;
  final Map<String, dynamic>? rawMetadata;

  const RouteResult({
    required this.routeId,
    required this.distanceKm,
    required this.durationMins,
    required this.polylinePoints,
    this.encodedPolyline,
    this.bounds,
    this.summary,
    this.steps = const [],
    this.rawMetadata,
  });

  Map<String, dynamic> toJson() => {
        'routeId': routeId,
        'distanceKm': distanceKm,
        'durationMins': durationMins,
        'polylinePoints': polylinePoints.map((p) => p.toJson()).toList(),
        if (encodedPolyline != null) 'encodedPolyline': encodedPolyline,
        if (bounds != null) 'bounds': bounds!.toJson(),
        if (summary != null) 'summary': summary,
        'steps': steps.map((s) => s.toJson()).toList(),
      };

  factory RouteResult.fromJson(Map<String, dynamic> json) {
    return RouteResult(
      routeId: json['routeId'] as String,
      distanceKm: (json['distanceKm'] as num).toDouble(),
      durationMins: (json['durationMins'] as num).toDouble(),
      polylinePoints: (json['polylinePoints'] as List<dynamic>)
          .map((p) => GeoPoint.fromJson(p as Map<String, dynamic>))
          .toList(),
      encodedPolyline: json['encodedPolyline'] as String?,
      bounds: json['bounds'] != null
          ? GeoBounds.fromJson(json['bounds'] as Map<String, dynamic>)
          : null,
      summary: json['summary'] as String?,
      steps: (json['steps'] as List<dynamic>?)
              ?.map((s) => RouteStep.fromJson(s as Map<String, dynamic>))
              .toList() ??
          const [],
    );
  }

  @override
  String toString() =>
      'RouteResult($distanceKm km, $durationMins mins, ${polylinePoints.length} points)';
}
