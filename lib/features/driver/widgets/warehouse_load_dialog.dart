import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:ropacalapp/core/theme/app_colors.dart';

/// Shift-start prompt: "How many bins are already on your truck?"
///
/// Replaces the old yes/no "are the bins loaded?" question — a boolean couldn't
/// represent reality (e.g. an 11-placement route on an 8-bin truck), which fed
/// the optimizer an impossible initial load and crashed the solver. This asks
/// for the exact count, hard-capped at the truck's capacity.
///
/// Returns the count on truck (0..capacity), or `null` if cancelled.
/// `0` means "I'll load at the warehouse" — the route will include warehouse
/// pickups.
class WarehouseLoadDialog extends HookWidget {
  /// Bins this route needs the driver to place (placements + redeployments).
  final int binsNeeded;

  /// Truck bin capacity — the hard ceiling on how many can be loaded.
  final int capacity;

  const WarehouseLoadDialog({
    super.key,
    required this.binsNeeded,
    required this.capacity,
  });

  @override
  Widget build(BuildContext context) {
    final maxLoad = capacity < 0 ? 0 : capacity;
    // Default to 0 ("Start at Warehouse") — the SAFE option. The driver must
    // actively step up to assert bins are already on board, so a mis-tap can
    // never silently claim a full truck (which would skip the warehouse stop
    // and route them to place bins they may not have).
    final count = useState<int>(0);

    final fitsInOneLoad = binsNeeded <= maxLoad;
    final value = count.value;

    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
      child: Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withValues(alpha: 0.96),
                Colors.white.withValues(alpha: 0.90),
              ],
            ),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.3),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.blue.shade900.withValues(alpha: 0.12),
                blurRadius: 40,
                offset: const Offset(0, 20),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ── Header ──
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.blue.shade50,
                        Colors.blue.shade50.withValues(alpha: 0.5),
                      ],
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.blue.shade600, Colors.blue.shade400],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.blue.withValues(alpha: 0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Icon(Icons.local_shipping_rounded,
                            color: Colors.white, size: 28),
                      ),
                      const SizedBox(width: 16),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Load your truck',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                                letterSpacing: -0.5,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'How many bins are on board?',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.black54,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // ── Content ──
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
                  child: Column(
                    children: [
                      // Route needs info
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.inventory_2_outlined,
                                size: 20, color: Colors.blue.shade600),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text.rich(
                                TextSpan(
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey.shade800,
                                  ),
                                  children: [
                                    const TextSpan(text: 'This route needs '),
                                    TextSpan(
                                      text:
                                          '$binsNeeded bin${binsNeeded == 1 ? '' : 's'}',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w700),
                                    ),
                                    TextSpan(text: '.  Truck holds $maxLoad.'),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // ── Stepper ──
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _StepButton(
                            icon: Icons.remove_rounded,
                            enabled: value > 0,
                            onTap: () {
                              HapticFeedback.selectionClick();
                              count.value = (value - 1).clamp(0, maxLoad);
                            },
                          ),
                          SizedBox(
                            width: 120,
                            child: Column(
                              children: [
                                Text(
                                  '$value',
                                  style: const TextStyle(
                                    fontSize: 48,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                    height: 1.0,
                                  ),
                                ),
                                Text(
                                  'of $maxLoad',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey.shade500,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          _StepButton(
                            icon: Icons.add_rounded,
                            enabled: value < maxLoad,
                            onTap: () {
                              HapticFeedback.selectionClick();
                              count.value = (value + 1).clamp(0, maxLoad);
                            },
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Contextual hint
                      _HintBanner(
                        value: value,
                        binsNeeded: binsNeeded,
                        fitsInOneLoad: fitsInOneLoad,
                      ),

                      const SizedBox(height: 20),

                      // ── Buttons ──
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.of(context).pop(null),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.grey.shade700,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                                side: BorderSide(
                                    color: Colors.grey.shade300, width: 2),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              child: const Text(
                                'Cancel',
                                style: TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 2,
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    AppColors.primaryGreen,
                                    AppColors.primaryGreen
                                        .withValues(alpha: 0.85),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(14),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.primaryGreen
                                        .withValues(alpha: 0.4),
                                    blurRadius: 12,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                              ),
                              child: ElevatedButton(
                                onPressed: () =>
                                    Navigator.of(context).pop(value),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  shadowColor: Colors.transparent,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                                child: Text(
                                  value == 0 ? 'Start at Warehouse' : 'Confirm',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Round +/- stepper button.
class _StepButton extends StatelessWidget {
  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  const _StepButton({
    required this.icon,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: enabled ? onTap : null,
        customBorder: const CircleBorder(),
        child: Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: enabled ? Colors.blue.shade50 : Colors.grey.shade100,
            shape: BoxShape.circle,
            border: Border.all(
              color: enabled ? Colors.blue.shade200 : Colors.grey.shade200,
              width: 1.5,
            ),
          ),
          child: Icon(
            icon,
            size: 26,
            color: enabled ? Colors.blue.shade700 : Colors.grey.shade400,
          ),
        ),
      ),
    );
  }
}

/// Contextual line under the stepper explaining what the chosen count means.
class _HintBanner extends StatelessWidget {
  final int value;
  final int binsNeeded;
  final bool fitsInOneLoad;

  const _HintBanner({
    required this.value,
    required this.binsNeeded,
    required this.fitsInOneLoad,
  });

  @override
  Widget build(BuildContext context) {
    final String text;
    final IconData icon;
    final Color color;

    if (value == 0) {
      text = "You'll load bins at the warehouse first.";
      icon = Icons.warehouse_rounded;
      color = Colors.blue.shade700;
    } else if (value >= binsNeeded) {
      text = 'Fully loaded — straight to placements, no warehouse trip.';
      icon = Icons.check_circle_rounded;
      color = AppColors.primaryGreen;
    } else {
      text =
          "Loaded $value — you'll reload at the warehouse for the other ${binsNeeded - value}.";
      icon = Icons.info_rounded;
      color = Colors.orange.shade700;
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 13,
              color: color,
              fontWeight: FontWeight.w500,
              height: 1.3,
            ),
          ),
        ),
      ],
    );
  }
}
