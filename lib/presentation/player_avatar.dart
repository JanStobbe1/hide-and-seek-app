import 'package:flutter/material.dart';

const playerAvatarIds = <String>[
  'avatar-1',
  'avatar-2',
  'avatar-3',
  'avatar-4',
  'avatar-5',
  'avatar-6',
  'avatar-7',
  'avatar-8',
  'avatar-9',
  'avatar-10',
  'avatar-11',
  'avatar-12',
];

String playerAvatarAsset(String id) {
  final index = playerAvatarIds.indexOf(id);
  final safeIndex = index < 0 ? 0 : index;
  return 'assets/images/players/${playerAvatarIds[safeIndex]}.png';
}

class PlayerAvatar extends StatelessWidget {
  const PlayerAvatar({
    required this.avatarId,
    this.radius = 28,
    this.borderColor,
    super.key,
  });

  final String avatarId;
  final double radius;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) => Container(
        width: radius * 2,
        height: radius * 2,
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: borderColor ?? Theme.of(context).colorScheme.primary,
          boxShadow: const [
            BoxShadow(
              color: Color(0x33000000),
              blurRadius: 5,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: ClipOval(
          child: Image.asset(
            playerAvatarAsset(avatarId),
            fit: BoxFit.cover,
          ),
        ),
      );
}
