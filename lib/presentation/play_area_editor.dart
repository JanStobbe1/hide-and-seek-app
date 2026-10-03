import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../domain/game_setup.dart';
import '../domain/models.dart';
import '../services/area_lookup.dart';

List<LatLng> mapPoints(List<AreaPoint> points) =>
    points.map((p) => LatLng(p.latitude, p.longitude)).toList();

class PlayAreaMap extends StatelessWidget {
  const PlayAreaMap(
      {required this.boundary, this.height = 240, this.controller, super.key});
  final List<AreaPoint> boundary;
  final double height;
  final MapController? controller;

  @override
  Widget build(BuildContext context) {
    if (boundary.isEmpty) return const Text('Nog geen speelgrens gekozen.');
    return SizedBox(
      height: height,
      child: FlutterMap(
        mapController: controller,
        key: ValueKey(boundary.map((p) => p.toJson().join(',')).join(';')),
        options: MapOptions(
          initialCameraFit: CameraFit.bounds(
            bounds: LatLngBounds.fromPoints(mapPoints(boundary)),
            padding: const EdgeInsets.all(24),
          ),
        ),
        children: [
          const _Tiles(),
          playBoundaryLayer(boundary),
          const _MapCredit(),
        ],
      ),
    );
  }
}

PolygonLayer playBoundaryLayer(List<AreaPoint> points) => PolygonLayer(
      polygons: points.length < 3
          ? []
          : [
              Polygon(
                points: mapPoints(points),
                color: const Color(0x33315c46),
                borderColor: const Color(0xff315c46),
                borderStrokeWidth: 3,
              ),
            ],
    );

class _Tiles extends StatelessWidget {
  const _Tiles();
  @override
  Widget build(BuildContext context) => TileLayer(
        urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
        userAgentPackageName: 'nl.janstobbe.verstobbertje',
      );
}

class PlayAreaEditor extends StatefulWidget {
  const PlayAreaEditor({required this.area, super.key});
  final SearchArea area;
  @override
  State<PlayAreaEditor> createState() => _PlayAreaEditorState();
}

class _PlayAreaEditorState extends State<PlayAreaEditor> {
  final _controller = MapController();
  final _lookup = AreaLookup();
  late List<AreaPoint> _points;
  List<AreaPoint>? _beforeDrawing;
  bool _drawing = false;
  bool _loading = false;
  String? _message;
  final Set<int> _pointers = {};
  Offset? _pointerStart;
  bool _canPlacePoint = false;

  void _pointerDown(PointerDownEvent event) {
    if (!_drawing) return;
    if (_pointers.isEmpty) {
      _pointerStart = event.localPosition;
      _canPlacePoint = true;
    }
    _pointers.add(event.pointer);
    if (_pointers.length > 1) _canPlacePoint = false;
  }

  void _pointerMove(PointerMoveEvent event) {
    if (_pointerStart != null &&
        (event.localPosition - _pointerStart!).distance > 8) {
      _canPlacePoint = false;
    }
  }

  void _pointerUp(PointerUpEvent event) {
    final place = _drawing &&
        _canPlacePoint &&
        _pointers.length == 1 &&
        _points.length < 32;
    _pointers.remove(event.pointer);
    if (!place) return;
    final point = _controller.camera.offsetToCrs(event.localPosition);
    setState(() => _points.add(AreaPoint(point.latitude, point.longitude)));
  }

  @override
  void initState() {
    super.initState();
    _points = List.of(widget.area.boundary);
  }

  @override
  void dispose() {
    _controller.dispose();
    _lookup.dispose();
    super.dispose();
  }

  void _fit() {
    if (_points.length < 2) return;
    _controller.fitCamera(
      CameraFit.bounds(
        bounds: LatLngBounds.fromPoints(mapPoints(_points)),
        padding: const EdgeInsets.all(40),
      ),
    );
  }

