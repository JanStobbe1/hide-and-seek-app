import 'package:flutter/material.dart';

import '../app_state.dart';
import '../domain/models.dart';
import '../services/introduction_service.dart';
import '../services/location_repository.dart';
import 'widgets.dart';

class CreateGameScreen extends StatefulWidget {
  const CreateGameScreen({required this.state, super.key});

  final AppState state;

  @override
  State<CreateGameScreen> createState() => _CreateGameScreenState();
}

class _CreateGameScreenState extends State<CreateGameScreen> {
  int step = 0;
  final name = TextEditingController(text: 'Test123');
  final intro = TextEditingController();
  final specificArea = TextEditingController(text: 'Niet van toepassing');
  final LocationRepository locations = const DemoLocationRepository();
  final IntroductionService introductionService =
      const DemoIntroductionService();
  LocationSelection location = const LocationSelection(
    country: 'Nederland',
    province: 'Flevoland',
    cities: ['Almere'],
    districts: ['Alle'],
    neighbourhoods: ['Alle'],
  );
  int introductionVariant = 0;
  bool introductionWasGenerated = false;

  bool isPublic = true;
  bool hints = true;
  bool questions = true;
  int players = 30;
  int duration = 120;
  int participantThreshold = 10;
  StartCondition condition = StartCondition.participantCount;
  DateTime scheduledDate = DateTime(2027, 8, 25);
  TimeOfDay scheduledTime = const TimeOfDay(hour: 16, minute: 0);

  @override
  void dispose() {
    name.dispose();
    intro.dispose();
    specificArea.dispose();
    super.dispose();
  }

  SearchArea get selectedArea => SearchArea(
        country: location.country ?? 'Nederland',
        province: location.province ?? 'Alle',
        city: _selectionLabel(location.cities),
        neighbourhood: _selectionLabel(
          location.neighbourhoods.isNotEmpty
              ? location.neighbourhoods
              : location.districts,
        ),
        specificArea: specificArea.text.trim(),
      );

  DateTime get selectedStart => DateTime(
        scheduledDate.year,
        scheduledDate.month,
        scheduledDate.day,
        scheduledTime.hour,
        scheduledTime.minute,
      );

  DateTime? get selectedScheduledStart {
    if (condition == StartCondition.scheduled) {
      return selectedStart;
    }
    return null;
  }

  int? get selectedParticipantThreshold {
    if (condition == StartCondition.participantCount) {
      return participantThreshold;
    }
    return null;
  }

