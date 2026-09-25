import 'package:flutter/material.dart';

import '../app_state.dart';
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
    super.key,
  });

  final AppState state;
  final bool startTour;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int index = 0;
  late bool tourActive;
  int tourStep = 0;

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
    'Kies hier welk hoofdstuk je wilt openen of ga direct verder met je actieve spel.',
    'Hier staan je actieve en geplande spellen. Tik op een spel om het te openen.',
    'Bekijk spellen in de buurt, sorteer ze en tik erop om de details te lezen of mee te doen.',
    'Open een afgerond spel om je score, eindpositie en medespelers terug te zien.',
    'Beheer hier je naam, vrienden, privacy, kaartmarker en de uitstraling van de app.',
  ];

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
                    onNext: _nextTourStep,
                    onSkip: _finishTour,
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
                      explanation: helpTexts[index],
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
            Expanded(child: content),
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
              explanation: helpTexts[index],
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
    if (tourStep >= _GuidedTourOverlay.steps.length - 1) {
      _finishTour();
      return;
    }
    setState(() => tourStep++);
  }

  void _finishTour() {
    setState(() => tourActive = false);
  }

  void _create() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => CreateGameScreen(state: widget.state)),
    );
  }
}

class _GuidedTourOverlay extends StatelessWidget {
  const _GuidedTourOverlay({
    required this.step,
    required this.onNext,
    required this.onSkip,
  });

  static const steps = [
    (
      title: 'Welkom in de inhoudsopgave',
      text:
          'Hier begin je. Vanuit dit hoofdscherm ga je naar je spellen, ontdek je nieuwe spellen en bekijk je resultaten.',
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
  final VoidCallback onNext;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    final current = steps[step];
    return Positioned.fill(
      child: ColoredBox(
        color: Colors.black54,
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 620),
              child: Card(
                margin: const EdgeInsets.all(24),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.sizeOf(context).height - 48,
                  ),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        StobbeGuide(explanation: current.text),
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
        ),
      ),
    );
  }
}
