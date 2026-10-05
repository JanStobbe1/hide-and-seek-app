import 'package:flutter/material.dart';

import '../app_state.dart';
import '../domain/models.dart';
import '../config/app_config.dart';
import 'create_game_screen.dart';
import 'games_screens.dart';
import 'home_screen.dart';
import 'profile_screen.dart';
import 'stobbe_guide.dart';
import 'widgets.dart';

class AppShell extends StatefulWidget {
  const AppShell({
    required this.state,
    this.startTour = false,
    required this.onTourComplete,
    super.key,
  });

  final AppState state;
  final bool startTour;
  final VoidCallback onTourComplete;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int index = 0;
  late bool tourActive;
  int tourStep = 0;
  int skippedInARow = 0;

  @override
  void initState() {
    super.initState();
    tourActive = widget.startTour;
  }

  static const helpTitles = [
    'Inhoudsopgave',
    'Mijn spellen',
    'Spellen ontdekken',
    'Resultaten',
    'Mijn profiel',
  ];

  static const helpTexts = [
    'Kies een tegel om verder te gaan.',
    'Hier staan je actieve en geplande spellen. Tik op een spel om het te openen.',
    'Bekijk spellen in de buurt, sorteer ze en tik erop om de details te lezen of mee te doen.',
    'Open een afgerond spel om je score, eindpositie en medespelers terug te zien.',
    'Beheer hier je naam, vrienden, privacy, kaartmarker en de uitstraling van de app.',
  ];

  String get _homeExplanation => homeHelpExplanation(widget.state);

