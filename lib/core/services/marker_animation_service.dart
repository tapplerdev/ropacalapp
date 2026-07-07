import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:google_navigation_flutter/google_navigation_flutter.dart';
import 'package:ropacalapp/core/utils/app_logger.dart';

/// Buffered playback for driver markers (Uber-style continuous motion).
///
/// GPS fixes arrive every ~3s. A one-shot slide between them leaves the
/// marker parked most of the time (slide 0.8s, freeze 2.2s). Instead, each
/// fix is enqueued with its device timestamp and a per-driver playhead
/// advances through the queue in device-time, rendered by the map's 60fps
/// loop. The marker therefore moves continuously a few seconds behind real
/// time — the same jitter-buffer trade streaming audio makes.
///
/// The playhead self-tunes: it aims to stay [_targetLagMs] behind the newest
/// fix, speeding up when a network burst backlogs the queue and slowing
/// down as the buffer drains, so motion never visibly stalls or snaps.
class MarkerAnimationService {
  final Map<String, _DriverPlayback> _playbacks = {};

  /// True while any driver has runway left to play (drives the 60fps timer).
  final animationStateNotifier = ValueNotifier<bool>(false);

  /// How far behind the newest fix the playhead aims to stay. Big enough to
  /// absorb the ~3s publish cadence plus network jitter; small enough to
  /// still feel live.
  static const double _targetLagMs = 3500;

  /// Playback rate bounds for catching up / stretching out.
  static const double _minRate = 0.6;
  static const double _maxRate = 1.5;

  /// A gap between fixes longer than this is a connection drop, not driving —
  /// jump to the new fix instead of gliding across the void.
  static const double _teleportGapMs = 15000;

  /// Fixes worse than this accuracy are noise; don't steer the marker by them.
  static const double _accuracyRejectM = 50.0;

  /// Segments shorter than this don't produce a trustworthy bearing.
  static const double _minBearingSegmentM = 3.0;

  /// Max marker rotation while smoothing toward the segment bearing,
  /// degrees per millisecond (≈ a full U-turn in half a second).
  static const double _maxTurnDegPerMs = 0.36;

  final Stopwatch _clock = Stopwatch()..start();
  double? _lastTickMs;

  /// Enqueue a GPS fix for playback. Name kept from the previous one-shot
  /// implementation so call sites read the same.
  void animateMarker({
    required String driverId,
    required LatLng newPosition,
    double? heading,
    double? accuracy,
    int? timestampMs,
  }) {
    if ((accuracy ?? 0) > _accuracyRejectM) {
      AppLogger.map(
        '🔇 Dropping low-accuracy fix for $driverId '
        '(${accuracy!.toStringAsFixed(0)}m)',
      );
      return;
    }

    final playback = _playbacks.putIfAbsent(driverId, () => _DriverPlayback());
    final ts =
        (timestampMs ?? DateTime.now().millisecondsSinceEpoch).toDouble();

    final last = playback.queue.isEmpty ? null : playback.queue.last;
    if (last != null && ts <= last.ts) {
      return; // out-of-order or duplicate timestamp — drop
    }

    // Connection drop: don't glide across a long dead gap, jump.
    if (last != null && ts - last.ts > _teleportGapMs) {
      AppLogger.map(
        '🛰️ Gap of ${((ts - last.ts) / 1000).toStringAsFixed(0)}s for '
        '$driverId — teleporting to the new fix',
      );
      playback.queue.clear();
      playback.playheadTs = null;
    }

    playback.queue.add(_TimedFix(pos: newPosition, ts: ts));
    playback.playheadTs ??= ts; // first fix: park the marker on it
    if (heading != null && playback.displayedHeading == null) {
      playback.displayedHeading = heading; // seed before any movement
    }

    // Cap memory: playback can never need more than the recent tail.
    while (playback.queue.length > 60) {
      playback.queue.removeAt(0);
    }

    if (!animationStateNotifier.value && playback.hasRunway) {
      animationStateNotifier.value = true;
    }
  }

