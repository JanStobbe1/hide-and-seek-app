import 'package:flutter/material.dart';

import '../app_state.dart';
import '../domain/models.dart';
import 'active_game_screen.dart';
import 'widgets.dart';

class AvailableGamesScreen extends StatefulWidget {
  const AvailableGamesScreen({required this.state, super.key});

  final AppState state;

  @override
  State<AvailableGamesScreen> createState() => _AvailableGamesScreenState();
}

class _AvailableGamesScreenState extends State<AvailableGamesScreen> {
  String sort = 'Afstand';

  @override
  Widget build(BuildContext context) {
    final games = [...widget.state.repository.availableGames];
    switch (sort) {
      case 'Alfabetisch':
        games.sort((a, b) => a.name.compareTo(b.name));
        break;
      case 'Starttijd':
        games.sort(_compareStartTimes);
        break;
      case 'Deelnemers':
        games.sort((a, b) => b.participants.compareTo(a.participants));
        break;
      case 'Afstand':
        games.sort((a, b) => a.distanceKm.compareTo(b.distanceKm));
        break;
    }
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          'Beschikbare spellen',
          style: Theme.of(context)
              .textTheme
              .headlineSmall
              ?.copyWith(fontWeight: FontWeight.w900),
        ),
        const Text('Ontdek een avontuur bij jou in de buurt.'),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          initialValue: sort,
          decoration: const InputDecoration(
            labelText: 'Sorteer op',
            prefixIcon: Icon(Icons.sort),
          ),
          items: ['Afstand', 'Alfabetisch', 'Starttijd', 'Deelnemers']
              .map(
                (value) => DropdownMenuItem(value: value, child: Text(value)),
              )
              .toList(),
          onChanged: (value) => setState(() => sort = value!),
        ),
        const SizedBox(height: 16),
        ...games.map(
          (game) => GameCard(
            game: game,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    GameDetailScreen(state: widget.state, game: game),
              ),
            ),
          ),
        ),
      ],
    );
  }

  int _compareStartTimes(Game a, Game b) {
    if (a.scheduledStart == null && b.scheduledStart == null) return 0;
    if (a.scheduledStart == null) return 1;
    if (b.scheduledStart == null) return -1;
    return a.scheduledStart!.compareTo(b.scheduledStart!);
  }
}

class GameCard extends StatelessWidget {
  const GameCard({required this.game, required this.onTap, super.key});

  final Game game;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Card(
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 26,
                    backgroundColor:
                        Theme.of(context).colorScheme.secondaryContainer,
                    child: const Icon(Icons.forest),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          game.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 17,
                          ),
                        ),
                        Text(
                          '${game.area.label} • '
                          '${game.distanceKm.toStringAsFixed(1)} km',
                        ),
                        const SizedBox(height: 5),
                        Text(
                          '${game.participants}/${game.maxParticipants} spelers',
                        ),
                        Text(
                          _startSummary(game),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right),
                ],
              ),
            ),
          ),
        ),
      );
}

class GameDetailScreen extends StatelessWidget {
  const GameDetailScreen({required this.state, required this.game, super.key});

  final AppState state;
  final Game game;

  @override
  Widget build(BuildContext context) {
    final joined = state.repository.joinedGames.any(
      (item) => item.id == game.id,
    );
    return Scaffold(
      appBar: AppBar(title: Text(game.name)),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Container(
                height: 180,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Theme.of(context).colorScheme.primary,
                      Theme.of(context).colorScheme.secondary,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(28),
                ),
                child: const Center(
                  child: Icon(Icons.forest, color: Colors.white, size: 90),
                ),
              ),
              const SizedBox(height: 18),
              Wrap(
                spacing: 8,
                children: [
                  Chip(
                    label: Text(game.isPublic ? 'Openbaar spel' : 'Privéspel'),
                    avatar: const Icon(Icons.public, size: 18),
                  ),
                  Chip(
                    label: Text(
                      '${game.participants}/${game.maxParticipants} spelers',
                    ),
                  ),
                ],
              ),
              Text(
                game.name,
                style: Theme.of(context)
                    .textTheme
                    .headlineMedium
                    ?.copyWith(fontWeight: FontWeight.w900),
              ),
              Text(
                game.description,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SectionTitle('Spelinformatie'),
              _Info(Icons.person, 'Organisator', game.organizer),
              _Info(Icons.schedule, 'Start & einde', _dateRange(game)),
              _Info(Icons.map, 'Zoekgebied', _areaDetails(game.area)),
              const SectionTitle('Bekende gezichten'),
              const Card(
                child: ListTile(
                  leading: CircleAvatar(child: Text('M')),
                  title: Text('Mila en 2 eerdere spelers doen mee'),
                  subtitle: Text('Jullie speelden eerder samen'),
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Demo-deellink gekopieerd.')),
                ),
                icon: const Icon(Icons.ios_share),
                label: const Text('Deel met vrienden'),
              ),
              const SizedBox(height: 10),
              FilledButton.icon(
                onPressed: joined
                    ? null
                    : () {
                        final reason = state.joinBlockReason(game.id);
                        if (reason != null) {
                          ScaffoldMessenger.of(context)
                              .showSnackBar(SnackBar(content: Text(reason)));
                          return;
                        }
                        final joinedNow = state.join(game.id);
                        if (!joinedNow) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Je doet mee! Het spel staat nu bij '
                              'Mijn spellen.',
                            ),
                          ),
                        );
                        Navigator.pop(context);
                      },
                icon: Icon(joined ? Icons.check : Icons.sports_kabaddi),
                label: Text(joined ? 'Je doet al mee' : 'Doe mee'),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  'Demo: er vindt geen echte betaling of reservering plaats.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Info extends StatelessWidget {
  const _Info(this.icon, this.label, this.value);

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Icon(icon),
        title: Text(label),
        subtitle: Text(value),
      );
}

