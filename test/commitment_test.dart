import 'package:flutter_test/flutter_test.dart';
import 'package:unchained/features/dashboard/domain/commitment.dart';

void main() {
  // These tests assume CommitmentStatus.testMode == false (real days).
  final start = DateTime(2026, 1, 1, 12);
  const brk = CommitmentStatus.breakDuration; // 30 minutes

  group('none / not started', () {
    test('no mode → none', () {
      final s = computeStatus(
          CommitmentMode.none, 30, 2, start, start.add(const Duration(days: 1)));
      expect(s.phase, CommitmentPhase.none);
    });

    test('template stored but not started (startedAt null) → none', () {
      final s = computeStatus(CommitmentMode.fixed, 30, 2, null, start);
      expect(s.phase, CommitmentPhase.none);
    });
  });

  group('forever', () {
    test('always locked and permanent, regardless of time', () {
      final s = computeStatus(CommitmentMode.forever, 0, 0, start,
          start.add(const Duration(days: 10000)));
      expect(s.isLocked, isTrue);
      expect(s.isPermanent, isTrue);
    });

    test('never offers a break', () {
      final s = computeStatus(CommitmentMode.forever, 0, 0, start,
          start.add(const Duration(days: 10000)));
      expect(s.isBreakAvailable, isFalse);
      expect(s.canPause, isFalse);
    });
  });

  group('fixed, no breaks (10 days)', () {
    CommitmentStatus at(Duration elapsed) =>
        computeStatus(CommitmentMode.fixed, 10, 0, start, start.add(elapsed));

    test('locked partway through', () {
      final s = at(const Duration(days: 3));
      expect(s.isLocked, isTrue);
      expect(s.daysLeft, lessThanOrEqualTo(10));
    });

    test('days-left never exceeds the chosen days', () {
      expect(at(const Duration(minutes: 1)).daysLeft, lessThanOrEqualTo(10));
    });

    test('no break is ever offered when breakCount is 0', () {
      expect(at(const Duration(days: 5)).isBreakAvailable, isFalse);
      expect(at(const Duration(days: 9)).isBreakAvailable, isFalse);
    });

    test('completed once the days are served', () {
      expect(at(const Duration(days: 10, minutes: 1)).phase,
          CommitmentPhase.completed);
    });
  });

  group('fixed, 1 break (10 protected days, break earned at the halfway mark)',
      () {
    CommitmentStatus at(Duration elapsed,
            {int used = 0, DateTime? claimedAt}) =>
        computeStatus(CommitmentMode.fixed, 10, 1, start, start.add(elapsed),
            breaksUsed: used, breakClaimedAt: claimedAt);

    test('locked before the break is earned', () {
      final s = at(const Duration(days: 2));
      expect(s.isLocked, isTrue);
      expect(s.isBreakAvailable, isFalse);
    });

    test('break becomes available after the first 5 protected days', () {
      final s = at(const Duration(days: 5, minutes: 1));
      expect(s.isBreakAvailable, isTrue);
      expect(s.breaksLeft, 1);
    });

    test('an unclaimed break WAITS — still available days later', () {
      // The old model opened a 30-minute window here and slammed it shut. A user
      // asleep through it never got a break at all.
      final s = at(const Duration(days: 8));
      expect(s.isBreakAvailable, isTrue);
    });

    test('an unclaimed break does not stall progress toward completion', () {
      // Protection stayed on the whole time, so the days still count.
      expect(at(const Duration(days: 10, minutes: 1)).phase,
          CommitmentPhase.completed);
    });

    test('claiming it opens a 30-minute break', () {
      final claim = start.add(const Duration(days: 5, minutes: 1));
      final s = at(const Duration(days: 5, minutes: 10),
          used: 1, claimedAt: claim);
      expect(s.isBreak, isTrue);
      expect(s.canPause, isTrue);
      expect(s.minutesLeft, inInclusiveRange(1, 30));
    });

    test('re-locks the moment the claimed break expires', () {
      final claim = start.add(const Duration(days: 5, minutes: 1));
      final s = at(const Duration(days: 5, minutes: 40),
          used: 1, claimedAt: claim);
      expect(s.isLocked, isTrue);
      expect(s.isBreak, isFalse);
      expect(s.canPause, isFalse, reason: 'protection must go back up');
    });

    test('a spent break is not offered again', () {
      final s = at(const Duration(days: 8), used: 1);
      expect(s.isBreakAvailable, isFalse);
      expect(s.isLocked, isTrue);
      expect(s.breaksLeft, 0);
    });

    test('break time does not count as protected time', () {
      // 10 days of wall clock, but 30 minutes of it was a break, so one segment
      // of protection is still owed.
      final s = at(const Duration(days: 10), used: 1);
      expect(s.isCompleted, isFalse);
      // Serving that final 30 minutes finishes it.
      expect(at(const Duration(days: 10, minutes: 31), used: 1).isCompleted,
          isTrue);
    });
  });

  group('fixed, 3 breaks (30 days) — breaks accrue one at a time', () {
    CommitmentStatus at(Duration elapsed, {int used = 0}) => computeStatus(
        CommitmentMode.fixed, 30, 3, start, start.add(elapsed),
        breaksUsed: used);

    test('none before the first quarter is served', () {
      expect(at(const Duration(days: 7)).isBreakAvailable, isFalse);
    });

    test('one after 7.5 days', () {
      expect(at(const Duration(days: 8)).isBreakAvailable, isTrue);
    });

    test('taking the first still leaves the second locked until it is earned',
        () {
      expect(at(const Duration(days: 8), used: 1).isLocked, isTrue);
      expect(at(const Duration(days: 16), used: 1).isBreakAvailable, isTrue);
    });

    test('cannot bank more breaks than the plan grants', () {
      // Deep into the span with none taken: still only offers what exists.
      final s = at(const Duration(days: 29));
      expect(s.isBreakAvailable, isTrue);
      expect(s.breaksLeft, 3);
      expect(s.breaksTotal, 3);
    });
  });

  group('cycle', () {
    test('completes like fixed — the caller restarts it', () {
      final s = computeStatus(CommitmentMode.cycle, 10, 1, start,
          start.add(const Duration(days: 10, minutes: 1)));
      expect(s.isCompleted, isTrue);
      expect(s.mode, CommitmentMode.cycle);
    });

    test('a restarted run is freshly locked with all breaks back', () {
      final restart = start.add(const Duration(days: 11));
      final s = computeStatus(
          CommitmentMode.cycle, 10, 1, restart, restart,
          breaksUsed: 0);
      expect(s.isLocked, isTrue);
      expect(s.breaksLeft, 1);
    });
  });

  group('regression: a break must never become a permanent escape', () {
    // The bug: turn protection off during a break, and nothing ever turned it
    // back on — the phone read "locked" while sitting unprotected for weeks.
    test('long after a claimed break, the phase is locked and unpausable', () {
      final claim = start.add(const Duration(days: 5));
      final s = computeStatus(
        CommitmentMode.fixed,
        30,
        1,
        start,
        claim.add(const Duration(days: 12)),
        breaksUsed: 1,
        breakClaimedAt: claim,
      );
      expect(s.isLocked, isTrue);
      expect(s.canPause, isFalse);
      expect(s.isBreak, isFalse);
    });

    test('an expired claim is charged exactly one break, not more', () {
      final claim = start.add(const Duration(days: 5));
      final late = computeStatus(
        CommitmentMode.fixed,
        10,
        1,
        start,
        start.add(const Duration(days: 10) + brk),
        breaksUsed: 1,
        breakClaimedAt: claim,
      );
      // 10 days + 30m wall clock, minus the one 30m break = exactly 10 served.
      expect(late.isCompleted, isTrue);
    });
  });
}
