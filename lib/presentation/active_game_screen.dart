import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../app_state.dart';
import '../domain/models.dart';
import 'widgets.dart';

class ActiveGameScreen extends StatefulWidget {
  const ActiveGameScreen({required this.state, super.key});

  final AppState state;

  @override
  State<ActiveGameScreen> createState() => _ActiveGameScreenState();
}

class _ActiveGameScreenState extends State<ActiveGameScreen> {
  late final Timer _timer;
  int _pageIndex = 1;

  AppState get state => widget.state;

  @override
  void initState() {
    super.initState();
    state.syncActiveGameClock();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      state.syncActiveGameClock();
      if (state.activeGame.countdown.isFinished) {
        _timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
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
              ),
              _StobbePowersPage(finished: state.gameFinished),
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
  const _ActiveMapPage({required this.state, required this.onCatch});

  final AppState state;
  final VoidCallback onCatch;

  @override
  State<_ActiveMapPage> createState() => _ActiveMapPageState();
}

class _ActiveMapPageState extends State<_ActiveMapPage> {
  static const playerPosition = Offset(550, 410);
  static const opponentPosition = Offset(950, 130);

  final TransformationController controller = TransformationController();
  bool showLegend = false;
  bool didInitialCenter = false;
  Size viewportSize = Size.zero;

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  void zoom(double factor) {
    if (viewportSize.isEmpty) return;
    final currentScale = controller.value.getMaxScaleOnAxis();
    final nextScale = (currentScale * factor).clamp(.55, 3.0);
    final appliedFactor = nextScale / currentScale;
    final center = viewportSize.center(Offset.zero);
    controller.value = Matrix4.identity()
      ..translate(center.dx, center.dy)
      ..scale(appliedFactor)
      ..translate(-center.dx, -center.dy)
      ..multiply(controller.value);
  }

  void recenter() {
    if (viewportSize.isEmpty) return;
    final scale = controller.value.getMaxScaleOnAxis().clamp(.55, 3.0);
    final center = viewportSize.center(Offset.zero);
    controller.value = Matrix4.identity()
      ..translate(
        center.dx - playerPosition.dx * scale,
        center.dy - playerPosition.dy * scale,
      )
      ..scale(scale);
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
                    minScale: .55,
                    maxScale: 3,
                    boundaryMargin: const EdgeInsets.all(300),
                    child: _GameMapCanvas(
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
                      onPressed: () =>
                          setState(() => showLegend = !showLegend),
                    ),
                  ],
                ),
              ),
              AnimatedBuilder(
                animation: controller,
                builder: (context, _) => _PlayerDirectionIndicator(
                  controller: controller,
                  viewportSize: viewportSize,
                  scenePosition: opponentPosition,
                  label: 'Mila',
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
                  onPressed:
                      widget.state.gameFinished ? null : widget.onCatch,
                  icon: const Icon(Icons.gps_fixed),
                  label: const Text('PAK SPELER'),
                ),
              ),
            ],
          );
        },
      );
}

class _PlayerDirectionIndicator extends StatelessWidget {
  const _PlayerDirectionIndicator({
    required this.controller,
    required this.viewportSize,
    required this.scenePosition,
    required this.label,
  });

  final TransformationController controller;
  final Size viewportSize;
  final Offset scenePosition;
  final String label;

  @override
  Widget build(BuildContext context) {
    if (viewportSize.isEmpty) return const SizedBox.shrink();
    final screenPosition =
        MatrixUtils.transformPoint(controller.value, scenePosition);
    final safeRect = Rect.fromLTWH(
      52,
      88,
      math.max(0, viewportSize.width - 104),
      math.max(0, viewportSize.height - 196),
    );
    if (safeRect.contains(screenPosition)) return const SizedBox.shrink();

    final center = viewportSize.center(Offset.zero);
    final direction = screenPosition - center;
    final halfWidth = math.max(1.0, safeRect.width / 2);
    final halfHeight = math.max(1.0, safeRect.height / 2);
    final xFactor = direction.dx.abs() < .01
        ? double.infinity
        : halfWidth / direction.dx.abs();
    final yFactor = direction.dy.abs() < .01
        ? double.infinity
        : halfHeight / direction.dy.abs();
    final edgeFactor = math.min(xFactor, yFactor);
    final edge = center + direction * edgeFactor;
    final angle = math.atan2(direction.dy, direction.dx) + math.pi / 2;

    return Positioned(
      left: edge.dx - 30,
      top: edge.dy - 30,
      child: Semantics(
        label: '$label ligt buiten beeld',
        child: Column(
          children: [
            Transform.rotate(
              angle: angle,
              child: const Icon(
                Icons.navigation,
                color: Color(0xff8d3f54),
                size: 36,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                label,
                style:
                    const TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ),
      ),
    );
  }
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
              left: 930,
              top: 105,
              child: _MapMarker(
                icon: Icons.directions_run,
                label: 'Mila',
                color: Color(0xff8d3f54),
              ),
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
              _LegendItem(Icons.navigation, 'Speler buiten beeld'),
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
  const _StobbePowersPage({required this.finished});
  final bool finished;

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
                      children: [
                        _PowerToken(
                            icon: Icons.flight,
                            name: 'Digitale drone',
                            description:
                                'Geeft je tijdelijk een ruimer zicht op het speelveld en laat meer van de omgeving zien.',
                            count: 1,
                            color: const Color(0xff3f6f91),
                            enabled: !finished),
                        _PowerToken(
                            icon: Icons.precision_manufacturing,
                            name: 'Arm van de Stobbe',
                            description:
                                'Verkleint tijdelijk jouw zichtbaarheid en maakt het voor zoekers moeilijker om je te vinden.',
                            count: 2,
                            color: const Color(0xff477653),
                            enabled: !finished),
                        _PowerToken(
                            icon: Icons.visibility_off,
                            name: 'Onzichtbaar',
                            description:
                                'Verbergt jouw digitale positie gedurende een korte periode op de kaart van andere spelers.',
                            count: 1,
                            color: const Color(0xff74558c),
                            enabled: !finished),
                      ],
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
    required this.enabled,
  });
  final IconData icon;
  final String name;
  final String description;
  final int count;
  final Color color;
  final bool enabled;

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
                    width: 78,
                    height: 78,
                    decoration: BoxDecoration(
                      color: enabled ? color : Colors.grey,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 4),
                      boxShadow: const [
                        BoxShadow(color: Colors.black26, blurRadius: 6)
                      ],
                    ),
                    child: Icon(icon, color: Colors.white, size: 38),
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
              const SizedBox(height: 9),
              Text(name,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontWeight: FontWeight.w800)),
              const SizedBox(height: 6),
              FilledButton.tonal(
                onPressed: enabled ? () => _activate(context) : null,
                child: const Text('INZETTEN'),
              ),
            ],
          ),
        ),
      );

  void _showPower(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 52),
            Text(
              name,
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            Text(description, textAlign: TextAlign.center),
            const SizedBox(height: 14),
            FilledButton(
              onPressed: enabled
                  ? () {
                      Navigator.pop(sheetContext);
                      _activate(context);
                    }
                  : null,
              child: const Text('Zet Stobbekracht in'),
            ),
          ],
        ),
      ),
    );
  }

  void _activate(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text('$name is ingezet. Demo: voorraad wordt later live.')),
    );
  }
}

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