class MyGamesScreen extends StatelessWidget {
  const MyGamesScreen({required this.state, super.key});

  final AppState state;

  @override
  Widget build(BuildContext context) => ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            'Ik speel al mee met',
            style: Theme.of(context)
                .textTheme
                .headlineSmall
                ?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 16),
          Card(
            child: ListTile(
              leading: const CircleAvatar(child: Icon(Icons.radar)),
              title: const Text(
                'Game X',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
              subtitle: Text(
                '${state.activeGame.playersFound} van 20 gevonden • Actief',
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => ActiveGameScreen(state: state)),
              ),
            ),
          ),
          const SectionTitle('Binnenkort'),
          if (state.repository.joinedGames.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Nog geen spellen. Ontdek een beschikbaar spel en doe mee!',
                ),
              ),
            ),
          ...state.repository.joinedGames.map(
            (game) => GameCard(
              game: game,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => GameDetailScreen(state: state, game: game),
                ),
              ),
            ),
          ),
        ],
      );
}

class CompletedGamesScreen extends StatelessWidget {
  const CompletedGamesScreen({required this.state, super.key});

  final AppState state;

  static const names = [
    'Verstopper',
    'Viavlavlop',
    'Familiedag verstoppen',
    'Almere verstopt',
    "Waasi's teambuilding",
  ];

  @override
  Widget build(BuildContext context) => ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            'Afgeronde spellen',
            style: Theme.of(context)
                .textTheme
                .headlineSmall
                ?.copyWith(fontWeight: FontWeight.w900),
          ),
          const Text('Jouw avonturen en resultaten.'),
          if (state.gameFinished)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Card(
                child: ListTile(
                  leading: const CircleAvatar(child: Icon(Icons.emoji_events)),
                  title: Text(
                    'Game X • ${state.activeGame.playersFound} '
                    'spelers gevonden',
                  ),
                  subtitle: const Text('840 punten'),
                ),
              ),
            ),
          const SizedBox(height: 16),
          ...names.asMap().entries.map(
                (entry) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Card(
                    child: ListTile(
                      leading: const CircleAvatar(child: Icon(Icons.flag)),
                      title: Text(
                        entry.value,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      subtitle: Text(
                        entry.key == 0
                            ? 'Dit was niet echt een succes. Je was al binnen '
                                '10 minuten gevonden. Houd de moed erin!'
                            : '${300 + entry.key * 125} punten • Almere',
                      ),
                      trailing: Text(entry.key < 3 ? 'Gewonnen' : 'Gevonden'),
                    ),
                  ),
                ),
              ),
        ],
      );
}

String _startSummary(Game game) {
  if (game.startCondition == StartCondition.participantCount) {
    return 'Start bij ${game.participantThreshold} deelnemers';
  }
  return 'Start ${_formatDateTime(game.scheduledStart!)}';
}

String _dateRange(Game game) {
  if (game.startCondition == StartCondition.participantCount) {
    return 'Start bij ${game.participantThreshold} deelnemers • '
        '${game.duration.inMinutes} minuten';
  }
  return '${_formatDateTime(game.scheduledStart!)} – '
      '${_formatTime(game.scheduledEnd!)}';
}

String _areaDetails(SearchArea area) =>
    '${area.city}, ${area.province} • ${area.neighbourhood} • '
    '${area.specificArea}';

String _formatDateTime(DateTime value) {
  const months = [
    'januari',
    'februari',
    'maart',
    'april',
    'mei',
    'juni',
    'juli',
    'augustus',
    'september',
    'oktober',
    'november',
    'december',
  ];
  return '${value.day} ${months[value.month - 1]} • ${_formatTime(value)}';
}

String _formatTime(DateTime value) =>
    '${value.hour.toString().padLeft(2, '0')}:'
    '${value.minute.toString().padLeft(2, '0')}';
