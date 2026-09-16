import 'package:flutter/material.dart';

import '../app_state.dart';
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
              const CircleAvatar(
                radius: 38,
                child: Text(
                  'A',
                  style: TextStyle(fontSize: 30, fontWeight: FontWeight.w900),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Arie',
                      style: Theme.of(context)
                          .textTheme
                          .headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w900),
                    ),
                    const Text('38 jaar • Almere'),
                    const Chip(label: Text('Beginner')),
                  ],
                ),
              ),
            ],
          ),
          const SectionTitle('Statistieken'),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _ProfileMetric('${state.gamesPlayed}', 'gespeeld'),
                  _ProfileMetric('${state.wins}', 'gewonnen'),
                  const _ProfileMetric('3', 'vrienden'),
                ],
              ),
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

class _ProfileMetric extends StatelessWidget {
  const _ProfileMetric(this.value, this.label);

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) => Column(
        children: [
          Text(
            value,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
          ),
          Text(label),
        ],
      );
}