  Future<void> _find() async {
    setState(() {
      _loading = true;
      _message = null;
    });
    try {
      final points = await _lookup.find(widget.area);
      if (!mounted) return;
      setState(() {
        _points = points;
        _message =
            'Dit is een rechthoek rond de gekozen locaties, geen exacte gemeentegrens. Pas hem aan waar nodig.';
      });
      _fit();
    } catch (error) {
      if (mounted) {
        setState(
          () => _message = error is FormatException
              ? error.message.toString()
              : 'Locatie zoeken lukt niet. Probeer opnieuw of teken zelf.',
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _scale(double factor) {
    final lat =
        _points.map((p) => p.latitude).reduce((a, b) => a + b) / _points.length;
    final lon = _points.map((p) => p.longitude).reduce((a, b) => a + b) /
        _points.length;
    final next = _points
        .map(
          (p) => AreaPoint(
            lat + (p.latitude - lat) * factor,
            lon + (p.longitude - lon) * factor,
          ),
        )
        .toList();
    final error = validatePlayBoundary(next);
    if (error != null) {
      setState(() => _message = error);
      return;
    }
    setState(() => _points = next);
    _fit();
  }

  @override
  Widget build(BuildContext context) {
    final error = validatePlayBoundary(_points);
    return Scaffold(
      appBar: AppBar(title: const Text('Kies je speelgrens')),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                _drawing
                    ? 'Tik in volgorde langs de rand. De laatste hoek wordt verbonden met de eerste.'
                    : 'Zoek je locatie of verplaats de kaart en teken zelf een grens.',
              ),
            ),
            Expanded(
              child: Listener(
                onPointerDown: _pointerDown,
                onPointerMove: _pointerMove,
                onPointerUp: _pointerUp,
                onPointerCancel: (event) {
                  _pointers.remove(event.pointer);
                  _canPlacePoint = false;
                },
                child: FlutterMap(
                  mapController: _controller,
                  options: MapOptions(
                    initialCenter: const LatLng(52.1, 5.3),
                    initialZoom: 7,
                    onMapReady: () {
                      if (_points.isEmpty) _find();
                    },
                    interactionOptions: InteractionOptions(
                      flags: _drawing
                          ? InteractiveFlag.all & ~InteractiveFlag.doubleTapZoom
                          : InteractiveFlag.all,
                    ),
                    initialCameraFit: _points.length >= 3
                        ? CameraFit.bounds(
                            bounds: LatLngBounds.fromPoints(mapPoints(_points)),
                            padding: const EdgeInsets.all(40),
                          )
                        : null,
                  ),
                  children: [
                    const _Tiles(),
                    playBoundaryLayer(_points),
                    if (_drawing)
                      MarkerLayer(
                        markers: [
                          for (var i = 0; i < _points.length; i++)
                            Marker(
                              point: LatLng(
                                _points[i].latitude,
                                _points[i].longitude,
                              ),
                              width: 28,
                              height: 28,
                              child: CircleAvatar(
                                child: Text(
                                  '${i + 1}',
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ),
                            ),
                        ],
                      ),
                    const _MapCredit(),
                  ],
                ),
              ),
            ),
            Flexible(
              flex: 0,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.sizeOf(context).height * .42,
                ),
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_message != null)
                          Text(_message!, textAlign: TextAlign.center),
                        if (_drawing && error != null)
                          Text(error, textAlign: TextAlign.center),
                        if (_loading) const LinearProgressIndicator(),
                        Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          alignment: WrapAlignment.center,
                          children: [
                            if (!_drawing) ...[
                              OutlinedButton(
                                onPressed: _loading ? null : _find,
                                child: const Text('Zoek gekozen locatie'),
                              ),
                              OutlinedButton(
                                onPressed: _loading
                                    ? null
                                    : () => setState(() {
                                          _beforeDrawing = List.of(_points);
                                          _points = [];
                                          _drawing = true;
                                          _message = null;
                                        }),
                                child: const Text('Teken grens'),
                              ),
                              OutlinedButton(
                                onPressed: _loading || error != null
                                    ? null
                                    : () => _scale(.8),
                                child: const Text('Gebied kleiner'),
                              ),
                              OutlinedButton(
                                onPressed: _loading || error != null
                                    ? null
                                    : () => _scale(1.25),
                                child: const Text('Gebied groter'),
                              ),
                            ] else ...[
                              TextButton(
                                onPressed: _points.isEmpty
                                    ? null
                                    : () =>
                                        setState(() => _points.removeLast()),
                                child: const Text('Punt terug'),
                              ),
                              TextButton(
                                onPressed: () => setState(() {
                                  _points = _beforeDrawing ?? [];
                                  _drawing = false;
                                }),
                                child: const Text('Tekenen annuleren'),
                              ),
                            ],
                            TextButton(
                              onPressed: _points.length < 3 ? null : _fit,
                              child: const Text('Hele gebied'),
                            ),
                          ],
                        ),
                        FilledButton.icon(
                          onPressed: _loading || error != null
                              ? null
                              : () => Navigator.pop(
                                    context,
                                    List<AreaPoint>.of(_points),
                                  ),
                          icon: const Icon(Icons.check),
                          label: const Text('Gebruik dit speelgebied'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MapCredit extends StatelessWidget {
  const _MapCredit();

  @override
  Widget build(BuildContext context) => const Align(
        alignment: Alignment.bottomRight,
        child: Padding(
          padding: EdgeInsets.all(4),
          child: ColoredBox(
            color: Colors.white,
            child: Padding(
              padding: EdgeInsets.all(4),
              child: Text('© OpenStreetMap contributors',
                  style: TextStyle(fontSize: 11, color: Colors.black87),
                  textAlign: TextAlign.right),
            ),
          ),
        ),
      );
}
