import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../app_state.dart';
import '../domain/models.dart';
import '../domain/stobbe_powers.dart';
import 'widgets.dart';

class _PlayerLocation {
  const _PlayerLocation({
    required this.latitude,
    required this.longitude,
    required this.accuracyMeters,
  });

  final double latitude;
  final double longitude;
  final double accuracyMeters;
}

class _RealLocationMap extends StatelessWidget {
  const _RealLocationMap({required this.location, required this.playerIcon});

  final _PlayerLocation location;
  final IconData playerIcon;

  @override
  Widget build(BuildContext context) {
    final center = LatLng(location.latitude, location.longitude);
    return FlutterMap(
      key: ValueKey('\${location.latitude}:\${location.longitude}'),
      options: MapOptions(
        initialCenter: center,
        initialZoom: 16,
        interactionOptions: const InteractionOptions(
          flags: InteractiveFlag.all,
        ),
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'nl.janstobbe.verstobbertje',
        ),
        MarkerLayer(
          markers: [
            Marker(
              point: center,
              width: 72,
              height: 72,
              child: Column(
                children: [
                  Icon(playerIcon, color: Color(0xff315c46), size: 42),
                  const Text(
                    'Jij',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class ActiveGameScreen extends StatefulWidget {
  const ActiveGameScreen({required this.state, super.key});

  final AppState state;

  @override
  State<ActiveGameScreen> createState() => _ActiveGameScreenState();
}

class _ActiveGameScreenState extends State<ActiveGameScreen> {
  late final Timer _timer;
  Timer? _powerEffectTimer;
  DateTime? _powerEffectStartedAt;
  Duration _powerEffectDuration = Duration.zero;
  int _pageIndex = 1;
  StobbePowerKind? _activePowerEffect;
  int _powerEffectId = 0;

  AppState get state => widget.state;

  @override
  void initState() {
    super.initState();
    state.syncActiveGameClock();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      state.syncActiveGameClock();
      if (mounted) setState(() {});
      if (state.activeGame.countdown.isFinished) {
        _timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    _powerEffectTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: state,
        builder: (context, _) => Scaffold(
          appBar: AppBar(
            title: const Text('Game X'),
            actions: [
              IconButton(
                tooltip: 'Vraag het de Stobbedetective',
                onPressed: _showDetectiveHelp,
                icon: const Icon(Icons.support_agent),
              ),
              const Padding(
                padding: EdgeInsets.all(12),
                child: DemoBadge(),
              ),
            ],
          ),
          body: IndexedStack(
            index: _pageIndex,
            children: [
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 760),
                  child: ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
                      _StatusRow(finished: state.gameFinished),
                      const SizedBox(height: 12),
                      _CountdownCard(state: state),
                    ],
                  ),
                ),
              ),
              _ActiveMapPage(
                state: state,
                onCatch: () => _showProximity(context),
                activePowerEffect: _activePowerEffect,
                activePowerDuration: _powerEffectDuration,
                activePowerRemaining: _powerEffectRemaining,
                powerEffectId: _powerEffectId,
              ),
              _StobbePowersPage(
                state: state,
                onActivate: _activatePower,
              ),
            ],
          ),
          bottomNavigationBar: NavigationBar(
            selectedIndex: _pageIndex,
            onDestinationSelected: (value) =>
                setState(() => _pageIndex = value),
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.dashboard_outlined),
                selectedIcon: Icon(Icons.dashboard),
                label: 'Overzicht',
              ),
              NavigationDestination(
                icon: Icon(Icons.map_outlined),
                selectedIcon: Icon(Icons.map),
                label: 'Kaart',
              ),
              NavigationDestination(
                icon: Icon(Icons.auto_awesome_outlined),
                selectedIcon: Icon(Icons.auto_awesome),
                label: 'Krachten',
              ),
            ],
          ),
        ),
      );

  void _activatePower(StobbePowerKind kind, String name) {
    if (!state.activateStobbePower(kind)) {
      _notice(context, '$name is niet meer beschikbaar.');
      return;
    }
    final definition = state.powerInventory.slotFor(kind)?.definition;
    final duration = definition?.duration ?? const Duration(seconds: 4);
    _powerEffectTimer?.cancel();
    _powerEffectStartedAt = DateTime.now();
    _powerEffectDuration = duration;
    setState(() {
      _pageIndex = 1;
      _activePowerEffect = kind;
      _powerEffectId++;
    });
    _notice(context, '$name is ingezet.');
    _powerEffectTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      if (_powerEffectRemaining == Duration.zero) {
        _powerEffectTimer?.cancel();
        setState(() {
          _activePowerEffect = null;
          _powerEffectStartedAt = null;
          _powerEffectDuration = Duration.zero;
        });
      } else {
        setState(() {});
      }
    });
  }

