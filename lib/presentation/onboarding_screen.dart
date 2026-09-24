import 'package:flutter/material.dart';

import '../app_state.dart';
import '../domain/profile_models.dart';
import 'widgets.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({
    required this.state,
    required this.onComplete,
    super.key,
  });

  final AppState state;
  final VoidCallback onComplete;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController controller = PageController();
  final TextEditingController name = TextEditingController();
  int page = 0;
  String? nameError;
  late PlayerMarker marker;

  @override
  void initState() {
    super.initState();
    marker = widget.state.playerMarker;
  }

  @override
  void dispose() {
    controller.dispose();
    name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('Welkom bij Verstobbertje'),
          actions: const [
            StobbeDetectiveButton(
              pageTitle: 'Je eerste stappen',
              explanation:
                  'Ik help je met je spelersnaam, kaartmarker en de belangrijkste spelregels. Daarna kom je bij de inhoudsopgave.',
            ),
          ],
        ),
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 680),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
                    child: Row(
                      children: List.generate(
                        4,
                        (index) => Expanded(
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 250),
                            height: 6,
                            margin: const EdgeInsets.symmetric(horizontal: 3),
                            decoration: BoxDecoration(
                              color: index <= page
                                  ? Theme.of(context).colorScheme.primary
                                  : Theme.of(context)
                                      .colorScheme
                                      .surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: PageView(
                      controller: controller,
                      physics: const NeverScrollableScrollPhysics(),
                      onPageChanged: (value) => setState(() => page = value),
                      children: [
                        _OnboardingPage(
                          icon: Icons.travel_explore,
                          title: 'Een avontuur in de buitenlucht',
                          text:
                              'Verstop, zoek, beweeg en verzamel punten. De Stobbedetective helpt je onderweg op ieder scherm.',
                          child: Image.asset(
                            'assets/images/stobbekarakter.png',
                            height: 220,
                            fit: BoxFit.contain,
                          ),
                        ),
                        _OnboardingPage(
                          icon: Icons.badge_outlined,
                          title: 'Hoe mogen spelers je noemen?',
                          text:
                              'Je profielnaam en kaartmarker zijn tijdens een spel herkenbaar voor andere spelers.',
                          child: Column(
                            children: [
                              TextField(
                                key: const Key('onboarding-name'),
                                controller: name,
                                maxLength: 30,
                                textInputAction: TextInputAction.done,
                                decoration: InputDecoration(
                                  labelText: 'Profielnaam',
                                  hintText: 'Bijvoorbeeld Noor',
                                  errorText: nameError,
                                ),
                              ),
                              const SizedBox(height: 12),
                              DropdownButtonFormField<PlayerMarker>(
                                initialValue: marker,
                                decoration: const InputDecoration(
                                  labelText: 'Mijn kaartmarker',
                                ),
                                items: PlayerMarker.values
                                    .map(
                                      (value) => DropdownMenuItem(
                                        value: value,
                                        child: Text(_markerLabel(value)),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (value) {
                                  if (value != null) marker = value;
                                },
                              ),
                            ],
                          ),
                        ),
                        const _OnboardingPage(
                          icon: Icons.map_outlined,
                          title: 'Zo werkt een spel',
                          text:
                              'Je rol, timer en speelgebied bepalen je opdracht. Op de kaart zie je wat voor jouw rol zichtbaar is. Stobbekrachten kun je pas na de eerste fase inzetten.',
                          child: _OnboardingFacts(
                            facts: [
                              'Blijf binnen het aangegeven speelgebied',
                              'Gebruik PAK SPELER wanneer iemand dichtbij is',
                              'Krachten en fiches gelden alleen voor dit spel',
                            ],
                          ),
                        ),
                        const _OnboardingPage(
                          icon: Icons.health_and_safety_outlined,
                          title: 'Speel slim en veilig',
                          text:
                              'Ga nooit een woning of privéterrein binnen om iemand te pakken. Respecteer de omgeving en stop wanneer een situatie niet veilig voelt.',
                          child: _OnboardingFacts(
                            facts: [
                              'Exacte locaties worden alleen gedeeld volgens de spelregels',
                              'De Stobbedetective legt ieder scherm uit',
                              'Je kunt privacy en uiterlijk later wijzigen in Profiel',
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        if (page > 0)
                          TextButton.icon(
                            onPressed: _previous,
                            icon: const Icon(Icons.arrow_back),
                            label: const Text('Terug'),
                          ),
                        const Spacer(),
                        FilledButton.icon(
                          onPressed: _next,
                          icon: Icon(page == 3
                              ? Icons.menu_book
                              : Icons.arrow_forward),
                          label: Text(
                              page == 3 ? 'Naar de inhoudsopgave' : 'Volgende'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

  void _previous() {
    controller.previousPage(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  void _next() {
    if (page == 1) {
      final error = widget.state.setDisplayName(name.text);
      if (error != null) {
        setState(() => nameError = error);
        return;
      }
      widget.state.setPlayerMarker(marker);
    }
    if (page == 3) {
      widget.onComplete();
      return;
    }
    controller.nextPage(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }
}

class _OnboardingPage extends StatelessWidget {
  const _OnboardingPage({
    required this.icon,
    required this.title,
    required this.text,
    required this.child,
  });

  final IconData icon;
  final String title;
  final String text;
  final Widget child;

  @override
  Widget build(BuildContext context) => ListView(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
        children: [
          Icon(icon, size: 46, color: Theme.of(context).colorScheme.primary),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: Theme.of(context)
                .textTheme
                .headlineSmall
                ?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 10),
          Text(text, textAlign: TextAlign.center),
          const SizedBox(height: 24),
          child,
        ],
      );
}

class _OnboardingFacts extends StatelessWidget {
  const _OnboardingFacts({required this.facts});

  final List<String> facts;

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: facts
                .map(
                  (fact) => ListTile(
                    leading: const Icon(Icons.check_circle_outline),
                    title: Text(fact),
                  ),
                )
                .toList(),
          ),
        ),
      );
}

String _markerLabel(PlayerMarker marker) => switch (marker) {
      PlayerMarker.ghost => 'Spookje',
      PlayerMarker.wolf => 'Wolf',
      PlayerMarker.police => 'Politie-embleem',
      PlayerMarker.explorer => 'Ontdekker',
    };
