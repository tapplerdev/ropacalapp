import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:google_navigation_flutter/google_navigation_flutter.dart';
import 'package:ropacalapp/core/utils/app_logger.dart';

/// Buffered playback for driver markers (Uber-style continuous motion).
///
/// GPS fixes arrive every ~3s. A one-shot slide between them leaves the
/// marker parked most of the time (slide 0.8s, freeze 2.2s). Instead, each
/// fix is enqueued with its device timestamp and a per-driver playhead
/// advances through the queue in device-time, rendered by the map's render
/// loop. The marker therefore moves continuously a few seconds behind real
/// time — the same jitter-buffer trade streaming audio makes.
///
/// The playhead self-tunes: it aims to stay [_targetLagMs] behind the newest
/// fix, speeding up when a network burst backlogs the queue and slowing
/// down as the buffer drains, so motion never visibly stalls or snaps.
///
/// Geometry between fixes, best first:
/// 1. GUIDE PATH — the driver's road-snapped OSRM route: fixes are projected
///    onto it (windowed + monotonic, so out-and-back streets can't snap to
///    the wrong leg) and the marker glides along real road geometry.
///    Off-route is latched with hysteresis (2 misses out, 2 hits back in)
///    and reported via [onOffRoute] so the route can be refetched at once.
/// 2. CATMULL-ROM — with no usable guide, a centripetal spline through the
///    surrounding fixes rounds corners plausibly instead of cutting chords.
/// 3. LERP — degenerate cases (missing neighbors, crawl speed).
class MarkerAnimationService {
  final Map<String, _DriverPlayback> _playbacks = {};

  /// True while any driver has runway left to play (drives the render timer).
  final animationStateNotifier = ValueNotifier<bool>(false);

  /// Fired once when a driver's fixes stop matching their guide path
  /// (latched off-route) — wire this to an immediate route refetch instead
  /// of waiting out the periodic refresh timer.
  void Function(String driverId)? onOffRoute;

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
  /// the planned route.
  static const double _maxGuideSnapM = 30.0;

  /// Below this reported speed the driver is parked: positional wander is
  /// GPS noise, so coalesce fixes instead of animating the drift.
  static const double _stationarySpeedMps = 1.0;

  /// Below this speed the heading is frozen — bearings derived from
  /// creeping GPS noise spin the marker while the truck sits at a bin.
  static const double _headingFreezeSpeedMps = 2.0;

  /// Implied speed above this (~100 mph) is a bad fix or a tunnel exit,
  /// not driving — teleport instead of gliding across it.
  static const double _teleportSpeedMps = 45.0;

  /// Windowed projection bounds around the last confirmed distance along
  /// the guide: small backtrack for jitter, generous forward allowance.
  /// This is what stops an out-and-back street from snapping fixes to the
  /// RETURN leg — a global nearest-segment scan renders that exactly like
  /// a botched U-turn.
  static const double _guideBacktrackM = 60.0;
  static const double _guideMaxAdvanceM = 400.0;

  /// Consecutive off/on-guide fixes required to latch out of / back into
  /// guide mode — one noisy fix must not flap the geometry source.
  static const int _guideHysteresisFixes = 2;

  /// Sample the guide bearing slightly ahead of the marker so the nose
  /// leads into turns instead of reacting to them.
  static const double _bearingLookaheadM = 6.0;

  /// A target-bearing flip bigger than this is a suspected reversal: hold
  /// heading until it persists into a NEWER fix (single multipath-reversed
  /// fixes otherwise cause mid-block pirouettes), then commit and turn.
  static const double _reversalCommitDeg = 120.0;

  /// Max marker rotation while smoothing toward the target bearing,
  /// degrees per millisecond (≈ a full U-turn in half a second).
  static const double _maxTurnDegPerMs = 0.36;

  /// Adaptive playhead lag: hold at least 2× the measured inter-arrival of
  /// distinct fixes (the Valve Source rule: interp delay ≥ 2× update
  /// interval), clamped so we never feel dead nor over-buffer. A clean ~1s
  /// stream keeps this at [_targetLagMs]; a publisher that quantizes to
  /// multi-second steps widens the buffer to absorb them instead of
  /// lurching. See the compounding-quantization root cause.
  static const double _maxTargetLagMs = 6000;

