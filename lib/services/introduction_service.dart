class IntroductionRequest {
  const IntroductionRequest({
    required this.gameName,
    required this.city,
    required this.durationMinutes,
    required this.maxParticipants,
    required this.hintsEnabled,
    required this.questionsEnabled,
  });

  final String gameName;
  final String city;
  final int durationMinutes;
  final int maxParticipants;
  final bool hintsEnabled;
  final bool questionsEnabled;
}

/// Local deterministic copy generator used only in DEMO MODE.
///
/// A production implementation can replace this interface with a reviewed
/// server-side AI integration without changing the game-creation UI.
abstract interface class IntroductionService {
  String generate(IntroductionRequest request, {required int variant});
}

class DemoIntroductionService implements IntroductionService {
  const DemoIntroductionService();

  @override
  String generate(IntroductionRequest request, {required int variant}) {
    final mechanics = [
      if (request.hintsEnabled) 'slimme hints',
      if (request.questionsEnabled) 'uitdagende vragen',
    ];
    final extras =
        mechanics.isEmpty ? 'pure verstopactie' : mechanics.join(' en ');
    final variants = [
      'Welkom bij ${request.gameName}! Verken ${request.city} tijdens een '
          'spannend spel van ${request.durationMinutes} minuten met maximaal '
          '${request.maxParticipants} spelers. Verwacht $extras.',
      '${request.city} wordt het speelveld van ${request.gameName}. Blijf uit '
          'zicht, speel slim en beleef ${request.durationMinutes} minuten '
          'avontuur met maximaal ${request.maxParticipants} deelnemers. '
          'Onderweg wachten $extras.',
      'Durf jij ${request.gameName} in ${request.city} aan? Verzamel maximaal '
          '${request.maxParticipants} spelers voor ${request.durationMinutes} '
          'minuten zoeken en verstoppen, aangevuld met $extras.',
    ];
    return variants[variant % variants.length];
  }
}
