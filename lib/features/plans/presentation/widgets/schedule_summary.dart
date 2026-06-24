import 'package:unchained/features/dashboard/domain/commitment.dart';
import 'package:unchained/l10n/app_localizations.dart';

/// Human-readable bullet lines describing a [CommitmentSchedule], shared by the
/// Monthly setup screen and the AI plan screen so both read the same way.
List<String> scheduleSummaryLines(AppLocalizations l, CommitmentSchedule s) {
  if (s.mode == CommitmentMode.forever) {
    return [l.commitment_forever_banner];
  }
  if (s.mode == CommitmentMode.none) return const [];
  return [
    l.schedule_summary_days(s.totalDays),
    s.hasBreaks
        ? l.schedule_summary_breaks(s.breakCount)
        : l.schedule_summary_no_breaks,
    s.repeats ? l.schedule_summary_constant : l.schedule_summary_once,
  ];
}
