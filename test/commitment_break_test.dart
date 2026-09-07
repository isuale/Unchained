import 'package:flutter_test/flutter_test.dart';
import 'package:unchained/features/dashboard/domain/commitment.dart';

/// The break notification is only as good as this instant: `BreakNotifier.kt`
/// sets an AlarmManager alarm for whatever [nextBreakAvailableAt] returns, and
/// nothing re-checks it until the alarm fires. If the maths drifts, the user is
/// told about their break on the wrong day — so these tests pin it against
/// [computeStatus], which is the definition of when a break is really earned.
void main() {
  final start = DateTime(2026, 9, 1, 12, 0);

  /// How much real time [n] plan-days are worth.
  ///
  /// [CommitmentStatus.testMode] reinterprets every "day" as a minute so the
  /// whole lock → break → re-lock cycle can be watched by hand in a few
  /// minutes. These tests go through this helper rather than hardcoding
  /// `Duration(days:)`, so they stay true — and keep testing the real thing —
  /// whichever way that switch is set.
  Duration planDays(int n) => CommitmentStatus.testMode
      ? Duration(minutes: n)
      : Duration(days: n);

  /// Every case is checked from both sides: locked one minute earlier,
  /// available one second later.
  void expectBoundary(CommitmentMode mode, int days, int breaks, int used) {
    final at = nextBreakAvailableAt(mode, days, breaks, start, breaksUsed: used);
    expect(at, isNotNull,
        reason: 'a break should still be coming for $days/$breaks/used=$used');

    final justBefore = computeStatus(
        mode, days, breaks, start, at!.subtract(const Duration(minutes: 1)),
        breaksUsed: used);
    expect(justBefore.isLocked, isTrue,
        reason: 'still locked a minute before $at');

    final justAfter = computeStatus(
        mode, days, breaks, start, at.add(const Duration(seconds: 1)),
        breaksUsed: used);
    expect(justAfter.isBreakAvailable, isTrue,
        reason: 'break should be available a second after $at');
  }

  group('nextBreakAvailableAt', () {
    test('lands exactly where computeStatus grants the break', () {
      expectBoundary(CommitmentMode.fixed, 30, 2, 0);
      expectBoundary(CommitmentMode.fixed, 30, 2, 1);
      expectBoundary(CommitmentMode.fixed, 14, 2, 0);
      expectBoundary(CommitmentMode.fixed, 45, 1, 0);
      expectBoundary(CommitmentMode.cycle, 60, 1, 0);
    });

    test('splits the span evenly: 30 days / 2 breaks earns one every 10 days',
        () {
      expect(nextBreakAvailableAt(CommitmentMode.fixed, 30, 2, start),
          start.add(planDays(10)));
    });

    test('a spent break pushes the next one out by its own 30 minutes', () {
      // Break time does not count as served, so the second break lands 20 days
      // of *protected* time in — which is 20 days plus one break of wall clock.
      expect(
        nextBreakAvailableAt(CommitmentMode.fixed, 30, 2, start, breaksUsed: 1),
        start.add(planDays(20) + CommitmentStatus.breakDuration),
      );
    });

    test('returns null when there is nothing to announce', () {
      expect(nextBreakAvailableAt(CommitmentMode.fixed, 30, 2, null), isNull,
          reason: 'run not started');
      expect(nextBreakAvailableAt(CommitmentMode.forever, 0, 0, start), isNull,
          reason: 'Forever plan has no breaks');
      expect(nextBreakAvailableAt(CommitmentMode.none, 30, 2, start), isNull,
          reason: 'no commitment');
      expect(nextBreakAvailableAt(CommitmentMode.fixed, 90, 0, start), isNull,
          reason: 'plan configured with zero breaks');
      expect(
          nextBreakAvailableAt(CommitmentMode.fixed, 30, 2, start,
              breaksUsed: 2),
          isNull,
          reason: 'every break already spent');
    });

    test('Forever ignores any leftover day count from a previous plan', () {
      // The shape a switch-to-Forever leaves behind: mode is forever, but the
      // old plan's totalDays/breakCount are still sitting in the row. None of
      // it may leak into what the user sees or into a break schedule.
      final status = computeStatus(CommitmentMode.forever, 60, 1, start,
          start.add(const Duration(days: 3)),
          breaksUsed: 0);
      expect(status.isPermanent, isTrue);
      expect(status.isLocked, isTrue);
      expect(status.daysLeft, 0, reason: 'Forever never counts down');
      expect(status.nextBreakAt, isNull);
      expect(nextBreakAvailableAt(CommitmentMode.forever, 60, 1, start), isNull,
          reason: 'Forever must never schedule a break notification');
    });

    test('Forever only engages once the run is anchored', () {
      // Why the repair re-anchors: with a null anchor computeStatus reports no
      // commitment at all, which would hand the user a freely-toggleable
      // protection switch the instant they moved to Forever.
      expect(
        computeStatus(CommitmentMode.forever, 0, 0, null, start).isLocked,
        isFalse,
      );
      expect(
        computeStatus(CommitmentMode.forever, 0, 0, start, start).isLocked,
        isTrue,
      );
    });

    test('CommitmentStatus.nextBreakAt is set while locked, not while waiting',
        () {
      final locked = computeStatus(
          CommitmentMode.fixed, 30, 2, start, start.add(planDays(1)));
      expect(locked.isLocked, isTrue);
      expect(locked.nextBreakAt, start.add(planDays(10)));

      final waiting = computeStatus(
          CommitmentMode.fixed, 30, 2, start, start.add(planDays(11)));
      expect(waiting.isBreakAvailable, isTrue);
      expect(waiting.nextBreakAt, isNull,
          reason: 'a break already waiting is not a *next* break');
    });
  });
}
