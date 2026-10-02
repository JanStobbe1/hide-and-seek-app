import 'package:flutter/material.dart';

import '../app_state.dart';
import '../config/app_theme.dart';
import '../domain/profile_models.dart';
import 'avatar_picker.dart';
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
              TappablePlayerAvatar(
                key: const Key('profile-avatar'),
                state: state,
                radius: 38,
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
          const SectionTitle('Punten'),
          const Card(
            child: Column(
              children: [
                ListTile(
                  leading: Icon(Icons.stars),
                  title: Text('Puntensaldo'),
                  trailing: Text('840'),
                ),
                ListTile(
                  leading: Icon(Icons.info_outline),
                  title: Text('Spelvaluta'),
                  trailing: Text('Alleen punten'),
                ),
                Padding(
                  padding: EdgeInsets.all(12),
                  child: Text(
                    'Je profielgegevens en voorkeuren.',
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
          const SectionTitle('Privacy & account'),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
              minimumSize: const Size.fromHeight(52),
            ),
            onPressed: state.backendConnected
                ? () => _confirmDeleteAccount(context)
                : null,
            icon: const Icon(Icons.delete_forever_outlined),
            label: const Text('Verwijder account'),
          ),
          const SizedBox(height: 8),
          const Text(
            'Je account en bijbehorende gegevens worden definitief verwijderd.',
            style: TextStyle(fontSize: 12),
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
              final error = state.setDisplayName(controller.text);
              if (error == null) {
                Navigator.pop(dialogContext);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(error)),
                );
              }
            },
            child: const Text('Opslaan'),
          ),
        ],
      ),
    ).whenComplete(controller.dispose);
  }

  void _confirmDeleteAccount(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Account verwijderen?'),
        content: const Text(
          'Je account en de bijbehorende gegevens worden definitief verwijderd. '
          'Dit kan niet ongedaan worden gemaakt.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Annuleren'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              final deleted = await state.deleteAccount();
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    deleted
                        ? 'Je account is verwijderd.'
                        : 'Het account kon niet worden verwijderd.',
                  ),
                ),
              );
            },
            child: const Text('Definitief verwijderen'),
          ),
        ],
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
        appBar: AppBar(
          title: const Text('Vrienden'),
          actions: const [
            StobbeDetectiveButton(
              pageTitle: 'Vrienden',
              explanation:
                  'Bekijk hier je vrienden en hun spelstatistieken. Zo zie je '
                  'met wie je vaker op avontuur kunt gaan.',
            ),
          ],
        ),
        body: ListView.separated(
          padding: const EdgeInsets.all(20),
          itemCount: friends.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
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
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
            ),
            Text(label),
          ],
        ),
      );
}
