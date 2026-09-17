import 'package:flutter/material.dart';

import '../app_state.dart';
import '../config/app_theme.dart';
import '../domain/profile_models.dart';
import 'widgets.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({required this.state, super.key});

  final AppState state;

  @override
  Widget build(BuildContext context) => ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 38,
                child: Text(
                  state.profileAvatar,
                  style: const TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      state.displayName,
                      style: Theme.of(context)
                          .textTheme
                          .headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w900),
                    ),
                    const Text('38 jaar • Almere'),
                    const Chip(label: Text('Beginner')),
                    Wrap(
                      spacing: 8,
                      children: [
                        TextButton.icon(
                          onPressed: () => _editName(context),
                          icon: const Icon(Icons.edit),
                          label: const Text('Wijzig naam'),
                        ),
                        TextButton.icon(
                          onPressed: () => _choosePhoto(context),
                          icon: const Icon(Icons.add_a_photo_outlined),
                          label: const Text('Kies foto'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SectionTitle('Statistieken'),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Wrap(
                alignment: WrapAlignment.spaceAround,
                runSpacing: 16,
                children: [
                  _ProfileMetric('${state.gamesPlayed}', 'gespeeld'),
                  _ProfileMetric('${state.wins}', 'gewonnen'),
                  _ProfileMetric('${state.friends.length}', 'vrienden'),
                  _ProfileMetric('${state.points}', 'punten'),
                ],
              ),
            ),
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.people_outline),
            title: const Text('Vrienden'),
            subtitle: const Text('Bekijk spelstatistieken van je vrienden'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => FriendsScreen(friends: state.friends),
              ),
            ),
          ),
          const SectionTitle('Uiterlijk'),
          DropdownButtonFormField<ThemePreference>(
            initialValue: state.themePreference,
            decoration: const InputDecoration(
              labelText: 'Appkleur',
              prefixIcon: Icon(Icons.palette_outlined),
            ),
            items: ThemePreference.values
                .map(
                  (preference) => DropdownMenuItem(
                    value: preference,
                    child: Text(AppTheme.labelFor(preference)),
                  ),
                )
                .toList(),
            onChanged: (value) {
              if (value != null) state.setThemePreference(value);
            },
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<PlayerMarker>(
            initialValue: state.playerMarker,
            decoration: const InputDecoration(
              labelText: 'Mijn kaartmarker',
              prefixIcon: Icon(Icons.location_on_outlined),
            ),
            items: PlayerMarker.values
                .map(
                  (marker) => DropdownMenuItem(
                    value: marker,
                    child: Row(
                      children: [
                        Icon(markerIcon(marker)),
                        const SizedBox(width: 10),
                        Text(_markerLabel(marker)),
                      ],
                    ),
                  ),
                )
                .toList(),
            onChanged: (value) {
              if (value != null) state.setPlayerMarker(value);
            },
          ),
          const Padding(
            padding: EdgeInsets.only(top: 8),
            child: Text(
              'Kleur, foto en kaartmarker worden in deze prototypeversie '
              'alleen lokaal bewaard.',
              style: TextStyle(fontSize: 12),
            ),
          ),
          const SectionTitle('Demo financiën'),
          const Card(
            child: Column(
              children: [
                ListTile(
                  leading: Icon(Icons.account_balance_wallet_outlined),
                  title: Text('Mocksaldo'),
                  trailing: Text('€ 12,50'),
                ),
                ListTile(
                  leading: Icon(Icons.payments_outlined),
                  title: Text('Gesimuleerd uitgekeerd'),
                  trailing: Text('€ 0,00'),
                ),
                Padding(
                  padding: EdgeInsets.all(12),
                  child: Text(
                    'Alle bedragen zijn demonstratiedata. Er is geen echte '
                    'wallet en er wordt niets overgemaakt.',
                    style: TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
          const SectionTitle('Privacy & voorkeuren'),
          ...state.privacy.entries.map(
            (entry) => SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(entry.key),
              value: entry.value,
              onChanged: (value) => state.setPrivacy(entry.key, value),
            ),
          ),
          const SectionTitle('Demo beheren'),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
              minimumSize: const Size.fromHeight(52),
            ),
            onPressed: () => _confirmReset(context),
            icon: const Icon(Icons.restart_alt),
            label: const Text('Reset demo data'),
          ),
        ],
      );

  void _editName(BuildContext context) {
    final controller = TextEditingController(text: state.displayName);
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Weergavenaam wijzigen'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Weergavenaam'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Annuleren'),
          ),
          FilledButton(
            onPressed: () {
              state.setDisplayName(controller.text);
              Navigator.pop(dialogContext);
            },
            child: const Text('Opslaan'),
          ),
        ],
      ),
    ).whenComplete(controller.dispose);
  }

  void _choosePhoto(BuildContext context) {
    const choices = ['A', '🧭', '👻', '🐺'];
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Kies een profielfoto'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Demo: kies een lokale avatar. Bestandsupload en opslag volgen '
              'pas met een veilige backend.',
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              children: choices
                  .map(
                    (choice) => InkWell(
                      onTap: () {
                        state.setProfileAvatar(choice);
                        Navigator.pop(dialogContext);
                      },
                      borderRadius: BorderRadius.circular(30),
                      child: CircleAvatar(
                        radius: 26,
                        child: Text(
                          choice,
                          style: const TextStyle(fontSize: 22),
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmReset(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Demo data resetten?'),
        content: const Text(
          'Deelnames, voortgang en voorkeuren gaan terug naar de vaste beginstand.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Annuleren'),
          ),
          FilledButton(
            onPressed: () {
              state.reset();
              Navigator.pop(dialogContext);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Demo data is hersteld.')),
              );
            },
            child: const Text('Reset demo data'),
          ),
        ],
      ),
    );
  }
}

class FriendsScreen extends StatelessWidget {
  const FriendsScreen({required this.friends, super.key});

  final List<FriendProfile> friends;

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Vrienden')),
        body: ListView.separated(
          padding: const EdgeInsets.all(20),
          itemCount: friends.length,
          separatorBuilder: (_, _) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final friend = friends[index];
            return Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    CircleAvatar(child: Text(friend.name[0])),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            friend.name,
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                          Text(friend.city),
                          const SizedBox(height: 8),
                          Text(
                            '${friend.gamesPlayed} gespeeld • '
                            '${friend.gamesWon} gewonnen • '
                            '${friend.points} punten',
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      );
}

String _markerLabel(PlayerMarker marker) => switch (marker) {
  PlayerMarker.ghost => 'Spook',
  PlayerMarker.wolf => 'Wolf',
  PlayerMarker.police => 'Politie-embleem',
  PlayerMarker.explorer => 'Ontdekker',
};

class _ProfileMetric extends StatelessWidget {
  const _ProfileMetric(this.value, this.label);

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: 110,
        child: Column(
          children: [
            Text(
              value,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w900,
              ),
            ),
            Text(label),
          ],
        ),
      );
}