  /// On buffer underrun (playhead caught the newest fix) with an active
  /// guide, dead-reckon forward along the road at the last speed for up to
  /// this long before holding — a late fix reads as continued motion, not a
  /// freeze. Mirrors Mapbox RouteControllerDeadReckoningTimeInterval (1.0s).
  /// Only ever advances ALONG the guide geometry — never free heading-based
  /// extrapolation (a documented pitfall).
  static const double _deadReckonMaxMs = 1000;

  /// When a fresh guide arrives, the rendered marker is re-projected onto it
  /// (continuity-preserving swap). A projection this close along-track behind
  /// the new path's start still counts as on-route — the expected geometry
  /// when a just-fetched guide is anchored a beat ahead of the delayed
  /// playhead, not a real divergence.
  static const double _guideResnapM = 60.0;

  /// Wall-clock source in milliseconds. Injectable so tests can drive
  /// virtual time; production uses a monotonic stopwatch.
  MarkerAnimationService({double Function()? nowMs})
      : _nowMs = nowMs ??
            (() {
              _defaultClock ??= Stopwatch()..start();
              return _defaultClock!.elapsedMilliseconds.toDouble();
            });

  static Stopwatch? _defaultClock;
  final double Function() _nowMs;
  double? _lastTickMs;

  /// Enqueue a GPS fix for playback. Name kept from the original one-shot
  /// implementation so call sites read the same.
  void animateMarker({
    required String driverId,
    required LatLng newPosition,
    double? heading,
    double? accuracy,
    double? speed,
    int? timestampMs,
  }) {
    if ((accuracy ?? 0) > _accuracyRejectM) {
      AppLogger.map(
        '🔇 Dropping low-accuracy fix for $driverId '
        '(${accuracy!.toStringAsFixed(0)}m)',
      );
      return;
    }

    final playback =
        _playbacks.putIfAbsent(driverId, () => _DriverPlayback(driverId));
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
      // Position jumped: re-anchor guide projection + forward-only clamp so a
      // backward teleport isn't held ahead and the window re-finds the fix.
      playback.lastConfirmedS = null;
      playback.renderedGuideS = null;
      playback.underrunMs = 0;
    }

    // Physically implausible jump (bad fix that self-reports good
    // accuracy): teleport rather than render a 600 km/h glide.
    if (playback.queue.isNotEmpty) {
      final prev = playback.queue.last;
      final impliedMps =
          _distanceMeters(prev.pos, newPosition) / ((ts - prev.ts) / 1000.0);
      if (impliedMps > _teleportSpeedMps) {
        AppLogger.map(
          '🛰️ Implied ${impliedMps.toStringAsFixed(0)} m/s for $driverId '
          '— teleporting to the new fix',
        );
        playback.queue.clear();
        playback.playheadTs = null;
      }
    }

    // Parked: GPS wander at a stop is noise, not motion. Anchor a
    // zero-length "parked" segment at the settled position instead of
    // animating the drift. IMPORTANT: never stretch a MOVING segment's end
    // timestamp — that dilates its playback time and the marker oozes into
    // the stop asymptotically instead of arriving crisply (caught by the
    // red-light invariant test).
    if (playback.queue.isNotEmpty &&
        speed != null &&
        speed < _stationarySpeedMps) {
      final prev = playback.queue.last;
      final drift = _distanceMeters(prev.pos, newPosition);
      if (drift < max(accuracy ?? 8.0, 8.0)) {
        if ((prev.speed ?? double.infinity) < _stationarySpeedMps) {
          // Already parked: extend the zero-length parked segment.
          playback.queue[playback.queue.length - 1] =
              _TimedFix(pos: prev.pos, ts: ts, speed: speed);
        } else {
          // Moving → stopped: append the parked anchor so the final moving
          // segment keeps its true duration and the playhead lands exactly.
          playback.queue.add(_TimedFix(pos: prev.pos, ts: ts, speed: speed));
        }
        if (!animationStateNotifier.value && playback.hasRunway) {
          animationStateNotifier.value = true;
        }
        return;
      }
    }