  static const destinations = [
    NavigationDestination(
      icon: Icon(Icons.explore_outlined),
      selectedIcon: Icon(Icons.explore),
      label: 'Home',
    ),
    NavigationDestination(
      icon: Icon(Icons.sports_kabaddi_outlined),
      selectedIcon: Icon(Icons.sports_kabaddi),
      label: 'Mijn spellen',
    ),
    NavigationDestination(icon: Icon(Icons.travel_explore), label: 'Ontdekken'),
    NavigationDestination(
      icon: Icon(Icons.emoji_events_outlined),
      label: 'Resultaten',
    ),
    NavigationDestination(
      icon: Icon(Icons.person_outline),
      selectedIcon: Icon(Icons.person),
      label: 'Profiel',
    ),
  ];

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: widget.state,
        builder: (context, _) => LayoutBuilder(
          builder: (context, constraints) {
            final pages = [
              HomeScreen(
                state: widget.state,
                onNavigate: (value) => setState(() => index = value),
                onCreate: _create,
              ),
              MyGamesScreen(state: widget.state),
              AvailableGamesScreen(state: widget.state),
              CompletedGamesScreen(state: widget.state),
              ProfileScreen(state: widget.state),
            ];
            final content = SafeArea(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 980),
                  child: pages[index],
                ),
              ),
            );
            final layout = constraints.maxWidth >= 800
                ? _buildWideLayout(content)
                : _buildMobileLayout(content);
            return Stack(
              children: [
                ExcludeSemantics(
                  excluding: tourActive,
                  child: ExcludeFocus(
                    excluding: tourActive,
                    child: layout,
                  ),
                ),
                if (tourActive)
                  _GuidedTourOverlay(
                    step: tourStep,
                    homeExplanation: _homeExplanation,
                    onNext: _nextTourStep,
                    onSkip: _skipTour,
                  ),
              ],
            );
          },
        ),
      );

  Widget _buildWideLayout(Widget content) => Scaffold(
        body: Row(
          children: [
            NavigationRail(
              selectedIndex: index,
              onDestinationSelected: (value) => setState(() => index = value),
              labelType: NavigationRailLabelType.all,
              leading: Padding(
                padding: const EdgeInsets.symmetric(vertical: 18),
                child: Column(
                  children: [
                    const CircleAvatar(child: Icon(Icons.location_searching)),
                    StobbeDetectiveButton(
                      pageTitle: helpTitles[index],
                      explanation: index == 0
                          ? _homeExplanation
                          : helpTexts[index],
                    ),
                    const DemoBadge(),
                  ],
                ),
              ),
              destinations: destinations
                  .map(
                    (destination) => NavigationRailDestination(
                      icon: destination.icon,
                      selectedIcon: destination.selectedIcon,
                      label: Text(destination.label),
                    ),
                  )
                  .toList(),
            ),
            const VerticalDivider(width: 1),
            Expanded(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                    child: StobbeGuide(
                      explanation: index == 0
                          ? _homeExplanation
                          : helpTexts[index],
                    ),
                  ),
                  Expanded(child: content),
                ],
              ),
            ),
          ],
        ),
        floatingActionButton: index == 0
            ? FloatingActionButton.extended(
                onPressed: _create,
                icon: const Icon(Icons.add),
                label: const Text('Nieuw spel'),
              )
            : null,
      );

  Widget _buildMobileLayout(Widget content) => Scaffold(
        appBar: AppBar(
          title: const Text(
            AppConfig.appName,
            style: TextStyle(fontWeight: FontWeight.w900),
          ),
          actions: [
            StobbeDetectiveButton(
              pageTitle: helpTitles[index],
              explanation: index == 0 ? _homeExplanation : helpTexts[index],
            ),
            const Padding(
              padding: EdgeInsets.only(right: 12),
              child: Center(child: DemoBadge()),
            ),
          ],
        ),
        body: content,
        bottomNavigationBar: NavigationBar(
          selectedIndex: index,
          onDestinationSelected: (value) => setState(() => index = value),
          destinations: destinations,
        ),
        floatingActionButton: index == 0
            ? FloatingActionButton(
                onPressed: _create,
                tooltip: 'Nieuw spel',
                child: const Icon(Icons.add),
              )
            : null,
      );

  void _nextTourStep() {
    skippedInARow = 0;
    _advanceTour();
  }

  void _advanceTour() {
    if (tourStep >= _GuidedTourOverlay.steps.length - 1) {
      _finishTour();
      return;
    }
    setState(() => tourStep++);
  }

  void _skipTour() {
    skippedInARow++;
    if (skippedInARow < 2) {
      _advanceTour();
      return;
    }
    showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Rondleiding onderbreken?'),
        content: const Text(
          'Wil je de guided tour nog steeds afmaken, of wil je gewoon beginnen?',
        ),
        actions: [
          TextButton(
            key: const Key('guided-tour-continue'),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Rondleiding voortzetten'),
          ),
          FilledButton(
            key: const Key('guided-tour-start'),
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Gewoon beginnen'),
          ),
        ],
      ),
    ).then((continueTour) {
      if (!mounted) return;
      skippedInARow = 0;
      if (continueTour == true) {
        _advanceTour();
      } else if (continueTour == false) {
        _finishTour();
      }
    });
  }

  void _finishTour() {
    setState(() => tourActive = false);
    widget.onTourComplete();
  }

  void _create() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => CreateGameScreen(state: widget.state)),
    );
  }
}

String homeHelpExplanation(AppState state) {
  final joinedGames = state.repository.joinedGames;
  if (joinedGames.any((game) => game.status == GameStatus.active)) {
    return 'Kies een tegel om te openen of ga direct verder met je actieve spel.';
  }
  final joinedIds = joinedGames.map((game) => game.id).toSet();
  final now = DateTime.now();
  final discoverableGames = state.repository.availableGames.where(
    (game) =>
        !joinedIds.contains(game.id) &&
        (game.scheduledEnd == null || game.scheduledEnd!.isAfter(now)),
  );
  if (discoverableGames.isNotEmpty) {
    return 'Kies een tegel om verder te gaan. Kijk bij Spellen ontdekken voor een leuk spel.';
  }
  if (joinedGames.isNotEmpty) {
    return 'Je hebt nog geen actief spel. Bekijk Mijn spellen voor je geplande spel.';
  }
  return 'Er zijn nog geen spellen beschikbaar in de buurt. Maak er zelf één aan via Nieuw spel.';
}

