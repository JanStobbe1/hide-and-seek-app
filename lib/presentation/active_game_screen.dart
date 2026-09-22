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
  late final PageController _pageController;
  int _pageIndex = 1;

  AppState get state => widget.state;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _pageIndex);
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
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: state,
        builder: (context, _) => Scaffold(
          appBar: AppBar(
            title: const Text('Game X'),
            actions: const [
              Padding(padding: EdgeInsets.all(12), child: DemoBadge()),
            ],
          ),
          body: PageView(
            controller: _pageController,
            onPageChanged: (value) => setState(() => _pageIndex = value),
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
              _ActiveMapPage(state: state),
              _StobbePowersPage(finished: state.gameFinished),
            ],
          ),
          bottomNavigationBar: NavigationBar(
            selectedIndex: _pageIndex,
            onDestinationSelected: (value) {
              setState(() => _pageIndex = value);
              _pageController.animateToPage(
                value,
                duration: const Duration(milliseconds: 280),
                curve: Curves.easeOut,
              );
            },
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
  const _ActiveMapPage({required this.state});

  final AppState state;

  @override
  State<_ActiveMapPage> createState() => _ActiveMapPageState();
}

class _ActiveMapPageState extends State<_ActiveMapPage> {
  bool showLegend = true;

  @override
  Widget build(BuildContext context) => Stack(
        children: [
          Positioned.fill(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: MapPlaceholder(playerMarker: widget.state.playerMarker),
            ),
          ),
          Positioned(
            top: 24,
            right: 24,
            child: FloatingActionButton.small(
              heroTag: 'map-legend',
              tooltip: showLegend ? 'Legenda sluiten' : 'Legenda openen',
              onPressed: () => setState(() => showLegend = !showLegend),
              child: Icon(showLegend ? Icons.close : Icons.layers_outlined),
            ),
          ),
          if (showLegend)
            Positioned(
              left: 24,
              right: 84,
              bottom: 24,
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Wrap(
                    spacing: 16,
                    runSpacing: 8,
                    children: const [
                      _LegendItem(Icons.person_pin_circle, 'Jij'),
                      _LegendItem(Icons.help_outline, 'Zoekgebied'),
                      _LegendItem(Icons.auto_awesome, 'Stobbekracht'),
                    ],
                  ),
                ),
              ),
            ),
        ],
      );
}

class _LegendItem extends StatelessWidget {
  const _LegendItem(this.icon, this.label);

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: 6),
          Text(label),
        ],
      );
}

class _StobbePowersPage extends StatelessWidget {
  const _StobbePowersPage({required this.finished});

  final bool finished;

  @override
  Widget build(BuildContext context) => ListView(
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
            'Krachten gelden alleen tijdens dit spel en vervallen na afloop.',
          ),
          const SizedBox(height: 16),
          Card(
            color: Theme.of(context).colorScheme.secondaryContainer,
            child: const ListTile(
              leading: Icon(Icons.lock_clock),
              title: Text('Vergrendeld tijdens fase 1'),
              subtitle: Text(
                'Zodra fase 2 begint, worden gevonden krachten bruikbaar.',
              ),
            ),
          ),
          const SizedBox(height: 12),
          _PowerCard(
            icon: Icons.visibility_off_outlined,
            name: 'Onzichtbaarheidsdrankje',
            detail: '0 in voorraad • maximaal 1× per spel',
            enabled: false,
          ),
          _PowerCard(
            icon: Icons.precision_manufacturing_outlined,
            name: 'Arm van de Stobbe',
            detail: '0 in voorraad • maximaal 2× per spel',
            enabled: false,
          ),
          _PowerCard(
            icon: Icons.flight_outlined,
            name: 'Digitale drone',
            detail: '1 in voorraad • maximaal 2× per spel',
            enabled: !finished,
          ),
          const SectionTitle('Profielbeloningen'),
          const Card(
            child: ListTile(
              leading: Icon(Icons.redeem_outlined),
              title: Text('Puntenkisten'),
              subtitle: Text(
                '50–200 punten komen vaker voor. De zeldzame gouden kist '
                'geeft 1.000 profielpunten en telt niet mee voor de uitslag.',
              ),
            ),
          ),
        ],
      );
}

class _PowerCard extends StatelessWidget {
  const _PowerCard({
    required this.icon,
    required this.name,
    required this.detail,
    required this.enabled,
  });

  final IconData icon;
  final String name;
  final String detail;
  final bool enabled;

  @override
  Widget build(BuildContext context) => Card(
        child: ListTile(
          enabled: enabled,
          leading: CircleAvatar(child: Icon(icon)),
          title: Text(name, style: const TextStyle(fontWeight: FontWeight.w700)),
          subtitle: Text(detail),
          trailing: FilledButton.tonal(
            onPressed: enabled
                ? () => ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Demo: deze kracht wordt pas vanaf fase 2 ingezet.',
                        ),
                      ),
                    )
                : null,
            child: const Text('Gebruik'),
          ),
        ),
      );
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