  String get _detectiveExplanation {
    const explanations = [
      'Geef je avontuur een naam en kies de belangrijkste spelregels.',
      'Kies het speelgebied. Je kunt meerdere gemeenten, wijken en buurten '
          'selecteren.',
      'Bepaal wanneer het spel start en schrijf een uitnodigende introductie.',
      'Controleer alle keuzes voordat je het spel beschikbaar maakt.',
    ];
    return explanations[step];
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('Nieuw spel'),
          actions: [
            StobbeDetectiveButton(
              pageTitle: 'Nieuw spel',
              explanation: _detectiveExplanation,
            ),
          ],
        ),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: Stepper(
              currentStep: step,
              onStepTapped: (value) => setState(() => step = value),
              onStepContinue:
                  step == 3 ? _publish : () => setState(() => step++),
              onStepCancel: step == 0 ? null : () => setState(() => step--),
              controlsBuilder: _buildControls,
              steps: [
                Step(
                  title: const Text('Basis'),
                  isActive: step >= 0,
                  content: _withStepSpacing(_buildBasics()),
                ),
                Step(
                  title: const Text('Zoekgebied'),
                  isActive: step >= 1,
                  content: _withStepSpacing(_buildSearchArea()),
                ),
                Step(
                  title: const Text('Start & introductie'),
                  isActive: step >= 2,
                  content: _withStepSpacing(_buildStartAndIntroduction()),
                ),
                Step(
                  title: const Text('Controleren'),
                  isActive: step >= 3,
                  content: _withStepSpacing(_Review(
                    name: name.text,
                    isPublic: isPublic,
                    duration: duration,
                    players: players,
                    hints: hints,
                    questions: questions,
                    intro: intro.text,
                    area: selectedArea,
                    startCondition: condition,
                    scheduledStart: selectedScheduledStart,
                    participantThreshold: selectedParticipantThreshold,
                  )),
                ),
              ],
            ),
          ),
        ),
      );

  Widget _withStepSpacing(Widget child) => Padding(
        padding: const EdgeInsets.only(top: 12),
        child: child,
      );

  Widget _buildControls(BuildContext context, ControlsDetails details) =>
      Padding(
        padding: const EdgeInsets.only(top: 20),
        child: Row(
          children: [
            Expanded(
              child: FilledButton(
                onPressed: details.onStepContinue,
                child: Text(step == 3 ? 'Stel spel beschikbaar' : 'Volgende'),
              ),
            ),
            if (step > 0) ...[
              const SizedBox(width: 8),
              TextButton(
                onPressed: details.onStepCancel,
                child: const Text('Terug'),
              ),
            ],
          ],
        ),
      );

  Widget _buildBasics() => Column(
        children: [
          TextField(
            controller: name,
            onChanged: (_) => _sourceChanged(),
            decoration: const InputDecoration(
              labelText: 'Naam van het spel',
              floatingLabelBehavior: FloatingLabelBehavior.always,
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 16, vertical: 18),
            ),
          ),
          const SizedBox(height: 12),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(isPublic ? 'Openbaar spel' : 'Privéspel'),
            subtitle: const Text('Wie kan dit spel ontdekken?'),
            value: isPublic,
            onChanged: (value) => setState(() => isPublic = value),
          ),
          _SettingSlider(
            label: 'Duur',
            value: duration.toDouble(),
            min: 30,
            max: 360,
            divisions: 11,
            suffix: ' minuten',
            onChanged: (value) {
              _sourceChanged();
              setState(() => duration = value.round());
            },
          ),
          _SettingSlider(
            label: 'Maximum deelnemers',
            value: players.toDouble(),
            min: 6,
            max: 60,
            divisions: 9,
            suffix: ' spelers',
            onChanged: (value) => setState(() {
              players = value.round();
              if (participantThreshold > players) {
                participantThreshold = players;
              }
            }),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Hints kunnen worden gekocht'),
            value: hints,
            onChanged: (value) => setState(() => hints = value),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Vragen kunnen worden beantwoord'),
            value: questions,
            onChanged: (value) => setState(() => questions = value),
          ),
        ],
      );

  Widget _buildSearchArea() => Column(
        children: [
          _LocationAutocomplete(
            label: 'Land(en)',
            value: location.country,
            options: locations.countries,
            onSelected: (value) {
              _sourceChanged();
              setState(() => location = location.selectCountry(value));
            },
          ),
          _LocationAutocomplete(
            label: 'Provincie(s)',
            value: location.province,
            options: location.country == null
                ? const []
                : locations.provincesFor(location.country!),
            enabled: location.country != null,
            onSelected: (value) {
              _sourceChanged();
              setState(() => location = location.selectProvince(value));
            },
          ),
          _MultiLocationPicker(
            label: 'Gemeente(n)',
            values: location.cities,
            options: location.country == null || location.province == null
                ? const []
                : locations.citiesFor(location.country!, location.province!),
            enabled: location.province != null && location.province != 'Alle',
            onChanged: (values) {
              _sourceChanged();
              setState(() => location = location.selectCities(values));
            },
          ),
          _MultiLocationPicker(
            label: 'Wijk(en)',
            values: location.districts,
            options: location.country == null ||
                    location.province == null ||
                    location.cities.isEmpty
                ? const []
                : locations.districtsFor(
                    location.country!,
                    location.province!,
                    location.cities,
                  ),
            enabled:
                location.cities.isNotEmpty && !location.cities.contains('Alle'),
            onChanged: (values) {
              _sourceChanged();
              setState(() => location = location.selectDistricts(values));
            },
          ),
          _MultiLocationPicker(
            label: 'Buurt(en)',
            values: location.neighbourhoods,
            options: location.country == null ||
                    location.province == null ||
                    location.districts.isEmpty
                ? const []
                : locations.neighbourhoodsFor(
                    location.country!,
                    location.province!,
                    location.districts,
                  ),
            enabled: location.districts.isNotEmpty &&
                !location.districts.contains('Alle'),
            onChanged: (values) {
              _sourceChanged();
              setState(
                () => location = location.selectNeighbourhoods(values),
              );
            },
          ),
          _AreaField(label: 'Specifiek gebied', controller: specificArea),
          const SizedBox(height: 4),
          const MapPlaceholder(height: 190),
          const Padding(
            padding: EdgeInsets.all(8),
            child: Text(
              'Selecteer één of meerdere gemeenten, wijken en buurten. '
              '‘Alle’ kiest het volledige bovenliggende gebied.',
              style: TextStyle(fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      );

  Widget _buildStartAndIntroduction() => RadioGroup<StartCondition>(
        groupValue: condition,
        onChanged: (value) {
          if (value == null) return;
          setState(() => condition = value);
        },
        child: Column(
          children: [
            RadioListTile<StartCondition>(
              value: StartCondition.participantCount,
              title: const Text('Start bij genoeg deelnemers'),
              subtitle: Text('Wanneer $participantThreshold spelers meedoen'),
            ),
            if (condition == StartCondition.participantCount)
              _SettingSlider(
                label: 'Benodigde deelnemers',
                value: participantThreshold.toDouble(),
                min: 2,
                max: players.toDouble(),
                divisions: players - 2,
                suffix: ' spelers',
                onChanged: (value) =>
                    setState(() => participantThreshold = value.round()),
              ),
            RadioListTile<StartCondition>(
              value: StartCondition.scheduled,
              title: const Text('Start op datum en tijd'),
              subtitle: Text(_formatScheduledStart(selectedStart)),
            ),
            if (condition == StartCondition.scheduled)
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _pickDate,
                      icon: const Icon(Icons.calendar_month),
                      label: const Text('Kies datum'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _pickTime,
                      icon: const Icon(Icons.schedule),
                      label: const Text('Kies tijd'),
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 16),
            TextField(
              controller: intro,
              onChanged: (_) => introductionWasGenerated = false,
              maxLines: 5,
              decoration: const InputDecoration(
                labelText: 'Spelintroductie',
                hintText: 'Vertel spelers wat ze kunnen verwachten…',
              ),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: _generateIntroduction,
              icon: const Icon(Icons.auto_awesome),
              label: const Text('Genereer introductie met AI (demo)'),
            ),
          ],
        ),
      );

  void _generateIntroduction() {
    final locationLabel = introductionLocationLabel(location);
    final request = IntroductionRequest(
      gameName: name.text.trim().isEmpty ? 'dit spel' : name.text.trim(),
      city: locationLabel,
      durationMinutes: duration,
      maxParticipants: players,
      hintsEnabled: hints,
      questionsEnabled: questions,
      organizer: widget.state.displayName,
      region: locationLabel,
    );
    intro.text = introductionService.generate(
      request,
      variant: introductionVariant,
    );
    introductionWasGenerated = true;
    introductionVariant++;
  }

  void _sourceChanged() {
    if (introductionWasGenerated && intro.text.isNotEmpty) {
      intro.clear();
      introductionWasGenerated = false;
    }
  }

  Future<void> _pickDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: scheduledDate,
      firstDate: DateTime(2026),
      lastDate: DateTime(2035, 12, 31),
      helpText: 'Kies de startdatum',
    );
    if (selected != null && mounted) setState(() => scheduledDate = selected);
  }

  Future<void> _pickTime() async {
    final selected = await showTimePicker(
      context: context,
      initialTime: scheduledTime,
      helpText: 'Kies de starttijd',
    );
    if (selected != null && mounted) setState(() => scheduledTime = selected);
  }

  void _publish() {
    final now = DateTime.now();
    widget.state.publish(
      Game(
        id: 'created-${now.millisecondsSinceEpoch}',
        name: name.text.trim().isEmpty ? 'Naamloos spel' : name.text.trim(),
        organizer: 'Arie',
        description: intro.text.trim().isEmpty
            ? 'Een nieuw avontuur in Almere.'
            : intro.text.trim(),
        area: selectedArea,
        status: GameStatus.available,
        duration: Duration(minutes: duration),
        participants: 1,
        maxParticipants: players,
        distanceKm: 1.2,
        startCondition: condition,
        scheduledStart: selectedScheduledStart,
        participantThreshold: selectedParticipantThreshold,
        isPublic: isPublic,
        rules: GameRules(hintsEnabled: hints, questionsEnabled: questions),
      ),
    );
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: const Icon(Icons.rocket_launch, size: 46),
        title: const Text('Spel is beschikbaar!'),
        content: Text(
          '${name.text} staat nu lokaal tussen Beschikbare spellen.',
        ),
        actions: [
          FilledButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              Navigator.pop(context);
            },
            child: const Text('Klaar'),
          ),
        ],
      ),
    );
  }
}

