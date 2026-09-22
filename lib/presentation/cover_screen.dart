import 'package:flutter/material.dart';

import '../config/app_config.dart';

class CoverScreen extends StatefulWidget {
  const CoverScreen({required this.onEnter, super.key});

  final VoidCallback onEnter;

  @override
  State<CoverScreen> createState() => _CoverScreenState();
}

class _CoverScreenState extends State<CoverScreen>
    with TickerProviderStateMixin {
  late final AnimationController _welcomeController;
  late final AnimationController _idleController;

  @override
  void initState() {
    super.initState();
    _welcomeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    );
    _idleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3600),
    );
    _welcomeController.forward().whenComplete(() {
      if (mounted) {
        _idleController.repeat(reverse: true);
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    precacheImage(
      const AssetImage('assets/images/stobbekarakter_welkom.webp'),
      context,
    );
  }

  @override
  void dispose() {
    _welcomeController.dispose();
    _idleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              colors.primaryContainer,
              colors.surfaceContainerLowest,
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 620),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 28, 24, 32),
                child: Column(
                  children: [
                    Text(
                      AppConfig.appName,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.displaySmall?.copyWith(
                            color: colors.onPrimaryContainer,
                            fontWeight: FontWeight.w900,
                          ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Zoek. Verstop. Beweeg. Beleef.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: colors.onPrimaryContainer,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    Expanded(child: _buildAnimatedCharacter()),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: widget.onEnter,
                        icon: const Icon(Icons.auto_stories),
                        label: const Text('Aan de slag'),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Samen op avontuur in de echte wereld',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: colors.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedCharacter() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: AnimatedBuilder(
        animation: Listenable.merge([_welcomeController, _idleController]),
        builder: (context, child) {
          final reduceMotion = MediaQuery.disableAnimationsOf(context);
          final welcomeValue = reduceMotion ? 1.0 : _welcomeController.value;
          final entrance = Curves.easeOutBack.transform(
            (welcomeValue / 0.32).clamp(0.0, 1.0).toDouble(),
          );
          final greetingOpacity = reduceMotion
              ? 0.0
              : TweenSequence<double>([
                  TweenSequenceItem(
                    tween: ConstantTween(0.0),
                    weight: 30,
                  ),
                  TweenSequenceItem(
                    tween: Tween<double>(begin: 0, end: 1),
                    weight: 12,
                  ),
                  TweenSequenceItem(
                    tween: ConstantTween(1.0),
                    weight: 28,
                  ),
                  TweenSequenceItem(
                    tween: Tween<double>(begin: 1, end: 0),
                    weight: 12,
                  ),
                  TweenSequenceItem(
                    tween: ConstantTween(0.0),
                    weight: 18,
                  ),
                ]).transform(welcomeValue);
          final idleLift = reduceMotion ? 0.0 : _idleController.value * 3;
          final greetingTilt = greetingOpacity * -0.025;
          final isGreeting = greetingOpacity >= 0.5;

          return Transform.translate(
            offset: Offset(0, (1 - entrance) * 34 - idleLift),
            child: Transform.rotate(
              angle: greetingTilt,
              child: Transform.scale(
                scale: 0.9 + (0.1 * entrance),
                child: Opacity(
                  opacity: entrance.clamp(0.0, 1.0).toDouble(),
                  child: Image.asset(
                    isGreeting
                        ? 'assets/images/stobbekarakter_welkom.webp'
                        : 'assets/images/stobbekarakter.png',
                    key: ValueKey(
                      isGreeting
                          ? 'stobbekarakter-welkom'
                          : 'stobbekarakter-normaal',
                    ),
                    fit: BoxFit.contain,
                    semanticLabel: isGreeting
                        ? 'Stobbekarakter licht zijn hoed en knipoogt'
                        : 'Stobbekarakter met vergrootglas en speellijst',
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
