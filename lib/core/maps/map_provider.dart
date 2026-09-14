// Core Map Provider Abstraction Library
//
// Exports vendor-agnostic models, interfaces, providers, and registry.
// Decouples all ride business logic from specific mapping/routing SDKs.

export 'interfaces/i_distance_matrix_service.dart';
export 'interfaces/i_geocoding_service.dart';
export 'interfaces/i_map_provider.dart';
export 'interfaces/i_routing_service.dart';
export 'map_provider_factory.dart';
export 'models/distance_matrix_result.dart';
export 'models/geo_bounds.dart';
export 'models/geo_point.dart';
export 'models/geocoded_location.dart';
export 'models/map_visuals.dart';
export 'models/route_result.dart';
export 'providers/google_map_provider.dart';
export 'providers/here_map_provider.dart';
export 'providers/mapbox_map_provider.dart';
export 'providers/mock_map_provider.dart';
export 'providers/osrm_map_provider.dart';
