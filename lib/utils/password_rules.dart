class PasswordRule {
  final String label;
  final bool Function(String password) test;

  const PasswordRule(this.label, this.test);
}

class PasswordRules {
  static const String specialCharacters = r'''^$*.[]{}()?"!@#%&/\,><':;|_~`''';

  static final List<PasswordRule> all = [
    PasswordRule('At least 8 characters', (p) => p.length >= 8),
    PasswordRule(
      'At least one uppercase letter (A–Z)',
      (p) => RegExp(r'[A-Z]').hasMatch(p),
    ),
    PasswordRule(
      'At least one lowercase letter (a–z)',
      (p) => RegExp(r'[a-z]').hasMatch(p),
    ),
    PasswordRule(
      'At least one number (0–9)',
      (p) => RegExp(r'[0-9]').hasMatch(p),
    ),
    PasswordRule(
      'At least one special character: ${specialCharacters.split('').join(' ')}',
      (p) => p.split('').any(specialCharacters.contains),
    ),
  ];

  static List<String> missing(String password) {
    return all
        .where((rule) => !rule.test(password))
        .map((rule) => rule.label)
        .toList();
  }

  static int metCount(String password) {
    return all.where((rule) => rule.test(password)).length;
  }

  static bool isValid(String password) => missing(password).isEmpty;
}
