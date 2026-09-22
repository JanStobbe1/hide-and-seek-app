import 'dart:async';

import 'package:flutter/material.dart';

import '../app_state.dart';
import '../domain/models.dart';
import '../domain/private_questions.dart';
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
                      if (!state.inActiveZone) _ZoneAlarm(state: state),
                      const SectionTitle('Zoekgebied'),
                      MapPlaceholder(playerMarker: state.playerMarker),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          OutlinedButton(
                            onPressed: _simulateGpsSpike,
                            child: const Text('Simuleer GPS-piek'),
                          ),
                          OutlinedButton(
                            onPressed: _confirmOutsideZone,
                            child: const Text('Bevestig buiten zone'),
                          ),
                          OutlinedButton(
                            onPressed:
                                state.inActiveZone ? null : _returnToZone,
                            child: const Text('Keer terug in zone'),
                          ),
                        ],
                      ),
                      const SectionTitle('Jouw acties'),
                      _GameActions(
                        state: state,
                        onHint: _useHint,
                        onQuestions: _showQuestions,
                      ),
                      const SizedBox(height: 18),
                      FilledButton.icon(
                        onPressed: state.gameFinished
                            ? null
                            : () => _showProximity(context),
                        icon: const Icon(Icons.sensors),
                        label: Text(
                          'Simuleer speler binnen '
                          '${state.findDistanceMeters.toStringAsFixed(0)} meter',
                        ),
                      ),
                      const SizedBox(height: 10),
                      OutlinedButton.icon(
                        onPressed: state.gameFinished
                            ? null
                            : () => _showHiderWarning(context),
                        icon: const Icon(Icons.visibility_off),
                        label: const Text('Bekijk hider-scenario'),
                      ),
                      TextButton(
                        onPressed: () => _showHiderResult(context),
                        child: const Text('Bekijk hider-resultaat'),
                      ),
                      const SizedBox(height: 10),
                      TextButton(
                        onPressed: state.gameFinished
                            ? () => _showSeekerResult(context)
                            : () => _finish(context),
                        child: Text(
                          state.gameFinished
                              ? 'Bekijk zoeker-resultaat'
                              : 'Beëindig demo-spel',
                        ),
                      ),
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

  void _showHiderWarning(BuildContext context) {
    final hiderValue = state.playerValue(PlayerRole.hider);
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: const Icon(Icons.warning_amber, size: 44),
        title: const Text('Let op!'),
        content: Text(
          'Zoeker ${state.displayName} zit binnen '
          '${state.findDistanceMeters.toStringAsFixed(0)} meter van jou.\n\n'
          'Omdat er ${state.activeGame.playersFound} spelers zijn gevonden '
          'is je actuele spelwaarde ${hiderValue.toStringAsFixed(0)} punten.'
          '\n\nBlijf bewegen en houd afstand.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Sluiten'),
          ),
        ],
      ),
    );
  }

  void _finish(BuildContext context) {
    state.finishGame();
    _showSeekerResult(context);
  }

  void _useHint() {
    final decision = state.useHint();
    if (decision.allowed) {
      final cost =
          decision.cost == 0 ? 'gratis hint' : '${decision.cost} punten';
      _notice(context, 'Hint gestart ($cost). Zoekcirkel: 60 seconden.');
      return;
    }
    final message = switch (decision.reason) {
      'cooldown' => 'Je hint heeft nog een cooldown van 10 minuten.',
      'insufficientPoints' => 'Je hebt onvoldoende punten voor deze hint.',
      _ => 'Hints zijn in deze fase niet beschikbaar.',
    };
    _notice(context, message);
  }

  void _showQuestions() {
    if (!state.startQuestionRound() &&
        state.questionAttempt.status != QuestionMarkerStatus.inProgress) {
      _notice(context, 'Deze vragenronde is niet meer beschikbaar.');
      return;
    }
    final answers = List<bool?>.filled(5, null);
    showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Vijf vragen over Mila'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(
                5,
                (index) => RadioGroup<bool>(
                  groupValue: answers[index],
                  onChanged: (value) =>
                      setDialogState(() => answers[index] = value),
                  child: ListTile(
                    title: Text('Vraag ${index + 1}: klopt deze stelling?'),
                    subtitle: const Row(
                      children: [
                        Expanded(
                          child: RadioListTile<bool>(
                            value: true,
                            title: Text('Ja'),
                          ),
                        ),
                        Expanded(
                          child: RadioListTile<bool>(
                            value: false,
                            title: Text('Nee'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Later'),
            ),
            FilledButton(
              onPressed: answers.every((answer) => answer != null)
                  ? () {
                      final correct =
                          answers.where((answer) => answer == true).length;
                      final earned = state.completeQuestionRound(correct);
                      Navigator.pop(dialogContext);
                      _notice(context, '$correct/5 goed: +$earned punten.');
                    }
                  : null,
              child: const Text('Afronden'),
            ),
          ],
        ),
      ),
    );
  }

  void _simulateGpsSpike() {
    state.registerZoneMeasurement(inside: false);
    state.registerZoneMeasurement(inside: true);
    _notice(context, 'Losse GPS-piek genegeerd; je blijft actief.');
  }

  void _confirmOutsideZone() {
    state.registerZoneMeasurement(inside: false);
    state.registerZoneMeasurement(inside: false);
  }

  void _returnToZone() => state.registerZoneMeasurement(inside: true);

  void _showHiderResult(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) => Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.sentiment_dissatisfied, size: 58),
            const Text(
              'Helaas, je bent gevonden!',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            const Text('Overlevingstijd: 1 uur en 42 minuten'),
            const Text('Ontvangen: 100 punten'),
            const Text('Rank: Beginner • 54% naar Avonturier'),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => Navigator.pop(sheetContext),
              child: const Text('Sluiten'),
            ),
          ],
        ),
      ),
    );
  }

  void _showSeekerResult(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.fromLTRB(
          24,
          24,
          24,
          MediaQuery.viewInsetsOf(sheetContext).bottom + 32,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.emoji_events, color: Color(0xffd99d18), size: 64),
            Text(
              'Sterk gezocht, ${state.displayName}!',
              style: const TextStyle(fontSize: 25, fontWeight: FontWeight.w900),
            ),
            Text(
              '${state.personallyFound} persoonlijk gevonden • '
              '${state.points + state.playerValue(PlayerRole.seeker).round()} punten',
            ),
            const Text('Rank: Beginner • 68% naar Avonturier'),
            const SizedBox(height: 12),
            Card(
              child: ListTile(
                leading: const Icon(Icons.stars),
                title: Text(
                  'Persoonlijk aandeel: ${state.personallyFound}/'
                  '${state.activeGame.playersFound}',
                ),
                subtitle: const Text('V1 gebruikt uitsluitend punten.'),
              ),
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: () => Navigator.pop(sheetContext),
              child: const Text('Terug naar het spel'),
            ),
          ],
        ),
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
  final TransformationController controller = TransformationController();
  bool showLegend = false;

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  void zoom(double factor) {
    final currentScale = controller.value.getMaxScaleOnAxis();
    final nextScale = (currentScale * factor).clamp(.55, 3.0);
    controller.value = Matrix4.identity()
      ..scaleByDouble(nextScale, nextScale, nextScale, 1);
  }

  void recenter() => controller.value = Matrix4.identity();

  @override
  Widget build(BuildContext context) => Stack(
        children: [
          Positioned.fill(
            child: ClipRect(
              child: InteractiveViewer(
                transformationController: controller,
                constrained: false,
                minScale: .55,
                maxScale: 3,
                boundaryMargin: const EdgeInsets.all(300),
                child: const _GameMapCanvas(),
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
                  'Speelveld • ${widget.state.findDistanceMeters.toStringAsFixed(0)} m vangafstand',
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
                    onPressed: () => zoom(1.3)),
                const SizedBox(height: 8),
                _MapButton(
                    tooltip: 'Uitzoomen',
                    icon: Icons.remove,
                    onPressed: () => zoom(.75)),
                const SizedBox(height: 8),
                _MapButton(
                    tooltip: 'Terug naar mijn locatie',
                    icon: Icons.my_location,
                    onPressed: recenter),
                const SizedBox(height: 8),
                _MapButton(
                  tooltip: 'Legenda',
                  icon: showLegend ? Icons.close : Icons.layers_outlined,
                  onPressed: () => setState(() => showLegend = !showLegend),
                ),
              ],
            ),
          ),
          if (showLegend)
            const Positioned(
                left: 16, right: 82, bottom: 88, child: _MapLegend()),
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
  const _GameMapCanvas();

  @override
  Widget build(BuildContext context) => SizedBox(
        width: 1100,
        height: 820,
        child: Stack(
          children: [
            Positioned.fill(child: CustomPaint(painter: _GameMapPainter())),
            const Positioned(
              left: 520,
              top: 375,
              child: _MapMarker(
                  icon: Icons.person_pin_circle,
                  label: 'Jij',
                  color: Color(0xff315c46)),
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
                      childAspectRatio: .9,
                      children: [
                        _PowerToken(
                            icon: Icons.flight,
                            name: 'Digitale drone',
                            count: 1,
                            color: const Color(0xff3f6f91),
                            enabled: !finished),
                        _PowerToken(
                            icon: Icons.precision_manufacturing,
                            name: 'Arm van de Stobbe',
                            count: 2,
                            color: const Color(0xff477653),
                            enabled: !finished),
                        _PowerToken(
                            icon: Icons.visibility_off,
                            name: 'Onzichtbaar',
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
    required this.count,
    required this.color,
    required this.enabled,
  });
  final IconData icon;
  final String name;
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
                        '×${count}',
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
            const Text(
              'Dit fiche is alleen tijdens het huidige spel te gebruiken. '
              'Na inzetten verdwijnt één fiche uit je Stobbetas.',
              textAlign: TextAlign.center,
            ),
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
          content:
              Text('${name} is ingezet. Demo: voorraad wordt later live.')),
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
        ],
      ),
    );
  }
}