  Duration get _powerEffectRemaining {
    final started = _powerEffectStartedAt;
    if (started == null) return Duration.zero;
    final remaining =
        started.add(_powerEffectDuration).difference(DateTime.now());
    return remaining.isNegative ? Duration.zero : remaining;
  }

  void _showDetectiveHelp() {
    const titles = ['Het overzicht', 'Het speelveld', 'Jouw Stobbetas'];
    const explanations = [
      'Hier zie je de resterende tijd, jouw rol, de voortgang en alle '
          'acties van dit spel.',
      'Sleep om rond te kijken en knijp met twee vingers om te zoomen. '
          'Je kunt ook de plus- en minknoppen gebruiken. Met het vizier '
          'spring je terug naar je eigen positie. PAK SPELER controleert '
          'wie binnen de vangafstand staat.',
      'Dit is jouw tijdelijke Stobbetas. De fiches zijn de krachten die '
          'je tijdens dit spel hebt verzameld. Tik op een fiche voor uitleg '
          'of zet de kracht direct in. Alles vervalt na dit spel.',
    ];
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        contentPadding: const EdgeInsets.fromLTRB(24, 18, 24, 8),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                'assets/images/stobbekarakter.png',
                height: 150,
                fit: BoxFit.contain,
              ),
              Text(
                titles[_pageIndex],
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 8),
              Text(explanations[_pageIndex], textAlign: TextAlign.center),
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
    );
  }

  void _notice(BuildContext context, String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  void _showProximity(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: const Icon(Icons.radar, size: 42),
        title: const Text('Speler dichtbij!'),
        content: Text(
          'Er is een speler binnen '
          '${state.findDistanceMeters.toStringAsFixed(0)} meter.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Later'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              final applied = state.foundPlayer();
              if (applied) {
                _showFoundConfirmation(context);
              } else {
                _notice(context, 'Deze vondst is al verwerkt.');
              }
            },
            child: const Text('GEVONDEN'),
          ),
        ],
      ),
    );
  }

  void _showFoundConfirmation(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: const Icon(Icons.celebration, size: 46),
        title: const Text('Gevonden!'),
        content: const Text(
          'Je hebt speler XYZ uitgeschakeld.\n\n'
          'Jij ontvangt 80 punten. Iedere andere actieve zoeker ontvangt '
          '20 punten en iedere resterende hider 10 punten.',
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Verder zoeken'),
          ),
        ],
      ),
    );
  }
}

class _ActiveMapPage extends StatefulWidget {
  const _ActiveMapPage({
    required this.state,
    required this.onCatch,
    required this.activePowerEffect,
    required this.activePowerDuration,
    required this.activePowerRemaining,
    required this.powerEffectId,
  });

  final AppState state;
  final VoidCallback onCatch;
  final StobbePowerKind? activePowerEffect;
  final Duration activePowerDuration;
  final Duration activePowerRemaining;
  final int powerEffectId;

  @override
  State<_ActiveMapPage> createState() => _ActiveMapPageState();
}

