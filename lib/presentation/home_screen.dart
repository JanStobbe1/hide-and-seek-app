import 'package:flutter/material.dart';

import '../app_state.dart';
import '../domain/models.dart';
import 'active_game_screen.dart';
import 'widgets.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({
    required this.state,
    required this.onNavigate,
    required this.onCreate,
    super.key,
  });

  final AppState state;
  final ValueChanged<int> onNavigate;
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.fromLTRB(20, 18, 20, 110),
    children: [
      Text(
        'Hoi ${state.displayName} 👋',
        style: Theme.of(context).textTheme.headlineMedium
            ?.copyWith(fontWeight: FontWeight.w900),
      ),
      const Text('Klaar voor je volgende avontuur?'),
      const SizedBox(height: 20),
      _ActiveGameCard(state: state),
      SectionTitle(
        'Snel naar',
        action: TextButton(
          onPressed: onCreate,
          child: const Text('Nieuw spel'),
        ),
      ),
      GridView.count(
        crossAxisCount: MediaQuery.sizeOf(context).width > 600 ? 4 : 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.35,
        children: [
          _QuickAction(
            icon: Icons.group,
            label: 'Ik speel al mee met',
            count: '${state.repository.joinedGames.length + 1}',
            onTap: () => onNavigate(1),
          ),
          _QuickAction(
            icon: Icons.travel_explore,
            label: 'Beschikbare spellen',
            count: '${state.repository.availableGames.length}',
            onTap: () => onNavigate(2),
          ),
          _QuickAction(
            icon: Icons.flag,
            label: 'Afgeronde spellen',
            count: '${state.gamesPlayed}',
            onTap: () => onNavigate(3),
          ),
          _QuickAction(
            icon: Icons.person,
            label: 'Persoonlijke omgeving',
            count: 'Beginner',
            onTap: () => onNavigate(4),
          ),
        ],
      ),
      const SectionTitle('Jouw voortgang'),
      Card(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _Metric('${state.gamesPlayed}', 'gespeeld'),
              _Metric('${state.wins}', 'gewonnen'),
              _Metric('${state.friends.length}', 'vrienden'),
            ],
          ),
        ),
      ),
    ],
  );
}

class _ActiveGameCard extends StatelessWidget {
  const _ActiveGameCard({required this.state});

  final AppState state;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final playerValue = state
        .playerValue(PlayerRole.seeker)
        .toStringAsFixed(2)
        .replaceAll('.', ',');
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [colors.primary, colors.secondary]),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.radar, color: Color(0xffffd267)),
              SizedBox(width: 8),
              Text(
                'NU ACTIEF',
                style: TextStyle(
                  color: Color(0xffffd267),
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Game X',
            style: TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.w900,
            ),
          ),
          const Text(
            'Jij bent ZOEKER • live countdown',
            style: TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              StatPill(
                icon: Icons.person_search,
                value: '${state.activeGame.playersFound}/20',
                label: 'gevonden',
              ),
              const SizedBox(width: 10),
              StatPill(
                icon: Icons.stars,
                value: '${playerValue} punten',
                label: 'demo-waarde',
              ),
            ],
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: colors.tertiaryContainer,
              foregroundColor: colors.onTertiaryContainer,
            ),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => ActiveGameScreen(state: state)),
            ),
            icon: const Icon(Icons.play_arrow),
            label: const Text('Open Game X'),
          ),
        ],
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.icon,
    required this.label,
    required this.count,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Card(
    child: InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(icon, color: Theme.of(context).colorScheme.primary),
            Text(
              count,
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
            ),
            Text(label, maxLines: 2),
          ],
        ),
      ),
    ),
  );
}

class _Metric extends StatelessWidget {
  const _Metric(this.value, this.label);

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Text(
        value,
        style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 24),
      ),
      Text(label),
    ],
  );
}
