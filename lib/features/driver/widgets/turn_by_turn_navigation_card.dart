import 'package:flutter/material.dart';
import 'package:ropacalapp/core/theme/app_colors.dart';
import 'package:ropacalapp/models/route_step.dart';
import 'package:ropacalapp/core/services/geofence_service.dart';

/// Turn-by-turn navigation card showing current instruction
/// Displays next maneuver, distance, and ETA
class TurnByTurnNavigationCard extends StatelessWidget {
  final RouteStep? currentStep;
  final double distanceToNextManeuver; // meters
  final Duration? estimatedTimeRemaining;
  final double? totalDistanceRemaining; // meters

  const TurnByTurnNavigationCard({
    super.key,
    this.currentStep,
    required this.distanceToNextManeuver,
    this.estimatedTimeRemaining,
    this.totalDistanceRemaining,
  });

  @override
  Widget build(BuildContext context) {
    if (currentStep == null) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Main navigation instruction
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Maneuver icon
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: AppColors.primaryGreen.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    _getManeuverIcon(
                      currentStep!.maneuverType,
                      currentStep!.modifier,
                    ),
                    size: 30,
                    color: AppColors.primaryGreen,
                  ),
                ),
                const SizedBox(width: 14),

                // Instruction text
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Distance to next maneuver
                      Text(
                        _formatDistance(distanceToNextManeuver),
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 2),

                      // Instruction
                      Text(
                        currentStep!.instruction,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.black54,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ETA and distance footer
          if (estimatedTimeRemaining != null || totalDistanceRemaining != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // ETA
                  if (estimatedTimeRemaining != null)
                    Row(
                      children: [
                        const Icon(
                          Icons.access_time,
                          size: 18,
                          color: Colors.black54,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _formatDuration(estimatedTimeRemaining!),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),

                  // Total distance remaining
                  if (totalDistanceRemaining != null)
                    Row(
                      children: [
                        const Icon(
                          Icons.straighten,
                          size: 18,
                          color: Colors.black54,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _formatDistance(totalDistanceRemaining!),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  /// Get icon for maneuver type
  IconData _getManeuverIcon(String maneuverType, String? modifier) {
    final type = maneuverType.toLowerCase();
    final mod = modifier?.toLowerCase();

    // Turn maneuvers
    if (type.contains('turn')) {
      if (mod?.contains('left') == true) {
        if (mod?.contains('slight') == true) return Icons.turn_slight_left;
        if (mod?.contains('sharp') == true) return Icons.turn_sharp_left;
        return Icons.turn_left;
      }
      if (mod?.contains('right') == true) {
        if (mod?.contains('slight') == true) return Icons.turn_slight_right;
        if (mod?.contains('sharp') == true) return Icons.turn_sharp_right;
        return Icons.turn_right;
      }
    }

    // U-turn
    if (type.contains('uturn') || type.contains('u-turn')) {
      return Icons.u_turn_left;
    }

    // Roundabout
    if (type.contains('roundabout') || type.contains('rotary')) {
      return Icons.roundabout_left;
    }

    // Merge
    if (type.contains('merge')) {
      return Icons.merge;
    }

    // Arrival
    if (type.contains('arrive') || type.contains('destination')) {
      return Icons.flag;
    }

    // Default: continue straight
    return Icons.arrow_upward;
  }

  /// Format distance in meters to readable string (imperial units)
  /// Delegates to GeofenceService for consistent formatting
  String _formatDistance(double meters) {
    // Clamp to minimum of 0 to avoid negative distances
    final clampedMeters = meters.clamp(0.0, double.infinity);
    return GeofenceService.formatDistance(clampedMeters);
  }

  /// Format duration to readable string
  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);

    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else {
      return '${minutes}m';
    }
  }
}
