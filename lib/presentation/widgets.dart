import 'package:flutter/material.dart';

import '../config/app_config.dart';
import '../domain/profile_models.dart';

class SectionTitle extends StatelessWidget {
  const SectionTitle(this.title, {this.action, super.key});

  final String title;
  final Widget? action;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 24, bottom: 12),
        child: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.w800),
              ),
            ),
            if (action != null) action!,
          ],
        ),
      );
}

class StatPill extends StatelessWidget {
  const StatPill({
    required this.icon,
    required this.value,
    required this.label,
    super.key,
  });

  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) => Expanded(
        child: Semantics(
          label: '$label: $value',
          child: Container(
            padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
              color: const Color(0x1fffffff),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Icon(icon, color: Colors.white),
                const SizedBox(height: 6),
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                  ),
                ),
                Text(
                  label,
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
        ),
      );
}

class DemoBadge extends StatelessWidget {
  const DemoBadge({super.key});

  @override
  Widget build(BuildContext context) {
    if (!AppConfig.demoMode) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: const Color(0xffffe19a),
          borderRadius: BorderRadius.circular(99),
        ),
      child: const Text(
          'DEMO MODE',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w900,
            letterSpacing: .5,
          ),
        ),
    );
  }
}

class MapPlaceholder extends StatelessWidget {
  const MapPlaceholder({
    this.height = 220,
    this.playerMarker = PlayerMarker.ghost,
    super.key,
  });

  final double height;
  final PlayerMarker playerMarker;

  @override
  Widget build(BuildContext context) => Semantics(
        label: 'Gesimuleerde kaart van het zoekgebied',
        child: Container(
          height: height,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: const Color(0xffdce9d4),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xffb6ceb0)),
          ),
          child: Stack(
            children: [
              ...List.generate(
                6,
                (index) => Positioned(
                  left: index * 72.0 - 50,
                  top: index.isEven ? 20 : 105,
                  child: Transform.rotate(
                    angle: -.25,
                    child:
                        Container(width: 190, height: 3, color: Colors.white70),
                  ),
                ),
              ),
              Positioned.fill(child: CustomPaint(painter: _AreaPainter())),
              Positioned(
                left: 28,
                top: 24,
                child: _Marker(
                  icon: markerIcon(playerMarker),
                  color: Theme.of(context).colorScheme.primary,
                  label: 'Jij',
                ),
              ),
              const Positioned(
                right: 38,
                top: 65,
                child: _Marker(
                  icon: Icons.location_on,
                  color: Color(0xffef6c4d),
                  label: 'Speler',
                ),
              ),
              const Positioned(
                left: 125,
                bottom: 24,
                child: _Marker(
                  icon: Icons.visibility,
                  color: Color(0xffe5a62c),
                  label: 'Hint',
                ),
              ),
              const Positioned(
                left: 14,
                bottom: 12,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.all(Radius.circular(10)),
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(8),
                    child: Text(
                      'Mockkaart • geen GPS',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
}

IconData markerIcon(PlayerMarker marker) => switch (marker) {
      PlayerMarker.ghost => Icons.cruelty_free,
      PlayerMarker.wolf => Icons.pets,
      PlayerMarker.police => Icons.local_police,
      PlayerMarker.explorer => Icons.explore,
    };

class _Marker extends StatelessWidget {
  const _Marker({required this.icon, required this.color, required this.label});

  final IconData icon;
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) => Tooltip(
        message: label,
        child: Icon(icon, color: color, size: 40),
      );
}

class _AreaPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0x44315c46)
      ..style = PaintingStyle.fill;
    final path = Path()
      ..moveTo(size.width * .18, size.height * .25)
      ..lineTo(size.width * .75, size.height * .12)
      ..lineTo(size.width * .92, size.height * .72)
      ..lineTo(size.width * .3, size.height * .88)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class StobbeDetectiveButton extends StatelessWidget {
  const StobbeDetectiveButton({
    required this.pageTitle,
    required this.explanation,
    super.key,
  });

  final String pageTitle;
  final String explanation;

  @override
  Widget build(BuildContext context) => IconButton(
        tooltip: 'Vraag het de Stobbedetective',
        icon: const Icon(Icons.support_agent),
        onPressed: () => showDialog<void>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            contentPadding: const EdgeInsets.fromLTRB(24, 18, 24, 8),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset(
                    'assets/images/stobbekarakter.png',
                    height: 200,
                    fit: BoxFit.contain,
                  ),
                  Text(
                    pageTitle,
                    textAlign: TextAlign.center,
                    style: Theme.of(context)
                        .textTheme
                        .headlineSmall
                        ?.copyWith(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 8),
                  Text(explanation, textAlign: TextAlign.center),
                ],
              ),
            ),
            actions: [
              FilledButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Begrepen, detective!'),
              ),
            ],
          ),
        ),
      );
}
