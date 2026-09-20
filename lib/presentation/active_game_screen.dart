import 'dart:async';

import 'package:flutter/material.dart';

import '../app_state.dart';
import '../domain/hints.dart';
import '../domain/models.dart';
import '../domain/private_questions.dart';
import '../domain/results.dart';
import 'widgets.dart';

class ActiveGameScreen extends StatefulWidget {
  const ActiveGameScreen({required this.state, super.key});

  final AppState state;

  @override
  State<ActiveGameScreen> createState() => _ActiveGameScreenState();
}

class _ActiveGameScreenState extends State<ActiveGameScreen> {
  late final Timer _timer;
  bool _resultScheduled = false;

  AppState get state => widget.state;

  @override
  void initState() {
    super.initState();
    state.syncActiveGameClock();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      state.syncActiveGameClock();
      _scheduleAutomaticResultIfNeeded();
      if (state.gameFinished) {
        _timer.cancel();
      }
    });
  }

  void _scheduleAutomaticResultIfNeeded() {
    if (_resultScheduled || !state.shouldAutoShowResult()) return;
    _resultScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _showSeekerResult(context);
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
        builder: (context, _) {
          _scheduleAutomaticResultIfNeeded();
          return Scaffold(
          appBar: AppBar(
            title: const Text('Game X'),
            actions: const [
              Padding(padding: EdgeInsets.all(12), child: DemoBadge()),
            ],
          ),
          body: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 760),
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  _StatusRow(finished: state.gameFinished),
                  const SizedBox(height: 12),
                  _CountdownCard(state: state),
                  const SectionTitle('Zoekgebied'),
                  MapPlaceholder(playerMarker: state.playerMarker),
                  const SectionTitle('Jouw acties'),
                  _GameActions(
                    state: state,
                    onHint: () => _useHint(context),
                    onQuestion: () => _showPrivateQuestion(context),
                    onNotice: (message) => _notice(context, message),
                  ),
                  const SizedBox(height: 18),
                  FilledButton.icon(
                    onPressed: state.gameFinished
                        ? null
                        : () => _showProximity(context),
                    icon: const Icon(Icons.sensors),
                    label: const Text('Simuleer speler binnen 5 meter'),
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    onPressed: state.gameFinished
                        ? null
                        : () => _showHiderWarning(context),
                    icon: const Icon(Icons.warning_amber),
                    label: const Text('Simuleer zoeker dichtbij'),
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
        );
        },
      );

  void _showPrivateQuestion(BuildContext context) {
    const subjectId = 'friend-mila';
    final visibility = state.questionVisibility(
      subjectId: subjectId,
      privateGame: true,
      enabled: true,
      inRange: true,
    );
    if (visibility == QuestionMarkerStatus.completed ||
        visibility == QuestionMarkerStatus.failed) {
      _notice(context, 'Deze persoonlijke vraag is al afgerond.');
      return;
    }
    state.startQuestion(subjectId);
    var selected = 0;
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: const Icon(Icons.quiz),
        title: const Text('Persoonlijke vragen over Mila'),
        content: StatefulBuilder(
          builder: (context, setDialogState) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Je bent binnen bereik. Beantwoord vijf persoonlijke vragen. '
                'In deze V1-simulatie kies je hoeveel antwoorden juist waren.',
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<int>(
                initialValue: selected,
                decoration: const InputDecoration(
                  labelText: 'Juiste antwoorden',
                ),
                items: [
                  for (var i = 0; i <= 5; i++)
                    DropdownMenuItem(value: i, child: Text('$i van 5')),
                ],
                onChanged: (value) =>
                    setDialogState(() => selected = value ?? 0),
              ),
              const SizedBox(height: 8),
              const Text(
                'Verlaat je het bereik, dan heb je 5 seconden om terug te '
                'keren.',
                style: TextStyle(fontSize: 12),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Later'),
          ),
          FilledButton(
            onPressed: () {
              final awarded = state.completeQuestion(subjectId, selected);
              Navigator.pop(dialogContext);
              _notice(
                context,
                'Vraag afgerond: +$awarded punten. Totaal: ${state.points}.',
              );
            },
            child: const Text('Afronden'),
          ),
        ],
      ),
    );
  }

  void _useHint(BuildContext context) {
    final result = state.useHint();
    if (result.started) {
      final kind = result.purchasedHints == 0 ? 'gratis hint' : 'gekochte hint';
      _notice(
        context,
        'Je $kind is gestart. De hintcirkel blijft 1 minuut zichtbaar '
        'en begint na 30 seconden te krimpen. Puntensaldo: ${result.points}.',
      );
      return;
    }
    final message = switch (result.reason) {
      HintBlockReason.cooldown =>
        'Wacht 10 minuten voordat je weer een hint gebruikt.',
      HintBlockReason.insufficientPoints =>
        'Je hebt niet genoeg punten voor deze hint.',
      HintBlockReason.finalQuarter =>
        'Hints zijn niet beschikbaar in het laatste kwart.',
      HintBlockReason.zoneTooSmall =>
        'Het zoekgebied is te klein voor een bruikbare hint.',
      null => 'Deze hint kan nu niet worden gebruikt.',
    };
    _notice(context, message);
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
        content: const Text('Er is een speler binnen 5 meter.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Later'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              final registered = state.foundPlayer();
              if (registered) {
                _showFoundConfirmation(context);
              } else {
                _notice(
                  context,
                  'Deze speler kan niet opnieuw worden gevonden.',
                );
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
        content: Text(
          'De vondst is verwerkt volgens de V1-puntenregels.\\n'
          'Jouw puntensaldo is nu ${state.points}.',
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
    _notice(
      context,
      'Een zoeker is dichtbij. Blijf binnen het actieve zoekgebied.',
    );
  }

  void _finish(BuildContext context) {
    state.finishGame();
    _showSeekerResult(context);
  }

  void _showHiderResult(BuildContext context) {
    final elapsed = state.activeGame.elapsed;
    final minutes = elapsed.inMinutes;
    final found = state.activeGame.playersFound > 0;
    final tone = const ResultService().hiderTone(
      found: found,
      foundAt: found ? elapsed : null,
      total: state.activeGameDuration,
      survivors: state.activeHiders,
    );
    final feedback = switch (tone) {
      ResultTone.mostNegative =>
        'Je werd vroeg gevonden. Volgende ronde biedt een nieuwe kans.',
      ResultTone.veryNegative => 'Je werd vrij vroeg gevonden.',
      ResultTone.negative => 'Je hield het een deel van het spel vol.',
      ResultTone.neutral => 'Je bleef een flink deel van het spel verborgen.',
      ResultTone.positive => 'Sterk verstopt: je hield het lang vol.',
      ResultTone.veryPositive =>
        'Maa shaa Allah, je bleef tot het einde verborgen.',
      ResultTone.mostPositive =>
        'Maa shaa Allah, jij bent de enige overgebleven verstopper.',
    };
    showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) => Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              found ? Icons.sentiment_dissatisfied : Icons.celebration,
              size: 58,
            ),
            Text(
              found ? 'Je bent gevonden' : 'Je bent niet gevonden!',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text('Overlevingstijd: $minutes minuten'),
            Text('Puntensaldo: ${state.finalPointsAfterHints} punten'),
            const SizedBox(height: 8),
            Text(feedback, textAlign: TextAlign.center),
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

  String _seekerFeedback() {
    final totalHiders = state.activeGame.playersFound + state.activeHiders;
    final tone = const ResultService().seekerTone(
      personallyFound: state.activeGame.playersFound,
      totalFound: state.activeGame.playersFound,
      totalHiders: totalHiders,
    );
    return switch (tone) {
      ResultTone.mostNegative =>
        'Volgende ronde biedt nieuwe kansen, in shaa Allah.',
      ResultTone.veryNegative => 'Blijf zoeken en verfijn je aanpak.',
      ResultTone.negative =>
        'Je bijdrage telt; probeer volgende keer meer te vinden.',
      ResultTone.neutral => 'Je hebt een nuttige bijdrage geleverd.',
      ResultTone.positive =>
        'Mooi gezocht, je had een duidelijk aandeel in het resultaat.',
      ResultTone.veryPositive =>
        'Sterk gezocht, je vond een groot deel van de verstoppers.',
      ResultTone.mostPositive =>
        'Maa shaa Allah, jij vond alle gevonden verstoppers.',
    };
  }

  void _showSeekerResult(BuildContext context) {
    final finalPoints = state.finalPointsAfterHints;
    final hintPenalty = state.hintState.purchasedHints;
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
              '${state.activeGame.playersFound} verstoppers gevonden • '
              '$finalPoints punten',
            ),
            if (hintPenalty > 0)
              Text('Hintcorrectie eindresultaat: -$hintPenalty punt(en)'),
            const SizedBox(height: 8),
            Text(_seekerFeedback(), textAlign: TextAlign.center),
            const SizedBox(height: 12),
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
            '${state.activeGame.playersFound} verstoppers gevonden • '
            '${state.activeHiders} nog actief',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 20,
            ),
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: state.activeGame.playersFound /
                (state.activeGame.playersFound + state.activeHiders),
            minHeight: 9,
            borderRadius: BorderRadius.circular(8),
          ),
          const SizedBox(height: 14),
          Text(
            'Jouw huidige spelwaarde is '
            '${value.toStringAsFixed(2).replaceAll('.', ',')} punten. '
            'Puntensaldo: ${state.points}.',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white),
          ),
          const Text(
            'Actuele spelwaarde',
            style: TextStyle(color: Colors.white60, fontSize: 11),
          ),
        ],
      ),
    );
  }
}

class _GameActions extends StatelessWidget {
  const _GameActions({
    required this.state,
    required this.onHint,
    required this.onQuestion,
    required this.onNotice,
  });

  final AppState state;
  final VoidCallback onHint;
  final VoidCallback onQuestion;
  final ValueChanged<String> onNotice;

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
              state.hintState.freeAvailable
                  ? 'Gebruik gratis hint'
                  : 'Hint: ${5} punten + kwartaaltoeslag',
            ),
            onPressed: onHint,
          ),
          ActionChip(
            avatar: const Icon(Icons.quiz),
            label: const Text('Persoonlijke vraag'),
            onPressed: onQuestion,
          ),
        ],
      );
}
