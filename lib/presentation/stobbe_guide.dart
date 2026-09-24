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
                  child: Text(
                    explanation,
                    key: const Key('stobbe-guide-bubble'),
                    style: const TextStyle(fontWeight: FontWeight.w600),
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
