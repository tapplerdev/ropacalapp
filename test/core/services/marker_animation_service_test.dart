import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:google_navigation_flutter/google_navigation_flutter.dart';
import 'package:ropacalapp/core/services/marker_animation_service.dart';

/// Machine verification of the marker playback: replays deterministic fix
/// sequences through the service at a virtual 30fps and asserts the motion
/// invariants that "looks good on the map" can't check — continuity, turn
/// rates, road adherence, U-turn commit behavior, teleports, hysteresis.

const _baseLat = 37.35;
const _baseLng = -121.99;
const _mPerDegLat = 110540.0;
final _mPerDegLng = 111320.0 * cos(_baseLat * pi / 180);

LatLng at(double xMeters, double yMeters) => LatLng(
      latitude: _baseLat + yMeters / _mPerDegLat,
      longitude: _baseLng + xMeters / _mPerDegLng,
    );

double distM(LatLng a, LatLng b) {
  final dx = (b.longitude - a.longitude) * _mPerDegLng;
  final dy = (b.latitude - a.latitude) * _mPerDegLat;
  return sqrt(dx * dx + dy * dy);
}

double headingDelta(double a, double b) {
  var d = b - a;
  if (d > 180) d -= 360;
  if (d < -180) d += 360;
  return d;
}

/// Distance from [pt] to the polyline [path], in meters.
double distToPath(LatLng pt, List<LatLng> path) {
  var best = double.infinity;
  for (var i = 0; i < path.length - 1; i++) {
    final ax = (path[i].longitude - pt.longitude) * _mPerDegLng;
    final ay = (path[i].latitude - pt.latitude) * _mPerDegLat;
    final bx = (path[i + 1].longitude - pt.longitude) * _mPerDegLng;
    final by = (path[i + 1].latitude - pt.latitude) * _mPerDegLat;
    final dx = bx - ax, dy = by - ay;
    final lenSq = dx * dx + dy * dy;
    final t = lenSq == 0 ? 0.0 : (-(ax * dx + ay * dy) / lenSq).clamp(0.0, 1.0);
    final px = ax + dx * t, py = ay + dy * t;
    best = min(best, sqrt(px * px + py * py));
  }
  return best;
}

/// Virtual-time driver: feeds fixes and ticks the render clock at 30fps.
class Harness {
  Harness() {
    svc = MarkerAnimationService(nowMs: () => now);
  }

  late final MarkerAnimationService svc;
  double now = 0; // virtual wall clock (ms)
  int deviceTs = 1000000; // virtual device timestamps (ms)
  static const driver = 'd1';

  final frames = <({LatLng pos, double? heading})>[];

  void fix(LatLng pos, {double speed = 13.0, int? gapMs}) {
    deviceTs += gapMs ?? 3000;
    svc.animateMarker(
      driverId: driver,
      newPosition: pos,
      speed: speed,
      accuracy: 5.0,
      timestampMs: deviceTs,
    );
  }

  /// Advance [ms] of wall time in ~33ms render ticks, recording frames.
  void run(double ms) {
    var remaining = ms;
    while (remaining > 0) {
      final step = min(33.0, remaining);
      now += step;
      final pos = svc.getInterpolatedPositions()[driver];
      final h = svc.getInterpolatedHeadings()[driver];
      if (pos != null) frames.add((pos: pos, heading: h));
      remaining -= step;
    }
  }

  /// Feed a fix then play 3s of wall time (the steady-state cadence).
  void driveStep(LatLng pos, {double speed = 13.0}) {
    fix(pos, speed: speed);
    run(3000);
  }
}