class _ActiveMapPageState extends State<_ActiveMapPage>
    with SingleTickerProviderStateMixin {
  static const playerPosition = Offset(550, 410);

  final TransformationController controller = TransformationController();
  late final AnimationController powerAnimation;
  bool showLegend = false;
  bool didInitialCenter = false;
  Size viewportSize = Size.zero;
  _PlayerLocation? currentLocation;
  StreamSubscription<Position>? locationSubscription;
  String? locationError;

  @override
  void initState() {
    super.initState();
    powerAnimation = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );
    _startRealLocation();
  }

  Future<void> _startRealLocation() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        if (mounted) setState(() => locationError = 'Locatieservice staat uit.');
        return;
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        if (mounted) setState(() => locationError = 'Locatietoestemming is nodig.');
        return;
      }
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      _setRealLocation(position);
      locationSubscription = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 5,
        ),
      ).listen(_setRealLocation);
    } catch (_) {
      if (mounted) {
        setState(() => locationError = 'Je locatie kon niet worden opgehaald.');
      }
    }
  }

  void _setRealLocation(Position position) {
    if (!mounted) return;
    setState(() {
      locationError = null;
      currentLocation = _PlayerLocation(
        latitude: position.latitude,
        longitude: position.longitude,
        accuracyMeters: position.accuracy,
      );
    });
  }

  @override
  void didUpdateWidget(covariant _ActiveMapPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.powerEffectId != oldWidget.powerEffectId) {
      powerAnimation.forward(from: 0);
    }
  }

  @override
  void dispose() {
    locationSubscription?.cancel();
    controller.dispose();
    powerAnimation.dispose();
    super.dispose();
  }

  void zoom(double factor) {
    if (viewportSize.isEmpty) return;
    final currentScale = controller.value.getMaxScaleOnAxis();
    final nextScale = (currentScale * factor).clamp(.55, 3.0);
    final appliedFactor = nextScale / currentScale;
    final center = viewportSize.center(Offset.zero);
    controller.value = Matrix4.identity()
      ..translateByDouble(center.dx, center.dy, 0, 1)
      ..scaleByDouble(appliedFactor, appliedFactor, 1, 1)
      ..translateByDouble(-center.dx, -center.dy, 0, 1)
      ..multiply(controller.value);
  }

  void recenter() {
    if (viewportSize.isEmpty) return;
    final scale = controller.value.getMaxScaleOnAxis().clamp(.55, 3.0);
    // Alignment.center already places the canvas center in the viewport.
    // Scale around the player's scene position so the marker stays centered
    // on small screens as well as on desktop.
    controller.value = Matrix4.identity()
      ..translateByDouble(playerPosition.dx, playerPosition.dy, 0, 1)
      ..scaleByDouble(scale, scale, 1, 1)
      ..translateByDouble(-playerPosition.dx, -playerPosition.dy, 0, 1);
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, constraints) {
          viewportSize = constraints.biggest;
          if (!didInitialCenter && !viewportSize.isEmpty) {
            didInitialCenter = true;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) recenter();
            });
          }
          return Stack(
            children: [
              Positioned.fill(
                child: ClipRect(
                  child: InteractiveViewer(
                    transformationController: controller,
                    constrained: false,
                    alignment: Alignment.center,
                    minScale: .55,
                    maxScale: 3,
                    boundaryMargin: const EdgeInsets.all(300),
                    child: currentLocation == null
                        ? Center(
                            child: Card(
                              child: Padding(
                                padding: const EdgeInsets.all(18),
                                child: Text(
                                  locationError ??
                                      'Je echte locatie wordt opgehaald…',
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                          )
                        : _RealLocationMap(
                            location: currentLocation!,
                            playerIcon: markerIcon(widget.state.playerMarker),
                          ),
                  ),
                ),
              ),
              Positioned(
                top: 16,
                left: 16,
                child: Card(
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Text(
                      'Speelveld • '
                      '${widget.state.findDistanceMeters.toStringAsFixed(0)} m '
                      'vangafstand',
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 16,
                right: 16,
                child: Column(
                  children: [
                    _MapButton(
                      tooltip: 'Inzoomen',
                      icon: Icons.add,
                      onPressed: () => zoom(1.3),
                    ),
                    const SizedBox(height: 8),
                    _MapButton(
                      tooltip: 'Uitzoomen',
                      icon: Icons.remove,
                      onPressed: () => zoom(.75),
                    ),
                    const SizedBox(height: 8),
                    _MapButton(
                      tooltip: 'Terug naar mijn locatie',
                      icon: Icons.my_location,
                      onPressed: recenter,
                    ),
                    const SizedBox(height: 8),
                    _MapButton(
                      tooltip: 'Legenda',
                      icon: showLegend ? Icons.close : Icons.layers_outlined,
                      onPressed: () => setState(() => showLegend = !showLegend),
                    ),
                  ],
                ),
              ),
              if (widget.activePowerEffect != null)
                Positioned.fill(
                  child: IgnorePointer(
                    child: _PowerMapEffect(
                      kind: widget.activePowerEffect!,
                      animation: powerAnimation,
                      remaining: widget.activePowerRemaining,
                      total: widget.activePowerDuration > Duration.zero
                          ? widget.activePowerDuration
                          : const Duration(seconds: 1),
                    ),
                  ),
                ),
              if (showLegend)
                const Positioned(
                  left: 16,
                  right: 82,
                  bottom: 88,
                  child: _MapLegend(),
                ),
              Positioned(
                left: 24,
                right: 24,
                bottom: 18,
                child: FilledButton.icon(
                  onPressed: widget.state.gameFinished ? null : widget.onCatch,
                  icon: const Icon(Icons.gps_fixed),
                  label: const Text('PAK SPELER'),
                ),
              ),
            ],
          );
        },
      );
}

class _PowerMapEffect extends StatelessWidget {
  const _PowerMapEffect({
    required this.kind,
    required this.animation,
    required this.remaining,
    required this.total,
  });

  final StobbePowerKind kind;
  final Animation<double> animation;
  final Duration remaining;
  final Duration total;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, constraints) => AnimatedBuilder(
          animation: animation,
          builder: (context, _) {
            final center = constraints.biggest.center(Offset.zero);
            final angle = animation.value * math.pi * 4;
            final isDrone = kind == StobbePowerKind.digitalDrone;
            final position = isDrone
                ? center + Offset(math.cos(angle) * 105, math.sin(angle) * 70)
                : center;
            final label = switch (kind) {
              StobbePowerKind.digitalDrone => 'Drone verkent het speelveld',
              StobbePowerKind.stobbeArm => 'Arm van de Stobbe beschermt je',
              StobbePowerKind.invisibilityPotion =>
                'Je bent tijdelijk onzichtbaar',
              _ => 'Stobbekracht actief',
            };
            final icon = switch (kind) {
              StobbePowerKind.digitalDrone => Icons.flight,
              StobbePowerKind.stobbeArm => Icons.precision_manufacturing,
              StobbePowerKind.invisibilityPotion => Icons.visibility_off,
              _ => Icons.auto_awesome,
            };
            final seconds = remaining.inSeconds.clamp(0, 5999);
            final minutes = seconds ~/ 60;
            final rest = seconds % 60;
            final timeLabel =
                '$minutes:${rest.toString().padLeft(2, '0')} resterend';
            final progress = (remaining.inMilliseconds / total.inMilliseconds)
                .clamp(0.0, 1.0)
                .toDouble();
            return Stack(
              children: [
                Positioned(
                  left: position.dx - 28,
                  top: position.dy - 28,
                  child: Transform.rotate(
                    angle: isDrone ? angle + math.pi / 2 : 0,
                    child: Material(
                      color: const Color(0xff6650a4),
                      elevation: 8,
                      shape: const CircleBorder(),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Icon(icon, color: Colors.white, size: 28),
                      ),
                    ),
                  ),
                ),
                Align(
                  alignment: const Alignment(0, -.72),
                  child: Card(
                    color: const Color(0xff6650a4),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(icon, color: Colors.white, size: 18),
                              const SizedBox(width: 6),
                              Text(label,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                  )),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(timeLabel,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              )),
                          const SizedBox(height: 4),
                          SizedBox(
                            width: 150,
                            child: LinearProgressIndicator(
                              value: progress,
                              minHeight: 3,
                              backgroundColor: Colors.white24,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      );
}

class _MapButton extends StatelessWidget {
  const _MapButton(
      {required this.tooltip, required this.icon, required this.onPressed});
  final String tooltip;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => FloatingActionButton.small(
        heroTag: tooltip,
        tooltip: tooltip,
        onPressed: onPressed,
        child: Icon(icon),
      );
}

class _GameMapCanvas extends StatelessWidget {
  const _GameMapCanvas({required this.playerIcon});

  final IconData playerIcon;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: 1100,
        height: 820,
        child: Stack(
          children: [
            Positioned.fill(child: CustomPaint(painter: _GameMapPainter())),
            Positioned(
              left: 520,
              top: 375,
              child: _MapMarker(
                icon: playerIcon,
                label: 'Jij',
                color: const Color(0xff315c46),
              ),
            ),
            const Positioned(
              left: 730,
              top: 230,
              child: _MapMarker(
                  icon: Icons.help_outline,
                  label: 'Zoekcirkel',
                  color: Color(0xffe5a62c)),
            ),
            const Positioned(
              left: 275,
              top: 565,
              child: _MapMarker(
                  icon: Icons.auto_awesome,
                  label: 'Stobbekracht',
                  color: Color(0xff6650a4)),
            ),
            const Positioned(
              left: 870,
              top: 520,
              child: _MapMarker(
                  icon: Icons.inventory_2,
                  label: 'Stobbekist',
                  color: Color(0xffa86b2d)),
            ),
          ],
        ),
      );
}

class _GameMapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
        Offset.zero & size, Paint()..color = const Color(0xffdce9d4));
    final grid = Paint()
      ..color = const Color(0x44315c46)
      ..strokeWidth = 1;
    for (double x = 0; x < size.width; x += 80) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), grid);
    }
    for (double y = 0; y < size.height; y += 80) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }
    final roads = Paint()
      ..color = Colors.white70
      ..strokeWidth = 22
      ..style = PaintingStyle.stroke;
    final road = Path()
      ..moveTo(-40, 180)
      ..cubicTo(260, 70, 520, 300, 1140, 120)
      ..moveTo(120, 860)
      ..cubicTo(180, 510, 690, 650, 980, -40);
    canvas.drawPath(road, roads);
    final boundary = Paint()
      ..color = const Color(0xff315c46)
      ..strokeWidth = 5
      ..style = PaintingStyle.stroke;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          const Rect.fromLTWH(105, 80, 890, 650), const Radius.circular(60)),
      boundary,
    );
    canvas.drawCircle(
      const Offset(550, 410),
      105,
      Paint()
        ..color = const Color(0x33315c46)
        ..style = PaintingStyle.fill,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _MapMarker extends StatelessWidget {
  const _MapMarker(
      {required this.icon, required this.label, required this.color});
  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Column(
        children: [
          Material(
            color: color,
            shape: const CircleBorder(),
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Icon(icon, color: Colors.white, size: 28),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
            color: Colors.white,
            child: Text(label,
                style:
                    const TextStyle(fontSize: 11, fontWeight: FontWeight.w800)),
          ),
        ],
      );
}

class _MapLegend extends StatelessWidget {
  const _MapLegend();

  @override
  Widget build(BuildContext context) => const Card(
        child: Padding(
          padding: EdgeInsets.all(12),
          child: Wrap(
            spacing: 14,
            runSpacing: 8,
            children: [
              _LegendItem(Icons.person_pin_circle, 'Jij'),
              _LegendItem(Icons.help_outline, 'Zoekcirkel'),
              _LegendItem(Icons.auto_awesome, 'Stobbekracht'),
              _LegendItem(Icons.inventory_2, 'Stobbekist: profielpunten'),
            ],
          ),
        ),
      );
}

class _LegendItem extends StatelessWidget {
  const _LegendItem(this.icon, this.label);
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [Icon(icon, size: 20), const SizedBox(width: 6), Text(label)],
      );
}

