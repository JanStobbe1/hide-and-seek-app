import 'package:flutter/material.dart';

import '../app_state.dart';
import 'widgets.dart';

class ActiveGameScreen extends StatelessWidget {
  const ActiveGameScreen({required this.state, super.key});

  final AppState state;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: state,
        builder: (context, _) => Scaffold(
          appBar: AppBar(
            title: const Text('Game X'),
            actions: const [
              Padding(
                padding: EdgeInsets.all(12),
                child: DemoBadge(),
              ),
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
                  const MapPlaceholder(),
                  const SectionTitle('Jouw acties'),
                  _GameActions(
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
        content: const Text('Er is een speler binnen 5 meter.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Later'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              state.foundPlayer();
              _showFoundConfirmation(context);
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
          'Je hebt speler XYZ uitgeschakeld.\nGoed gedaan!',
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
    final warning = state.activeGame.invisibilityAvailable
        ? _invisibilityAvailableText
        : _invisibilityUsedText;
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: const Icon(Icons.warning_amber, size: 44),
        title: const Text('Let op!'),
        content: Text('Zoeker Arie zit binnen 5 meter van jou.\n\n$warning'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Sluiten'),
          ),
          FilledButton(
            onPressed: state.activeGame.invisibilityAvailable
                ? () {
                    state.useInvisibility();
                    Navigator.pop(dialogContext);
                    _notice(
                      context,
                      'Je bent tijdelijk onzichtbaar (simulatie).',
                    );
                  }
                : null,
            child: const Text('Onzichtbaar maken'),
          ),
        ],
      ),
    );
  }

  static const _invisibilityAvailableText =
      'Je onzichtbaarheidskracht is nog beschikbaar.';
  static const _invisibilityUsedText =
      'Je onzichtbaarheidskracht is al gebruikt.';

  void _finish(BuildContext context) {
    state.finishGame();
    _showSeekerResult(context);
  }

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
            const Text('Ontvangen: 420 punten'),
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
            const Text(
              'Sterk gezocht, Arie!',
              style: TextStyle(fontSize: 25, fontWeight: FontWeight.w900),
            ),
            Text(
              '${state.activeGame.playersFound} spelers gevonden • 840 punten',
            ),
            const Text('Rank: Beginner • 68% naar Avonturier'),
            const SizedBox(height: 12),
            const Card(
              child: ListTile(
                leading: Icon(Icons.account_balance_wallet_outlined),
                title: Text('Demoresultaat: € 4,50'),
                subtitle: Text(
                  'Mockbedrag — er is geen geld ontvangen of overgemaakt.',
                ),
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

class _StatusRow extends StatelessWidget {
  const _StatusRow({required this.finished});

  final bool finished;

  @override
  Widget build(BuildContext context) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Chip(
            avatar: Icon(Icons.person_search),
            label: Text('ROL: ZOEKER'),
          ),
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
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xff223f31),
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
            const Row(
              children: [
                _Time('00', 'dagen'),
                _Time('00', 'uren'),
                _Time('26', 'minuten'),
                _Time('30', 'seconden'),
              ],
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
          ],
        ),
      );
}

class _GameActions extends StatelessWidget {
  const _GameActions({required this.onNotice});

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
            label: const Text('Koop hint (demo)'),
            onPressed: () => onNotice(
              'Hint ontgrendeld: kijk bij de grote eik. Geen echte betaling.',
            ),
          ),
          ActionChip(
            avatar: const Icon(Icons.quiz),
            label: const Text('Beantwoord vraag'),
            onPressed: () => onNotice(
              'Goed! Amsterdam is de hoofdstad van Nederland.',
            ),
          ),
        ],
      );
}

class _Time extends StatelessWidget {
  const _Time(this.value, this.label);

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) => Expanded(
        child: Column(
          children: [
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 27,
                fontWeight: FontWeight.w900,
              ),
            ),
            Text(
              label,
              style: const TextStyle(color: Colors.white60, fontSize: 11),
            ),
          ],
        ),
      );
}
