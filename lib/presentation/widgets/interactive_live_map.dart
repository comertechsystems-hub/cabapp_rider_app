import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

/// High-performance, zero-config live map widget using OpenStreetMap / CartoDB tiles.
/// Does not require any external SDKs, Google Cloud billing, or API keys to work immediately.
class InteractiveLiveMap extends StatefulWidget {
  final double pickupLat;
  final double pickupLng;
  final String pickupAddress;
  final double destinationLat;
  final double destinationLng;
  final String destinationAddress;
  final double? driverLat;
  final double? driverLng;
  final List<Map<String, dynamic>>? nearbyDrivers;

  const InteractiveLiveMap({
    super.key,
    required this.pickupLat,
    required this.pickupLng,
    required this.pickupAddress,
    required this.destinationLat,
    required this.destinationLng,
    required this.destinationAddress,
    this.driverLat,
    this.driverLng,
    this.nearbyDrivers,
  });

  @override
  State<InteractiveLiveMap> createState() => _InteractiveLiveMapState();
}

class _InteractiveLiveMapState extends State<InteractiveLiveMap> {
  late double _centerLat;
  late double _centerLng;
  double _zoom = 13.0;
  double _baseScaleZoom = 13.0;

  @override
  void initState() {
    super.initState();
    _recenter();
  }

