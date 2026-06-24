import 'package:flutter_test/flutter_test.dart';
import 'package:unchained/features/dashboard/domain/commitment.dart';

void main() {
  // These tests assume CommitmentStatus.testMode == false (real days).
  final start = DateTime(2026, 1, 1, 12);

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

    test('never advances', () {
      expect(advanceCycle(CommitmentMode.forever, 0, 0, start, start), isNull);
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

    test('completed once the span elapses', () {
      expect(at(const Duration(days: 10, minutes: 1)).phase,
          CommitmentPhase.completed);
    });

    test('fixed never advances', () {
      expect(
          advanceCycle(CommitmentMode.fixed, 10, 0, start,
              start.add(const Duration(days: 20))),
          isNull);
    });
  });

  group('fixed, 1 break (10 days → two 5-day locks with a 30m break)', () {
    CommitmentStatus at(Duration elapsed) =>
        computeStatus(CommitmentMode.fixed, 10, 1, start, start.add(elapsed));

    test('first segment is locked', () {
      expect(at(const Duration(days: 2)).isLocked, isTrue);
    });

    test('break opens right after the first 5-day segment', () {
      final s = at(const Duration(days: 5, minutes: 10));
      expect(s.isBreak, isTrue);
      expect(s.minutesLeft, inInclusiveRange(1, 30));
    });

    test('re-locks after the break', () {
      final s = at(const Duration(days: 5, minutes: 40));
      expect(s.isLocked, isTrue);
    });

    test('completes after the whole span (10d + 30m)', () {
      expect(at(const Duration(days: 10, hours: 1)).phase,
          CommitmentPhase.completed);
    });
  });

  group('cycle (repeats forever)', () {
    test('rolls startedAt forward by whole spans when elapsed', () {
      // span = 10d + 30m. After 11 days, exactly one span has passed.
      final now = start.add(const Duration(days: 11));
      final rolled = advanceCycle(CommitmentMode.cycle, 10, 1, start, now);
      expect(rolled, isNotNull);
      expect(rolled!.isAfter(start), isTrue);
      // The rolled-forward run is freshly locked again.
      final s = computeStatus(CommitmentMode.cycle, 10, 1, rolled, now);
      expect(s.isActive, isTrue);
    });

    test('does not roll forward mid-span', () {
      final now = start.add(const Duration(days: 3));
      expect(advanceCycle(CommitmentMode.cycle, 10, 1, start, now), isNull);
    });
  });
}
