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
    city: 'Almere',
    neighbourhood: 'Alle',
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
        city: location.city ?? 'Alle',
        neighbourhood: location.neighbourhood ?? 'Alle',
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
          _LocationAutocomplete(
            label: 'Stad/steden',
            value: location.city,
            options: location.country == null || location.province == null
                ? const []
                : locations.citiesFor(location.country!, location.province!),
            enabled: location.province != null && location.province != 'Alle',
            onSelected: (value) {
              _sourceChanged();
              setState(() => location = location.selectCity(value));
            },
          ),
          _LocationAutocomplete(
            label: 'Wijk(en)',
            value: location.neighbourhood,
            options: location.country == null ||
                    location.province == null ||
                    location.city == null
                ? const []
                : locations.neighbourhoodsFor(
                    location.country!,
                    location.province!,
                    location.city!,
                  ),
            enabled: location.city != null && location.city != 'Alle',
            onSelected: (value) {
              _sourceChanged();
              setState(() => location = location.selectNeighbourhood(value));
            },
          ),
          _AreaField(label: 'Specifiek gebied', controller: specificArea),
          const SizedBox(height: 4),
          const MapPlaceholder(height: 190),
          const Padding(
            padding: EdgeInsets.all(8),
            child: Text(
              'Mockselectie: meerdere gebieden kun je met komma’s invoeren. '
              'Later vervangbaar door een echte kaartservice.',
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
    final selectedCity =
        location.city ?? location.province ?? location.country ?? 'Nederland';
    final request = IntroductionRequest(
      gameName: name.text.trim().isEmpty ? 'dit spel' : name.text.trim(),
      city: selectedCity,
      durationMinutes: duration,
      maxParticipants: players,
      hintsEnabled: hints,
      questionsEnabled: questions,
      organizer: widget.state.displayName,
      region: '${selectedArea.country}, ${selectedArea.province}, ${selectedArea.city}',
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
