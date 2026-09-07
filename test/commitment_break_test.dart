import 'package:flutter_test/flutter_test.dart';
import 'package:unchained/features/dashboard/domain/commitment.dart';

/// The break notification is only as good as this instant: `BreakNotifier.kt`
/// sets an AlarmManager alarm for whatever [nextBreakAvailableAt] returns, and
/// nothing re-checks it until the alarm fires. If the maths drifts, the user is
/// told about their break on the wrong day — so these tests pin it against
/// [computeStatus], which is the definition of when a break is really earned.
void main() {
  final start = DateTime(2026, 9, 1, 12, 0);

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
          start.add(const Duration(days: 10)));
    });

    test('a spent break pushes the next one out by its own 30 minutes', () {
      // Break time does not count as served, so the second break lands 20 days
      // of *protected* time in — which is 20 days plus one break of wall clock.
      expect(
        nextBreakAvailableAt(CommitmentMode.fixed, 30, 2, start, breaksUsed: 1),
        start.add(const Duration(days: 20) + CommitmentStatus.breakDuration),
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

    test('CommitmentStatus.nextBreakAt is set while locked, not while waiting',
        () {
      final locked = computeStatus(CommitmentMode.fixed, 30, 2, start,
          start.add(const Duration(days: 1)));
      expect(locked.isLocked, isTrue);
      expect(locked.nextBreakAt, start.add(const Duration(days: 10)));

      final waiting = computeStatus(CommitmentMode.fixed, 30, 2, start,
          start.add(const Duration(days: 11)));
      expect(waiting.isBreakAvailable, isTrue);
      expect(waiting.nextBreakAt, isNull,
          reason: 'a break already waiting is not a *next* break');
    });
  });
}