    // Track the inter-arrival of distinct fixes (device-time gap) as an EMA,
    // so the playhead lag can widen to absorb a quantized publisher instead
    // of lurching. Ignore teleport-sized gaps (connection drops, not cadence).
    if (playback.queue.isNotEmpty) {
      final gap = ts - playback.queue.last.ts;
      if (gap > 0 && gap < _teleportGapMs) {
        playback.avgFixIntervalMs = playback.avgFixIntervalMs == null
            ? gap
            : playback.avgFixIntervalMs! * 0.7 + gap * 0.3;
      }
    }

    playback.queue.add(_TimedFix(pos: newPosition, ts: ts, speed: speed));
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

  /// Attach or clear a road-snapped guide path for a driver (their current
  /// OSRM route). While present and the fixes track it, playback follows
  /// the path's geometry instead of chords/splines.
  void setGuidePath(String driverId, List<LatLng>? path) {
    // Create the playback if needed — the route often loads before the
    // first live fix arrives.
    final playback =
        _playbacks.putIfAbsent(driverId, () => _DriverPlayback(driverId));
    final newGuide = (path != null && path.length >= 2) ? _GuidePath(path) : null;
    playback.guide = newGuide;
    playback.guideVersion++;
    // New geometry → the forward-only render clamp must not carry an old s.
    playback.renderedGuideS = null;

    // Continuity-preserving swap: instead of blanking projection state (which
    // made EVERY refresh re-run the off-route hysteresis from zero and latch
    // whenever the delayed playhead sat behind the fresh path's start), carry
    // the currently rendered marker onto the new geometry. If it still sits on
    // the new route, seed the confirmed progress from it and stay engaged — no
    // spurious latch, no visible snap. Only a genuine divergence (rendered
    // marker truly off the new path) falls back to re-confirming via hysteresis.
    playback.onGuideStreak = 0;
    playback.offGuideStreak = 0;
    if (newGuide == null) {
      playback.lastConfirmedS = null;
      playback.guideActive = false;
      return;
    }
    final rendered = playback.lastRendered;
    if (rendered == null) {
      // Cold start — no marker to carry. Trust the fresh geometry (original
      // behavior); the first fixes confirm the window.
      playback.lastConfirmedS = null;
      playback.guideActive = true;
      return;
    }
    final proj = newGuide.project(rendered);
    // On-route if within the perpendicular snap gate, OR clamped just behind
    // the start within the resnap band AND colinear with the road (the
    // just-fetched-ahead-of-playhead case) — the perp guard keeps a marker
    // that's 50m to the SIDE of the start from being falsely kept on-route.
    if (proj.distM <= _maxGuideSnapM ||
        (proj.s <= 1.0 &&
            proj.distM <= _guideResnapM &&
            newGuide.startPerpDist(rendered) <= _maxGuideSnapM)) {
      playback.lastConfirmedS = proj.s;
      playback.guideActive = true;
      return;
    }
    // The marker is genuinely off the new path (a real reroute/divergence):
    // start inactive so the on-route hysteresis must re-earn the guide with
    // real fixes, rather than silently claiming a wrong geometry.
    playback.lastConfirmedS = null;
    playback.guideActive = false;
  }

  /// Whether [driverId]'s marker is currently gliding on its guide (not
  /// latched off-route). Lets the map skip geometry refetches for drivers
  /// that are already tracking cleanly.
  bool guideActiveFor(String driverId) =>
      _playbacks[driverId]?.guideActive ?? false;

  /// The last position playback rendered for [driverId] (the delayed,
  /// on-screen position — a few seconds behind the raw live fix). Use this
  /// for anything that must line up with the drawn marker, e.g. trimming
  /// the route polyline.
  LatLng? lastRenderedPosition(String driverId) =>
      _playbacks[driverId]?.lastRendered;

