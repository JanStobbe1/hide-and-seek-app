class ProfileNameValidation {
  static const offensiveMessage = 'Deze naam is aanstootgevend, kies een andere naam.';
  static const _blocked = <String>{
    'kanker', 'nazi', 'putain', 'puta', 'fuck', 'shit', 'scheisse', 'قحبة', 'كس'
  };

  static String? validate(String input) {
    final value = input.trim();
    if (value.isEmpty) return 'Vul een naam in.';
    if (value.runes.length > 30) return 'Gebruik maximaal 30 tekens.';
    if (!RegExp(r'[A-Za-zÀ-ÿ\u0600-\u06FF0-9]').hasMatch(value)) return 'Gebruik letters of cijfers.';
    final letters = value.replaceAll(RegExp(r'[^A-Za-zÀ-ÿ\u0600-\u06FF]'), '');
    if (letters.isNotEmpty && letters == letters.toUpperCase() && letters != letters.toLowerCase()) {
      return 'Gebruik niet uitsluitend hoofdletters.';
    }
    final normalized = value.toLowerCase();
    if (_blocked.any((word) => normalized.contains(word))) return offensiveMessage;
    return null;
  }
}
