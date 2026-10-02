import 'package:flutter/material.dart';

import '../app_state.dart';
import 'player_avatar.dart';

Future<void> showAvatarPicker(BuildContext context, AppState state) {
  return showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Kies een profielfoto'),
      content: SizedBox(
        width: 420,
        child: GridView.builder(
          shrinkWrap: true,
          itemCount: playerAvatarIds.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
          ),
          itemBuilder: (_, index) {
            final avatarId = playerAvatarIds[index];
            final selected = avatarId == state.profileAvatar;
            return Semantics(
              button: true,
              selected: selected,
              label: 'Profielfoto ${index + 1}',
              child: InkWell(
                onTap: () {
                  state.setProfileAvatar(avatarId);
                  Navigator.pop(dialogContext);
                },
                borderRadius: BorderRadius.circular(40),
                child: PlayerAvatar(
                  avatarId: avatarId,
                  radius: 34,
                  borderColor:
                      selected ? Theme.of(context).colorScheme.secondary : null,
                ),
              ),
            );
          },
        ),
      ),
    ),
  );
}

class TappablePlayerAvatar extends StatelessWidget {
  const TappablePlayerAvatar({
    required this.state,
    this.radius = 38,
    super.key,
  });

  final AppState state;
  final double radius;

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        label: 'Profielfoto wijzigen',
        child: InkWell(
          key: key,
          onTap: () => showAvatarPicker(context, state),
          customBorder: const CircleBorder(),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              PlayerAvatar(avatarId: state.profileAvatar, radius: radius),
              Positioned(
                right: -2,
                bottom: -2,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Theme.of(context).colorScheme.surface,
                      width: 2,
                    ),
                  ),
                  child: const Padding(
                    padding: EdgeInsets.all(5),
                    child: Icon(Icons.edit, size: 14),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
}