class _GuidedTourOverlay extends StatelessWidget {
  const _GuidedTourOverlay({
    required this.step,
    required this.homeExplanation,
    required this.onNext,
    required this.onSkip,
  });

  static const steps = [
    (
      title: 'Welkom op het startscherm',
      text:
          'Kies een tegel om naar je spellen te gaan, spellen te ontdekken of je resultaten te bekijken.',
    ),
    (
      title: 'Je navigatie',
      text:
          'Onderaan op je telefoon of links op een groot scherm vind je de belangrijkste onderdelen van Verstobbertje.',
    ),
    (
      title: 'De Stobbedetective',
      text:
          'Zie je mij bij een scherm? Tik op mij als je uitleg wilt. Ik vertel je dan wat je hier kunt doen.',
    ),
    (
      title: 'Een nieuw spel',
      text:
          'Met deze knop maak je een spel aan. Ik loop straks ook met je door de belangrijkste keuzes heen.',
    ),
  ];

  final int step;
  final String homeExplanation;
  final VoidCallback onNext;
  final VoidCallback onSkip;

  Rect _targetRect(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final isWide = size.width >= 800;
    if (isWide) {
      return switch (step) {
        0 => Rect.fromLTWH(205, 24, size.width - 225, size.height - 160),
        1 => Rect.fromLTWH(0, 0, 190, size.height),
        2 => const Rect.fromLTWH(28, 70, 130, 145),
        _ => Rect.fromLTWH(size.width - 130, size.height - 125, 120, 100),
      };
    }
    return switch (step) {
      0 => Rect.fromLTWH(12, 12, size.width - 24, size.height - 205),
      1 => Rect.fromLTWH(0, size.height - 105, size.width, 105),
      2 => Rect.fromLTWH(size.width - 82, 0, 78, 70),
      _ => Rect.fromLTWH(size.width - 92, size.height - 175, 88, 88),
    };
  }

  @override
  Widget build(BuildContext context) {
    final current = steps[step];
    final explanation = step == 0 ? homeExplanation : current.text;
    final target = _targetRect(context);
    return Positioned.fill(
      child: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: _TourSpotlightPainter(target: target),
            ),
          ),
          SafeArea(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 620),
                child: Card(
                  margin: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        StobbeGuide(explanation: explanation),
                        const SizedBox(height: 12),
                        Text(
                          current.title,
                          textAlign: TextAlign.center,
                          style: Theme.of(context)
                              .textTheme
                              .titleLarge
                              ?.copyWith(fontWeight: FontWeight.w900),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Rondleiding ${step + 1} van ${steps.length}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            TextButton(
                              key: const Key('guided-tour-skip'),
                              onPressed: onSkip,
                              child: const Text('Overslaan'),
                            ),
                            const Spacer(),
                            FilledButton.icon(
                              key: const Key('guided-tour-next'),
                              onPressed: onNext,
                              icon: Icon(
                                step == steps.length - 1
                                    ? Icons.check
                                    : Icons.arrow_forward,
                              ),
                              label: Text(
                                step == steps.length - 1
                                    ? 'Beginnen'
                                    : 'Volgende',
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TourSpotlightPainter extends CustomPainter {
  const _TourSpotlightPainter({required this.target});

  final Rect target;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.saveLayer(Offset.zero & size, Paint());
    final overlay = Paint()..color = Colors.black54;
    canvas.drawRect(Offset.zero & size, overlay);

    final hole = RRect.fromRectAndRadius(target, const Radius.circular(18));
    canvas.drawRRect(
      hole,
      Paint()
        ..blendMode = BlendMode.dstOut
        ..color = Colors.white,
    );
    canvas.drawRRect(
      hole,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..color = Colors.white,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _TourSpotlightPainter oldDelegate) =>
      oldDelegate.target != target;
}
