import 'package:flutter/foundation.dart';

/// Where the user currently sits in the commitment cycle.
enum CommitmentPhase {
  /// No commitment running — protection toggles freely.
  none,

  /// Inside a lock window — protection cannot be turned off.
  locked,

  /// The short break between locks — protection may be turned off.
  breakOpen,
}

/// A growing commitment lock.
///
/// When the user starts it (cycle 1) protection is locked ON for 14 days.
/// At the end of each lock a short [breakDuration] window opens, then it
/// re-locks for one week longer than before:
///
///   cycle 1 → 14 days, cycle 2 → 21 days, cycle 3 → 28 days, ... (+7 each).
///
/// The breaks get rarer relative to the growing locks, so over time the user
/// relies on them less and less — the "down to 0%" curve.
@immutable
class CommitmentStatus {
  const CommitmentStatus({
    required this.phase,
    required this.cycle,
    this.lockUntil,
    this.breakUntil,
    this.daysLeft = 0,
    this.minutesLeft = 0,
  });

  /// TEMPORARY TEST MODE — set back to false before committing.
  /// When true, the cycle runs in minutes instead of weeks so the full
  /// lock → break → re-lock flow can be watched in a couple of minutes.
  static const bool testMode = false;

  /// The short release window between locks.
  static const Duration breakDuration =
      testMode ? Duration(minutes: 1) : Duration(minutes: 30);

  final CommitmentPhase phase;

  /// Which lock we're on (0 = none, 1 = first 14-day lock, ...).
  final int cycle;

  /// When the current lock expires (start of the break). Null when [none].
  final DateTime? lockUntil;

  /// When the current break expires (start of the next lock). Null when [none].
  final DateTime? breakUntil;

  /// Whole days left in the current lock (ceil), for display.
  final int daysLeft;

  /// Whole minutes left in the current break (ceil, capped at 30), for display.
  final int minutesLeft;

  bool get isActive => phase != CommitmentPhase.none;
  bool get isLocked => phase == CommitmentPhase.locked;
  bool get isBreak => phase == CommitmentPhase.breakOpen;

  /// Lock length for [cycle]: cycle 1 = 14 days, +7 days each cycle.
  /// In [testMode]: cycle 1 = 2 min, +1 min each cycle.
  static Duration lockDurationForCycle(int cycle) => testMode
      ? Duration(minutes: cycle + 1)
      : Duration(days: 7 * (cycle + 1));

  static const CommitmentStatus none_ =
      CommitmentStatus(phase: CommitmentPhase.none, cycle: 0);
}

/// Derives the current [CommitmentStatus] from stored values.
///
/// If the break has fully elapsed (the user is "past due" for a re-lock),
/// this reports [CommitmentPhase.none] — callers should run [advanceIfLapsed]
/// first and persist the result so the next lock begins.
CommitmentStatus computeCommitment(
    int cycle, DateTime? lockUntil, DateTime now) {
  if (cycle <= 0 || lockUntil == null) return CommitmentStatus.none_;
  final breakUntil = lockUntil.add(CommitmentStatus.breakDuration);

  if (now.isBefore(lockUntil)) {
    final remaining = lockUntil.difference(now);
    return CommitmentStatus(
      phase: CommitmentPhase.locked,
      cycle: cycle,
      lockUntil: lockUntil,
      breakUntil: breakUntil,
      daysLeft: _ceilDays(remaining),
    );
  }

  if (now.isBefore(breakUntil)) {
    final remaining = breakUntil.difference(now);
    final mins = (remaining.inSeconds / 60).ceil();
    return CommitmentStatus(
      phase: CommitmentPhase.breakOpen,
      cycle: cycle,
      lockUntil: lockUntil,
      breakUntil: breakUntil,
      minutesLeft: mins > 30 ? 30 : (mins < 1 ? 1 : mins),
    );
  }

  // Break elapsed — needs advancing; treat as none until persisted.
  return CommitmentStatus.none_;
}

/// If the break has fully elapsed, rolls forward to the next lock (one week
/// longer), starting from when the break ended. Loops in the unlikely case
/// the device was off long enough to miss several whole cycles.
///
/// Returns the new (cycle, lockUntil) to persist, or null if nothing changed.
({int cycle, DateTime lockUntil})? advanceIfLapsed(
    int cycle, DateTime? lockUntil, DateTime now) {
  if (cycle <= 0 || lockUntil == null) return null;

  var c = cycle;
  var lock = lockUntil;
  var changed = false;

  while (true) {
    final breakEnd = lock.add(CommitmentStatus.breakDuration);
    if (now.isBefore(breakEnd)) break;
    c += 1;
    lock = breakEnd.add(CommitmentStatus.lockDurationForCycle(c));
    changed = true;
  }

  return changed ? (cycle: c, lockUntil: lock) : null;
}

int _ceilDays(Duration d) {
  final days = (d.inMinutes / (60 * 24)).ceil();
  return days < 1 ? 1 : days;
}
