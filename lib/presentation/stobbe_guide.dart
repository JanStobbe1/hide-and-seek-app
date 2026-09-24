import 'dart:async';

import 'package:flutter/material.dart';

class StobbeGuide extends StatelessWidget {
  const StobbeGuide({
    required this.explanation,
    super.key,
  });

  final String explanation;

  @override
  Widget build(BuildContext context) => Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Image.asset(
            'assets/images/stobbekarakter.png',
            height: 104,
            width: 104,
            fit: BoxFit.contain,
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: Theme.of(context).colorScheme.primary,
                      width: 1.5,
                    ),
                    boxShadow: const [
                      BoxShadow(
                        blurRadius: 8,
                        color: Color(0x18000000),
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                  child: TypewriterText(
                    explanation,
                    key: const Key('stobbe-guide-bubble'),
                  ),
                ),
                Positioned(
                  left: -7,
                  top: 42,
                  child: Transform.rotate(
                    angle: 0.785398,
                    child: Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        border: Border(
                          left: BorderSide(
                            color: Theme.of(context).colorScheme.primary,
                            width: 1.5,
                          ),
                          bottom: BorderSide(
                            color: Theme.of(context).colorScheme.primary,
                            width: 1.5,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      );
}

class TypewriterText extends StatefulWidget {
  const TypewriterText(
    this.text, {
    super.key,
    this.speed = const Duration(milliseconds: 24),
  });

  final String text;
  final Duration speed;

  @override
  State<TypewriterText> createState() => _TypewriterTextState();
}

class _TypewriterTextState extends State<TypewriterText> {
  Timer? timer;
  int visibleCharacters = 0;

  @override
  void initState() {
    super.initState();
    _start();
  }

  @override
  void didUpdateWidget(covariant TypewriterText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text) _start();
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  void _start() {
    timer?.cancel();
    visibleCharacters = 0;
    timer = Timer.periodic(widget.speed, (_) {
      if (!mounted) return;
      if (visibleCharacters >= widget.text.length) {
        timer?.cancel();
        return;
      }
      setState(() => visibleCharacters++);
    });
  }

  @override
  Widget build(BuildContext context) => Text(
        widget.text.substring(
          0,
          visibleCharacters.clamp(0, widget.text.length),
        ),
        style: const TextStyle(fontWeight: FontWeight.w600),
      );
}
