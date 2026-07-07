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
///
/// When a road-snapped guide path is attached (the focused driver's OSRM
/// route), playback interpolates ALONG the path, so the marker follows
/// curves instead of cutting straight chords between 3-second fixes.
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

  /// A fix further than this from the guide path means the driver is off
  /// the planned route — fall back to straight-chord interpolation.
  static const double _maxGuideSnapM = 30.0;

  /// Max marker rotation while smoothing toward the target bearing,
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

  /// Attach or clear a road-snapped guide path for a driver (the focused
  /// driver's OSRM route). While present and the fixes track it, playback
  /// follows the path's geometry instead of straight chords.
  void setGuidePath(String driverId, List<LatLng>? path) {
    // Create the playback if needed — the route often loads before the
    // first live fix arrives.
    final playback = _playbacks.putIfAbsent(driverId, () => _DriverPlayback());
    playback.guide =
        (path != null && path.length >= 2) ? _GuidePath(path) : null;
    playback.guideVersion++;
  }

  /// The last position playback rendered for [driverId] (the delayed,
  /// on-screen position — a few seconds behind the raw live fix). Use this
  /// for anything that must line up with the drawn marker, e.g. trimming
  /// the route polyline.
  LatLng? lastRenderedPosition(String driverId) =>
      _playbacks[driverId]?.lastRendered;

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

      final rendered = _renderAt(p, dtMs);
      p.lastRendered = rendered;
      positions[entry.key] = rendered;
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
  /// displayed heading toward the travel bearing.
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

    // Road-following: when a guide path is attached and both endpoints of
    // the playing segment sit on it (in forward order), glide along the
    // path geometry instead of the straight chord.
    final guide = p.guide;
    if (guide != null) {
      final sA = _projectedS(a, guide, p.guideVersion);
      final sB = _projectedS(b, guide, p.guideVersion);
      if (sA != null && sB != null && sB > sA) {
        final s = sA + (sB - sA) * t;
        _steerHeading(p, guide.bearingAt(s), dtMs);
        return guide.pointAt(s);
      }
    }

    // Straight chord fallback.
    final pos = LatLng(
      latitude: a.pos.latitude + (b.pos.latitude - a.pos.latitude) * t,
      longitude: a.pos.longitude + (b.pos.longitude - a.pos.longitude) * t,
    );
    if (_distanceMeters(a.pos, b.pos) >= _minBearingSegmentM) {
      _steerHeading(p, _bearingDegrees(a.pos, b.pos), dtMs);
    }
    return pos;
  }

  /// Project [fix] onto [guide], caching the result per guide version.
  /// Returns the distance-along-path, or null when the fix is too far from
  /// the path to trust (driver off-route).
  double? _projectedS(_TimedFix fix, _GuidePath guide, int version) {
    if (fix.cachedVersion != version) {
      final proj = guide.project(fix.pos);
      fix.cachedS = proj.distM <= _maxGuideSnapM ? proj.s : null;
      fix.cachedVersion = version;
    }
    return fix.cachedS;
  }

  /// Rotate the displayed heading toward [target], shortest arc, capped
  /// turn rate — no snap-spinning on jittery fixes.
  void _steerHeading(_DriverPlayback p, double target, double dtMs) {
    final current = p.displayedHeading ?? target;
    var delta = target - current;
    if (delta > 180) delta -= 360;
    if (delta < -180) delta += 360;
    final maxStep = _maxTurnDegPerMs * max(dtMs, 1.0);
    p.displayedHeading =
        (current + delta.clamp(-maxStep, maxStep) + 360) % 360;
  }

  /// Initial bearing from [start] to [end] in degrees clockwise from north.
  static double _bearingDegrees(LatLng start, LatLng end) {
    final lat1 = start.latitude * pi / 180;
    final lat2 = end.latitude * pi / 180;
    final dLng = (end.longitude - start.longitude) * pi / 180;
    final y = sin(dLng) * cos(lat2);
    final x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(dLng);
    return (atan2(y, x) * 180 / pi + 360) % 360;
  }

  /// Haversine distance in meters.
  static double _distanceMeters(LatLng start, LatLng end) {
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

  /// Last position handed to the renderer (the on-screen, delayed position).
  LatLng? lastRendered;

  /// Road-snapped route to glide along, when one is attached.
  _GuidePath? guide;

  /// Bumped whenever [guide] changes so cached fix projections go stale.
  int guideVersion = 0;

  bool get hasRunway =>
      queue.isNotEmpty && playheadTs != null && playheadTs! < queue.last.ts;
}