class _StobbePowersPage extends StatelessWidget {
  const _StobbePowersPage({required this.state, required this.onActivate});

  final AppState state;
  final void Function(StobbePowerKind kind, String name) onActivate;

  @override
  Widget build(BuildContext context) => Container(
        color: const Color(0xffefe3ca),
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              'Jouw Stobbetas',
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(fontWeight: FontWeight.w900),
            ),
            const Text(
                'Verzameld in dit spel • ongebruikte fiches vervallen na afloop'),
            const SizedBox(height: 18),
            Center(
              child: Container(
                width: 620,
                padding: const EdgeInsets.fromLTRB(22, 12, 22, 26),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xffa76b35), Color(0xff70431f)],
                  ),
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: const Color(0xff4f2d16), width: 4),
                  boxShadow: const [
                    BoxShadow(
                        color: Colors.black26,
                        blurRadius: 14,
                        offset: Offset(0, 8))
                  ],
                ),
                child: Column(
                  children: [
                    Container(
                      width: 150,
                      height: 24,
                      decoration: BoxDecoration(
                        color: const Color(0xff4f2d16),
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    const SizedBox(height: 20),
                    GridView.count(
                      crossAxisCount:
                          MediaQuery.sizeOf(context).width < 520 ? 2 : 3,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 16,
                      childAspectRatio: .72,
                      children: state.powerInventory.slots.map((slot) {
                        final details = _powerDetails(slot.definition.kind);
                        return _PowerToken(
                          icon: details.icon,
                          name: slot.definition.name,
                          description: details.description,
                          count: slot.quantity,
                          color: details.color,
                          cooldownRemaining: slot.cooldownRemaining(),
                          cooldownUntil: slot.cooldownUntil,
                          showCooldownTimer: slot.quantity > 0 &&
                              slot.uses < slot.definition.maxUsesPerGame,
                          enabled: !state.gameFinished &&
                              slot.canUse(state.powerInventory.phase),
                          onActivate: () => onActivate(
                            slot.definition.kind,
                            slot.definition.name,
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
}

class _PowerToken extends StatelessWidget {
  const _PowerToken({
    required this.icon,
    required this.name,
    required this.description,
    required this.count,
    required this.color,
    required this.cooldownRemaining,
    required this.cooldownUntil,
    required this.showCooldownTimer,
    required this.enabled,
    required this.onActivate,
  });
  final IconData icon;
  final String name;
  final String description;
  final int count;
  final Color color;
  final Duration cooldownRemaining;
  final DateTime? cooldownUntil;
  final bool showCooldownTimer;
  final bool enabled;
  final VoidCallback onActivate;

  @override
  Widget build(BuildContext context) => InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => _showPower(context),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xfff5e9d0),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xffd2b98d), width: 2),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 68,
                    height: 68,
                    decoration: BoxDecoration(
                      color: enabled ? color : Colors.grey,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 4),
                      boxShadow: const [
                        BoxShadow(color: Colors.black26, blurRadius: 6)
                      ],
                    ),
                    child: Icon(icon, color: Colors.white, size: 34),
                  ),
                  Positioned(
                    right: -8,
                    top: -8,
                    child: CircleAvatar(
                      radius: 15,
                      backgroundColor: const Color(0xff2d2118),
                      child: Text(
                        '×$count',
                        style: const TextStyle(
                            color: Colors.white, fontWeight: FontWeight.w900),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(name,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontWeight: FontWeight.w800)),
              if (showCooldownTimer && cooldownRemaining > Duration.zero) ...[
                const SizedBox(height: 2),
                Text(
                  'Opnieuw inzetbaar over ${_formatPowerDuration(cooldownRemaining)}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 10, color: Colors.black54),
                ),
              ],
              const SizedBox(height: 6),
              FilledButton.tonal(
                onPressed: enabled ? onActivate : null,
                style: const ButtonStyle(
                  visualDensity: VisualDensity.compact,
                  padding: WidgetStatePropertyAll(
                    EdgeInsets.symmetric(horizontal: 10),
                  ),
                ),
                child: const Text('INZETTEN'),
              ),
            ],
          ),
        ),
      );

  void _showPower(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      builder: (_) => _PowerDetailsSheet(
        icon: icon,
        name: name,
        description: description,
        color: color,
        cooldownUntil: cooldownUntil,
        showCooldownTimer: showCooldownTimer,
        onActivate: onActivate,
      ),
    );
  }
}

