import 'package:flutter/material.dart';

import '../app_state.dart';
import '../config/app_config.dart';
import 'create_game_screen.dart';
import 'games_screens.dart';
import 'home_screen.dart';
import 'profile_screen.dart';
import 'widgets.dart';

class AppShell extends StatefulWidget {
  const AppShell({required this.state, super.key});
  final AppState state;
  @override State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int index = 0;
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.state,
    builder: (context, _) => LayoutBuilder(builder: (context, constraints) {
      final destinations = const [
        NavigationDestination(icon: Icon(Icons.explore_outlined), selectedIcon: Icon(Icons.explore), label: 'Home'),
        NavigationDestination(icon: Icon(Icons.sports_kabaddi_outlined), selectedIcon: Icon(Icons.sports_kabaddi), label: 'Mijn spellen'),
        NavigationDestination(icon: Icon(Icons.travel_explore), label: 'Ontdekken'),
        NavigationDestination(icon: Icon(Icons.emoji_events_outlined), label: 'Afgerond'),
        NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Profiel'),
      ];
      final pages = [
        HomeScreen(state: widget.state, onNavigate: (i) => setState(() => index = i), onCreate: _create),
        MyGamesScreen(state: widget.state),
        AvailableGamesScreen(state: widget.state),
        CompletedGamesScreen(state: widget.state),
        ProfileScreen(state: widget.state),
      ];
      final content = SafeArea(child: Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 980), child: pages[index])));
      if (constraints.maxWidth >= 800) {
        return Scaffold(body: Row(children: [NavigationRail(selectedIndex: index, onDestinationSelected: (i) => setState(() => index = i), labelType: NavigationRailLabelType.all, leading: const Padding(padding: EdgeInsets.symmetric(vertical: 18), child: Column(children: [CircleAvatar(child: Icon(Icons.location_searching)), SizedBox(height: 8), DemoBadge()])), destinations: destinations.map((d) => NavigationRailDestination(icon: d.icon, selectedIcon: d.selectedIcon, label: Text(d.label))).toList()), const VerticalDivider(width: 1), Expanded(child: content)]), floatingActionButton: index == 0 ? FloatingActionButton.extended(onPressed: _create, icon: const Icon(Icons.add), label: const Text('Nieuw spel')) : null);
      }
      return Scaffold(appBar: AppBar(title: const Text(AppConfig.appName, style: TextStyle(fontWeight: FontWeight.w900)), actions: const [Padding(padding: EdgeInsets.only(right: 12), child: Center(child: DemoBadge()))]), body: content, bottomNavigationBar: NavigationBar(selectedIndex: index, onDestinationSelected: (i) => setState(() => index = i), destinations: destinations), floatingActionButton: index == 0 ? FloatingActionButton(onPressed: _create, tooltip: 'Nieuw spel', child: const Icon(Icons.add)) : null);
    }),
  );

  void _create() => Navigator.of(context).push(MaterialPageRoute(builder: (_) => CreateGameScreen(state: widget.state)));
}
