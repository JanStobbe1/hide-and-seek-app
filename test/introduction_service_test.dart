import 'package:flutter_test/flutter_test.dart';
import 'package:verstobbertje/services/introduction_service.dart';

void main() {
  const service = DemoIntroductionService();

  test(
    'generated introduction uses current settings instead of stale city',
    () {
      const request = IntroductionRequest(
        gameName: 'Grachtenjacht',
        city: 'Amsterdam',
        durationMinutes: 90,
        maxParticipants: 24,
        hintsEnabled: true,
        questionsEnabled: false,
        organizer: 'Jan',
        region: 'Noord-Holland, Amsterdam',
      );

      final text = service.generate(request, variant: 0);

      expect(text, contains('Amsterdam'));
      expect(text, isNot(contains('Almere')));
      expect(text, contains('Grachtenjacht'));
      expect(text, contains('90'));
      expect(text, contains('24'));
    },
  );

  test('successive variants produce different copy', () {
    const request = IntroductionRequest(
      gameName: 'Test123',
      city: 'Almere',
      durationMinutes: 120,
      maxParticipants: 30,
      hintsEnabled: true,
      questionsEnabled: true,
      organizer: 'Jan',
      region: 'Flevoland, Almere',
    );

    expect(
      service.generate(request, variant: 1),
      isNot(service.generate(request, variant: 2)),
    );
  });

  test('at least ten variants are distinct and contain current context', () {
    const request = IntroductionRequest(
      gameName: 'Bosjacht',
      city: 'Haarlem',
      durationMinutes: 60,
      maxParticipants: 20,
      hintsEnabled: true,
      questionsEnabled: true,
      organizer: 'Jan',
      region: 'Noord-Holland, Haarlem',
    );
    final variants = {for (var index = 0; index < 10; index++) service.generate(request, variant: index)};
    expect(variants, hasLength(10));
    expect(variants.every((text) => text.contains('Bosjacht') && (text.contains('Haarlem') || text.contains('Noord-Holland'))), isTrue);
  });
}
