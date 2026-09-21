class IntroductionRequest {
  const IntroductionRequest({
    required this.gameName,
    required this.city,
    required this.durationMinutes,
    required this.maxParticipants,
    required this.hintsEnabled,
    required this.questionsEnabled,
    required this.organizer,
    required this.region,
  });

  final String gameName;
  final String city;
  final int durationMinutes;
  final int maxParticipants;
  final bool hintsEnabled;
  final bool questionsEnabled;
  final String organizer;
  final String region;
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
    final context =
        '${request.gameName} in ${request.region}, georganiseerd door ${request.organizer}';
    final variants = [
      'Welkom bij ${request.gameName} van ${request.organizer}! Verken ${request.region} tijdens een '
          'spannend spel van ${request.durationMinutes} minuten met maximaal '
          '${request.maxParticipants} spelers. Verwacht $extras.',
      '${request.region} wordt het speelveld van ${request.gameName} van ${request.organizer}. Blijf uit '
          'zicht, speel slim en beleef ${request.durationMinutes} minuten '
          'avontuur met maximaal ${request.maxParticipants} deelnemers. '
          'Onderweg wachten $extras.',
      'Durf jij ${request.gameName} van ${request.organizer} in ${request.region} aan? Verzamel maximaal '
          '${request.maxParticipants} spelers voor ${request.durationMinutes} '
          'minuten zoeken en verstoppen, aangevuld met $extras.',
      '$context daagt je uit: verstop, zoek en scoor tijdens ${request.durationMinutes} minuten $extras.',
      'Vandaag verandert ${request.region} in het decor voor ${request.gameName}. ${request.organizer} ontvangt maximaal ${request.maxParticipants} spelers voor $extras.',
      'Maak je klaar voor ${request.gameName}: ${request.organizer} zet in ${request.region} een ronde vol $extras klaar.',
      'Wie blijft ongezien in ${request.region}? Bij ${request.gameName} van ${request.organizer} draait alles om bewegen en $extras.',
      '${request.organizer} nodigt je uit voor ${request.gameName} in ${request.region}: ${request.durationMinutes} minuten slim zoeken, verstoppen en $extras.',
      'De jacht begint in ${request.region}. Speel ${request.gameName} met maximaal ${request.maxParticipants} deelnemers en gebruik $extras verstandig.',
      'Ontdek ${request.region} op een nieuwe manier tijdens ${request.gameName}, een spel van ${request.organizer} met $extras.',
      '${request.gameName} staat klaar in ${request.region}. Houd ${request.durationMinutes} minuten stand en verras ${request.organizer} met jouw tactiek en $extras.',
    ];
    return variants[variant % variants.length];
  }
}

enum IntroductionOrigin { none, manual, generated }

class IntroductionDraft {
  const IntroductionDraft(
      {this.text = '',
      this.origin = IntroductionOrigin.none,
      this.sourceFingerprint});
  final String text;
  final IntroductionOrigin origin;
  final String? sourceFingerprint;

  IntroductionDraft invalidateFor(String newFingerprint) {
    if (origin == IntroductionOrigin.generated &&
        sourceFingerprint != newFingerprint) {
      return const IntroductionDraft();
    }
    return this;
  }
}
