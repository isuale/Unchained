import 'package:flutter/foundation.dart';

/// Which kind of commitment lock the active plan imposes.
///
/// The plan the user picks decides this:
///  - [forever]  — Forever plan: protection is locked ON permanently. No break,
///                 never ends.
///  - [fixed]    — Monthly / AI plan: [CommitmentSchedule.totalDays] days of
///                 protection with [CommitmentSchedule.breakCount] short breaks
///                 earned along the way. When the days are served, the
///                 commitment clears (protection stays on but becomes freely
///                 toggleable again).
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

  /// Total *protected* days across the whole span (ignored for
  /// [CommitmentMode.forever]). Time spent on a break does not count toward
  /// this, so the user always serves the full number of days they chose.
  final int totalDays;

  /// How many short breaks are earned across the span (0 = none).
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

  /// A break has been earned but not taken yet. Protection is still on, and
  /// turning it off *claims* the break (which starts its countdown).
  ///
  /// This phase waits indefinitely. That is the whole point: a break pinned to
  /// a wall-clock instant lands at 3am as often as not, and a user asleep
  /// through their only 30-minute window effectively has the Forever plan.
  breakAvailable,

  /// A claimed break is running — protection may be off until it expires, at
  /// which point the caller must turn protection back on.
  breakOpen,

  /// The full span has been served. The caller should clear the commitment
  /// (protection stays on but becomes freely toggleable) or, for
  /// [CommitmentMode.cycle], restart it.
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
    this.breaksUsed = 0,
    this.breaksTotal = 0,
  });

  /// TEMPORARY TEST MODE — set back to false before committing.
  /// When true, "days" are interpreted as minutes so a full
  /// lock → break → re-lock span can be watched in a couple of minutes.
  static const bool testMode = false;

  /// How long a break lasts once the user claims it.
  static const Duration breakDuration =
      testMode ? Duration(minutes: 1) : Duration(minutes: 30);

  final CommitmentPhase phase;
  final CommitmentMode mode;

  /// When the whole protection span is expected to end (for display of "locked
  /// until"), assuming every remaining break is taken. Null for
  /// [CommitmentMode.forever] and when not locked.
  final DateTime? lockUntil;

  /// When the current break expires (start of the next lock). Null unless a
  /// break is actually running.
  final DateTime? breakUntil;

  /// Whole protected days still to serve (ceil), for display.
  final int daysLeft;

  /// Whole minutes left in the running break (ceil), for display.
  final int minutesLeft;

  /// True for the Forever plan — locked with no end.
  final bool isPermanent;

  /// Breaks already claimed, and how many the plan grants in total.
  final int breaksUsed;
  final int breaksTotal;

  /// Breaks still to come, including one that is available right now.
  int get breaksLeft {
    final left = breaksTotal - breaksUsed;
    return left < 0 ? 0 : left;
  }

  bool get isActive =>
      phase == CommitmentPhase.locked ||
      phase == CommitmentPhase.breakAvailable ||
      phase == CommitmentPhase.breakOpen;

  /// True only when protection genuinely may not be turned off.
  bool get isLocked => phase == CommitmentPhase.locked;

  /// A break is earned and waiting to be claimed.
  bool get isBreakAvailable => phase == CommitmentPhase.breakAvailable;

  /// A claimed break is running right now.
  bool get isBreak => phase == CommitmentPhase.breakOpen;

  /// Either kind of break state — protection is allowed to be off.
  bool get canPause =>
      phase == CommitmentPhase.breakAvailable ||
      phase == CommitmentPhase.breakOpen;

  bool get isCompleted => phase == CommitmentPhase.completed;

  static const CommitmentStatus none_ =
      CommitmentStatus(phase: CommitmentPhase.none);
}

/// Total *protected* time the user signed up for. Breaks sit on top of this
/// rather than eating into it, so a 30-day plan always means 30 days protected.
Duration _totalLockDuration(int totalDays) => Duration(
    minutes: CommitmentStatus.testMode ? totalDays : totalDays * 24 * 60);

/// How much protected time must be served to earn each successive break: the
/// total split evenly across the [breakCount] + 1 stretches between breaks.
Duration _segmentLength(int totalDays, int breakCount) {
  final total = _totalLockDuration(totalDays).inMinutes;
  return Duration(minutes: (total / (breakCount + 1)).round());
}

/// Derives the current [CommitmentStatus] from the stored schedule, the run
/// anchor [startedAt] (null = template stored but the user hasn't started yet),
/// and the break bookkeeping.
///
/// [breaksUsed] is how many breaks have been claimed so far; [breakClaimedAt] is
/// when the newest one was claimed (null if no break is running). A claim whose
/// [CommitmentStatus.breakDuration] has already elapsed reads as locked again —
/// the caller is responsible for clearing it and re-arming protection.
CommitmentStatus computeStatus(
  CommitmentMode mode,
  int totalDays,
  int breakCount,
  DateTime? startedAt,
  DateTime now, {
  int breaksUsed = 0,
  DateTime? breakClaimedAt,
}) {
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
  final brk = CommitmentStatus.breakDuration;
  final totalLock = _totalLockDuration(totalDays);
  final segLen = _segmentLength(totalDays, breakCount);

  // A running break outranks everything else.
  if (breakClaimedAt != null) {
    final breakEnd = breakClaimedAt.add(brk);
    if (now.isBefore(breakEnd)) {
      final mins = (breakEnd.difference(now).inSeconds / 60).ceil();
      return CommitmentStatus(
        phase: CommitmentPhase.breakOpen,
        mode: mode,
        breakUntil: breakEnd,
        minutesLeft: mins < 1 ? 1 : mins,
        breaksUsed: breaksUsed,
        breaksTotal: breakCount,
      );
    }
    // Expired claim falls through: it counts as spent (it is already included
    // in breaksUsed) and the user is locked again.
  }

  // Protected time served so far = wall clock minus every break consumed.
  var served = now.difference(startedAt) - brk * breaksUsed;
  if (served.isNegative) served = Duration.zero;

  if (served >= totalLock) {
    return CommitmentStatus(
      phase: CommitmentPhase.completed,
      mode: mode,
      breaksUsed: breaksUsed,
      breaksTotal: breakCount,
    );
  }

  final remaining = totalLock - served;

  // One break is earned per completed stretch. Clamped so the final stretch
  // can't hand out a break that does not exist.
  var earned = segLen.inSeconds <= 0
      ? breakCount
      : served.inSeconds ~/ segLen.inSeconds;
  if (earned > breakCount) earned = breakCount;

  return CommitmentStatus(
    phase: earned > breaksUsed
        ? CommitmentPhase.breakAvailable
        : CommitmentPhase.locked,
    mode: mode,
    // The realistic finish date: the protected time still owed, plus the
    // wall-clock the remaining breaks will add on top.
    lockUntil: now.add(remaining + brk * (breakCount - breaksUsed).clamp(0, breakCount)),
    daysLeft: _ceilDays(remaining),
    breaksUsed: breaksUsed,
    breaksTotal: breakCount,
  );
}

int _ceilDays(Duration d) {
  if (CommitmentStatus.testMode) {
    final mins = (d.inSeconds / 60).ceil();
    return mins < 1 ? 1 : mins;
  }
  final days = (d.inMinutes / (60 * 24)).ceil();
  return days < 1 ? 1 : days;
}
