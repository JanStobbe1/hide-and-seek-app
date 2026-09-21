import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:verstobbertje/domain/friends.dart';
import 'package:verstobbertje/domain/game_lifecycle.dart';
import 'package:verstobbertje/domain/hints.dart';
import 'package:verstobbertje/domain/models.dart';
import 'package:verstobbertje/domain/private_questions.dart';
import 'package:verstobbertje/domain/profile_validation.dart';
import 'package:verstobbertje/domain/results.dart';
import 'package:verstobbertje/domain/scoring.dart';
import 'package:verstobbertje/domain/seeker_decay.dart';
import 'package:verstobbertje/domain/zone.dart';
import 'package:verstobbertje/services/introduction_service.dart';

void main() {
  group('lifecycle', () {
    final start = DateTime(2026);
    const life = GameLifecycle();
    test('join exact 5:00 but not 5:01', () {
      expect(
        life.canJoin(
          startedAt: start,
          now: start.add(const Duration(minutes: 5)),
        ),
        isTrue,
      );
      expect(
        life.canJoin(
          startedAt: start,
          now: start.add(const Duration(minutes: 5, seconds: 1)),
        ),
        isFalse,
      );
    });
    test('all three end conditions', () {
      for (final args in [
        (Duration.zero, 1, 1),
        (const Duration(minutes: 1), 0, 1),
        (const Duration(minutes: 1), 1, 0),
      ]) {
        expect(
          life.statusFor(
            remaining: args.$1,
            activeHiders: args.$2,
            activeSeekers: args.$3,
          ),
          GameStatus.completed,
        );
      }
    });
    test('result auto-opens once', () {
      final t = ResultPresentationTracker();
      expect(t.shouldAutoShow('g'), isTrue);
      expect(t.shouldAutoShow('g'), isFalse);
      expect(t.canOpenManually('g'), isTrue);
    });
  });
  group('decay', () {
    const d = SeekerDecay();
    const duration = Duration(minutes: 60);
    test('rates increase exactly 1.5 and reach zero', () {
      final rates = [
        for (var q = 0; q < 4; q++)
          d.ratePerMinute(startValue: 50, gameDuration: duration, quarter: q),
      ];
      expect(rates[0], closeTo(.4102564103, 1e-9));
      for (var q = 1; q < 4; q++) {
        expect(rates[q], closeTo(rates[q - 1] * 1.5, 1e-12));
      }
      expect(
        d.valueAt(startValue: 50, gameDuration: duration, elapsed: duration),
        closeTo(0, 1e-10),
      );
      expect(
        d.valueAt(
          startValue: 50,
          gameDuration: duration,
          elapsed: const Duration(hours: 2),
        ),
        0,
      );
    });
  });
  test('finding rewards each player once', () {
    final state = FindingState([
      const ScoringPlayer(id: 'a', role: PlayerRole.seeker, points: 0),
      const ScoringPlayer(id: 'b', role: PlayerRole.seeker, points: 0),
      const ScoringPlayer(id: 'c', role: PlayerRole.seeker, points: 0),
      const ScoringPlayer(id: 'h', role: PlayerRole.hider, points: 100),
      const ScoringPlayer(id: 's1', role: PlayerRole.hider, points: 5),
      const ScoringPlayer(id: 's2', role: PlayerRole.hider, points: 5),
    ]);
    const service = FindingService();
    expect(
      service.register(state: state, eventId: 'e', finderId: 'a', hiderId: 'h'),
      isTrue,
    );
    expect(
      [
        state.players['a']!.points,
        state.players['b']!.points,
        state.players['c']!.points,
      ],
      [80, 20, 20],
    );
    expect(
      [state.players['s1']!.points, state.players['s2']!.points],
      [15, 15],
    );
    expect(state.players['h']!.active, isFalse);
    expect(
      service.register(state: state, eventId: 'e', finderId: 'a', hiderId: 'h'),
      isFalse,
    );
  });
  group('hints', () {
    test('free, paid, cooldown and blocks are atomic', () {
      const service = HintService();
      final state = HintState(points: 20);
      final now = DateTime(2026);
      expect(
        service
            .use(state: state, now: now, quarter: 0, zoneLargeEnough: true)
            .started,
        isTrue,
      );
      expect(state.points, 20);
      expect(
        service
            .use(state: state, now: now, quarter: 0, zoneLargeEnough: true)
            .reason,
        HintBlockReason.cooldown,
      );
      expect(
        service
            .use(
              state: state,
              now: now.add(const Duration(minutes: 10)),
              quarter: 0,
              zoneLargeEnough: true,
            )
            .started,
        isTrue,
      );
      expect(state.points, 15);
      expect(state.purchasedHints, 1);
      expect(service.finalPoints(state), 14);
      expect(
        service
            .use(
              state: state,
              now: now.add(const Duration(minutes: 20)),
              quarter: 3,
              zoneLargeEnough: true,
            )
            .started,
        isFalse,
      );
      expect(state.points, 15);
    });
  });
  group('questions', () {
    const service = PrivateQuestionService();
    test('score table and own marker', () {
      expect(PrivateQuestionService.scores, [0, 10, 20, 40, 60, 100]);
      expect(
        service.visibility(
          privateGame: true,
          enabled: true,
          inRange: true,
          playerId: 'a',
          subjectId: 'a',
        ),
        QuestionMarkerStatus.own,
      );
      expect(
        service.visibility(
          privateGame: false,
          enabled: true,
          inRange: true,
          playerId: 'a',
          subjectId: 'b',
        ),
        QuestionMarkerStatus.unavailable,
      );
    });
    test('return within 5 seconds resumes; after 5 fails', () {
      final a = QuestionAttempt(playerId: 'a', subjectId: 'b');
      service.start(a);
      final now = DateTime(2026);
      service.updateRange(a, inRange: false, now: now);
      service.updateRange(
        a,
        inRange: true,
        now: now.add(const Duration(seconds: 5)),
      );
      expect(a.status, QuestionMarkerStatus.active);
      service.updateRange(
        a,
        inRange: false,
        now: now.add(const Duration(seconds: 6)),
      );
      service.updateRange(
        a,
        inRange: false,
        now: now.add(const Duration(seconds: 12)),
      );
      expect(a.status, QuestionMarkerStatus.failed);
    });
    test('perfect bonus once and only perfect', () {
      final b = PerfectQuestionBonus();
      expect(
        b.award(
          playerId: 'a',
          expectedSubjects: {'b', 'c'},
          results: {'b': 5, 'c': 5},
        ),
        500,
      );
      expect(
        b.award(
          playerId: 'a',
          expectedSubjects: {'b', 'c'},
          results: {'b': 5, 'c': 5},
        ),
        0,
      );
      expect(
        b.award(playerId: 'x', expectedSubjects: {'b'}, results: {'b': 4}),
        0,
      );
    });
  });
  group('zone and gps', () {
    const zones = ZoneService();
    test('area shrinks 5%, three times and stays contained', () {
      var z = const CircleZone(center: Point2(0, 0), radius: 100);
      for (var i = 0; i < 3; i++) {
        final next = zones.candidate(z, const Point2(0, 0));
        expect(next.area / z.area, closeTo(.95, 1e-12));
        expect(z.containsZone(next), isTrue);
        z = next;
      }
      expect(z.area / (math.pi * 10000), closeTo(math.pow(.95, 3), 1e-12));
      expect(
        () => zones.requireContained(
          const CircleZone(center: Point2(0, 0), radius: 100),
          const CircleZone(center: Point2(10, 0), radius: 100),
        ),
        throwsArgumentError,
      );
    });
    test('return min/max and false spike', () {
      const gps = ZoneGpsService();
      expect(
        gps.returnTime(
          distanceMeters: 1,
          metersPerSecond: 1,
          gameDuration: const Duration(minutes: 60),
        ),
        const Duration(minutes: 2),
      );
      expect(
        gps.returnTime(
          distanceMeters: 999999,
          metersPerSecond: 1,
          gameDuration: const Duration(minutes: 60),
        ),
        const Duration(minutes: 6),
      );
      final state = ZoneGpsState();
      final now = DateTime(2026);
      gps.record(
        state,
        inside: false,
        valid: true,
        now: now,
        allowance: const Duration(minutes: 2),
      );
      expect(state.confirmedOutside, isFalse);
      gps.record(
        state,
        inside: true,
        valid: true,
        now: now,
        allowance: const Duration(minutes: 2),
      );
      expect(state.countdownStartedAt, isNull);
    });
  });
  test('profile validation and privacy', () {
    const v = ProfileNameValidator();
    expect(v.validate(List.filled(31, 'a').join()).valid, isFalse);
    expect(v.validate('JAN').valid, isFalse);
    expect(v.validate('Jan123').valid, isTrue);
    expect(v.validate('fuck').message, ProfileNameValidator.offensiveMessage);
    expect(v.validate('Jan de fuck').valid, isFalse);
    expect(v.validate('Fuckerby').valid, isTrue);
    expect(v.validate('شرموطة').valid, isFalse);
    const privacy = PrivacyService();
    final publicPayload = privacy.payload(
      const ParticipantView(name: 'Jan', rank: '1', age: 30, photo: 'x'),
      friend: false,
      shareAge: true,
      sharePhoto: true,
    );
    expect(publicPayload.keys, unorderedEquals(['name', 'rank']));

    final friendPayload = privacy.payload(
      const ParticipantView(
        name: 'Jan',
        rank: '1',
        age: 30,
        photo: 'x',
        gamesWon: 4,
        gamesPlayed: 10,
        badges: ['Scherp oog'],
        streak: 3,
        upcomingGames: ['Zaterdagspel'],
        currentGame: 'Nu actief',
        points: 999,
        pointsToNextRank: 12,
      ),
      friend: true,
      shareAge: true,
      sharePhoto: true,
    );
    expect(
      friendPayload.keys,
      unorderedEquals([
        'name',
        'rank',
        'age',
        'photo',
        'gamesWon',
        'gamesPlayed',
        'badges',
        'streak',
        'upcomingGames',
      ]),
    );
    expect(friendPayload, isNot(contains('currentGame')));
    expect(friendPayload, isNot(contains('points')));
    expect(friendPayload, isNot(contains('pointsToNextRank')));
  });
  test('results and friends', () {
    const results = ResultService();
    expect(results.seekersWon(found: 5, total: 10), isTrue);
    expect(results.seekersWon(found: 4, total: 10), isFalse);
    final friends = FriendshipService();
    final now = DateTime(2026);
    expect(
      friends.choose(from: 'a', to: 'b', now: now),
      FriendDecision.pending,
    );
    expect(
      friends.choose(from: 'b', to: 'a', now: now),
      FriendDecision.friends,
    );
    final rejected = FriendRequest(sender: 'r', receiver: 's', createdAt: now);
    expect(friends.reject(rejected), FriendDecision.rejected);
    expect(friends.canWithdraw(rejected), isFalse);
    final blocked = FriendRequest(sender: 'm', receiver: 'n', createdAt: now);
    expect(friends.block(blocked), FriendDecision.blocked);
    final old = FriendRequest(sender: 'x', receiver: 'y', createdAt: now);
    expect(
      friends.accept(old, now.add(const Duration(days: 2, seconds: 1))),
      FriendDecision.expired,
    );
  });
  test('intro supports ten variants and invalidation', () {
    const service = DemoIntroductionService();
    const r = IntroductionRequest(
      gameName: 'X',
      region: 'Utrecht',
      organizer: 'Jan',
      durationMinutes: 60,
      maxParticipants: 10,
      hintsEnabled: true,
      questionsEnabled: false,
    );
    final variants = {
      for (var i = 0; i < 10; i++) service.generate(r, variant: i),
    };
    expect(variants.length, 10);
    expect(variants.first, contains('Jan'));
    final d = IntroductionDraft();
    d.setGenerated(variants.first, r);
    d.sourcesChanged(
      const IntroductionRequest(
        gameName: 'X',
        region: 'Haarlem',
        organizer: 'Jan',
        durationMinutes: 60,
        maxParticipants: 10,
        hintsEnabled: true,
        questionsEnabled: false,
      ),
    );
    expect(d.text, isEmpty);
    d.setManual('Eigen tekst');
    d.sourcesChanged(r);
    expect(d.text, 'Eigen tekst');
  });
}
