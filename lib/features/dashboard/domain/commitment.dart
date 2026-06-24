import 'package:flutter/foundation.dart';

/// Which kind of commitment lock the active plan imposes.
///
/// The plan the user picks decides this:
///  - [forever]  — Forever plan: protection is locked ON permanently. No break,
///                 never ends.
///  - [fixed]    — Monthly / AI plan: a single span of [CommitmentSchedule.totalDays]
///                 days with [CommitmentSchedule.breakCount] short breaks spaced
///                 evenly inside. When the span ends, the commitment clears
///                 (protection stays on but becomes freely toggleable again).
///  - [cycle]    — Monthly "Constant" / AI repeating: same as [fixed] but it
///                 restarts forever when the span ends — a never-ending cycle.
///  - [none]     — Free trial / nothing picked: no lock, protection toggles freely.
enum CommitmentMode { none, forever, fixed, cycle }

CommitmentMode commitmentModeFromString(String? s) => switch (s) {
      'forever' => CommitmentMode.forever,
      'fixed' => CommitmentMode.fixed,
      'cycle' => CommitmentMode.cycle,
      _ => CommitmentMode.none,
    };

/// The DB string for a mode. [CommitmentMode.none] is stored as `null`.
String? commitmentModeToString(CommitmentMode m) => switch (m) {
      CommitmentMode.forever => 'forever',
      CommitmentMode.fixed => 'fixed',
      CommitmentMode.cycle => 'cycle',
      CommitmentMode.none => null,
    };

/// The commitment template a plan stores at activation. It describes the lock
/// shape but does not by itself start a lock — the run begins (an anchor date
/// is recorded) only when the user first turns protection on.
@immutable
class CommitmentSchedule {
  const CommitmentSchedule({
    required this.mode,
    this.totalDays = 0,
    this.breakCount = 0,
  });

  final CommitmentMode mode;

  /// Total locked days across the whole span (ignored for [CommitmentMode.forever]).
  final int totalDays;

  /// How many short breaks are spaced evenly inside the span (0 = none).
  final int breakCount;

  bool get isNone => mode == CommitmentMode.none;
  bool get isForever => mode == CommitmentMode.forever;
  bool get repeats => mode == CommitmentMode.cycle;
  bool get hasBreaks => breakCount > 0;

  static const CommitmentSchedule none =
      CommitmentSchedule(mode: CommitmentMode.none);

  /// The fixed Forever-plan template.
  static const CommitmentSchedule forever =
      CommitmentSchedule(mode: CommitmentMode.forever);
}

/// Where the user currently sits in the commitment.
enum CommitmentPhase {
  /// No commitment running — protection toggles freely.
  none,

  /// Inside a lock window — protection cannot be turned off.
  locked,

  /// A short release window between locks — protection may be turned off.
  breakOpen,

  /// A [CommitmentMode.fixed] span has fully elapsed. The caller should clear
  /// the commitment (protection stays on but becomes freely toggleable).
  completed,
}

/// The live, derived state of the commitment, recomputed every second.
@immutable
class CommitmentStatus {
  const CommitmentStatus({
    required this.phase,
    this.mode = CommitmentMode.none,
    this.lockUntil,
    this.breakUntil,
    this.daysLeft = 0,
    this.minutesLeft = 0,
    this.isPermanent = false,
  });

  /// TEMPORARY TEST MODE — set back to false before committing.
  /// When true, "days" are interpreted as minutes so a full
  /// lock → break → re-lock span can be watched in a couple of minutes.
  static const bool testMode = false;

  /// The short release window between locks.
  static const Duration breakDuration =
      testMode ? Duration(minutes: 1) : Duration(minutes: 30);

  final CommitmentPhase phase;
  final CommitmentMode mode;

  /// When the whole protection span ends (for display of "locked until").
  /// Null for [CommitmentMode.forever] and when not locked.
  final DateTime? lockUntil;

  /// When the current break expires (start of the next lock). Null unless on a break.
  final DateTime? breakUntil;

  /// Whole days left until the span ends (ceil), for display.
  final int daysLeft;

  /// Whole minutes left in the current break (ceil), for display.
  final int minutesLeft;

  /// True for the Forever plan — locked with no end.
  final bool isPermanent;

  bool get isActive =>
      phase == CommitmentPhase.locked || phase == CommitmentPhase.breakOpen;
  bool get isLocked => phase == CommitmentPhase.locked;
  bool get isBreak => phase == CommitmentPhase.breakOpen;
  bool get isCompleted => phase == CommitmentPhase.completed;