  /// Advance all playheads and return the rendered position per driver.
  /// Called by the map's render loop; parked drivers report their last
  /// position so the caller has one consistent source.
  Map<String, LatLng> getInterpolatedPositions() {
    final nowMs = _nowMs();
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
        // Self-tuning rate: 1.0 at the (adaptive) target lag, faster when
        // backlogged, slower as the buffer drains — the marker eases instead
        // of hard-stopping when a fix is late.
        final rate = (lag / p.targetLagMs).clamp(_minRate, _maxRate);
        p.playheadTs = min(p.playheadTs! + dtMs * rate, newestTs);
        p.underrunMs = 0;
      } else if (dtMs > 0) {
        // Caught up to the newest fix: accumulate underrun time so the render
        // path can dead-reckon along the guide (capped) instead of freezing.
        p.underrunMs = min(p.underrunMs + dtMs, _deadReckonMaxMs);
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

  /// Smoothed direction-of-travel per driver, derived from the geometry
  /// under the playhead. Absent until a driver has moved (or a payload
  /// heading seeded it).
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

    // Keep ONE fix behind the playing segment (the spline needs a
    // predecessor point); drop anything older.
    while (queue.length > 2 && queue[2].ts <= playhead) {
      queue.removeAt(0);
    }

    // Locate the playing segment [a, b] containing the playhead.
    var i = 0;
    while (i + 1 < queue.length && queue[i + 1].ts <= playhead) {
      i++;
    }
    if (i + 1 >= queue.length) {
      // Underrun: the playhead reached the newest fix. If we're gliding on a
      // guide and the truck was moving, dead-reckon forward ALONG the road at
      // the last speed for up to _deadReckonMaxMs — a late fix then reads as
      // continued motion instead of a freeze — then hold. Never extrapolate
      // off the geometry, and never while parked.
      final last = queue.last;
      final guide = p.guide;
      final overshoot = p.underrunMs; // wall-time parked at newest, capped
      final speed = last.speed ?? 0.0;
      if (guide != null &&
          p.guideActive &&
          overshoot > 0 &&
          speed >= _stationarySpeedMps &&
          p.lastConfirmedS != null) {
        final s = min(p.lastConfirmedS! + speed * overshoot / 1000.0,
            guide.length);
        // Record how far we dead-reckoned so the on-guide render holds here
        // (forward-only) instead of snapping back when the delayed fix lands.
        p.renderedGuideS = s;
        _steerHeading(
            p, guide.bearingAt(min(s + _bearingLookaheadM, guide.length)),
            dtMs, last.ts);
        return guide.pointAt(s);
      }
      return last.pos; // parked at the newest fix
    }

    final a = queue[i];
    final b = queue[i + 1];
    final t = ((playhead - a.ts) / (b.ts - a.ts)).clamp(0.0, 1.0);

    // Freeze heading at crawl speed: bearings derived from GPS creep spin
    // the marker while the truck is actually sitting at a bin.
    final slowFix = (b.speed ?? double.infinity) < _headingFreezeSpeedMps;

    // ── Tier 1: guide path (real road geometry) ──
    final guide = p.guide;
    if (guide != null) {
      final sA = _projectedS(a, p);
      final sB = _projectedS(b, p);
      if (p.guideActive && sA != null && sB != null && sB > sA) {
        var s = sA + (sB - sA) * t;
        // Forward-only: never render behind where we've already drawn on this
        // guide (dead-reckon may have nudged us slightly ahead of the last
        // real fix — hold there rather than snap backward when it arrives).
        if (p.renderedGuideS != null && s < p.renderedGuideS!) {
          s = p.renderedGuideS!;
        } else {
          p.renderedGuideS = s;
        }
        if (!slowFix) {
          // Sample slightly ahead so the nose leads into turns.
          final lookS = min(s + _bearingLookaheadM, guide.length);
          _steerHeading(p, guide.bearingAt(lookS), dtMs, b.ts);
        }
        return guide.pointAt(s);
      }
    }

    // ── Tier 2: centripetal Catmull-Rom through the surrounding fixes ──
    final p0 = i > 0 ? queue[i - 1] : null;
    final p3 = i + 2 < queue.length ? queue[i + 2] : null;
    if (p0 != null &&
        p3 != null &&
        (b.speed ?? double.infinity) >= _stationarySpeedMps) {
      final spline =
          _catmullRom(p0.pos, a.pos, b.pos, p3.pos, t, a.pos.latitude);
      if (spline != null) {
        if (!slowFix) {
          _steerHeading(p, spline.bearing, dtMs, b.ts);
        }
        return spline.pos;
      }
    }

    // ── Tier 3: straight chord ──
    final pos = LatLng(
      latitude: a.pos.latitude + (b.pos.latitude - a.pos.latitude) * t,
      longitude: a.pos.longitude + (b.pos.longitude - a.pos.longitude) * t,
    );
    if (!slowFix && _distanceMeters(a.pos, b.pos) >= _minBearingSegmentM) {
      _steerHeading(p, _bearingDegrees(a.pos, b.pos), dtMs, b.ts);
    }
    return pos;
  }

