import 'package:flutter/material.dart';

import '../app_state.dart';
import '../domain/models.dart';
import '../services/financial_service.dart';
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
  final country = TextEditingController(text: 'Nederland');
  final province = TextEditingController(text: 'Flevoland');
  final city = TextEditingController(text: 'Almere');
  final neighbourhood = TextEditingController(text: 'Alle');
  final specificArea = TextEditingController(text: 'Niet van toepassing');

  bool isPublic = true;
  bool hints = true;
  bool questions = true;
  double entry = 10;
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
    country.dispose();
    province.dispose();
    city.dispose();
    neighbourhood.dispose();
    specificArea.dispose();
    super.dispose();
  }

  SearchArea get selectedArea => SearchArea(
        country: country.text.trim(),
        province: province.text.trim(),
        city: city.text.trim(),
        neighbourhood: neighbourhood.text.trim(),
        specificArea: specificArea.text.trim(),
      );

  DateTime get selectedStart => DateTime(
        scheduledDate.year,
        scheduledDate.month,
        scheduledDate.day,
        scheduledTime.hour,
        scheduledTime.minute,
      );

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
              onStepCancel:
                  step == 0 ? null : () => setState(() => step--),
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
                    entry: entry,
                    players: players,
                    hints: hints,
                    questions: questions,
                    intro: intro.text,
                    area: selectedArea,
                    startCondition: condition,
                    scheduledStart: condition == StartCondition.scheduled
                        ? selectedStart
                        : null,
                    participantThreshold:
                        condition == StartCondition.participantCount
                            ? participantThreshold
                            : null,
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
            decoration: const InputDecoration(labelText: 'Naam van het spel'),
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
            onChanged: (value) => setState(() => duration = value.round()),
          ),
          _SettingSlider(
            label: 'Demo-inleg',
            value: entry,
            min: 0,
            max: 25,
            divisions: 25,
            suffix: ' euro',
            onChanged: (value) => setState(() => entry = value),
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
          _AreaField(label: 'Land(en)', controller: country),
          _AreaField(label: 'Provincie(s)', controller: province),
          _AreaField(label: 'Stad/steden', controller: city),
          _AreaField(label: 'Wijk(en)', controller: neighbourhood),
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

  Widget _buildStartAndIntroduction() => Column(
        children: [
          RadioListTile<StartCondition>(
            value: StartCondition.participantCount,
            groupValue: condition,
            onChanged: (value) => setState(() => condition = value!),
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
            groupValue: condition,
            onChanged: (value) => setState(() => condition = value!),
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
            maxLines: 5,
            decoration: const InputDecoration(
              labelText: 'Spelintroductie',
              hintText: 'Vertel spelers wat ze kunnen verwachten…',
            ),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: () => setState(() {
              intro.text = 'Durf jij je te verstoppen in Almere? Slimme '
                  'zoekers, verrassende hints en een spannend zoekgebied '
                  'wachten op je. Blijf uit zicht en speel voor de eer!';
            }),
            icon: const Icon(Icons.auto_awesome),
            label: const Text('Genereer introductie met AI'),
          ),
        ],
      );

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
        entryFee: entry,
        participants: 1,
        maxParticipants: players,
        distanceKm: 1.2,
        startCondition: condition,
        scheduledStart: condition == StartCondition.scheduled
            ? selectedStart
            : null,
        participantThreshold: condition == StartCondition.participantCount
            ? participantThreshold
            : null,
        isPublic: isPublic,
        rules: GameRules(
          hintsEnabled: hints,
          questionsEnabled: questions,
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

class _Review extends StatelessWidget {
  const _Review({
    required this.name,
    required this.isPublic,
    required this.duration,
    required this.entry,
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
  final double entry;
  final SearchArea area;
  final StartCondition startCondition;
  final DateTime? scheduledStart;
  final int? participantThreshold;

  @override
  Widget build(BuildContext context) {
    final money = const FinancialService().calculate(
      players: players,
      entryFee: entry,
    );
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
          value:
              '${area.country} • ${area.province} • ${area.city} • '
              '${area.neighbourhood}',
        ),
        _ReviewRow(
          label: 'Mechanieken',
          value: [if (hints) 'Hints', if (questions) 'Vragen'].join(' • '),
        ),
        const SizedBox(height: 10),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Gesimuleerde prijzenpot',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
                Text(
                  '$players × € ${entry.toStringAsFixed(2)} = '
                  '€ ${money.grossPool.toStringAsFixed(2)} bruto',
                ),
                Text(
                  'Voorbeeld platformkosten: '
                  '€ ${money.platformFee.toStringAsFixed(2)}',
                ),
                Text(
                  'Getoonde prijzenpot: '
                  '€ ${money.prizePool.toStringAsFixed(2)}',
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                const Text(
                  'Demo — geen echt geld',
                  style: TextStyle(fontSize: 12),
                ),
              ],
            ),
          ),
        ),
        if (intro.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(intro),
        ],
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