  static const CommitmentStatus none_ =
      CommitmentStatus(phase: CommitmentPhase.none);
}

/// Length of a single lock segment: the total locked time split evenly across
/// the [breakCount] + 1 segments. In [CommitmentStatus.testMode], "days" are
/// treated as minutes.
Duration _segmentLength(int totalDays, int breakCount) {
  final totalMinutes =
      CommitmentStatus.testMode ? totalDays : totalDays * 24 * 60;
  final segments = breakCount + 1;
  return Duration(minutes: (totalMinutes / segments).round());
}

/// The whole span = (breakCount+1) lock segments + breakCount breaks between them.
Duration _spanLength(Duration segLen, int breakCount) =>
    segLen * (breakCount + 1) + CommitmentStatus.breakDuration * breakCount;

/// Derives the current [CommitmentStatus] from the stored schedule + the run
/// anchor [startedAt] (null = template stored but the user hasn't started yet).
///
/// For [CommitmentMode.cycle], call [advanceCycle] first and persist its result
/// so a lapsed span has already been rolled forward into a fresh cycle.
CommitmentStatus computeStatus(
  CommitmentMode mode,
  int totalDays,
  int breakCount,
  DateTime? startedAt,
  DateTime now,
) {
  if (mode == CommitmentMode.none || startedAt == null) {
    return CommitmentStatus.none_;
  }
  if (mode == CommitmentMode.forever) {
    return const CommitmentStatus(
      phase: CommitmentPhase.locked,
      mode: CommitmentMode.forever,
      isPermanent: true,
    );
  }

  // fixed or cycle
  final segLen = _segmentLength(totalDays, breakCount);
  final brk = CommitmentStatus.breakDuration;
  final spanEnd = startedAt.add(_spanLength(segLen, breakCount));

  if (!now.isBefore(spanEnd)) {
    // Span elapsed. A cycle should have been advanced already; treat as done.
    return CommitmentStatus(phase: CommitmentPhase.completed, mode: mode);
  }

  var cursor = startedAt;
  for (var i = 0; i <= breakCount; i++) {
    final lockEnd = cursor.add(segLen);
    if (now.isBefore(lockEnd)) {
      // Breaks add a little wall-clock time on top of the locked days; cap the
      // displayed days-left at the days the user actually chose so a 30-day
      // plan never reads as "31 days".
      final days = _ceilDays(spanEnd.difference(now));
      return CommitmentStatus(
        phase: CommitmentPhase.locked,
        mode: mode,
        lockUntil: spanEnd,
        daysLeft: days > totalDays ? totalDays : days,
      );
    }
    cursor = lockEnd;
    if (i < breakCount) {
      final breakEnd = cursor.add(brk);
      if (now.isBefore(breakEnd)) {
        final mins = (breakEnd.difference(now).inSeconds / 60).ceil();
        return CommitmentStatus(
          phase: CommitmentPhase.breakOpen,
          mode: mode,
          breakUntil: breakEnd,
          minutesLeft: mins < 1 ? 1 : mins,
        );
      }
      cursor = breakEnd;
    }
  }
  // Unreachable given the spanEnd guard above, but stay safe.
  return CommitmentStatus(phase: CommitmentPhase.completed, mode: mode);
}

/// For a [CommitmentMode.cycle] whose span has fully elapsed, rolls [startedAt]
/// forward by whole spans so a fresh cycle is running. Loops in case the device
/// was off long enough to miss several spans.
///
/// Returns the new [startedAt] to persist, or null if nothing changed / not
/// applicable.
DateTime? advanceCycle(
  CommitmentMode mode,
  int totalDays,
  int breakCount,
  DateTime? startedAt,
  DateTime now,
) {
  if (mode != CommitmentMode.cycle || startedAt == null) return null;
  final segLen = _segmentLength(totalDays, breakCount);
  final spanLen = _spanLength(segLen, breakCount);
  if (spanLen.inSeconds <= 0) return null;

  var start = startedAt;
  var changed = false;
  while (!now.isBefore(start.add(spanLen))) {
    start = start.add(spanLen);
    changed = true;
  }
  return changed ? start : null;
}

int _ceilDays(Duration d) {
  if (CommitmentStatus.testMode) {
    final mins = (d.inSeconds / 60).ceil();
    return mins < 1 ? 1 : mins;
  }
  final days = (d.inMinutes / (60 * 24)).ceil();
  return days < 1 ? 1 : days;
}
