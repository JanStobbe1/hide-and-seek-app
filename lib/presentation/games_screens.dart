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
  void initState() {
    super.initState();
    widget.state.refreshBackendGames();
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final joinedIds = widget.state.repository.joinedGames
        .map((game) => game.id)
        .toSet();
    final games = widget.state.repository.availableGames
        .where(
          (game) =>
              !joinedIds.contains(game.id) &&
              (game.scheduledEnd == null || game.scheduledEnd!.isAfter(now)),
        )
        .toList();
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

class GameDetailScreen extends StatefulWidget {
  const GameDetailScreen({required this.state, required this.game, super.key});

  final AppState state;
  final Game game;

  @override
  State<GameDetailScreen> createState() => _GameDetailScreenState();
}

class _GameDetailScreenState extends State<GameDetailScreen> {
  List<String> participantNames = const [];
  bool loadingParticipants = true;

  @override
  void initState() {
    super.initState();
    _loadParticipants();
  }

  Future<void> _loadParticipants() async {
    final game = widget.game;
    final names = widget.state.backendClient == null
        ? [
            game.organizer,
            ...List<String>.filled(
              (game.participants - 1).clamp(0, game.maxParticipants),
              'Deelnemer',
            ),
          ]
        : await widget.state.backendClient!.fetchGameParticipants(game.id);
    if (!mounted) return;
    setState(() {
      participantNames = names;
      loadingParticipants = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final game = widget.game;
    final joined = widget.state.repository.joinedGames.any(
      (item) => item.id == game.id,
    );
    return Scaffold(
      appBar: AppBar(
        title: Text(game.name),
        actions: const [
          StobbeDetectiveButton(
            pageTitle: 'Spelgegevens',
            explanation:
                'Bekijk hier wanneer en waar het spel plaatsvindt, wie het '
                'organiseert en welke bekenden meedoen. Onderaan kun je het '
                'spel delen of jezelf aanmelden.',
          ),
        ],
      ),
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
                  Chip(label: Text('${game.participants}/${game.maxParticipants} spelers')),
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
              SectionTitle(
                'Deelnemers',
                action: TextButton.icon(
                  onPressed: () => _showParticipants(context),
                  icon: const Icon(Icons.people_outline),
                  label: const Text('Bekijk'),
                ),
              ),
              Card(
                child: ListTile(
                  leading: const CircleAvatar(child: Icon(Icons.people)),
                  title: Text(
                    '${game.participants} '
                    '${game.participants == 1 ? 'deelnemer' : 'deelnemers'}',
                  ),
                  subtitle: Text(
                    loadingParticipants
                        ? 'Deelnemers worden geladen…'
                        : 'Tik op Bekijk om te zien wie meedoet.',
                  ),
                  onTap: () => _showParticipants(context),
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Deellink gekopieerd.')),
                ),
                icon: const Icon(Icons.ios_share),
                label: const Text('Deel met vrienden'),
              ),
              const SizedBox(height: 10),
              FilledButton.icon(
                onPressed: joined
                    ? null
                    : () async {
                        final joinedNow =
                            await widget.state.joinAsync(game.id);
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              joinedNow
                                  ? 'Je doet mee! Het spel staat nu bij Mijn spellen.'
                                  : 'Deelname is niet gelukt of de deelnameperiode is gesloten.',
                            ),
                          ),
                        );
                        if (joinedNow) Navigator.pop(context);
                      },
                icon: Icon(joined ? Icons.check : Icons.sports_kabaddi),
                label: Text(joined ? 'Je doet al mee' : 'Doe mee'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showParticipants(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Wie doen er mee?'),
        content: SizedBox(
          width: 360,
          child: participantNames.isEmpty
              ? const Text('Deelnemers zijn nog niet beschikbaar.')
              : ListView.separated(
                  shrinkWrap: true,
                  itemCount: participantNames.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (_, index) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(child: Text('${index + 1}')),
                    title: Text(participantNames[index]),
                  ),
                ),
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
  Widget build(BuildContext context) {
    final joinedGames = state.repository.joinedGames;
    final activeGames = joinedGames
        .where((game) => game.status == GameStatus.active)
        .toList(growable: false);
    final upcomingGames = joinedGames
        .where((game) => game.status != GameStatus.active)
        .toList(growable: false);

    return ListView(
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
        if (activeGames.isEmpty)
          const Card(
            child: ListTile(
              leading: CircleAvatar(child: Icon(Icons.radar)),
              title: Text('Nog geen actief spel'),
              subtitle: Text(
                'Wanneer een aangemeld spel begint, verschijnt het hier.',
              ),
            ),
          ),
        ...activeGames.map(
          (game) => GameCard(
            game: game,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ActiveGameScreen(state: state),
              ),
            ),
          ),
        ),
        const SectionTitle('Binnenkort'),
        if (upcomingGames.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'Nog geen spellen. Ontdek een beschikbaar spel en doe mee!',
              ),
            ),
          ),
        ...upcomingGames.map(
          (game) => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              GameCard(
                game: game,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => GameDetailScreen(state: state, game: game),
                  ),
                ),
              ),
              if ((game.createdBy != null &&
                      game.createdBy == state.backendPlayerId) ||
                  game.organizer == state.displayName)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: OutlinedButton.icon(
                    onPressed: () => _confirmWithdraw(context, state, game),
                    icon: const Icon(Icons.undo),
                    label: const Text('Intrekken spel'),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  void _confirmWithdraw(BuildContext context, AppState state, Game game) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Spel intrekken?'),
        content: const Text(
          'Dit spel wordt vóór de start ingetrokken en is daarna niet meer '
          'beschikbaar voor deelnemers.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Annuleren'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              final withdrawn = await state.withdrawGame(game.id);
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    withdrawn
                        ? 'Het spel is ingetrokken.'
                        : 'Het spel kon niet worden ingetrokken.',
                  ),
                ),
              );
            },
            child: const Text('Intrekken'),
          ),
        ],
      ),
    );
  }
}

