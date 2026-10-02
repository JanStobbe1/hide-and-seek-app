import 'package:flutter/material.dart';

import '../app_state.dart';
import '../domain/profile_models.dart';
import 'seasonal_stobbe.dart';
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
  final TextEditingController age = TextEditingController();
  final TextEditingController city = TextEditingController();
  int page = 0;
  String? nameError;
  String? ageError;
  String? cityError;
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
    age.dispose();
    city.dispose();
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
                        6,
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
                              'Welkom in mijn app! Ik ben Mr. Stobbe, zoals je kan zien ben ik een gewortelde detective maar ik deel mijn kwaliteiten graag met een groentje zoals jij. Kan je me vertellen hoe jij heet?',
                          child: Column(
                            children: [
                              const SeasonalStobbe(
                                assetPath: 'assets/images/stobbekarakter.png',
                                height: 200,
                                fit: BoxFit.contain,
                              ),
                              const SizedBox(height: 12),
                              TextField(
                                key: const Key('onboarding-name'),
                                controller: name,
                                maxLength: 30,
                                textInputAction: TextInputAction.done,
                                decoration: InputDecoration(
                                  labelText: 'Jouw naam in het spel',
                                  hintText: 'Bijvoorbeeld Noor',
                                  errorText: nameError,
                                ),
                              ),
                            ],
                          ),
                        ),
                        _OnboardingPage(
                          icon: Icons.forest_outlined,
                          title: 'Hoeveel jaarringen heb jij?',
                          text:
                              'Ik heb al heel wat jaarringen verzameld. Geen zorgen: ik vraag niet naar mijn leeftijd. Hoeveel jaarringen mag ik bij jou noteren?',
                          child: TextField(
                            key: const Key('onboarding-age'),
                            controller: age,
                            keyboardType: TextInputType.number,
                            maxLength: 3,
                            decoration: InputDecoration(
                              labelText: 'Jouw leeftijd',
                              hintText: 'Bijvoorbeeld 12',
                              errorText: ageError,
                            ),
                          ),
                        ),
                        _OnboardingPage(
                          icon: Icons.badge_outlined,
                          title: 'Jouw pionnetje',
                          text:
                              'Dank je! Waar staat jouw basis? En wat voor speler ben jij? Kies een pionnetje, zodat ik je straks tussen alle spelers herken.',
                          child: Column(
                            children: [
                              TextField(
                                key: const Key('onboarding-city'),
                                controller: city,
                                maxLength: 40,
                                textInputAction: TextInputAction.done,
                                decoration: InputDecoration(
                                  labelText: 'Woonplaats',
                                  hintText: 'Bijvoorbeeld Amsterdam',
                                  errorText: cityError,
                                ),
                              ),
                              const SizedBox(height: 12),
                              DropdownButtonFormField<PlayerMarker>(
                                initialValue: marker,
                                decoration: const InputDecoration(
                                  labelText: 'Mijn pionnetje',
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
                                  if (value != null) {
                                    setState(() => marker = value);
                                  }
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
                              'Verkregen krachten zijn alleen bruikbaar in het spel waarin ze gevonden worden',
                            ],
                          ),
                        ),
                        const _OnboardingPage(
                          icon: Icons.health_and_safety_outlined,
                          title: 'Nog één belangrijke afspraak',
                          text:
                              'Een goede detective is slim én netjes. Verkeer gaat voor het spel: kijk goed om je heen en gebruik je telefoon niet tijdens het lopen. Ga nooit een woning of privéterrein binnen en stop altijd als iets niet veilig voelt.',
                          child: _OnboardingFacts(
                            facts: [
                              'Exacte locaties worden alleen gedeeld volgens de spelregels',
                              'De Mr. Stobbe legt ieder scherm uit',
                              'Je kunt privacy en uiterlijk later wijzigen in Profiel',
                            ],
                          ),
                        ),
                        _OnboardingPage(
                          icon: Icons.fact_check_outlined,
                          title: 'Even controleren, detective',
                          text:
                              'Zo ${widget.state.displayName}, je bent er helemaal klaar voor. Nog één keer checken of ik alles goed heb genoteerd:',
                          child: _OnboardingConfirmation(
                            playerName: widget.state.displayName,
                            playerAge: age.text,
                            playerCity: city.text,
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
                          icon: Icon(page == 5
                              ? Icons.menu_book
                              : Icons.arrow_forward),
                          label: Text(
                            page == 5 ? 'Akkoord en ondertekenen' : 'Volgende',
                          ),
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
    if (page == 0) {
      final error = widget.state.setDisplayName(name.text);
      if (error != null) {
        setState(() => nameError = error);
        return;
      }
    }
    if (page == 1) {
      final value = age.text.trim();
      final parsed = int.tryParse(value);
      if (parsed == null) {
        setState(() => ageError = 'Vul je leeftijd in als getal.');
        return;
      }
      if (parsed < 6 || parsed > 120) {
        setState(() => ageError = 'Vul een leeftijd tussen 6 en 120 jaar in.');
        return;
      }
      setState(() => ageError = null);
      widget.state.setProfileAge(parsed.toString());
    }
    if (page == 2) {
      final value = city.text.trim();
      if (value.isEmpty) {
        setState(() => cityError = 'Vul je woonplaats in.');
        return;
      }
      widget.state.setProfileCity(value);
      widget.state.setPlayerMarker(marker);
      setState(() {
        confirmed = false;
        confirmationError = null;
      });
    }
    if (page == 5) {
      if (!confirmed) {
        setState(
          () => confirmationError = 'Vink eerst aan dat je gegevens kloppen.',
        );
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
    required this.playerAge,
    required this.playerCity,
    required this.marker,
    required this.confirmed,
    required this.errorText,
    required this.onChanged,
  });

  final String playerName;
  final String playerAge;
  final String playerCity;
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
                  'Naam: $playerName\nLeeftijd: $playerAge\nWoonplaats: $playerCity\nPionnetje: ${_markerLabel(marker)}',
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Mr. Stobbe',
                      key: Key('onboarding-signature'),
                      style: TextStyle(
                        fontFamily: 'cursive',
                        fontStyle: FontStyle.italic,
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(width: 2),
                        color: Theme.of(context).colorScheme.secondaryContainer,
                      ),
                      child: const Text(
                        'HIRED',
                        key: Key('onboarding-hired-stamp'),
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
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
