class AppValidators {
  static final _gstin = RegExp(
    r'^[0-9]{2}[A-Z]{5}[0-9]{4}[A-Z]{1}[1-9A-Z]{1}Z[0-9A-Z]{1}$',
  );
  static final _email = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
  static final _phone = RegExp(r'^[6-9]\d{9}$');
  static final _phoneLoose = RegExp(r'^\+?[0-9]{10,13}$');

  static bool isGstin(String value) => _gstin.hasMatch(value.trim().toUpperCase());

  static bool isEmail(String value) => _email.hasMatch(value.trim());

  static bool isPhone(String value) {
    final digits = value.replaceAll(RegExp(r'[\s-]'), '');
    final normalized = digits.startsWith('+91')
        ? digits.substring(3)
        : digits.startsWith('91') && digits.length == 12
            ? digits.substring(2)
            : digits;
    return _phone.hasMatch(normalized) || _phoneLoose.hasMatch(digits);
  }

  static bool isWebsite(String value) {
    final uri = Uri.tryParse(value.trim().startsWith('http')
        ? value.trim()
        : 'https://${value.trim()}');
    return uri != null && uri.hasScheme && uri.host.contains('.');
  }

  static String? optionalGstin(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    if (!isGstin(value)) return 'invalid_gstin';
    return null;
  }

  static String? optionalEmail(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    if (!isEmail(value)) return 'invalid_email';
    return null;
  }

  static String? optionalPhone(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    if (!isPhone(value)) return 'invalid_phone';
    return null;
  }

  static String? optionalWebsite(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    if (!isWebsite(value)) return 'invalid_website';
    return null;
  }
}