class _PowerDetailsSheet extends StatefulWidget {
  const _PowerDetailsSheet({
    required this.icon,
    required this.name,
    required this.description,
    required this.color,
    required this.cooldownUntil,
    required this.showCooldownTimer,
    required this.onActivate,
  });

  final IconData icon;
  final String name;
  final String description;
  final Color color;
  final DateTime? cooldownUntil;
  final bool showCooldownTimer;
  final VoidCallback onActivate;

  @override
  State<_PowerDetailsSheet> createState() => _PowerDetailsSheetState();
}

class _PowerDetailsSheetState extends State<_PowerDetailsSheet> {
  late final Timer _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  Duration get _cooldownRemaining {
    final until = widget.cooldownUntil;
    if (until == null) return Duration.zero;
    final remaining = until.difference(DateTime.now());
    return remaining.isNegative ? Duration.zero : remaining;
  }

  @override
  Widget build(BuildContext context) {
    final remaining = _cooldownRemaining;
    final canActivate =
        widget.showCooldownTimer && remaining == Duration.zero;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(widget.icon, color: widget.color, size: 52),
          Text(
            widget.name,
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          Text(widget.description, textAlign: TextAlign.center),
          if (widget.showCooldownTimer && remaining > Duration.zero)
            Text(
              'Opnieuw inzetbaar over '
              '${_formatPowerDuration(remaining)}',
            ),
          if (!widget.showCooldownTimer)
            const Text('Deze kracht is opgebruikt.'),
          const SizedBox(height: 14),
          FilledButton(
            onPressed: canActivate
                ? () {
                    Navigator.pop(context);
                    widget.onActivate();
                  }
                : null,
            child: const Text('Zet Stobbekracht in'),
          ),
        ],
      ),
    );
  }
}

