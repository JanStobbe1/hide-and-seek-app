import 'package:flutter_test/flutter_test.dart';
import 'package:verstobbertje/domain/stobbe_powers.dart';

void main() {
  const drone = StobbePowerDefinition(
    kind: StobbePowerKind.digitalDrone,
    name: 'Digitale drone',
    maxUsesPerGame: 2,
    maxInventory: 2,
    duration: Duration(minutes: 2),
    cooldown: Duration(seconds: 30),
  );
  const points = StobbePowerDefinition(
    kind: StobbePowerKind.profilePoints,
    name: 'Stobbekist',
    maxUsesPerGame: 1,
    maxInventory: 1,
    profilePoints: 200,
  );

  test('krachten zijn tijdens de voorbereidingsfase vergrendeld', () {
    final inventory = const GamePowerInventory().add(drone);
    expect(inventory.slots.single.canUse(inventory.phase), isFalse);
  });

  test('inzetlimiet en voorraad gelden binnen het actieve spel', () {
    var inventory = const GamePowerInventory()
        .add(drone)
        .add(drone)
        .add(drone)
        .startActivePhase();
    expect(inventory.slots.single.quantity, 2);

    final now = DateTime(2026, 9, 26, 8);
    var slot = inventory.slots.single.use(inventory.phase, now);
    slot = slot.use(
      inventory.phase,
      now.add(const Duration(seconds: 30)),
    );
    expect(slot.quantity, 0);
    expect(slot.uses, 2);
    expect(slot.canUse(inventory.phase), isFalse);
  });

  test('inzetten via de tas verlaagt de zichtbare voorraad direct', () {
    final inventory =
        const GamePowerInventory().add(drone).add(drone).startActivePhase();

    final afterUse = inventory.use(StobbePowerKind.digitalDrone);

    expect(afterUse.slotFor(StobbePowerKind.digitalDrone)!.quantity, 1);
    expect(afterUse.slotFor(StobbePowerKind.digitalDrone)!.uses, 1);
  });

  test('een gebruikte kracht toont de resterende cooldown', () {
    final now = DateTime(2026, 9, 26, 8);
    final inventory =
        const GamePowerInventory().add(drone).add(drone).startActivePhase();

    final afterUse = inventory.use(StobbePowerKind.digitalDrone, now);
    final slot = afterUse.slotFor(StobbePowerKind.digitalDrone)!;

    expect(slot.cooldownRemaining(now), const Duration(seconds: 30));
    expect(slot.canUse(GamePhase.active, now), isFalse);
    expect(
      slot.canUse(GamePhase.active, now.add(const Duration(seconds: 30))),
      isTrue,
    );
  });

  test('ongebruikte krachten vervallen na het spel', () {
    final inventory =
        const GamePowerInventory().add(drone).startActivePhase().finishGame();
    expect(inventory.phase, GamePhase.finished);
    expect(inventory.slots, isEmpty);
  });

  test('profielpunten komen niet in de tijdelijke Stobbetas', () {
    final inventory = const GamePowerInventory().add(points);
    expect(inventory.slots, isEmpty);
    expect(points.isProfileReward, isTrue);
  });
}
