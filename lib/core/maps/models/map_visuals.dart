import 'package:flutter/material.dart';
import 'geo_point.dart';

/// Camera state for Map View rendering.
class MapCameraPosition {
  final GeoPoint target;
  final double zoom;
  final double bearing;
  final double tilt;

  const MapCameraPosition({
    required this.target,
    this.zoom = 14.0,
    this.bearing = 0.0,
    this.tilt = 0.0,
  });

  Map<String, dynamic> toJson() => {
        'target': target.toJson(),
        'zoom': zoom,
        'bearing': bearing,
        'tilt': tilt,
      };

  factory MapCameraPosition.fromJson(Map<String, dynamic> json) {
    return MapCameraPosition(
      target: GeoPoint.fromJson(json['target'] as Map<String, dynamic>),
      zoom: (json['zoom'] as num?)?.toDouble() ?? 14.0,
      bearing: (json['bearing'] as num?)?.toDouble() ?? 0.0,
      tilt: (json['tilt'] as num?)?.toDouble() ?? 0.0,
    );
  }

  @override
  String toString() => 'MapCameraPosition($target, zoom: $zoom)';
}

/// Generic map marker overlay representation.
class MapMarker {
  final String id;
  final GeoPoint position;
  final String? title;
  final String? snippet;
  final IconData? icon;
  final Color? color;
  final double size;
  final VoidCallback? onTap;

  const MapMarker({
    required this.id,
    required this.position,
    this.title,
    this.snippet,
    this.icon,
    this.color,
    this.size = 32.0,
    this.onTap,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MapMarker && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

/// Generic polyline overlay representation.
class MapPolyline {
  final String id;
  final List<GeoPoint> points;
  final Color color;
  final double width;
  final bool isDotted;

  const MapPolyline({
    required this.id,
    required this.points,
    this.color = const Color(0xFF1E3A8A),
    this.width = 4.0,
    this.isDotted = false,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MapPolyline && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