  /// Advance all playheads and return the rendered position per driver.
  /// Called by the map's 60fps loop; parked drivers report their last
  /// position so the caller has one consistent source.
  Map<String, LatLng> getInterpolatedPositions() {
    final nowMs = _clock.elapsedMilliseconds.toDouble();
    final dtMs = _lastTickMs == null ? 0.0 : nowMs - _lastTickMs!;
    _lastTickMs = nowMs;

    final positions = <String, LatLng>{};
    var anyRunway = false;

    for (final entry in _playbacks.entries) {
      final p = entry.value;
      if (p.queue.isEmpty || p.playheadTs == null) continue;

      final newestTs = p.queue.last.ts;
      final lag = newestTs - p.playheadTs!;

      if (lag > 0 && dtMs > 0) {
        // Self-tuning rate: 1.0 at target lag, faster when backlogged,
        // slower as the buffer drains — the marker eases instead of
        // hard-stopping when a fix is late.
        final rate = (lag / _targetLagMs).clamp(_minRate, _maxRate);
        p.playheadTs = min(p.playheadTs! + dtMs * rate, newestTs);
      }

      positions[entry.key] = _renderAt(p, dtMs);
      if (p.hasRunway) anyRunway = true;
    }

    if (animationStateNotifier.value != anyRunway) {
      animationStateNotifier.value = anyRunway;
    }

    return positions;
  }

  /// Smoothed direction-of-travel per driver, derived from the motion
  /// vector of the segment under the playhead. Absent until a driver has
  /// moved (or a payload heading seeded it).
  Map<String, double> getInterpolatedHeadings() {
    final headings = <String, double>{};
    for (final entry in _playbacks.entries) {
      final h = entry.value.displayedHeading;
      if (h != null) headings[entry.key] = h;
    }
    return headings;
  }

  /// Whether any driver still has queued motion to play.
  bool get hasActiveAnimations => _playbacks.values.any((p) => p.hasRunway);

  /// Interpolate the playback's position at its playhead and steer the
  /// displayed heading toward the segment bearing.
  LatLng _renderAt(_DriverPlayback p, double dtMs) {
    final queue = p.queue;
    final playhead = p.playheadTs!;

    // Drop segments fully behind the playhead (keep one as segment start).
    while (queue.length > 1 && queue[1].ts <= playhead) {
      queue.removeAt(0);
    }

    if (queue.length == 1 || playhead >= queue.last.ts) {
      return queue.last.pos; // parked at the newest fix
    }

    final a = queue[0];
    final b = queue[1];
    final t = ((playhead - a.ts) / (b.ts - a.ts)).clamp(0.0, 1.0);
    final pos = LatLng(
      latitude: a.pos.latitude + (b.pos.latitude - a.pos.latitude) * t,
      longitude: a.pos.longitude + (b.pos.longitude - a.pos.longitude) * t,
    );

    // Steer displayed heading toward this segment's bearing, shortest arc,
    // capped turn rate — no snap-spinning on jittery fixes.
    if (_distanceMeters(a.pos, b.pos) >= _minBearingSegmentM) {
      final target = _bearingDegrees(a.pos, b.pos);
      final current = p.displayedHeading ?? target;
      var delta = target - current;
      if (delta > 180) delta -= 360;
      if (delta < -180) delta += 360;
      final maxStep = _maxTurnDegPerMs * max(dtMs, 1.0);
      p.displayedHeading =
          (current + delta.clamp(-maxStep, maxStep) + 360) % 360;
    }

    return pos;
  }

  /// Initial bearing from [start] to [end] in degrees clockwise from north.
  double _bearingDegrees(LatLng start, LatLng end) {
    final lat1 = start.latitude * pi / 180;
    final lat2 = end.latitude * pi / 180;
    final dLng = (end.longitude - start.longitude) * pi / 180;
    final y = sin(dLng) * cos(lat2);
    final x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(dLng);
    return (atan2(y, x) * 180 / pi + 360) % 360;
  }

  /// Haversine distance in meters.
  double _distanceMeters(LatLng start, LatLng end) {
    const earthRadius = 6371000.0;
    final lat1 = start.latitude * pi / 180;
    final lat2 = end.latitude * pi / 180;
    final dLat = (end.latitude - start.latitude) * pi / 180;
    final dLng = (end.longitude - start.longitude) * pi / 180;
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1) * cos(lat2) * sin(dLng / 2) * sin(dLng / 2);
    return earthRadius * 2 * atan2(sqrt(a), sqrt(1 - a));
  }

  /// Clean up resources
  void dispose() {
    _playbacks.clear();
    animationStateNotifier.dispose();
  }
}

/// Per-driver playback state: the fix queue and where the playhead is in it.
class _DriverPlayback {
  final List<_TimedFix> queue = [];

  /// Playback position in device-timestamp milliseconds. Null until the
  /// first fix arrives.
  double? playheadTs;

  /// Smoothed direction of travel shown on the marker.
  double? displayedHeading;

  bool get hasRunway =>
      queue.isNotEmpty && playheadTs != null && playheadTs! < queue.last.ts;
}

/// A GPS fix with its device-side timestamp (ms).
class _TimedFix {
  final LatLng pos;
  final double ts;

  const _TimedFix({required this.pos, required this.ts});
}
