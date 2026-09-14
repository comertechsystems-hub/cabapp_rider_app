import 'geo_point.dart';

/// Vendor-agnostic geocoded location representation.
class GeocodedLocation {
  final String formattedAddress;
  final GeoPoint point;
  final String? name;
  final String? streetNumber;
  final String? route;
  final String? sublocality;
  final String? city;
  final String? state;
  final String? country;
  final String? postalCode;
  final String? placeId;

  const GeocodedLocation({
    required this.formattedAddress,
    required this.point,
    this.name,
    this.streetNumber,
    this.route,
    this.sublocality,
    this.city,
    this.state,
    this.country,
    this.postalCode,
    this.placeId,
  });

  Map<String, dynamic> toJson() => {
        'formattedAddress': formattedAddress,
        'point': point.toJson(),
        if (name != null) 'name': name,
        if (streetNumber != null) 'streetNumber': streetNumber,
        if (route != null) 'route': route,
        if (sublocality != null) 'sublocality': sublocality,
        if (city != null) 'city': city,
        if (state != null) 'state': state,
        if (country != null) 'country': country,
        if (postalCode != null) 'postalCode': postalCode,
        if (placeId != null) 'placeId': placeId,
      };

  factory GeocodedLocation.fromJson(Map<String, dynamic> json) {
    return GeocodedLocation(
      formattedAddress: json['formattedAddress'] as String,
      point: GeoPoint.fromJson(json['point'] as Map<String, dynamic>),
      name: json['name'] as String?,
      streetNumber: json['streetNumber'] as String?,
      route: json['route'] as String?,
      sublocality: json['sublocality'] as String?,
      city: json['city'] as String?,
      state: json['state'] as String?,
      country: json['country'] as String?,
      postalCode: json['postalCode'] as String?,
      placeId: json['placeId'] as String?,
    );
  }

  @override
  String toString() => 'GeocodedLocation($formattedAddress, $point)';
}

/// Place search prediction / suggestion item for auto-complete.
class PlaceSuggestion {
  final String placeId;
  final String mainText;
  final String secondaryText;
  final String description;

  const PlaceSuggestion({
    required this.placeId,
    required this.mainText,
    required this.secondaryText,
    required this.description,
  });

  Map<String, dynamic> toJson() => {
        'placeId': placeId,
        'mainText': mainText,
        'secondaryText': secondaryText,
        'description': description,
      };

  factory PlaceSuggestion.fromJson(Map<String, dynamic> json) {
    return PlaceSuggestion(
      placeId: json['placeId'] as String,
      mainText: json['mainText'] as String,
      secondaryText: json['secondaryText'] as String,
      description: json['description'] as String,
    );
  }

  @override
  String toString() => 'PlaceSuggestion($mainText, $secondaryText)';
}
