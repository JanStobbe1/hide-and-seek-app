import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as latlong;

import '../config/app_config.dart';
import '../domain/models.dart';
import '../domain/profile_models.dart';
import 'seasonal_stobbe.dart';

class SectionTitle extends StatelessWidget {
  const SectionTitle(this.title, {this.action, super.key});

  final String title;
  final Widget? action;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 24, bottom: 12),
        child: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.w800),
              ),
            ),
            if (action != null) action!,
          ],
        ),
      );
}

class StatPill extends StatelessWidget {
  const StatPill({
    required this.icon,
    required this.value,
    required this.label,
    super.key,
  });

  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) => Expanded(
        child: Semantics(
          label: '$label: $value',
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0x1fffffff),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Icon(icon, color: Colors.white),
                const SizedBox(height: 6),
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                  ),
                ),
                Text(
                  label,
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
        ),
      );
}

class DemoBadge extends StatelessWidget {
  const DemoBadge({super.key});

  @override
  Widget build(BuildContext context) {
    if (!AppConfig.demoMode) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xffffe19a),
        borderRadius: BorderRadius.circular(99),
      ),
      child: const Text(
        'DEMO MODE',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w900,
          letterSpacing: .5,
        ),
      ),
    );
  }
}

class MapPlaceholder extends StatelessWidget {
  const MapPlaceholder({
    this.height = 220,
    this.playerMarker = PlayerMarker.ghost,
    super.key,
  });

  final double height;
  final PlayerMarker playerMarker;