void main() {
  group('continuity', () {
    test('straight drive: no frame jumps beyond physical speed', () {
      final h = Harness();
      // Straight east at 13 m/s, fixes every 3s = 39m apart.
      for (var i = 0; i < 12; i++) {
        h.driveStep(at(i * 39.0, 0));
      }

      // Skip the warm-up (buffer filling); check steady-state frames.
      final steady = h.frames.skip(120).toList();
      expect(steady.length, greaterThan(150));
      var moved = 0.0;
      for (var i = 1; i < steady.length; i++) {
        final step = distM(steady[i - 1].pos, steady[i].pos);
        moved += step;
        // 13 m/s * 33ms * 1.5 max playback rate ≈ 0.65m; allow slack.
        expect(step, lessThan(1.0),
            reason: 'frame $i jumped ${step.toStringAsFixed(2)}m');
      }
      // And it must actually be MOVING, not parked (continuity of motion).
      expect(moved, greaterThan(200));
    });

    test('red light: parked truck is pixel-still with frozen heading', () {
      final h = Harness();
      for (var i = 0; i < 5; i++) {
        h.driveStep(at(i * 39.0, 0));
      }
      final stopPos = at(4 * 39.0, 0);
      // Stationary fixes with GPS wander inside the accuracy floor.
      for (var i = 0; i < 6; i++) {
        h.frames.clear();
        h.driveStep(
          at(4 * 39.0 + (i.isEven ? 3.0 : -3.0), i.isEven ? 2.0 : -2.0),
          speed: 0.0,
        );
      }
      // Last stationary window: zero drift, heading pinned east.
      for (final f in h.frames) {
        expect(distM(f.pos, stopPos), lessThan(0.5),
            reason: 'parked truck drifted');
        expect(headingDelta(f.heading ?? 90, 90).abs(), lessThan(5));
      }
    });
  });

  group('rotation', () {
    test('90° corner: heading sweeps at capped rate, no steps', () {
      final h = Harness();
      // East 5 fixes, then north 5 fixes (hard 90° corner, no guide).
      for (var i = 0; i < 5; i++) {
        h.driveStep(at(i * 39.0, 0));
      }
      for (var i = 1; i <= 5; i++) {
        h.driveStep(at(4 * 39.0, i * 39.0));
      }
      final headings =
          h.frames.map((f) => f.heading).whereType<double>().toList();
      // Per-frame turn must respect the cap (0.36°/ms * 33ms ≈ 11.9°).
      for (var i = 1; i < headings.length; i++) {
        expect(headingDelta(headings[i - 1], headings[i]).abs(),
            lessThanOrEqualTo(12.5),
            reason: 'rotation stepped at frame $i');
      }
      // And it must END pointing north.
      expect(headingDelta(headings.last, 0).abs(), lessThan(15));
    });

    test('single reversed fix: heading HOLDS (no pirouette)', () {
      final h = Harness();
      for (var i = 0; i < 6; i++) {
        h.driveStep(at(i * 39.0, 0));
      }
      // One multipath fix BEHIND the previous one, then forward resumes.
      h.driveStep(at(5 * 39.0 - 20.0, 0)); // reversed
      h.driveStep(at(6 * 39.0, 0));
      h.driveStep(at(7 * 39.0, 0));

      for (final f in h.frames) {
        final hd = f.heading;
        if (hd == null) continue;
        // Never swings anywhere near west (270°) — held at ~east.
        expect(headingDelta(hd, 90).abs(), lessThan(60),
            reason: 'pirouetted to ${hd.toStringAsFixed(0)}°');
      }
    });

    test('persisting reversal: heading COMMITS to the U-turn', () {
      final h = Harness();
      for (var i = 0; i < 6; i++) {
        h.driveStep(at(i * 39.0, 0));
      }
      // Genuine U-turn: keep driving back west.
      for (var i = 1; i <= 6; i++) {
        h.driveStep(at(5 * 39.0 - i * 39.0, 0));
      }
      final last = h.frames.last.heading!;
      expect(headingDelta(last, 270).abs(), lessThan(15),
          reason: 'never committed to the U-turn (at $last°)');
    });
  });

  group('guide path', () {
    test('L-corner with guide: rendered points hug the road', () {
      final h = Harness();
      // Road: east 200m then north 200m, with a vertex at the corner.
      final road = [at(0, 0), at(200, 0), at(200, 200)];
      h.svc.setGuidePath(Harness.driver, road);
      // Fixes ride the road at 39m spacing (as road distance).
      final roadFix = (double s) =>
          s <= 200 ? at(s, 0) : at(200, min(s - 200, 200.0));
      for (var i = 0; i <= 10; i++) {
        h.driveStep(roadFix(i * 39.0));
      }
      final steady = h.frames.skip(120).toList();
      for (final f in steady) {
        expect(distToPath(f.pos, road), lessThan(2.0),
            reason: 'left the road by ${distToPath(f.pos, road)}m');
      }
    });

    test('out-and-back street: noisy fix cannot snap to the return leg', () {
      final h = Harness();
      // Out east on y=0, U at the end, back west on y=20 — legs 20m apart,
      // both within the 30m snap radius of a noisy fix between them.
      final road = [at(0, 0), at(300, 0), at(300, 20), at(0, 20)];
      h.svc.setGuidePath(Harness.driver, road);
      // Outbound fixes on the y=0 leg...
      h.driveStep(at(20, 0));
      h.driveStep(at(60, 0));
      // ...then a noisy fix 12m north: globally NEARER to the return leg
      // (8m) than the outbound leg (12m). The monotonic window must keep
      // it on the outbound leg — the wave-2 wrong-leg fix.
      h.driveStep(at(100, 12));
      h.driveStep(at(140, 0));
      h.driveStep(at(180, 0));

      for (final f in h.frames) {
        final hd = f.heading;
        if (hd == null) continue;
        expect(headingDelta(hd, 90).abs(), lessThan(45),
            reason: 'snapped to return leg (heading $hd° ≈ west)');
      }
    });

    test('off-route hysteresis: latches once, fires refetch once', () {
      final h = Harness();
      final road = [at(0, 0), at(500, 0)];
      h.svc.setGuidePath(Harness.driver, road);
      var refetches = 0;
      h.svc.onOffRoute = (_) => refetches++;

      h.driveStep(at(20, 0));
      h.driveStep(at(60, 0));
      // Diverge 60m south of the road (beyond the 30m gate)...
      h.driveStep(at(100, -60));
      expect(refetches, 0, reason: 'latched after a single miss');
      h.driveStep(at(140, -60));
      expect(refetches, 1, reason: 'did not latch after two misses');
      h.driveStep(at(180, -60));
      expect(refetches, 1, reason: 'fired more than once per latch');
    });
  });

  group('teleports', () {
    test('>15s gap: jumps, never glides across the void', () {
      final h = Harness();
      for (var i = 0; i < 4; i++) {
        h.driveStep(at(i * 39.0, 0));
      }
      h.frames.clear();
      // 21s silence, then a fix 270m ahead.
      h.fix(at(3 * 39.0 + 270.0, 0), gapMs: 21000);
      h.run(3000);
      // No rendered frame may sit in the skipped middle stretch.
      for (final f in h.frames) {
        final x = (f.pos.longitude - _baseLng) * _mPerDegLng;
        final inVoid = x > 3 * 39.0 + 30 && x < 3 * 39.0 + 240;
        expect(inVoid, isFalse,
            reason: 'glided through the gap at x=${x.toStringAsFixed(0)}m');
      }
    });

    test('implied 90 m/s between fixes: teleports instead of gliding', () {
      final h = Harness();
      for (var i = 0; i < 4; i++) {
        h.driveStep(at(i * 39.0, 0));
      }
      h.frames.clear();
      // A "good accuracy" fix 270m away only 3s later (~90 m/s — bogus).
      h.driveStep(at(3 * 39.0 + 270.0, 0));
      for (final f in h.frames) {
        final x = (f.pos.longitude - _baseLng) * _mPerDegLng;
        final inVoid = x > 3 * 39.0 + 30 && x < 3 * 39.0 + 240;
        expect(inVoid, isFalse,
            reason: 'rendered a 600km/h glide at x=${x.toStringAsFixed(0)}m');
      }
    });
  });
}
