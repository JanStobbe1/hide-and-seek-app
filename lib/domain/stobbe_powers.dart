enum GamePhase { preparation, active, finished }

enum StobbePowerKind {
  profilePoints,
  invisibilityPotion,
  stobbeArm,
  digitalDrone,
  timeJump,
  jammer,
  roleSwap,
}

class StobbePowerDefinition {
  const StobbePowerDefinition({
    required this.kind,
    required this.name,
    required this.maxUsesPerGame,
    required this.maxInventory,
    this.profilePoints = 0,
    this.duration,
    this.cooldown = Duration.zero,
  });

  final StobbePowerKind kind;
  final String name;
  final int maxUsesPerGame;
  final int maxInventory;
  final int profilePoints;
  final Duration? duration;
  final Duration cooldown;

  bool get isProfileReward => profilePoints > 0;
}

class StobbePowerSlot {
  const StobbePowerSlot({
    required this.definition,
    this.quantity = 1,
    this.uses = 0,
    this.cooldownUntil,
  });

  final StobbePowerDefinition definition;
  final int quantity;
  final int uses;
  final DateTime? cooldownUntil;

  Duration cooldownRemaining([DateTime? now]) {
    final until = cooldownUntil;
    if (until == null) return Duration.zero;
    final remaining = until.difference(now ?? DateTime.now());
    return remaining.isNegative ? Duration.zero : remaining;
  }

  bool canUse(GamePhase phase, [DateTime? now]) =>
      phase == GamePhase.active &&
      quantity > 0 &&
      uses < definition.maxUsesPerGame &&
      cooldownRemaining(now) == Duration.zero;

  StobbePowerSlot use(GamePhase phase, [DateTime? now]) {
    if (!canUse(phase, now)) return this;
    final current = now ?? DateTime.now();
    final cooldown = definition.cooldown;
    return StobbePowerSlot(
      definition: definition,
      quantity: quantity - 1,
      uses: uses + 1,
      cooldownUntil: cooldown == Duration.zero ? null : current.add(cooldown),
    );
  }
}

class GamePowerInventory {
  const GamePowerInventory({
    this.phase = GamePhase.preparation,
    this.slots = const [],
  });

  final GamePhase phase;
  final List<StobbePowerSlot> slots;

  GamePowerInventory startActivePhase() =>
      GamePowerInventory(phase: GamePhase.active, slots: slots);

  GamePowerInventory finishGame() =>
      const GamePowerInventory(phase: GamePhase.finished);

  GamePowerInventory add(StobbePowerDefinition power) {
    if (phase == GamePhase.finished || power.isProfileReward) return this;
    final index = slots.indexWhere(
      (slot) => slot.definition.kind == power.kind,
    );
    if (index < 0) {
      return GamePowerInventory(
        phase: phase,
        slots: [...slots, StobbePowerSlot(definition: power)],
      );
    }
    final current = slots[index];
    if (current.quantity >= power.maxInventory) return this;
    final updated = [...slots];
    updated[index] = StobbePowerSlot(
      definition: current.definition,
      quantity: current.quantity + 1,
      uses: current.uses,
      cooldownUntil: current.cooldownUntil,
    );
    return GamePowerInventory(phase: phase, slots: updated);
  }

  StobbePowerSlot? slotFor(StobbePowerKind kind) {
    for (final slot in slots) {
      if (slot.definition.kind == kind) return slot;
    }
    return null;
  }

  GamePowerInventory use(StobbePowerKind kind, [DateTime? now]) {
    final index = slots.indexWhere((slot) => slot.definition.kind == kind);
    if (index < 0 || !slots[index].canUse(phase, now)) return this;
    final updated = [...slots];
    updated[index] = slots[index].use(phase, now);
    return GamePowerInventory(phase: phase, slots: updated);
  }
}