String _formatPowerDuration(Duration duration) {
  final seconds = duration.inSeconds.clamp(0, 5999);
  final minutes = seconds ~/ 60;
  final rest = seconds % 60;
  return '$minutes:${rest.toString().padLeft(2, '0')}';
}

({IconData icon, String description, Color color}) _powerDetails(
  StobbePowerKind kind,
) =>
    switch (kind) {
      StobbePowerKind.digitalDrone => (
          icon: Icons.flight,
          description:
              'Geeft je tijdelijk een ruimer zicht op het speelveld en laat meer van de omgeving zien.',
          color: const Color(0xff3f6f91),
        ),
      StobbePowerKind.stobbeArm => (
          icon: Icons.precision_manufacturing,
          description:
              'Verkleint tijdelijk jouw zichtbaarheid en maakt het voor zoekers moeilijker om je te vinden.',
          color: const Color(0xff477653),
        ),
      StobbePowerKind.invisibilityPotion => (
          icon: Icons.visibility_off,
          description:
              'Verbergt jouw digitale positie gedurende een korte periode op de kaart van andere spelers.',
          color: const Color(0xff74558c),
        ),
      _ => (
          icon: Icons.auto_awesome,
          description: 'Een tijdelijke Stobbekracht voor dit spel.',
          color: const Color(0xff6650a4),
        ),
    };