  @override
  void didUpdateWidget(covariant InteractiveLiveMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.pickupLat != widget.pickupLat ||
        oldWidget.pickupLng != widget.pickupLng ||
        oldWidget.destinationLat != widget.destinationLat ||
        oldWidget.destinationLng != widget.destinationLng) {
      _recenter();
    }
  }

  void _recenter() {
    setState(() {
      _centerLat = (widget.pickupLat + widget.destinationLat) / 2.0;
      _centerLng = (widget.pickupLng + widget.destinationLng) / 2.0;
      _zoom = 13.0;
    });
  }

  void _zoomIn() {
    setState(() {
      if (_zoom < 17.0) _zoom += 1.0;
    });
  }

  void _zoomOut() {
    setState(() {
      if (_zoom > 10.0) _zoom -= 1.0;
    });
  }

  // Web Mercator projections
  static double _lngToPixelX(double lng, double zoom) {
    return (lng + 180.0) / 360.0 * math.pow(2.0, zoom) * 256.0;
  }

  static double _latToPixelY(double lat, double zoom) {
    final latRad = lat.clamp(-85.0511, 85.0511) * math.pi / 180.0;
    final y = (1.0 - math.log(math.tan(latRad) + 1.0 / math.cos(latRad)) / math.pi) / 2.0;
    return y * math.pow(2.0, zoom) * 256.0;
  }

  static double _pixelXToLng(double px, double zoom) {
    return px / (math.pow(2.0, zoom) * 256.0) * 360.0 - 180.0;
  }

  static double _pixelYToLat(double py, double zoom) {
    final n = math.pi - 2.0 * math.pi * py / (math.pow(2.0, zoom) * 256.0);
    return 180.0 / math.pi * math.atan(0.5 * (math.exp(n) - math.exp(-n)));
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = constraints.maxHeight;

        final int currentZoom = _zoom.round().clamp(10, 18);
        final centerPx = _lngToPixelX(_centerLng, currentZoom.toDouble());
        final centerPy = _latToPixelY(_centerLat, currentZoom.toDouble());

        // Tile coverage
        final minPx = centerPx - width / 2.0;
        final maxPx = centerPx + width / 2.0;
        final minPy = centerPy - height / 2.0;
        final maxPy = centerPy + height / 2.0;

        final minTileX = (minPx / 256.0).floor();
        final maxTileX = (maxPx / 256.0).floor();
        final minTileY = (minPy / 256.0).floor();
        final maxTileY = (maxPy / 256.0).floor();

        final maxTilesOnZoom = math.pow(2, currentZoom).toInt();

        // Markers position
        final pickupScreenX = _lngToPixelX(widget.pickupLng, currentZoom.toDouble()) - centerPx + width / 2.0;
        final pickupScreenY = _latToPixelY(widget.pickupLat, currentZoom.toDouble()) - centerPy + height / 2.0;

        final destScreenX = _lngToPixelX(widget.destinationLng, currentZoom.toDouble()) - centerPx + width / 2.0;
        final destScreenY = _latToPixelY(widget.destinationLat, currentZoom.toDouble()) - centerPy + height / 2.0;

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onScaleStart: (details) {
            _baseScaleZoom = _zoom;
          },
          onScaleUpdate: (details) {
            setState(() {
              final newCenterPx = centerPx - details.focalPointDelta.dx;
              final newCenterPy = centerPy - details.focalPointDelta.dy;
              _centerLng = _pixelXToLng(newCenterPx, currentZoom.toDouble());
              _centerLat = _pixelYToLat(newCenterPy, currentZoom.toDouble());

              if (details.scale != 1.0) {
                final zoomDelta = math.log(details.scale) / math.ln2;
                _zoom = (_baseScaleZoom + zoomDelta).clamp(10.0, 18.0);
              }
            });
          },
          onDoubleTap: () {
            setState(() {
              if (_zoom < 17.0) _zoom += 1.0;
            });
          },
          child: Stack(
            children: [
              // 1. Base Map Background
              Container(color: const Color(0xFFE5E9E0)),

              // 2. OpenStreetMap / CartoDB Raster Tiles Grid
              ...() {
                final tiles = <Widget>[];
                for (int tx = minTileX; tx <= maxTileX; tx++) {
                  for (int ty = minTileY; ty <= maxTileY; ty++) {
                    if (ty < 0 || ty >= maxTilesOnZoom) continue;
                    final wrappedTx = ((tx % maxTilesOnZoom) + maxTilesOnZoom) % maxTilesOnZoom;

                    final tileLeft = tx * 256.0 - centerPx + width / 2.0;
                    final tileTop = ty * 256.0 - centerPy + height / 2.0;

                    final tileUrl = 'https://tile.openstreetmap.org/$currentZoom/$wrappedTx/$ty.png';
                    final fallbackTileUrl = 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Street_Map/MapServer/tile/$currentZoom/$ty/$wrappedTx.jpg';

                    tiles.add(
                      Positioned(
                        left: tileLeft,
                        top: tileTop,
                        width: 256,
                        height: 256,
                        child: Image.network(
                          tileUrl,
                          headers: const {'User-Agent': 'CabAppMobility/1.0 (https://cabapp.com.ng)'},
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Image.network(
                            fallbackTileUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              decoration: BoxDecoration(
                                color: const Color(0xFFE8ECE9),
                                border: Border.all(color: Colors.black12, width: 0.5),
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }
                }
                return tiles;
              }(),

              // 3. Route Polyline Overlay
              CustomPaint(
                size: Size(width, height),
                painter: _RoutePainter(
                  startX: pickupScreenX,
                  startY: pickupScreenY,
                  endX: destScreenX,
                  endY: destScreenY,
                ),
              ),

              // 4. Pickup Pin
              Positioned(
                left: pickupScreenX - 16,
                top: pickupScreenY - 32,
                child: _buildPin(
                  isPickup: true,
                  title: widget.pickupAddress.split(',').first,
                ),
              ),

              // 5. Destination Pin
              Positioned(
                left: destScreenX - 16,
                top: destScreenY - 32,
                child: _buildPin(
                  isPickup: false,
                  title: widget.destinationAddress.split(',').first,
                ),
              ),

              // 5b. Live Driver Car Marker
              if (widget.driverLat != null && widget.driverLng != null)
                Positioned(
                  left: (_lngToPixelX(widget.driverLng!, currentZoom.toDouble()) - centerPx + width / 2.0) - 18,
                  top: (_latToPixelY(widget.driverLat!, currentZoom.toDouble()) - centerPy + height / 2.0) - 18,
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.navy,
                      shape: BoxShape.circle,
                      boxShadow: const [
                        BoxShadow(color: Colors.black38, blurRadius: 6, offset: Offset(0, 2)),
                      ],
                      border: Border.all(color: Colors.white, width: 2.5),
                    ),
                    child: const Icon(Icons.directions_car, color: Colors.white, size: 20),
                  ),
                ),

              // 5c. Nearby Online Fleet Vehicles
              if (widget.nearbyDrivers != null)
                ...widget.nearbyDrivers!.map((d) {
                  final dLat = (d['latitude'] as num?)?.toDouble();
                  final dLng = (d['longitude'] as num?)?.toDouble();
                  if (dLat == null || dLng == null) return const SizedBox.shrink();
                  final screenX = _lngToPixelX(dLng, currentZoom.toDouble()) - centerPx + width / 2.0;
                  final screenY = _latToPixelY(dLat, currentZoom.toDouble()) - centerPy + height / 2.0;
                  return Positioned(
                    left: screenX - 16,
                    top: screenY - 16,
                    child: Tooltip(
                      message: '${d['first_name'] ?? 'Driver'} · ${d['vehicle_category'] ?? 'Cab'}',
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: AppColors.navy,
                          shape: BoxShape.circle,
                          boxShadow: const [
                            BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2)),
                          ],
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: const Icon(Icons.directions_car, color: Colors.white, size: 16),
                      ),
                    ),
                  );
                }),

              // 6. Map Controls Overlay (Recenter, Zoom In, Zoom Out)
              Positioned(
                right: 14,
                bottom: 14,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildMapControlButton(
                      icon: Icons.my_location,
                      tooltip: 'Recenter',
                      onPressed: _recenter,
                    ),
                    const SizedBox(height: 8),
                    _buildMapControlButton(
                      icon: Icons.add,
                      tooltip: 'Zoom In',
                      onPressed: _zoomIn,
                    ),
                    const SizedBox(height: 4),
                    _buildMapControlButton(
                      icon: Icons.remove,
                      tooltip: 'Zoom Out',
                      onPressed: _zoomOut,
                    ),
                  ],
                ),
              ),

              // 7. OSM / CartoDB Attribution
              Positioned(
                left: 10,
                bottom: 6,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    '© OpenStreetMap, Esri',
                    style: TextStyle(fontSize: 8.5, color: Colors.black54),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPin({required bool isPickup, required String title}) {
    final color = isPickup ? AppColors.navy : AppColors.coral;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2))],
            border: Border.all(color: color, width: 1),
          ),
          child: Text(
            title,
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color),
          ),
        ),
        const SizedBox(height: 2),
        Container(
          width: 26,
          height: 26,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 5, offset: Offset(0, 3))],
          ),
          alignment: Alignment.center,
          child: Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMapControlButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onPressed,
  }) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2))],
      ),
      child: IconButton(
        icon: Icon(icon, size: 18, color: AppColors.navy),
        padding: EdgeInsets.zero,
        tooltip: tooltip,
        onPressed: onPressed,
      ),
    );
  }
}

class _RoutePainter extends CustomPainter {
  final double startX;
  final double startY;
  final double endX;
  final double endY;

  _RoutePainter({
    required this.startX,
    required this.startY,
    required this.endX,
    required this.endY,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final casingPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.9)
      ..strokeWidth = 6.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final routePaint = Paint()
      ..color = AppColors.navy
      ..strokeWidth = 4.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final path = Path();
    path.moveTo(startX, startY);

    // Smooth midpoint curve simulating actual highway trajectory
    final midX = (startX + endX) / 2.0;
    final midY = (startY + endY) / 2.0 - 20;

    path.quadraticBezierTo(midX, midY, endX, endY);

    canvas.drawPath(path, casingPaint);
    canvas.drawPath(path, routePaint);
  }

  @override
  bool shouldRepaint(covariant _RoutePainter oldDelegate) {
    return oldDelegate.startX != startX ||
        oldDelegate.startY != startY ||
        oldDelegate.endX != endX ||
        oldDelegate.endY != endY;
  }
}
