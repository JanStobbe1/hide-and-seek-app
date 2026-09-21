import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:verstobbertje/config/app_config.dart';
import 'package:verstobbertje/domain/game_lifecycle.dart';
import 'package:verstobbertje/domain/hints.dart';
import 'package:verstobbertje/domain/private_questions.dart';
import 'package:verstobbertje/domain/profile_validation.dart';
import 'package:verstobbertje/domain/scoring.dart';
import 'package:verstobbertje/domain/zones.dart';

void main() {
  test('CFG-04 question marker uses a twenty-meter radius', () {
    expect(AppConfig.questionRangeMeters, 20);
  });

  group('AC-005 scoring', () {
    test('80% finder, 20% per other seeker, +10 remaining hiders, idempotent',
        () {
      final players = <String, ParticipantScore>{
        'a': ParticipantScore(id: 'a', role: ScoreRole.seeker, value: 0),
        'b': ParticipantScore(id: 'b', role: ScoreRole.seeker, value: 0),
        'c': ParticipantScore(id: 'c', role: ScoreRole.seeker, value: 0),
        'h1': ParticipantScore(id: 'h1', role: ScoreRole.hider, value: 100),
        'h2': ParticipantScore(id: 'h2', role: ScoreRole.hider, value: 100),
        'h3': ParticipantScore(id: 'h3', role: ScoreRole.hider, value: 100),
      };
      final service = ScoringService();
      const event = FindEvent(id: 'find-1', finderId: 'a', hiderId: 'h1');
      final first = service.registerFind(event, players);
      expect(first.deltas, {'a': 80, 'b': 20, 'c': 20, 'h2': 10, 'h3': 10});
      expect(players['h1']!.active, isFalse);
      expect(service.registerFind(event, players).applied, isFalse);
      expect(players['a']!.value, 80);
    });
  });

  group('AC-PNT-DECAY', () {
    const total = Duration(minutes: 60);
    test('four quarter rates and exact zero at 60 minutes', () {
      final boundaries = [0, 15, 30, 45, 60]
          .map((minutes) => SeekerDecay.valueAt(
              startValue: 50,
              total: total,
              elapsed: Duration(minutes: minutes)))
          .toList();
      final losses = List.generate(
          4, (index) => boundaries[index] - boundaries[index + 1]);
      expect(losses[1] / losses[0], closeTo(1.5, 1e-9));
      expect(losses[2] / losses[1], closeTo(1.5, 1e-9));
      expect(losses[3] / losses[2], closeTo(1.5, 1e-9));
      expect(boundaries.last, 0);
      expect(
          SeekerDecay.valueAt(
              startValue: 50, total: total, elapsed: const Duration(hours: 2)),
          0);
    });
    test('rank steps add five points',
        () => expect(SeekerDecay.startValue(base: 50, rankSteps: 2), 60));
  });

  group('AC-008/009 private questions', () {
    test('own marker hidden and score table exact', () {
      expect(QuestionAttempt(playerId: 'a', subjectId: 'a').visible, isFalse);
      expect(List.generate(6, QuestionScoring.pointsFor),
          [0, 10, 20, 40, 60, 100]);
    });
    test('return at five seconds resumes; later failure is permanent', () {
      final start = DateTime(2026);
      final attempt = QuestionAttempt(playerId: 'a', subjectId: 'b');
      expect(
          attempt.start(
              isPrivateGame: true, questionsEnabled: true, inRange: true),
          isTrue);
      attempt.updateRange(inRange: false, now: start);
      attempt.updateRange(
          inRange: true, now: start.add(const Duration(seconds: 5)));
      expect(attempt.status, QuestionMarkerStatus.inProgress);
      attempt.updateRange(
          inRange: false, now: start.add(const Duration(seconds: 6)));
      attempt.updateRange(
          inRange: false, now: start.add(const Duration(seconds: 12)));
      expect(attempt.status, QuestionMarkerStatus.failed);
      expect(attempt.visible, isFalse);
    });
    test('perfect bonus is exactly once', () {
      final attempts = ['b', 'c'].map((subject) {
        final attempt = QuestionAttempt(playerId: 'a', subjectId: subject);
        attempt.start(
            isPrivateGame: true, questionsEnabled: true, inRange: true);
        attempt.complete(5);
        return attempt;
      }).toList();
      final bonus = PerfectQuestionBonus();
      expect(bonus.award('a', attempts, 2), 500);
      expect(bonus.award('a', attempts, 2), 0);
    });
  });

  group('AC-ZONE/GPS', () {
    test('CFG-18 find distance is one percent with a ten-meter floor', () {
      expect(ZoneRules.findDistance(100000), 1000);
      expect(ZoneRules.findDistance(50000), 500);
      expect(ZoneRules.findDistance(5000), 50);
      expect(ZoneRules.findDistance(1000), 10);
      expect(ZoneRules.findDistance(100), 10);
    });

    test('CFG-19 hints and questions stop at a 100-meter radius', () {
      expect(ZoneRules.allowsHintsAndQuestions(100.01), isTrue);
      expect(ZoneRules.allowsHintsAndQuestions(100), isFalse);
      expect(ZoneRules.allowsHintsAndQuestions(50), isFalse);
    });

    test('shrink reduces area by 5% and remains contained', () {
      const original = CircleZone(x: 0, y: 0, radius: 100);
      final next = ZoneRules.shrink(original, offsetX: 1, offsetY: 0);
      expect(next.area / original.area, closeTo(.95, 1e-9));
      expect(original.containsZone(next), isTrue);
      final thirdArea = original.area * math.pow(.95, 3);
      expect(thirdArea / original.area, closeTo(.857375, 1e-9));
    });
    test('invalid outside candidate is rejected', () {
      expect(
          () => ZoneRules.shrink(const CircleZone(x: 0, y: 0, radius: 100),
              offsetX: 20, offsetY: 0),
          throwsArgumentError);
    });
    test('return time respects min and max', () {
      expect(
          ZoneRules.returnTime(
              distanceMeters: 1,
              speedMetersPerSecond: 1,
              gameDuration: const Duration(hours: 1)),
          const Duration(minutes: 2));
      expect(
          ZoneRules.returnTime(
              distanceMeters: 100000,
              speedMetersPerSecond: 1,
              gameDuration: const Duration(hours: 1)),
          const Duration(minutes: 6));
    });
    test('one false GPS spike is ignored and return clears countdown', () {
      final tracker = OutsideZoneTracker();
      final now = DateTime(2026);
      expect(tracker.update(inside: false, reliable: true, now: now), isFalse);
      expect(tracker.update(inside: true, reliable: true, now: now), isFalse);
      tracker.update(inside: false, reliable: true, now: now);
      expect(tracker.update(inside: false, reliable: true, now: now), isTrue);
      expect(tracker.update(inside: true, reliable: true, now: now), isFalse);
    });
  });

  group('AC-001 lifecycle', () {
    test('join exact 5:00 succeeds and 5:01 fails', () {
      final start = DateTime(2026);
      final game =
          GameLifecycle(startsAt: start, duration: const Duration(hours: 1));
      expect(game.canJoin(start.add(const Duration(minutes: 5))), isTrue);
      expect(game.canJoin(start.add(const Duration(minutes: 5, seconds: 1))),
          isFalse);
    });
    test('all three end conditions are idempotent', () {
      final start = DateTime(2026);
      final game =
          GameLifecycle(startsAt: start, duration: const Duration(hours: 1));
      expect(game.finishIfNeeded(now: start, activeHiders: 0, activeSeekers: 1),
          isTrue);
      expect(game.finishIfNeeded(now: start, activeHiders: 0, activeSeekers: 1),
          isFalse);
      expect(game.takeAutomaticResultDisplay(), isTrue);
      expect(game.takeAutomaticResultDisplay(), isFalse);
    });
  });

  test('AC-013 profile name validation', () {
    expect(ProfileNameValidation.validate('Arie123'), isNull);
    expect(ProfileNameValidation.validate('ABCDEFGHIJKLMNOPQRSTUVWXYZABCDE'),
        isNotNull);
    expect(ProfileNameValidation.validate('ARIE'), isNotNull);
    expect(ProfileNameValidation.validate('fuck123'),
        ProfileNameValidation.offensiveMessage);
  });

  test('AC-007 hint costs are atomic and cooldown enforced', () {
    final now = DateTime(2026);
    final state = HintState(points: 10);
    const service = HintService();
    expect(
        service
            .use(state: state, now: now, quarter: 1, zoneAllowsHints: true)
            .cost,
        0);
    expect(
        service
            .use(state: state, now: now, quarter: 1, zoneAllowsHints: true)
            .allowed,
        isFalse);
    final later = now.add(const Duration(minutes: 10));
    expect(
        service
            .use(state: state, now: later, quarter: 1, zoneAllowsHints: true)
            .cost,
        5);
    expect(state.points, 5);
    expect(service.resultPenalty(state), 1);
  });
}
