import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:rider_app/core/maps/map_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('GeoPoint & GeoBounds Domain Models', () {
    test('GeoPoint calculates accurate Haversine distance and bearing', () {
      // Victoria Island to Lekki Phase 1
      const vi = GeoPoint(latitude: 6.4281, longitude: 3.4219);
      const lekki = GeoPoint(latitude: 6.4474, longitude: 3.4723);

      final distanceKm = vi.distanceTo(lekki);
      expect(distanceKm, greaterThan(5.0));
      expect(distanceKm, lessThan(8.0));

      final bearing = vi.bearingTo(lekki);
      expect(bearing, greaterThan(0.0));
      expect(bearing, lessThan(360.0));

      // Serialization
      final json = vi.toJson();
      final reconstructed = GeoPoint.fromJson(json);
      expect(reconstructed.latitude, vi.latitude);
      expect(reconstructed.longitude, vi.longitude);
      expect(reconstructed, equals(vi));
    });

    test('GeoBounds verifies containment and computes center', () {
      const p1 = GeoPoint(latitude: 6.40, longitude: 3.40);
      const p2 = GeoPoint(latitude: 6.50, longitude: 3.50);
      final bounds = GeoBounds.fromPoints([p1, p2]);

      expect(bounds.contains(const GeoPoint(latitude: 6.45, longitude: 3.45)), isTrue);
      expect(bounds.contains(const GeoPoint(latitude: 6.60, longitude: 3.45)), isFalse);

      final center = bounds.center;
      expect(center.latitude, closeTo(6.45, 0.001));
      expect(center.longitude, closeTo(3.45, 0.001));
    });
  });

  group('GeocodedLocation & DistanceMatrix Models', () {
    test('GeocodedLocation serializes and deserializes accurately', () {
      const loc = GeocodedLocation(
        formattedAddress: '14 Admiralty Way, Lekki',
        point: GeoPoint(latitude: 6.4474, longitude: 3.4723),
        name: 'Lekki Admiralty',
        city: 'Lagos',
        placeId: 'lekki_01',
      );

      final json = loc.toJson();
      final parsed = GeocodedLocation.fromJson(json);
      expect(parsed.formattedAddress, '14 Admiralty Way, Lekki');
      expect(parsed.placeId, 'lekki_01');
      expect(parsed.point.latitude, 6.4474);
    });

    test('DistanceMatrixResult indexes matrix elements correctly', () {
      const o1 = GeoPoint(latitude: 6.4281, longitude: 3.4219);
      const d1 = GeoPoint(latitude: 6.4474, longitude: 3.4723);

      const el = DistanceMatrixElement(
        originIndex: 0,
        destinationIndex: 0,
        origin: o1,
        destination: d1,
        distanceKm: 6.8,
        durationMins: 14.5,
        status: DistanceMatrixStatus.ok,
      );

      const matrix = DistanceMatrixResult(
        origins: [o1],
        destinations: [d1],
        rows: [
          DistanceMatrixRow(elements: [el]),
        ],
      );

      final retrieved = matrix.element(0, 0);
      expect(retrieved, isNotNull);
      expect(retrieved!.distanceKm, 6.8);
      expect(retrieved.durationMins, 14.5);
      expect(retrieved.status, DistanceMatrixStatus.ok);
    });
  });

  group('MockMapProvider Service Tests', () {
    late MockMapProvider mockProvider;

    setUp(() {
      mockProvider = MockMapProvider();
    });

    test('MockGeocodingService searches Lagos locations and reverse geocodes', () async {
      final results = await mockProvider.geocoding.searchPlaces('Lekki');
      expect(results.isNotEmpty, isTrue);
      expect(results.first.formattedAddress, contains('Lekki'));

      final reverse = await mockProvider.geocoding.reverseGeocode(6.4281, 3.4219);
      expect(reverse, isNotNull);
      expect(reverse!.formattedAddress, contains('Victoria Island'));
    });

    test('MockRoutingService returns route geometry and steps', () async {
      const origin = GeoPoint(latitude: 6.4281, longitude: 3.4219);
      const destination = GeoPoint(latitude: 6.4474, longitude: 3.4723);

      final route = await mockProvider.routing.getRoute(
        origin: origin,
        destination: destination,
      );

      expect(route.distanceKm, greaterThan(0));
      expect(route.durationMins, greaterThan(0));
      expect(route.polylinePoints.length, greaterThanOrEqualTo(2));
      expect(route.steps.isNotEmpty, isTrue);

      final alternatives = await mockProvider.routing.getAlternativeRoutes(
        origin: origin,
        destination: destination,
        maxAlternatives: 2,
      );
      expect(alternatives.length, 2);
    });

    test('MockDistanceMatrixService calculates NxM matrix', () async {
      const o1 = GeoPoint(latitude: 6.4281, longitude: 3.4219);
      const o2 = GeoPoint(latitude: 6.5774, longitude: 3.3211);
      const d1 = GeoPoint(latitude: 6.4474, longitude: 3.4723);

      final matrix = await mockProvider.distanceMatrix.getDistanceMatrix(
        origins: [o1, o2],
        destinations: [d1],
      );

      expect(matrix.rows.length, 2);
      expect(matrix.element(0, 0)!.distanceKm, greaterThan(0));
      expect(matrix.element(1, 0)!.distanceKm, greaterThan(0));
    });

    testWidgets('MockMapProvider renders MapView widget cleanly', (tester) async {
      IMapController? capturedController;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: mockProvider.buildMapView(
              initialCamera: const MapCameraPosition(
                target: GeoPoint(latitude: 6.4281, longitude: 3.4219),
                zoom: 14.0,
              ),
              onMapCreated: (ctrl) => capturedController = ctrl,
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(GestureDetector), findsWidgets);
      expect(find.textContaining('Mock Map'), findsOneWidget);
      expect(capturedController, isNotNull);
    });
  });

  group('Multi-Vendor Map Providers', () {
    test('GoogleMapProvider identifies vendor and initializes', () async {
      final google = GoogleMapProvider(apiKey: 'TEST_KEY');
      expect(google.vendor, MapVendor.googleMaps);
      expect(google.name, 'Google Maps');

      await google.initialize(apiKey: 'NEW_KEY');
      expect(google.isInitialized, isTrue);
      expect(google.apiKey, 'NEW_KEY');

      // Fallback routing executes cleanly in test
      final route = await google.routing.getRoute(
        origin: const GeoPoint(latitude: 6.4281, longitude: 3.4219),
        destination: const GeoPoint(latitude: 6.4474, longitude: 3.4723),
      );
      expect(route.distanceKm, greaterThan(0));
    });

    test('MapboxMapProvider identifies vendor and initializes', () async {
      final mapbox = MapboxMapProvider(accessToken: 'TEST_TOKEN');
      expect(mapbox.vendor, MapVendor.mapbox);
      expect(mapbox.name, 'Mapbox');

      await mapbox.initialize(apiKey: 'NEW_TOKEN');
      expect(mapbox.isInitialized, isTrue);
      expect(mapbox.accessToken, 'NEW_TOKEN');
    });

    test('HereMapProvider identifies vendor and initializes', () async {
      final here = HereMapProvider(apiKey: 'TEST_KEY');
      expect(here.vendor, MapVendor.here);
      expect(here.name, 'HERE Technologies');

      await here.initialize(apiKey: 'NEW_KEY');
      expect(here.isInitialized, isTrue);
      expect(here.apiKey, 'NEW_KEY');
    });

    test('OsrmMapProvider identifies vendor and initializes', () async {
      final osrm = OsrmMapProvider();
      expect(osrm.vendor, MapVendor.osrm);
      expect(osrm.name, 'OpenStreetMap / OSRM');
      expect(osrm.isInitialized, isTrue);
    });
  });

  group('MapProviderRegistry Dynamic Migration Tests', () {
    test('Registry enables runtime vendor switching without changing business logic', () {
      final registry = MapProviderRegistry.instance;
      registry.reset();

      // 1. Initial active provider is Mock
      expect(registry.activeVendor, MapVendor.mock);
      expect(registry.current.name, 'Mock Map Engine');

      // 2. Switch to Google Maps
      registry.setActive(MapVendor.googleMaps);
      expect(registry.activeVendor, MapVendor.googleMaps);
      expect(registry.current.name, 'Google Maps');
      expect(registry.geocoding, isNotNull);
      expect(registry.routing, isNotNull);
      expect(registry.distanceMatrix, isNotNull);

      // 3. Switch to Mapbox
      registry.setActive(MapVendor.mapbox);
      expect(registry.activeVendor, MapVendor.mapbox);
      expect(registry.current.name, 'Mapbox');

      // 4. Switch to HERE
      registry.setActive(MapVendor.here);
      expect(registry.activeVendor, MapVendor.here);
      expect(registry.current.name, 'HERE Technologies');

      // 5. Switch to OSRM
      registry.setActive(MapVendor.osrm);
      expect(registry.activeVendor, MapVendor.osrm);
      expect(registry.current.name, 'OpenStreetMap / OSRM');

      // Reset
      registry.reset();
      expect(registry.activeVendor, MapVendor.mock);
    });
  });
}
