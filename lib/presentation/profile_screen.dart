import 'package:flutter/material.dart';

import '../app_state.dart';
import '../config/app_theme.dart';
import '../config/app_config.dart';
import '../services/push_notifications.dart';
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
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            state.displayName,
                            key: const Key('profile-display-name'),
                            style: Theme.of(context)
                                .textTheme
                                .headlineSmall
                                ?.copyWith(fontWeight: FontWeight.w900),
                          ),
                        ),
                        IconButton(
                          key: const Key('profile-name-edit'),
                          tooltip: 'Naam wijzigen',
                          onPressed: () => _editName(context),
                          icon: const Icon(Icons.edit),
                        ),
                      ],
                    ),
                    if (state.profileAge.isNotEmpty ||
                        state.profileCity.isNotEmpty)
                      Text(_profileDetails(state)),
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
                  _ProfileMetric(_friendRank(state), 'Ranking bij vrienden'),
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
            selectedItemBuilder: (_) => PlayerMarker.values
                .map(
                  (marker) => Row(
                    children: [
                      Transform.scale(
                        key: ValueKey('compact-marker-${marker.name}'),
                        scale: .78,
                        child: PlayerMarkerBadge(marker: marker, size: 28),
                      ),
                      const SizedBox(width: 10),
                      Text(_markerLabel(marker)),
                    ],
                  ),
                )
                .toList(),
            items: PlayerMarker.values
                .map(
                  (marker) => DropdownMenuItem(
                    value: marker,
                    child: Row(
                      children: [
                        PlayerMarkerBadge(marker: marker, size: 28),
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
          const SectionTitle('Punten & ranking'),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.forest),
                  title: const Text('Mr. Stobbe zegt'),
                  subtitle: Text(
                    state.backendClient != null
                        ? 'Ik begin je teller op 1.000 punten. Je kunt ze nog niet uitgeven; de ranglijst wordt later gekoppeld.'
                        : 'Ik begin je teller op 1.000 punten. Ze tellen mee voor je ranking bij vrienden, maar uitgeven kan nog niet.',
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.stars),
                  title: const Text('Puntensaldo'),
                  trailing: Text('${state.points}'),
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
          const SectionTitle('Startmeldingen in de buurt'),
          _NearbyGamePushSettings(state: state),
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

String _profileDetails(AppState state) => [
      if (state.profileAge.isNotEmpty) '${state.profileAge} jaar',
      if (state.profileCity.isNotEmpty) state.profileCity,
    ].join(' • ');

String _friendRank(AppState state) {
  if (state.backendClient != null || state.friends.isEmpty) return '—';
  final playersAhead =
      state.friends.where((friend) => friend.points > state.points).length;
  return '#${playersAhead + 1}';
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


class _NearbyGamePushSettings extends StatefulWidget {
  const _NearbyGamePushSettings({required this.state});

  final AppState state;

  @override
  State<_NearbyGamePushSettings> createState() =>
      _NearbyGamePushSettingsState();
}

class _NearbyGamePushSettingsState extends State<_NearbyGamePushSettings> {
  bool _enabled = false;
  bool _loading = true;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final enabled = widget.state.backendAvailable &&
        await hasNearbyPushSubscription();
    if (mounted) setState(() {
      _enabled = enabled;
      _loading = false;
    });
  }

  Future<void> _toggle(bool enabled) async {
    final client = widget.state.backendClient;
    if (client == null || !widget.state.backendConnected) return;
    setState(() => _busy = true);
    try {
      if (enabled) {
        final subscription = await enableNearbyPush(AppConfig.vapidPublicKey);
        subscription['city'] = widget.state.profileCity;
        await client.registerPushSubscription(subscription);
      } else {
        final endpoint = await nearbyPushEndpoint();
        if (endpoint != null) await client.removePushSubscription(endpoint);
        await disableNearbyPush();
      }
      if (!mounted) return;
      setState(() => _enabled = enabled);
      _message(
        enabled
            ? 'Je ontvangt nu startmeldingen voor spellen binnen 25 km.'
            : 'Startmeldingen zijn uitgezet en je opgeslagen locatie is verwijderd.',
      );
    } catch (error) {
      if (!mounted) return;
      _message(_errorMessage(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _refreshLocation() async {
    final client = widget.state.backendClient;
    if (client == null || !widget.state.backendConnected) return;
    setState(() => _busy = true);
    try {
      final subscription = await refreshNearbyPushLocation();
      subscription['city'] = widget.state.profileCity;
      await client.registerPushSubscription(subscription);
      if (mounted) _message('Je locatie voor startmeldingen is bijgewerkt.');
    } catch (error) {
      if (mounted) _message(_errorMessage(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _message(String value) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(value)),
    );
  }

  String _errorMessage(Object error) {
    final value = error.toString();
    if (value.contains('notification_permission_denied')) {
      return 'Sta meldingen toe in de browserinstellingen om startmeldingen te gebruiken.';
    }
    if (value.contains('location_permission_required')) {
      return 'Sta locatie toe zodat we startgebieden binnen 25 km kunnen herkennen.';
    }
    if (value.contains('push_not_configured')) {
      return 'Pushmeldingen zijn nog niet volledig ingesteld. Probeer het later opnieuw.';
    }
    return 'Startmeldingen konden niet worden ingesteld. Controleer je internet- en browserinstellingen.';
  }

  @override
  Widget build(BuildContext context) {
    if (widget.state.demoMode) {
      return const Card(
        child: ListTile(
          leading: Icon(Icons.notifications_off_outlined),
          title: Text('Niet beschikbaar in de demo'),
          subtitle: Text(
            'Startmeldingen werken voor aangemelde spelers in de productieomgeving.',
          ),
        ),
      );
    }
    if (!widget.state.backendAvailable) {
      return const Card(
        child: ListTile(
          leading: Icon(Icons.notifications_outlined),
          title: Text('Meld je aan om meldingen in te stellen'),
        ),
      );
    }
    return Card(
      child: Column(
        children: [
          SwitchListTile(
            value: _enabled,
            onChanged: _loading || _busy ? null : _toggle,
            title: const Text('Spellen binnen 25 km'),
            subtitle: Text(
              _loading
                  ? 'Instellingen laden…'
                  : 'Ontvang een pushmelding zodra een spel in jouw omgeving start.',
            ),
            secondary: const Icon(Icons.notifications_active_outlined),
          ),
          if (_enabled)
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: _busy ? null : _refreshLocation,
                icon: const Icon(Icons.my_location),
                label: const Text('Locatie bijwerken'),
              ),
            ),
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Text(
              'Bij inschakelen vraagt je browser om meldings- en locatietoestemming. '
              'Je locatie wordt afgerond op circa 1 km nauwkeurig opgeslagen, '
              'alleen om startgebieden binnen 25 km te vinden. Uitschakelen '
              'verwijdert je pushregistratie en opgeslagen locatie.',
              style: TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}
