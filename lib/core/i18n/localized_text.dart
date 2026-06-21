import 'package:unchained/l10n/app_localizations.dart';

extension AppLocalizationsByKey on AppLocalizations {
  String byKey(String key) {
    final getter = _byKey[key];
    if (getter == null) {
      throw ArgumentError('Unknown localization key: $key');
    }
    return getter(this);
  }
}

final Map<String, String Function(AppLocalizations)> _byKey = {
  'onboarding_q1_text': (l) => l.onboarding_q1_text,
  'onboarding_q1_a1': (l) => l.onboarding_q1_a1,
  'onboarding_q1_a2': (l) => l.onboarding_q1_a2,
  'onboarding_q1_a3': (l) => l.onboarding_q1_a3,
  'onboarding_q1_a4': (l) => l.onboarding_q1_a4,
  'onboarding_q2_text': (l) => l.onboarding_q2_text,
  'onboarding_q2_a1': (l) => l.onboarding_q2_a1,
  'onboarding_q2_a2': (l) => l.onboarding_q2_a2,
  'onboarding_q2_a3': (l) => l.onboarding_q2_a3,
  'onboarding_q2_a4': (l) => l.onboarding_q2_a4,
  'onboarding_q3_text': (l) => l.onboarding_q3_text,
  'onboarding_q3_a1': (l) => l.onboarding_q3_a1,
  'onboarding_q3_a2': (l) => l.onboarding_q3_a2,
  'onboarding_q3_a3': (l) => l.onboarding_q3_a3,
  'onboarding_q3_a4': (l) => l.onboarding_q3_a4,
  'onboarding_q4_text': (l) => l.onboarding_q4_text,
  'onboarding_q4_a1': (l) => l.onboarding_q4_a1,
  'onboarding_q4_a2': (l) => l.onboarding_q4_a2,
  'onboarding_q4_a3': (l) => l.onboarding_q4_a3,
  'onboarding_q4_a4': (l) => l.onboarding_q4_a4,
  'onboarding_q5_text': (l) => l.onboarding_q5_text,
  'onboarding_q5_a1': (l) => l.onboarding_q5_a1,
  'onboarding_q5_a2': (l) => l.onboarding_q5_a2,
  'onboarding_q5_a3': (l) => l.onboarding_q5_a3,
  'onboarding_q5_a4': (l) => l.onboarding_q5_a4,
  'onboarding_q6_text': (l) => l.onboarding_q6_text,
  'onboarding_q6_a1': (l) => l.onboarding_q6_a1,
  'onboarding_q6_a2': (l) => l.onboarding_q6_a2,
  'onboarding_q6_a3': (l) => l.onboarding_q6_a3,
  'onboarding_q6_a4': (l) => l.onboarding_q6_a4,
  'onboarding_q7_text': (l) => l.onboarding_q7_text,
  'onboarding_q7_a1': (l) => l.onboarding_q7_a1,
  'onboarding_q7_a2': (l) => l.onboarding_q7_a2,
  'onboarding_q7_a3': (l) => l.onboarding_q7_a3,
  'onboarding_q7_a4': (l) => l.onboarding_q7_a4,
  'onboarding_q7_a5': (l) => l.onboarding_q7_a5,
  'onboarding_q8_text': (l) => l.onboarding_q8_text,
  'onboarding_q8_a1': (l) => l.onboarding_q8_a1,
  'onboarding_q8_a2': (l) => l.onboarding_q8_a2,
  'onboarding_q8_a3': (l) => l.onboarding_q8_a3,
  'onboarding_q8_a4': (l) => l.onboarding_q8_a4,
};
