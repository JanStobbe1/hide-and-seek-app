import 'package:flutter_test/flutter_test.dart';
import 'package:verstobbertje/domain/stobbe_powers.dart';

void main() {
  const drone = StobbePowerDefinition(
    kind: StobbePowerKind.digitalDrone,
    name: 'Digitale drone',
    maxUsesPerGame: 2,
    maxInventory: 2,
    duration: Duration(minutes: 2),
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

    var slot = inventory.slots.single.use(inventory.phase);
    slot = slot.use(inventory.phase);
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
