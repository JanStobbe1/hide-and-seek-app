import 'package:flutter_test/flutter_test.dart';
import 'package:verstobbertje/app_state.dart';
import 'package:verstobbertje/domain/models.dart';
import 'package:verstobbertje/domain/private_questions.dart';

void main() {
  test('find action applies rewards and cannot process the same hider twice', () {
    final state = AppState();
    final before = state.playerValue(PlayerRole.seeker);

    expect(state.foundPlayer(), isTrue);
    expect(state.personallyFound, 3);
    expect(state.playerValue(PlayerRole.seeker), closeTo(before + 80, 1e-9));
    expect(state.demoScores['seeker-2']!.value, 20);
    expect(state.demoScores['hider-2']!.value, 110);
    expect(state.foundPlayer(), isFalse);
  });

  test('hint UI state follows free use, cooldown and paid use', () {
    final state = AppState();
    final now = DateTime(2026);

    expect(state.useHint(now).cost, 0);
    expect(state.useHint(now).allowed, isFalse);
    final paid = state.useHint(now.add(const Duration(minutes: 10)));
    expect(paid.allowed, isTrue);
    expect(paid.cost, 5);
    expect(state.hintState.points, 45);
  });

  test('question round awards score and one perfect bonus', () {
    final state = AppState();

    expect(state.startQuestionRound(), isTrue);
    expect(state.completeQuestionRound(5), 600);
    expect(state.questionAttempt.status, QuestionMarkerStatus.completed);
    expect(state.completeQuestionRound(5), 0);
  });

  test('GPS spike is ignored, confirmation alarms, return clears alarm', () {
    final state = AppState();
    final now = DateTime(2026);

    expect(
      state.registerZoneMeasurement(inside: false, timestamp: now),
      isFalse,
    );
    expect(
      state.registerZoneMeasurement(inside: true, timestamp: now),
      isFalse,
    );
    state.registerZoneMeasurement(inside: false, timestamp: now);
    expect(
      state.registerZoneMeasurement(inside: false, timestamp: now),
      isTrue,
    );
    expect(state.inActiveZone, isFalse);
    state.registerZoneMeasurement(inside: true, timestamp: now);
    expect(state.inActiveZone, isTrue);
    expect(state.zoneReturnDeadline, isNull);
  });
}
