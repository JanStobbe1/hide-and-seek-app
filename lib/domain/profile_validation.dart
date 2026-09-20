class NameValidationResult {
  const NameValidationResult(this.valid, [this.message]);
  final bool valid;
  final String? message;
}

class ProfileNameValidator {
  const ProfileNameValidator();
  static const offensiveMessage =
      'Deze naam is aanstootgevend, kies een andere naam.';
  static const _blocked = {
    'kanker',
    'nazi',
    'puta',
    'putain',
    'scheisse',
    'fuck',
    'كلب',
  };
  NameValidationResult validate(String input) {
    final value = input.trim();
    if (value.isEmpty)
      return const NameValidationResult(false, 'Vul een naam in.');
    if (value.runes.length > 30)
      return const NameValidationResult(false, 'Gebruik maximaal 30 tekens.');
    if (!RegExp(r'[\p{L}]', unicode: true).hasMatch(value))
      return const NameValidationResult(false, 'Gebruik letters in je naam.');
    if (value == value.toUpperCase() && value != value.toLowerCase())
      return const NameValidationResult(
        false,
        'Gebruik niet uitsluitend hoofdletters.',
      );
    final normalized = value.toLowerCase();
    if (_blocked.any((word) => normalized.contains(word)))
      return const NameValidationResult(false, offensiveMessage);
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