class _StatusRow extends StatelessWidget {
  const _StatusRow({required this.finished});

  final bool finished;

  @override
  Widget build(BuildContext context) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Chip(
              avatar: Icon(Icons.person_search), label: Text('ROL: ZOEKER')),
          Chip(
            avatar: const Icon(Icons.circle, size: 12),
            label: Text(finished ? 'AFGEROND' : 'SPEL ACTIEF'),
          ),
        ],
      );
}

class _CountdownCard extends StatelessWidget {
  const _CountdownCard({required this.state});

  final AppState state;

  @override
  Widget build(BuildContext context) {
    final remaining = state.activeGame.countdown.remaining;
    final hours = remaining.inHours;
    final minutes = remaining.inMinutes.remainder(60);
    final seconds = remaining.inSeconds.remainder(60);
    final value = state.playerValue(PlayerRole.seeker);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          const Text(
            'RESTERENDE TIJD',
            style: TextStyle(
              color: Colors.white70,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '${hours.toString().padLeft(2, '0')}:'
            '${minutes.toString().padLeft(2, '0')}:'
            '${seconds.toString().padLeft(2, '0')}',
            semanticsLabel: '$hours uur, $minutes minuten en $seconds seconden',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 34,
              fontWeight: FontWeight.w900,
            ),
          ),
          const Divider(color: Colors.white24, height: 28),
          Text(
            '${state.activeGame.playersFound} van de '
            '${state.activeGame.totalPlayers} gevonden',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 20,
            ),
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value:
                state.activeGame.playersFound / state.activeGame.totalPlayers,
            minHeight: 9,
            borderRadius: BorderRadius.circular(8),
          ),
          const SizedBox(height: 14),
          Text(
            '${state.personallyFound} van ${state.activeGame.playersFound} '
            'door mij gevonden',
            style: const TextStyle(color: Colors.white),
          ),
          Text(
            state.inActiveZone ? 'Binnen speelgebied' : 'Buiten speelgebied',
            style: const TextStyle(color: Colors.white),
          ),
          Text(
            'Omdat je ${state.activeGame.playersFound} spelers hebt gevonden '
            'is je actuele spelwaarde ${value.toStringAsFixed(0)} punten.',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white),
          ),
          const Text(
            'Actuele puntenwaarde',
            style: TextStyle(color: Colors.white60, fontSize: 11),
          ),
          const Divider(color: Colors.white24, height: 28),
          Row(
            children: [
              Expanded(
                child: _ScoreStat(
                  value: '${state.questionPoints + value.round()}',
                  label: 'spelpunten verzameld',
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: _ScoreStat(
                  value: '3e',
                  label: 'van 20 spelers',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ScoreStat extends StatelessWidget {
  const _ScoreStat({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: const Color(0x1fffffff),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w900,
              ),
            ),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ],
        ),
      );
}
