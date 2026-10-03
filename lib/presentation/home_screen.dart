import 'package:flutter/material.dart';

import '../app_state.dart';
import '../domain/models.dart';
import 'active_game_screen.dart';

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
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 680;
          final activeGames = state.repository.joinedGames
              .where((game) => game.status == GameStatus.active)
              .toList(growable: false);
          final currentGame = activeGames.isEmpty ? null : activeGames.first;
          final chapters = [
            _ContentsChapter(
              number: '01',
              icon: Icons.add_location_alt_outlined,
              title: 'Nieuw spel',
              description: 'Bepaal het speelgebied en nodig spelers uit.',
              onTap: onCreate,
            ),
            _ContentsChapter(
              number: '02',
              icon: Icons.sports_kabaddi_outlined,
              title: 'Mijn spellen',
              description: 'Bekijk de spellen waaraan je al meedoet.',
              count: state.repository.joinedGames.length,
              onTap: () => onNavigate(1),
            ),
            _ContentsChapter(
              number: '03',
              icon: Icons.travel_explore,
              title: 'Spellen ontdekken',
              description: 'Vind een nieuw avontuur bij jou in de buurt.',
              count: state.repository.availableGames.length,
              onTap: () => onNavigate(2),
            ),
            _ContentsChapter(
              number: '04',
              icon: Icons.emoji_events_outlined,
              title: 'Resultaten',
              description: 'Herbeleef afgeronde spellen en overwinningen.',
              count: state.gamesPlayed,
              onTap: () => onNavigate(3),
            ),
            _ContentsChapter(
              number: '05',
              icon: Icons.person_outline,
              title: 'Mijn profiel',
              description: 'Bekijk je vrienden, instellingen en voortgang.',
              onTap: () => onNavigate(4),
            ),
          ];

          return ListView(
            padding: EdgeInsets.fromLTRB(
              isWide ? 32 : 20,
              isWide ? 30 : 22,
              isWide ? 32 : 20,
              110,
            ),
            children: [
              const _ContentsHeading(),
              const SizedBox(height: 22),
              if (currentGame != null) ...[
                _ContinuePlayingCard(state: state, game: currentGame),
                const SizedBox(height: 28),
              ],
              Text(
                'Kies je volgende hoofdstuk',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
              ),
              const SizedBox(height: 12),
              GridView.builder(
                itemCount: chapters.length,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: isWide ? 2 : 1,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: isWide ? 2.45 : 3.15,
                ),
                itemBuilder: (context, index) => chapters[index],
              ),
              const SizedBox(height: 28),
              _ProgressSummary(state: state),
            ],
          );
        },
      );
}

class _ContentsHeading extends StatelessWidget {
  const _ContentsHeading();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 34,
              height: 4,
              decoration: BoxDecoration(
                color: colors.primary,
                borderRadius: BorderRadius.circular(99),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'INHOUDSOPGAVE',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: colors.primary,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          'Waar begint jouw\nvolgende avontuur?',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w900,
                height: 1.08,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          'Kies een hoofdstuk en ga meteen verder.',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: colors.onSurfaceVariant,
              ),
        ),
      ],
    );
  }
}

class _ContinuePlayingCard extends StatelessWidget {
  const _ContinuePlayingCard({required this.state, required this.game});

  final AppState state;
  final Game game;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ActiveGameScreen(state: state, game: game),
          ),
        ),
        child: Ink(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [colors.primary, colors.secondary],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(22),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.play_arrow_rounded,
                    size: 34,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'VERDER SPELEN',
                        style: TextStyle(
                          color: Color(0xffffd267),
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.8,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        game.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 23,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Text(
                        game.area.city.isEmpty ? game.area.province : game.area.city,
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.chevron_right, color: Colors.white),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ContentsChapter extends StatelessWidget {
  const _ContentsChapter({
    required this.number,
    required this.icon,
    required this.title,
    required this.description,
    required this.onTap,
    this.count,
  });

  final String number;
  final IconData icon;
  final String title;
  final String description;
  final VoidCallback onTap;
  final int? count;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Card(
      margin: EdgeInsets.zero,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    number,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: colors.primary,
                          fontWeight: FontWeight.w900,
                        ),
                  ),
                  Icon(icon, color: colors.primary),
                ],
              ),
              const SizedBox(width: 16),
              Container(width: 1, color: colors.outlineVariant),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.w900),
                          ),
                        ),
                        if (count != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: colors.primaryContainer,
                              borderRadius: BorderRadius.circular(99),
                            ),
                            child: Text(
                              '$count',
                              style: TextStyle(
                                color: colors.onPrimaryContainer,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: colors.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProgressSummary extends StatelessWidget {
  const _ProgressSummary({required this.state});

  final AppState state;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Icon(Icons.auto_stories_outlined, color: colors.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Jouw verhaal tot nu toe',
              style: Theme.of(context)
                  .textTheme
                  .titleSmall
                  ?.copyWith(fontWeight: FontWeight.w900),
            ),
          ),
          Text(
            '${state.gamesPlayed} gespeeld  •  ${state.wins} gewonnen',
            style: TextStyle(color: colors.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}
