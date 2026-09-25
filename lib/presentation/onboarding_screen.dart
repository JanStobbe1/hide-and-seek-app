import 'package:flutter/material.dart';

import '../app_state.dart';
import '../domain/profile_models.dart';
import 'stobbe_guide.dart';

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
  String? confirmationError;
  bool confirmed = false;
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
                          title: 'Aangenaam kennis te maken!',
                          text:
                              'Hoi! Ik ben de Stobbedetective. Ik heb al heel wat jaarringen, maar ik blijf nieuwsgierig. Ik leg je uit hoe Verstobbertje werkt en help je op elk scherm verder.',
                          child: Image.asset(
                            'assets/images/stobbekarakter.png',
                            height: 220,
                            fit: BoxFit.contain,
                          ),
                        ),
                        _OnboardingPage(
                          icon: Icons.badge_outlined,
                          title: 'Hoe mag ik je noemen?',
                          text:
                              'Ik weet nu wie ik ben. Nu ben ik benieuwd naar jou: welke naam mag ik op je vinklijstje zetten? Kies daarna ook een marker — zo herken ik je straks tussen alle spelers.',
                          child: Column(
                            children: [
                              TextField(
                                key: const Key('onboarding-name'),
                                controller: name,
                                maxLength: 30,
                                textInputAction: TextInputAction.done,
                                decoration: InputDecoration(
                                  labelText: 'Jouw naam voor het spel',
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
                          title: 'Zo spelen we samen',
                          text:
                              'De regels zijn simpel: ik geef je een rol, een timer en een speelgebied. Jij ontdekt wat er op de kaart gebeurt. Mijn krachten houd ik nog even achter mijn rug — anders wordt het wel erg makkelijk.',
                          child: _OnboardingFacts(
                            facts: [
                              'Blijf binnen het aangegeven speelgebied',
                              'Gebruik PAK SPELER wanneer iemand dichtbij is',
                              'Krachten en fiches gelden alleen voor dit spel',
                            ],
                          ),
                        ),
                        _OnboardingPage(
                          icon: Icons.fact_check_outlined,
                          title: 'Even controleren, detective',
                          text:
                              'Kijk je vinklijstje nog één keer na. Klopt alles? Dan zet ik mijn handtekening eronder en maken we je profiel definitief.',
                          child: _OnboardingConfirmation(
                            playerName: widget.state.displayName,
                            marker: marker,
                            confirmed: confirmed,
                            errorText: confirmationError,
                            onChanged: (value) => setState(() {
                              confirmed = value;
                              confirmationError = null;
                            }),
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
                              page == 3 ? 'Akkoord en ondertekenen' : 'Volgende'),
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
      if (!confirmed) {
        setState(() => confirmationError = 'Vink eerst aan dat je gegevens kloppen.');
        return;
      }
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
          StobbeGuide(explanation: text),
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


class _OnboardingConfirmation extends StatelessWidget {
  const _OnboardingConfirmation({
    required this.playerName,
    required this.marker,
    required this.confirmed,
    required this.errorText,
    required this.onChanged,
  });

  final String playerName;
  final PlayerMarker marker;
  final bool confirmed;
  final String? errorText;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) => Card(
        key: const Key('onboarding-checklist'),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              CheckboxListTile(
                key: const Key('onboarding-confirmation'),
                value: confirmed,
                onChanged: (value) => onChanged(value ?? false),
                title: const Text('Mijn gegevens kloppen'),
                subtitle: Text(
                  'Naam: $playerName\nMarker: ${_markerLabel(marker)}',
                ),
                controlAffinity: ListTileControlAffinity.leading,
              ),
              if (errorText != null)
                Text(
                  errorText!,
                  key: const Key('onboarding-confirmation-error'),
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.error,
                  ),
                ),
              if (confirmed) ...[
                const Divider(),
                const SizedBox(height: 4),
                const Text(
                  'Ondertekend door de Stobbedetective',
                  key: Key('onboarding-signature'),
                  style: TextStyle(
                    fontStyle: FontStyle.italic,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Text('Stobbe ✍️'),
              ],
            ],
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