class _ZoneAlarm extends StatelessWidget {
  const _ZoneAlarm({required this.state});

  final AppState state;

  @override
  Widget build(BuildContext context) => Card(
        color: Theme.of(context).colorScheme.errorContainer,
        child: ListTile(
          leading: const Icon(Icons.warning_amber),
          title: const Text('Je staat buiten het actieve speelveld'),
          subtitle: Text(
            'Keer terug vóór ${state.zoneReturnDeadline?.hour.toString().padLeft(2, '0')}:'
            '${state.zoneReturnDeadline?.minute.toString().padLeft(2, '0')}.',
          ),
        ),
      );
}

class _GameActions extends StatelessWidget {
  const _GameActions({
    required this.state,
    required this.onHint,
    required this.onQuestions,
  });

  final AppState state;
  final VoidCallback onHint;
  final VoidCallback onQuestions;

  @override
  Widget build(BuildContext context) => Wrap(
        spacing: 10,
        runSpacing: 10,
        children: [
          ActionChip(
            avatar: const Icon(Icons.visibility),
            label: const Text('2 zichtbare verstoppers'),
            onPressed: () {},
          ),
          ActionChip(
            avatar: const Icon(Icons.lightbulb),
            label: Text(
              state.hintState.freeHintAvailable
                  ? 'Gebruik gratis hint'
                  : 'Koop hint met punten',
            ),
            onPressed: onHint,
          ),
          ActionChip(
            avatar: const Icon(Icons.quiz),
            label: const Text('Beantwoord vraag'),
            onPressed: state.questionAttempt.visible ? onQuestions : null,
          ),
        ],
      );
}
