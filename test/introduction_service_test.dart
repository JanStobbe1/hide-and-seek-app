import 'package:flutter_test/flutter_test.dart';
import 'package:verstobbertje/services/introduction_service.dart';

void main() {
  const service = DemoIntroductionService();

  test('generated introduction uses current settings instead of stale city', () {
    const request = IntroductionRequest(
      gameName: 'Grachtenjacht',
      city: 'Amsterdam',
      durationMinutes: 90,
      maxParticipants: 24,
      hintsEnabled: true,
      questionsEnabled: false,
    );

    final text = service.generate(request, variant: 0);

    expect(text, contains('Amsterdam'));
    expect(text, isNot(contains('Almere')));
    expect(text, contains('Grachtenjacht'));
    expect(text, contains('90'));
    expect(text, contains('24'));
  });

  test('successive variants produce different copy', () {
    const request = IntroductionRequest(
      gameName: 'Test123',
      city: 'Almere',
      durationMinutes: 120,
      maxParticipants: 30,
      hintsEnabled: true,
      questionsEnabled: true,
    );

    expect(
      service.generate(request, variant: 1),
      isNot(service.generate(request, variant: 2)),
    );
  });
}
