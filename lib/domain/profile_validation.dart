class NameValidationResult {
  const NameValidationResult(this.valid, [this.message]);
  final bool valid;
  final String? message;
}

class ProfileNameValidator {
  const ProfileNameValidator();

  static const offensiveMessage =
      'deze naam is aanstootgevend kies een andere naam';

  // Compact V1 baseline. This deliberately is not intended to be a complete
  // profanity dictionary. Keep the list small and replace it later with
  // contextual/server-side moderation when the product needs it.
  //
  // Sources used as a starting point for the six supported languages:
  // LDNOOBW and comparable multilingual moderation lists. Terms are kept
  // locally so validation remains deterministic/offline in the V1 demo.
  static const _blocked = <String>{
    // Dutch
    'kanker', 'tering', 'tyfus', 'kut', 'lul', 'hoer', 'slet', 'klootzak',
    'eikel', 'mongool', 'debiel', 'idioot', 'sukkel', 'flikker', 'homo',
    'neger', 'nazi', 'fascist', 'racist', 'pedo',

    // English
    'fuck', 'fucker', 'fucking', 'shit', 'bitch', 'cunt', 'dick', 'cock',
    'asshole', 'bastard', 'slut', 'whore', 'retard', 'moron', 'idiot',
    'nigger', 'faggot', 'pedophile', 'motherfucker',

    // German
    'scheisse', 'scheiße', 'arschloch', 'wichser', 'fotze', 'hurensohn',
    'hure', 'schlampe', 'depp', 'vollidiot', 'missgeburt',
    'spast', 'schwuchtel', 'faschist', 'rassist', 'kanake',
    'drecksau', 'mistkerl',

    // French
    'putain', 'merde', 'connard', 'connasse', 'salope', 'pute', 'encule',
    'enculé', 'enculee', 'enculée', 'batard', 'bâtard', 'con', 
    'debile', 'débile', 'facho', 'raciste', 
    'pédophile',

    // Spanish
    'puta', 'puto', 'mierda', 'cabron', 'cabrón', 'gilipollas', 'pendejo',
    'pendeja', 'coño', 'joder', 'zorra', 'maricon', 'maricón', 'idiota',
    'imbecil', 'imbécil', 'racista', 'fascista', 'pedofilo',
    'pedófilo',

    // Arabic (Modern Standard + common colloquial insults)
    'كلب', 'كلبة', 'حمار', 'حمارة', 'غبي', 'غبية', 'احمق', 'أحمق', 'حقير',
    'حقيرة', 'قذر', 'قذرة', 'لعنة', 'ملعون', 'ملعونة', 'عاهرة', 'شرموط',
    'شرموطة', 'زب', 'كس',
  };

  NameValidationResult validate(String input) {
    final value = input.trim();
    if (value.isEmpty) {
      return const NameValidationResult(false, 'Vul een naam in.');
    }
    if (value.runes.length > 30) {
      return const NameValidationResult(false, 'Gebruik maximaal 30 tekens.');
    }
    if (!RegExp(r'[\p{L}]', unicode: true).hasMatch(value)) {
      return const NameValidationResult(false, 'Gebruik letters in je naam.');
    }
    if (value == value.toUpperCase() && value != value.toLowerCase()) {
      return const NameValidationResult(
        false,
        'Gebruik niet uitsluitend hoofdletters.',
      );
    }

    final normalized = value.toLowerCase();
    final tokens = normalized
        .split(RegExp(r'[^\p{L}]+', unicode: true))
        .where((token) => token.isNotEmpty);

    if (_blocked.contains(normalized) || tokens.any(_blocked.contains)) {
      return const NameValidationResult(false, offensiveMessage);
    }
    return const NameValidationResult(true);
  }
}

class ProfileVariantText {
  const ProfileVariantText(this.isIslamic);
  final bool isIslamic;
  String get greeting => isIslamic ? 'as-salāmu ʿalaykum' : 'Welkom';
  String get startGame => isIslamic ? 'bismillāh' : 'Start spel';
  String outcome(bool won) => isIslamic
      ? (won ? 'Allāhumma bārik' : 'alḥamdulillāh')
      : (won ? 'Gewonnen!' : 'Volgende keer beter');
}
