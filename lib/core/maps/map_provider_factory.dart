import 'interfaces/i_distance_matrix_service.dart';
import 'interfaces/i_geocoding_service.dart';
import 'interfaces/i_map_provider.dart';
import 'interfaces/i_routing_service.dart';
import 'providers/google_map_provider.dart';
import 'providers/here_map_provider.dart';
import 'providers/mapbox_map_provider.dart';
import 'providers/mock_map_provider.dart';
import 'providers/osrm_map_provider.dart';

/// Factory creating configured instances of supported MapProviders.
class MapProviderFactory {
  static IMapProvider create(
    MapVendor vendor, {
    String? apiKey,
    Map<String, dynamic>? options,
  }) {
    switch (vendor) {
      case MapVendor.googleMaps:
        return GoogleMapProvider(apiKey: apiKey);
      case MapVendor.mapbox:
        return MapboxMapProvider(accessToken: apiKey);
      case MapVendor.here:
        return HereMapProvider(apiKey: apiKey);
      case MapVendor.osrm:
        return OsrmMapProvider();
      case MapVendor.mock:
        return MockMapProvider();
    }
  }
}

/// Central registry managing the application's active MapProvider.
///
/// Allows dynamic runtime switching between Google Maps, Mapbox, HERE, OSRM,
/// and Mock engines without changing any ride booking or dispatch business logic.
class MapProviderRegistry {
  static final MapProviderRegistry _instance = MapProviderRegistry._internal();
  static MapProviderRegistry get instance => _instance;

  final Map<MapVendor, IMapProvider> _providers = {};
  MapVendor _activeVendor = MapVendor.mock;

  MapProviderRegistry._internal() {
    // Register default implementations
    registerProvider(MockMapProvider());
    registerProvider(GoogleMapProvider());
    registerProvider(MapboxMapProvider());
    registerProvider(HereMapProvider());
    registerProvider(OsrmMapProvider());
  }

  /// Register or override a provider implementation
  void registerProvider(IMapProvider provider) {
    _providers[provider.vendor] = provider;
  }

  /// Get provider by specific vendor enum
  IMapProvider? getProvider(MapVendor vendor) => _providers[vendor];

  /// Get currently active MapProvider
  IMapProvider get current {
    final provider = _providers[_activeVendor];
    if (provider != null) return provider;
    return _providers[MapVendor.mock] ?? MockMapProvider();
  }

  /// Convenience accessors for active sub-services
  IGeocodingService get geocoding => current.geocoding;
  IRoutingService get routing => current.routing;
  IDistanceMatrixService get distanceMatrix => current.distanceMatrix;

  /// Active vendor
  MapVendor get activeVendor => _activeVendor;

  /// Switch the active map vendor at runtime
  void setActive(MapVendor vendor) {
    if (_providers.containsKey(vendor)) {
      _activeVendor = vendor;
    } else {
      _providers[vendor] = MapProviderFactory.create(vendor);
      _activeVendor = vendor;
    }
  }

  /// Reset registry to initial state (defaults to mock engine)
  void reset() {
    _activeVendor = MapVendor.mock;
  }
}