  /// Project [fix] onto the playback's guide, caching per guide version.
  /// Applies the monotonic window, updates the confirmed progress, and
  /// drives the off-route hysteresis. Returns the distance-along-path or
  /// null when the fix doesn't sit on the guide.
  double? _projectedS(_TimedFix fix, _DriverPlayback p) {
    final guide = p.guide;
    if (guide == null) return null;

    if (fix.cachedVersion != p.guideVersion) {
      // Windowed, monotonic search anchored at the last confirmed progress
      // — a global scan can snap to the RETURN leg of an out-and-back
      // street. While off-route we scan the whole path so a rejoin
      // anywhere can be found.
      double? from;
      double? to;
      if (p.guideActive && p.lastConfirmedS != null) {
        from = p.lastConfirmedS! - _guideBacktrackM;
        to = p.lastConfirmedS! + _guideMaxAdvanceM;
      }
      final proj = guide.project(fix.pos, windowStartS: from, windowEndS: to);
      fix.cachedVersion = p.guideVersion;

      // On-route within the perpendicular gate, OR clamped just behind the
      // path start within the resnap band AND colinear with the road — the
      // latter is a fix bracketing a playhead a beat behind a freshly-fetched
      // guide's origin, not a divergence. The perp guard rejects a fix off to
      // the SIDE near the start. Without this, every guide refresh at speed
      // latched.
      final onRoute = proj.distM <= _maxGuideSnapM ||
          (proj.s <= 1.0 &&
              proj.distM <= _guideResnapM &&
              guide.startPerpDist(fix.pos) <= _maxGuideSnapM);
      if (onRoute) {
        fix.cachedS = proj.s;
        p.onGuideStreak++;
        p.offGuideStreak = 0;
        p.lastConfirmedS = max(p.lastConfirmedS ?? proj.s, proj.s);
        if (!p.guideActive && p.onGuideStreak >= _guideHysteresisFixes) {
          p.guideActive = true;
          AppLogger.map('🛣️ ${p.driverId} back on route');
        }
      } else {
        fix.cachedS = null;
        p.offGuideStreak++;
        p.onGuideStreak = 0;
        if (p.guideActive && p.offGuideStreak >= _guideHysteresisFixes) {
          p.guideActive = false;
          AppLogger.map(
            '🛣️ ${p.driverId} off route '
            '(${proj.distM.toStringAsFixed(0)}m) — requesting refetch',
          );
          onOffRoute?.call(p.driverId);
        }
      }
    }
    return fix.cachedS;
  }

  /// Rotate the displayed heading toward [target], shortest arc, capped
  /// turn rate. A target flip > [_reversalCommitDeg] must persist into a
  /// NEWER fix before the marker commits to the turn — single reversed
  /// fixes (multipath) otherwise cause mid-block pirouettes.
  void _steerHeading(
      _DriverPlayback p, double target, double dtMs, double segEndTs) {
    final current = p.displayedHeading ?? target;
    var delta = target - current;
    if (delta > 180) delta -= 360;
    if (delta < -180) delta += 360;

    if (delta.abs() > _reversalCommitDeg) {
      if (!p.reversalCommitted) {
        if (p.reversalSeenAtTs == null) {
          p.reversalSeenAtTs = segEndTs;
          return; // hold heading — might be one bad fix
        }
        if (segEndTs <= p.reversalSeenAtTs!) {
          return; // still the same fix — keep holding
        }
        p.reversalCommitted = true; // persisted — it's a real turn
      }
    } else {
      p.reversalCommitted = false;
      p.reversalSeenAtTs = null;
    }

    final maxStep = _maxTurnDegPerMs * max(dtMs, 1.0);
    p.displayedHeading =
        (current + delta.clamp(-maxStep, maxStep) + 360) % 360;
  }