class _SettingSlider extends StatelessWidget {
  const _SettingSlider({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.divisions,
    required this.suffix,
    required this.onChanged,
  });

  final String label;
  final String suffix;
  final double value;
  final double min;
  final double max;
  final int divisions;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label: ${value.round()}$suffix',
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          Slider(
            value: value,
            min: min,
            max: max,
            divisions: divisions,
            onChanged: onChanged,
          ),
        ],
      );
}

class _AreaField extends StatelessWidget {
  const _AreaField({required this.label, required this.controller});

  final String label;
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: TextField(
          controller: controller,
          decoration: InputDecoration(
            labelText: label,
            prefixIcon: const Icon(Icons.location_on_outlined),
          ),
        ),
      );
}

class _LocationAutocomplete extends StatelessWidget {
  const _LocationAutocomplete({
    required this.label,
    required this.value,
    required this.options,
    required this.onSelected,
    this.enabled = true,
  });

  final String label;
  final String? value;
  final List<String> options;
  final ValueChanged<String> onSelected;
  final bool enabled;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Autocomplete<String>(
          key: ValueKey('$label-$value-$enabled'),
          initialValue: TextEditingValue(text: value ?? ''),
          optionsBuilder: (text) {
            if (!enabled) return const Iterable<String>.empty();
            return filterLocationOptions(options, text.text);
          },
          onSelected: onSelected,
          fieldViewBuilder:
              (context, controller, focusNode, onFieldSubmitted) =>
                  TextFormField(
            controller: controller,
            focusNode: focusNode,
            enabled: enabled,
            onFieldSubmitted: (_) => onFieldSubmitted(),
            decoration: InputDecoration(
              labelText: label,
              hintText: enabled ? 'Typ om te zoeken' : 'Kies eerst hierboven',
              prefixIcon: const Icon(Icons.location_on_outlined),
              suffixIcon: const Icon(Icons.arrow_drop_down),
              floatingLabelBehavior: FloatingLabelBehavior.always,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 18,
              ),
            ),
          ),
        ),
      );
}