/// A GPS fix with its device-side timestamp (ms) and a cached projection
/// onto the current guide path.
class _TimedFix {
  final LatLng pos;
  final double ts;

  /// Distance along the guide path at the nearest point, or null when the
  /// fix was too far from the path. Valid only for [cachedVersion].
  double? cachedS;
  int cachedVersion = -1;

  _TimedFix({required this.pos, required this.ts});
}

/// A polyline with precomputed cumulative lengths, supporting projection
/// of a point onto it and lookup of the point/bearing at a distance along
/// it. Uses a locally-flat (equirectangular) approximation — fine at route
/// scale, cheap enough for per-fix projection.
class _GuidePath {
  final List<LatLng> points;
  final List<double> cum; // cumulative meters; cum[0] = 0

  _GuidePath(this.points) : cum = List.filled(points.length, 0) {
    for (var i = 1; i < points.length; i++) {
      cum[i] = cum[i - 1] +
          MarkerAnimationService._distanceMeters(points[i - 1], points[i]);
    }
  }

  /// Nearest point on the path to [pt]: distance-along-path and offset.
  ({double s, double distM}) project(LatLng pt) {
    final cosLat = cos(pt.latitude * pi / 180);
    const mPerDegLat = 110540.0;
    final mPerDegLng = 111320.0 * cosLat;

    var bestS = 0.0;
    var bestDist = double.infinity;

    for (var i = 0; i < points.length - 1; i++) {
      final ax = (points[i].longitude - pt.longitude) * mPerDegLng;
      final ay = (points[i].latitude - pt.latitude) * mPerDegLat;
      final bx = (points[i + 1].longitude - pt.longitude) * mPerDegLng;
      final by = (points[i + 1].latitude - pt.latitude) * mPerDegLat;

      final dx = bx - ax;
      final dy = by - ay;
      final segLenSq = dx * dx + dy * dy;
      final t = segLenSq == 0
          ? 0.0
          : (-(ax * dx + ay * dy) / segLenSq).clamp(0.0, 1.0);

      final px = ax + dx * t;
      final py = ay + dy * t;
      final dist = sqrt(px * px + py * py);

      if (dist < bestDist) {
        bestDist = dist;
        bestS = cum[i] + (cum[i + 1] - cum[i]) * t;
      }
    }

    return (s: bestS, distM: bestDist);
  }

  /// The point at [s] meters along the path (clamped to its ends).
  LatLng pointAt(double s) {
    final i = _segmentIndexFor(s);
    final segLen = cum[i + 1] - cum[i];
    final t = segLen == 0 ? 0.0 : ((s - cum[i]) / segLen).clamp(0.0, 1.0);
    return LatLng(
      latitude: points[i].latitude +
          (points[i + 1].latitude - points[i].latitude) * t,
      longitude: points[i].longitude +
          (points[i + 1].longitude - points[i].longitude) * t,
    );
  }

  /// Bearing of the path segment containing [s].
  double bearingAt(double s) {
    final i = _segmentIndexFor(s);
    return MarkerAnimationService._bearingDegrees(points[i], points[i + 1]);
  }

  /// Binary search for the segment whose cumulative range contains [s].
  int _segmentIndexFor(double s) {
    if (s <= 0) return 0;
    if (s >= cum.last) return points.length - 2;
    var lo = 0;
    var hi = points.length - 2;
    while (lo < hi) {
      final mid = (lo + hi + 1) >> 1;
      if (cum[mid] <= s) {
        lo = mid;
      } else {
        hi = mid - 1;
      }
    }
    return lo;
  }
}