  /// Centripetal (α = 0.5) Catmull-Rom through P0..P3 evaluated at [t]
  /// within the P1→P2 segment, in a locally-flat meters frame. Returns
  /// null on degenerate knot spacing (caller falls back to lerp).
  ({LatLng pos, double bearing})? _catmullRom(
    LatLng p0,
    LatLng p1,
    LatLng p2,
    LatLng p3,
    double t,
    double refLat,
  ) {
    final cosLat = cos(refLat * pi / 180);
    const mPerDegLat = 110540.0;
    final mPerDegLng = 111320.0 * cosLat;

    // Meters frame relative to p1.
    ({double x, double y}) toM(LatLng pt) => (
          x: (pt.longitude - p1.longitude) * mPerDegLng,
          y: (pt.latitude - p1.latitude) * mPerDegLat,
        );
    final v0 = toM(p0), v1 = toM(p1), v2 = toM(p2), v3 = toM(p3);

    double d(({double x, double y}) a, ({double x, double y}) b) =>
        sqrt((b.x - a.x) * (b.x - a.x) + (b.y - a.y) * (b.y - a.y));

    // Centripetal knots: t_{i+1} = t_i + dist^0.5.
    final t0 = 0.0;
    final t1 = t0 + sqrt(d(v0, v1));
    final t2 = t1 + sqrt(d(v1, v2));
    final t3 = t2 + sqrt(d(v2, v3));
    if (t1 - t0 < 1e-3 || t2 - t1 < 1e-3 || t3 - t2 < 1e-3) {
      return null; // coincident knots — spline is ill-conditioned
    }

    ({double x, double y}) eval(double u) {
      ({double x, double y}) lerp(
              ({double x, double y}) a, ({double x, double y}) b, double w) =>
          (x: a.x + (b.x - a.x) * w, y: a.y + (b.y - a.y) * w);
      final a1 = lerp(v0, v1, (u - t0) / (t1 - t0));
      final a2 = lerp(v1, v2, (u - t1) / (t2 - t1));
      final a3 = lerp(v2, v3, (u - t2) / (t3 - t2));
      final b1 = lerp(a1, a2, (u - t0) / (t2 - t0));
      final b2 = lerp(a2, a3, (u - t1) / (t3 - t1));
      return lerp(b1, b2, (u - t1) / (t2 - t1));
    }

    final u = t1 + (t2 - t1) * t;
    final c = eval(u);
    // Tangent via a small forward sample for the bearing.
    final du = (t2 - t1) * 0.02;
    final cAhead = eval(min(u + du, t2));
    final dx = cAhead.x - c.x;
    final dy = cAhead.y - c.y;
    final bearing = dx.abs() < 1e-6 && dy.abs() < 1e-6
        ? _bearingDegrees(p1, p2)
        : (atan2(dx, dy) * 180 / pi + 360) % 360;

    return (
      pos: LatLng(
        latitude: p1.latitude + c.y / mPerDegLat,
        longitude: p1.longitude + c.x / mPerDegLng,
      ),
      bearing: bearing,
    );
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
  _DriverPlayback(this.driverId);

  final String driverId;
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

  /// Furthest confirmed distance along the guide — anchors the monotonic
  /// projection window.
  double? lastConfirmedS;

  /// EMA of the device-time gap between distinct fixes (ms). Null until two
  /// fixes have arrived. Drives the adaptive playhead lag.
  double? avgFixIntervalMs;

  /// Playhead lag target for this driver: ~1.25× the measured fix interval
  /// (reliable WS transport spaces fixes rather than dropping them, so the
  /// buffer only needs to cover the interval plus jitter — not the 2× a
  /// lossy channel demands), clamped to [_targetLagMs, _maxTargetLagMs].
  /// A clean ~1s or steady ~3s stream stays at the floor; only a genuinely
  /// slow/quantized feed widens the buffer to absorb its multi-second steps.
  double get targetLagMs {
    final avg = avgFixIntervalMs;
    // The floor already covers a clean ≤~3s stream with runway to spare;
    // only a genuinely slow/quantized feed (interval above the floor) needs
    // a wider buffer, so normal cadences render exactly as before.
    if (avg == null || avg <= MarkerAnimationService._targetLagMs) {
      return MarkerAnimationService._targetLagMs;
    }
    return (avg * 1.25)
        .clamp(MarkerAnimationService._targetLagMs,
            MarkerAnimationService._maxTargetLagMs)
        .toDouble();
  }

  /// Off-route hysteresis state.
  bool guideActive = false;
  int onGuideStreak = 0;
  int offGuideStreak = 0;

  /// Suspected-reversal (U-turn) commit state for heading steering.
  double? reversalSeenAtTs;
  bool reversalCommitted = false;

  /// Wall-time (ms) the playhead has been parked at the newest fix, capped
  /// at [_deadReckonMaxMs]. Keeps the render loop alive while dead-reckoning
  /// forward on the guide, then lets it idle.
  double underrunMs = 0;

  /// Furthest guide distance the marker has actually been RENDERED at (this
  /// guide version). Dead-reckoning can push the marker a little past the
  /// last real fix; when a delayed fix then lands behind that (driver was
  /// decelerating), the on-guide render is clamped forward to here so the
  /// marker HOLDS instead of rewinding. Reset on guide swap / teleport.
  double? renderedGuideS;

  bool get hasRunway =>
      queue.isNotEmpty &&
      playheadTs != null &&
      (playheadTs! < queue.last.ts ||
          (underrunMs > 0 && underrunMs < MarkerAnimationService._deadReckonMaxMs));
}

/// A GPS fix with its device-side timestamp (ms), reported speed (m/s),
/// and a cached projection onto the current guide path.
class _TimedFix {
  final LatLng pos;
  final double ts;
  final double? speed;

