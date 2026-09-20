import 'package:flutter/material.dart';

import '../app_state.dart';
import '../domain/models.dart';
import '../domain/profile_validation.dart';
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
  MultiLocationSelection multiLocation = const MultiLocationSelection(
    countries: {'Nederland'},
    provinces: {'Flevoland'},
    cities: {'Almere'},
  );
  int introductionVariant = 0;
  final IntroductionDraft introductionDraft = IntroductionDraft();
  final ProfileNameValidator nameValidator = const ProfileNameValidator();

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
        country: multiLocation.countries.join(', '),
        province: multiLocation.provinces.isEmpty
            ? 'Alle'
            : multiLocation.provinces.join(', '),
        city: multiLocation.cities.isEmpty
            ? 'Alle'
            : multiLocation.cities.join(', '),
        neighbourhood: multiLocation.neighbourhoods.isEmpty
            ? 'Alle'
            : multiLocation.neighbourhoods.join(', '),
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

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Nieuw spel')),
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
                  content: _buildBasics(),
                ),
                Step(
                  title: const Text('Zoekgebied'),
                  isActive: step >= 1,
                  content: _buildSearchArea(),
                ),
                Step(
                  title: const Text('Start & introductie'),
                  isActive: step >= 2,
                  content: _buildStartAndIntroduction(),
                ),
                Step(
                  title: const Text('Controleren'),
                  isActive: step >= 3,
                  content: _Review(
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
                  ),
                ),
              ],
            ),
          ),
        ),
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
            onChanged: (_) => _sourcesChanged(),
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
            onChanged: (value) => setState(() {
              isPublic = value;
              if (isPublic) questions = false;
              _sourcesChanged();
            }),
          ),
          _SettingSlider(
            label: 'Duur',
            value: duration.toDouble(),
            min: 30,
            max: 360,
            divisions: 11,
            suffix: ' minuten',
            onChanged: (value) => setState(() {
              duration = value.round();
              _sourcesChanged();
            }),
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
              _sourcesChanged();
            }),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Hints kunnen worden gekocht'),
            value: hints,
            onChanged: (value) => setState(() {
              hints = value;
              _sourcesChanged();
            }),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Vragen kunnen worden beantwoord'),
            value: questions,
            subtitle: Text(
              isPublic
                  ? 'Persoonlijke vragen zijn alleen beschikbaar in privéspellen.'
                  : 'Vijf persoonlijke vragen per speler.',
            ),
            onChanged: isPublic
                ? null
                : (value) => setState(() {
                      questions = value;
                      _sourcesChanged();
                    }),
          ),
        ],
      );

  Widget _buildSearchArea() => Column(
        children: [
          _MultiLocationPicker(
            label: 'Land(en)',
            selected: multiLocation.countries,
            options: locations.countries,
            onToggle: (value) => setState(() {
              multiLocation = multiLocation.toggleCountry(value, locations);
              _sourcesChanged();
            }),
          ),
          _MultiLocationPicker(
            label: 'Provincie(s)',
            selected: multiLocation.provinces,
            options: {
              for (final country in multiLocation.countries)
                ...locations
                    .provincesFor(country)
                    .where((value) => value != 'Alle'),
            }.toList(),
            enabled: multiLocation.countries.isNotEmpty,
            onToggle: (value) => setState(() {
              multiLocation = multiLocation.toggleProvince(value, locations);
              _sourcesChanged();
            }),
          ),
          _MultiLocationPicker(
            label: 'Stad/steden',
            selected: multiLocation.cities,
            options: {
              for (final country in multiLocation.countries)
                for (final province in multiLocation.provinces)
                  if (locations.provincesFor(country).contains(province))
                    ...locations
                        .citiesFor(country, province)
                        .where((value) => value != 'Alle'),
            }.toList(),
            enabled: multiLocation.provinces.isNotEmpty,
            onToggle: (value) => setState(() {
              multiLocation = multiLocation.toggleCity(value, locations);
              _sourcesChanged();
            }),
          ),
          _MultiLocationPicker(
            label: 'Wijk(en)',
            selected: multiLocation.neighbourhoods,
            options: {
              for (final country in multiLocation.countries)
                for (final province in multiLocation.provinces)
                  for (final city in multiLocation.cities)
                    if (locations.containsCity(country, province, city))
                      ...locations
                          .neighbourhoodsFor(country, province, city)
                          .where((value) => value != 'Alle'),
            }.toList(),
            enabled: multiLocation.cities.isNotEmpty,
            onToggle: (value) => setState(() {
              multiLocation =
                  multiLocation.toggleNeighbourhood(value, locations);
              _sourcesChanged();
            }),
          ),
          _AreaField(label: 'Specifiek gebied', controller: specificArea),
          const SizedBox(height: 4),
          const MapPlaceholder(height: 190),
          const Padding(
            padding: EdgeInsets.all(8),
            child: Text(
              'Je kunt meerdere gebieden selecteren. Lagere keuzes worden '
              'automatisch opgeschoond wanneer een bovenliggend gebied wijzigt.',
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
              onChanged: introductionDraft.setManual,
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

  IntroductionRequest _introductionRequest() {
    String selectedCity = 'Nederland';
    if (multiLocation.countries.isNotEmpty) {
      selectedCity = multiLocation.countries.join(', ');
    }
    if (multiLocation.provinces.isNotEmpty) {
      selectedCity = multiLocation.provinces.join(', ');
    }
    if (multiLocation.cities.isNotEmpty) {
      selectedCity = multiLocation.cities.join(', ');
    }
    return IntroductionRequest(
      gameName: name.text.trim().isEmpty ? 'dit spel' : name.text.trim(),
      region: selectedCity,
      organizer: widget.state.displayName,
      durationMinutes: duration,
      maxParticipants: players,
      hintsEnabled: hints,
      questionsEnabled: questions,
    );
  }

  void _sourcesChanged() {
    final request = _introductionRequest();
    introductionDraft.sourcesChanged(request);
    if (introductionDraft.origin == IntroductionOrigin.empty &&
        intro.text.isNotEmpty) {
      intro.clear();
    }
  }

  void _generateIntroduction() {
    final request = _introductionRequest();
    final generated = introductionService.generate(
      request,
      variant: introductionVariant,
    );
    introductionDraft.setGenerated(generated, request);
    intro.text = generated;
    introductionVariant++;
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
    final validation = nameValidator.validate(name.text);
    if (!validation.valid) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(validation.message ?? 'Ongeldige spelnaam.')),
      );
      setState(() => step = 0);
      return;
    }
    final now = DateTime.now();
    widget.state.publish(
      Game(
        id: 'created-${now.millisecondsSinceEpoch}',
        name: name.text.trim().isEmpty ? 'Naamloos spel' : name.text.trim(),
        organizer: widget.state.displayName,
        description: intro.text.trim().isEmpty
            ? 'Een nieuw avontuur in ${selectedArea.city}.'
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
        rules: GameRules(
          hintsEnabled: hints,
          questionsEnabled: !isPublic && questions,
        ),
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

class _MultiLocationPicker extends StatefulWidget {
  const _MultiLocationPicker({
    required this.label,
    required this.selected,
    required this.options,
    required this.onToggle,
    this.enabled = true,
  });

  final String label;
  final Set<String> selected;
  final List<String> options;
  final ValueChanged<String> onToggle;
  final bool enabled;

  @override
  State<_MultiLocationPicker> createState() => _MultiLocationPickerState();
}

class _MultiLocationPickerState extends State<_MultiLocationPicker> {
  String query = '';

  @override
  Widget build(BuildContext context) {
    final filtered = filterLocationOptions(widget.options, query).toList();
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: widget.label,
          floatingLabelBehavior: FloatingLabelBehavior.always,
          enabled: widget.enabled,
        ),
        child: Column(
          children: [
            TextField(
              enabled: widget.enabled,
              onChanged: (value) => setState(() => query = value),
              decoration: const InputDecoration(
                hintText: 'Zoek binnen deze opties',
                prefixIcon: Icon(Icons.search),
                isDense: true,
              ),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  for (final option in filtered)
                    FilterChip(
                      label: Text(option),
                      selected: widget.selected.contains(option),
                      onSelected: widget.enabled
                          ? (_) => widget.onToggle(option)
                          : null,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
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

  String get startLabel => startCondition == StartCondition.scheduled
      ? _formatScheduledStart(scheduledStart!)
      : 'Bij $participantThreshold deelnemers';

  @override
  Widget build(BuildContext context) {
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
  Widget build(BuildContext context) => ListTile(
        contentPadding: EdgeInsets.zero,
        leading: const Icon(Icons.check_circle_outline),
        title: Text(label),
        trailing: SizedBox(
          width: 240,
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
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