class CompletedGamesScreen extends StatelessWidget {
  const CompletedGamesScreen({required this.state, super.key});

  final AppState state;

  static const games = [
    _CompletedGameData(
      name: 'Verstopper',
      summary: 'Binnen 10 minuten gevonden',
      result: 'Gevonden',
      points: 300,
      rank: 7,
      role: 'Verstopper',
      duration: '10 minuten',
      location: 'Almere Haven',
      players: ['Jij', 'Houda', 'Mila', 'Sam', 'Noa', 'Omar', 'Lotte'],
    ),
    _CompletedGameData(
      name: 'Viavlavlop',
      summary: 'Sterk gespeeld tot de laatste ronde',
      result: 'Gewonnen',
      points: 425,
      rank: 1,
      role: 'Verstopper',
      duration: '1 uur 42 minuten',
      location: 'Almere Stad',
      players: ['Jij', 'Houda', 'Mila', 'Daan', 'Sofia'],
    ),
    _CompletedGameData(
      name: 'Familiedag verstoppen',
      summary: 'Vier spelers gevonden als zoeker',
      result: 'Gewonnen',
      points: 550,
      rank: 2,
      role: 'Zoeker',
      duration: '1 uur 18 minuten',
      location: 'Haarlemmermeer',
      players: ['Jij', 'Houda', 'Eva', 'Bram', 'Nora', 'Sem'],
    ),
    _CompletedGameData(
      name: 'Almere verstopt',
      summary: 'Lang verborgen gebleven',
      result: 'Gewonnen',
      points: 675,
      rank: 1,
      role: 'Verstopper',
      duration: '2 uur',
      location: 'Almere Buiten',
      players: ['Jij', 'Mila', 'Sam', 'Noa', 'Liam'],
    ),
    _CompletedGameData(
      name: "Waasi's teambuilding",
      summary: 'Gevonden in de tweede fase',
      result: 'Gevonden',
      points: 800,
      rank: 4,
      role: 'Verstopper',
      duration: '56 minuten',
      location: 'Amsterdam',
      players: ['Jij', 'Houda', 'Waasi', 'Iris', 'Finn', 'Yara'],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final visibleGames = [
      if (state.gameFinished)
        _CompletedGameData(
          name: 'Game X',
          summary: '${state.activeGame.playersFound} spelers gevonden',
          result: 'Afgerond',
          points: 840,
          rank: 2,
          role: 'Zoeker',
          duration: '1 uur 36 minuten',
          location: 'Almere',
          players: const ['Jij', 'Houda', 'Mila', 'Sam', 'Noa'],
        ),
      if (state.backendClient == null) ...games,
    ];
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          'Resultaten',
          style: Theme.of(context)
              .textTheme
              .headlineSmall
              ?.copyWith(fontWeight: FontWeight.w900),
        ),
        const Text(
            'Open een avontuur om je uitslag en medespelers te bekijken.'),
        const SizedBox(height: 16),
        if (visibleGames.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 48),
            child: Center(child: Text('Je hebt nog geen afgeronde spellen.')),
          ),
        ...visibleGames.map(
          (game) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Card(
              child: ListTile(
                leading: CircleAvatar(
                  child: Icon(
                    game.result == 'Gewonnen' ? Icons.emoji_events : Icons.flag,
                  ),
                ),
                title: Text(
                  game.name,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                subtitle: Text('${game.points} punten • ${game.location}'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => _CompletedGameDetailScreen(game: game),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _CompletedGameDetailScreen extends StatelessWidget {
  const _CompletedGameDetailScreen({required this.game});

  final _CompletedGameData game;

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: Text(game.name),
          actions: const [
            StobbeDetectiveButton(
              pageTitle: 'Spelresultaat',
              explanation:
                  'Hier zie je hoe je het hebt gedaan: je score, eindpositie, '
                  'rol en speelduur. Onder Medespelers staat met wie je dit '
                  'avontuur hebt gespeeld.',
            ),
          ],
        ),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        Icon(
                          game.result == 'Gewonnen'
                              ? Icons.emoji_events
                              : Icons.flag,
                          size: 58,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          game.result,
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(fontWeight: FontWeight.w900),
                        ),
                        Text(game.summary, textAlign: TextAlign.center),
                      ],
                    ),
                  ),
                ),
                const SectionTitle('Jouw resultaat'),
                _Info(Icons.stars, 'Punten', '${game.points} punten'),
                _Info(Icons.leaderboard, 'Eindpositie', 'Nummer ${game.rank}'),
                _Info(Icons.theater_comedy, 'Jouw rol', game.role),
                _Info(Icons.timer_outlined, 'Speelduur', game.duration),
                _Info(Icons.location_on_outlined, 'Gebied', game.location),
                const SectionTitle('Medespelers'),
                Card(
                  child: Column(
                    children: game.players
                        .map(
                          (player) => ListTile(
                            leading: CircleAvatar(
                              child: Text(player.substring(0, 1)),
                            ),
                            title: Text(player),
                            subtitle: Text(
                              player == 'Jij'
                                  ? 'Dit ben jij'
                                  : 'Speelde mee in dit avontuur',
                            ),
                          ),
                        )
                        .toList(growable: false),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
}

class _CompletedGameData {
  const _CompletedGameData({
    required this.name,
    required this.summary,
    required this.result,
    required this.points,
    required this.rank,
    required this.role,
    required this.duration,
    required this.location,
    required this.players,
  });

  final String name;
  final String summary;
  final String result;
  final int points;
  final int rank;
  final String role;
  final String duration;
  final String location;
  final List<String> players;
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
  return '${value.day} ${months[value.month - 1]} ${value.year} • '
      '${_formatTime(value)}';
}

String _formatTime(DateTime value) =>
    '${value.hour.toString().padLeft(2, '0')}:'
    '${value.minute.toString().padLeft(2, '0')}';