  /// Distance along the guide path at the nearest point, or null when the
  /// fix was too far from the path. Valid only for [cachedVersion].
  double? cachedS;
  int cachedVersion = -1;

  _TimedFix({required this.pos, required this.ts, this.speed});
}

/// A polyline with precomputed cumulative lengths, supporting (optionally
/// windowed) projection of a point onto it and lookup of the point/bearing
/// at a distance along it. Uses a locally-flat (equirectangular)
/// approximation — fine at route scale, cheap per projection.
class _GuidePath {
  final List<LatLng> points;
  final List<double> cum; // cumulative meters; cum[0] = 0

  _GuidePath(this.points) : cum = List.filled(points.length, 0) {
    for (var i = 1; i < points.length; i++) {
      cum[i] = cum[i - 1] +
          MarkerAnimationService._distanceMeters(points[i - 1], points[i]);
    }
  }

  double get length => cum.last;

  /// Nearest point on the path to [pt]: distance-along-path and offset.
  /// When [windowStartS]/[windowEndS] are given, only segments overlapping
  /// that arc-length window are considered.
  ({double s, double distM}) project(
    LatLng pt, {
    double? windowStartS,
    double? windowEndS,
  }) {
    final cosLat = cos(pt.latitude * pi / 180);
    const mPerDegLat = 110540.0;
    final mPerDegLng = 111320.0 * cosLat;

    var bestS = 0.0;
    var bestDist = double.infinity;

    var first = 0;
    if (windowStartS != null && windowStartS > 0) {
      first = _segmentIndexFor(windowStartS);
    }

    for (var i = first; i < points.length - 1; i++) {
      if (windowEndS != null && cum[i] > windowEndS) break;

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

  /// Perpendicular distance (m) from [pt] to the INFINITE line through the
  /// first segment. Distinguishes a point behind the start but ON the road
  /// (small — the resnap band should keep it) from one off to the SIDE near
  /// the start (large — a real divergence the band must not swallow).
  double startPerpDist(LatLng pt) {
    if (points.length < 2) return double.infinity;
    final cosLat = cos(pt.latitude * pi / 180);
    const mPerDegLat = 110540.0;
    final mPerDegLng = 111320.0 * cosLat;
    final ax = (points[0].longitude - pt.longitude) * mPerDegLng;
    final ay = (points[0].latitude - pt.latitude) * mPerDegLat;
    final bx = (points[1].longitude - pt.longitude) * mPerDegLng;
    final by = (points[1].latitude - pt.latitude) * mPerDegLat;
    final dx = bx - ax, dy = by - ay;
    final segLenSq = dx * dx + dy * dy;
    if (segLenSq == 0) return sqrt(ax * ax + ay * ay);
    final t = -(ax * dx + ay * dy) / segLenSq; // unclamped: line, not segment
    final px = ax + dx * t, py = ay + dy * t;
    return sqrt(px * px + py * py);
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