class _MultiLocationPicker extends StatelessWidget {
  const _MultiLocationPicker({
    required this.label,
    required this.values,
    required this.options,
    required this.onChanged,
    this.enabled = true,
  });

  final String label;
  final List<String> values;
  final List<String> options;
  final ValueChanged<List<String>> onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: InkWell(
          onTap: enabled ? () => _showPicker(context) : null,
          borderRadius: BorderRadius.circular(12),
          child: InputDecorator(
            decoration: InputDecoration(
              labelText: label,
              hintText: enabled ? 'Kies één of meer' : 'Kies eerst hierboven',
              prefixIcon: const Icon(Icons.location_on_outlined),
              suffixIcon: const Icon(Icons.arrow_drop_down),
              enabled: enabled,
            ),
            isEmpty: values.isEmpty,
            child: values.isEmpty
                ? null
                : Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: values
                        .map(
                          (value) => Chip(
                            label: Text(value),
                            visualDensity: VisualDensity.compact,
                          ),
                        )
                        .toList(growable: false),
                  ),
          ),
        ),
      );

  Future<void> _showPicker(BuildContext context) async {
    var query = '';
    final selected = values.toSet();
    final result = await showDialog<List<String>>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) {
          final filtered = filterLocationOptions(options, query).toList();
          return AlertDialog(
            title: Text(label),
            content: SizedBox(
              width: 520,
              height: 480,
              child: Column(
                children: [
                  TextField(
                    autofocus: true,
                    onChanged: (value) => setDialogState(() => query = value),
                    decoration: const InputDecoration(
                      hintText: 'Typ om te zoeken',
                      prefixIcon: Icon(Icons.search),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: ListView.builder(
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final option = filtered[index];
                        return CheckboxListTile(
                          value: selected.contains(option),
                          title: Text(option),
                          controlAffinity: ListTileControlAffinity.leading,
                          onChanged: (checked) => setDialogState(() {
                            if (checked ?? false) {
                              if (option == 'Alle') {
                                selected
                                  ..clear()
                                  ..add(option);
                              } else {
                                selected
                                  ..remove('Alle')
                                  ..add(option);
                              }
                            } else {
                              selected.remove(option);
                            }
                          }),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Annuleren'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(
                  dialogContext,
                  selected.toList(growable: false),
                ),
                child: const Text('Toepassen'),
              ),
            ],
          );
        },
      ),
    );
    if (result != null) onChanged(result);
  }
}