  @override
  Widget build(BuildContext context) => Semantics(
        label: 'Gesimuleerde kaart van het zoekgebied',
        child: Container(
          height: height,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: const Color(0xffdce9d4),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xffb6ceb0)),
          ),
          child: Stack(
            children: [
              ...List.generate(
                6,
                (index) => Positioned(
                  left: index * 72.0 - 50,
                  top: index.isEven ? 20 : 105,
                  child: Transform.rotate(
                    angle: -.25,
                    child:
                        Container(width: 190, height: 3, color: Colors.white70),
                  ),
                ),
              ),
              Positioned.fill(child: CustomPaint(painter: _AreaPainter())),
              Positioned(
                left: 28,
                top: 24,
                child: _Marker(
                  icon: markerIcon(playerMarker),
                  color: Theme.of(context).colorScheme.primary,
                  label: 'Jij',
                ),
              ),
              const Positioned(
                right: 38,
                top: 65,
                child: _Marker(
                  icon: Icons.location_on,
                  color: Color(0xffef6c4d),
                  label: 'Speler',
                ),
              ),
              const Positioned(
                left: 125,
                bottom: 24,
                child: _Marker(
                  icon: Icons.visibility,
                  color: Color(0xffe5a62c),
                  label: 'Hint',
                ),
              ),
              const Positioned(
                left: 14,
                bottom: 12,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.all(Radius.circular(10)),
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(8),
                    child: Text(
                      'Mockkaart • geen GPS',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
}

class SearchAreaMap extends StatefulWidget {
  const SearchAreaMap({required this.area, this.height = 240, super.key});

  final SearchArea area;
  final double height;

  @override
  State<SearchAreaMap> createState() => _SearchAreaMapState();
}

class _SearchAreaMapState extends State<SearchAreaMap> {
  final MapController controller = MapController();

  @override
  Widget build(BuildContext context) {
    final center = _centerFor(widget.area);
    final zoom = _zoomFor(widget.area);
    return Semantics(
      label: 'Interactieve kaart van het gekozen speelgebied',
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: SizedBox(
          height: widget.height,
          child: Stack(
            children: [
              FlutterMap(
                key: ValueKey(widget.area.label + widget.area.specificArea),
                mapController: controller,
                options: MapOptions(
                  initialCenter: center,
                  initialZoom: zoom,
                  interactionOptions: const InteractionOptions(
                    flags: InteractiveFlag.all,
                  ),
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'nl.janstobbe.verstobbertje',
                  ),
                  PolygonLayer(
                    polygons: [
                      Polygon(
                        points: _areaPolygon(center, zoom),
                        color: const Color(0x33315c46),
                        borderColor: const Color(0xff315c46),
                        borderStrokeWidth: 2,
                      ),
                    ],
                  ),
                ],
              ),
              Positioned(
                right: 10,
                top: 10,
                child: Column(
                  children: [
                    _MapButton(
                      icon: Icons.add,
                      tooltip: 'Uitzoomen',
                      onPressed: () => controller.move(
                        controller.camera.center,
                        controller.camera.zoom - 1,
                      ),
                    ),
                    const SizedBox(height: 6),
                    _MapButton(
                      icon: Icons.remove,
                      tooltip: 'Inzoomen',
                      onPressed: () => controller.move(
                        controller.camera.center,
                        controller.camera.zoom + 1,
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                left: 10,
                right: 10,
                bottom: 10,
                child: Card(
                  margin: EdgeInsets.zero,
                  color: Colors.white.withValues(alpha: .92),
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                    child: Text(
                      'Versleep en zoom om de kaart te bekijken\n'
                      '© OpenStreetMap contributors',
                      style: Theme.of(context).textTheme.bodySmall,
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  latlong.LatLng _centerFor(SearchArea area) {
    final source = '${area.city} ${area.province}'.toLowerCase();
    const known = <String, latlong.LatLng>{
      'almere': latlong.LatLng(52.3508, 5.2647),
      'amsterdam': latlong.LatLng(52.3676, 4.9041),
      'dronten': latlong.LatLng(52.525, 5.718),
      'antwerpen': latlong.LatLng(51.2194, 4.4025),
      'utrecht': latlong.LatLng(52.0907, 5.1214),
      'rotterdam': latlong.LatLng(51.9244, 4.4777),
      'den haag': latlong.LatLng(52.0705, 4.3007),
      'eindhoven': latlong.LatLng(51.4416, 5.4697),
      'groningen': latlong.LatLng(53.2194, 6.5665),
      'flevoland': latlong.LatLng(52.527, 5.595),
    };
    for (final entry in known.entries) {
      if (source.contains(entry.key)) return entry.value;
    }
    return const latlong.LatLng(52.1326, 5.2913);
  }

  double _zoomFor(SearchArea area) {
    if (area.neighbourhood != 'Alle') return 14;
    if (area.city != 'Alle') return 12;
    if (area.province != 'Alle') return 9;
    return 7;
  }

  List<latlong.LatLng> _areaPolygon(latlong.LatLng center, double zoom) {
    final span = 0.28 / (zoom / 7);
    return [
      latlong.LatLng(center.latitude - span, center.longitude - span),
      latlong.LatLng(center.latitude - span * .7, center.longitude + span),
      latlong.LatLng(center.latitude + span, center.longitude + span * .8),
      latlong.LatLng(center.latitude + span * .65, center.longitude - span),
    ];
  }
}

class _MapButton extends StatelessWidget {
  const _MapButton(
      {required this.icon, required this.tooltip, required this.onPressed});

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        elevation: 2,
        child: IconButton(
          onPressed: onPressed,
          tooltip: tooltip,
          icon: Icon(icon),
          visualDensity: VisualDensity.compact,
        ),
      );
}

IconData markerIcon(PlayerMarker marker) => switch (marker) {
      PlayerMarker.ghost => Icons.cruelty_free,
      PlayerMarker.wolf => Icons.pets,
      PlayerMarker.police => Icons.local_police,
      PlayerMarker.explorer => Icons.explore,
    };

class _Marker extends StatelessWidget {
  const _Marker({required this.icon, required this.color, required this.label});

  final IconData icon;
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) => Tooltip(
        message: label,
        child: Icon(icon, color: color, size: 40),
      );
}

class _AreaPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0x44315c46)
      ..style = PaintingStyle.fill;
    final path = Path()
      ..moveTo(size.width * .18, size.height * .25)
      ..lineTo(size.width * .75, size.height * .12)
      ..lineTo(size.width * .92, size.height * .72)
      ..lineTo(size.width * .3, size.height * .88)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class StobbeDetectiveButton extends StatelessWidget {
  const StobbeDetectiveButton({
    required this.pageTitle,
    required this.explanation,
    super.key,
  });

  final String pageTitle;
  final String explanation;

  @override
  Widget build(BuildContext context) => IconButton(
        tooltip: 'Vraag het de Stobbedetective',
        icon: const Icon(Icons.support_agent),
        onPressed: () => showDialog<void>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            contentPadding: const EdgeInsets.fromLTRB(24, 18, 24, 8),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SeasonalStobbe(
                    assetPath: 'assets/images/stobbekarakter.png',
                    height: 200,
                    fit: BoxFit.contain,
                  ),
                  Text(
                    pageTitle,
                    textAlign: TextAlign.center,
                    style: Theme.of(context)
                        .textTheme
                        .headlineSmall
                        ?.copyWith(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 8),
                  Text(explanation, textAlign: TextAlign.center),
                ],
              ),
            ),
            actions: [
              FilledButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Begrepen, detective!'),
              ),
            ],
          ),
        ),
      );
}