class _Review extends StatelessWidget {
  const _Review({
    required this.name,
    required this.isPublic,
    required this.duration,
    required this.players,
    required this.hints,
    required this.questions,
    required this.intro,
    required this.area,
    required this.startCondition,
    required this.scheduledStart,
    required this.participantThreshold,
  });

  final String name;
  final String intro;
  final bool isPublic;
  final bool hints;
  final bool questions;
  final int duration;
  final int players;
  final SearchArea area;
  final StartCondition startCondition;
  final DateTime? scheduledStart;
  final int? participantThreshold;

  @override
  Widget build(BuildContext context) {
    final startLabel = startCondition == StartCondition.scheduled
        ? _formatScheduledStart(scheduledStart!)
        : 'Bij $participantThreshold deelnemers';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          name,
          style: Theme.of(context)
              .textTheme
              .headlineSmall
              ?.copyWith(fontWeight: FontWeight.w900),
        ),
        Text(isPublic ? 'Openbaar' : 'Privé'),
        const Divider(),
        _ReviewRow(label: 'Duur', value: '$duration minuten'),
        _ReviewRow(label: 'Deelnemers', value: 'maximaal $players'),
        _ReviewRow(label: 'Start', value: startLabel),
        _ReviewRow(
          label: 'Zoekgebied',
          value: '${area.country} • ${area.province} • ${area.city} • '
              '${area.neighbourhood}',
        ),
        _ReviewRow(
          label: 'Mechanieken',
          value: [if (hints) 'Hints', if (questions) 'Vragen'].join(' • '),
        ),
        const SizedBox(height: 10),
        const Card(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Text('V1 gebruikt uitsluitend punten.'),
          ),
        ),
        if (intro.isNotEmpty) ...[const SizedBox(height: 12), Text(intro)],
      ],
    );
  }
}

class _ReviewRow extends StatelessWidget {
  const _ReviewRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, constraints) {
          final valueText = Text(
            value,
            textAlign:
                constraints.maxWidth >= 520 ? TextAlign.end : TextAlign.start,
            softWrap: true,
            style: const TextStyle(fontWeight: FontWeight.w700),
          );
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 2),
                  child: Icon(Icons.check_circle_outline),
                ),
                const SizedBox(width: 12),
                if (constraints.maxWidth >= 520) ...[
                  Expanded(flex: 2, child: Text(label)),
                  const SizedBox(width: 16),
                  Expanded(flex: 3, child: valueText),
                ] else
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(label),
                        const SizedBox(height: 4),
                        valueText,
                      ],
                    ),
                  ),
              ],
            ),
          );
        },
      );
}

String _formatScheduledStart(DateTime value) {
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
  final minutes = value.minute.toString().padLeft(2, '0');
  return '${value.day} ${months[value.month - 1]} ${value.year} '
      'om ${value.hour}:$minutes';
}

String _selectionLabel(List<String> values) {
  if (values.isEmpty) return 'Alle';
  return values.join(', ');
}
