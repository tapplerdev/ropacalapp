import 'package:flutter/material.dart';

/// Animated transition wrapper for shifting between empty state and active route
/// Uses Material Design 3 Fade Through pattern with scale
class AnimatedShiftTransition extends StatelessWidget {
  final bool hasActiveShift;
  final Widget emptyState;
  final Widget activeRouteCard;

  const AnimatedShiftTransition({
    super.key,
    required this.hasActiveShift,
    required this.emptyState,
    required this.activeRouteCard,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 750),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (Widget child, Animation<double> animation) {
        // Fade Through with Scale animation (Material Design 3)
        return FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            scale: Tween<double>(
              begin: 0.95,
              end: 1.0,
            ).animate(
              CurvedAnimation(
                parent: animation,
                curve: Curves.easeOutCubic,
              ),
            ),
            child: child,
          ),
        );
      },
      layoutBuilder: (Widget? currentChild, List<Widget> previousChildren) {
        return Stack(
          alignment: Alignment.topCenter,
          children: <Widget>[
            ...previousChildren,
            if (currentChild != null) currentChild,
          ],
        );
      },
      child: hasActiveShift
          ? KeyedSubtree(
              key: const ValueKey('active_route'),
              child: activeRouteCard,
            )
          : KeyedSubtree(
              key: const ValueKey('empty_state'),
              child: emptyState,
            ),
    );
  }
}

/// Extended version with slide animation option
class AnimatedShiftTransitionWithSlide extends StatelessWidget {
  final bool hasActiveShift;
  final Widget emptyState;
  final Widget activeRouteCard;
  final bool useSlideAnimation;

  const AnimatedShiftTransitionWithSlide({
    super.key,
    required this.hasActiveShift,
    required this.emptyState,
    required this.activeRouteCard,
    this.useSlideAnimation = false,
  });

  @override
  Widget build(BuildContext context) {
    if (!useSlideAnimation) {
      return AnimatedShiftTransition(
        hasActiveShift: hasActiveShift,
        emptyState: emptyState,
        activeRouteCard: activeRouteCard,
      );
    }

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 400),
      switchInCurve: Curves.easeOutQuart,
      switchOutCurve: Curves.easeInQuart,
      transitionBuilder: (Widget child, Animation<double> animation) {
        // Slide up + Fade animation (snappier)
        final offsetAnimation = Tween<Offset>(
          begin: const Offset(0.0, 0.08), // Start slightly below
          end: Offset.zero,
        ).animate(
          CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutQuart,
          ),
        );

        return SlideTransition(
          position: offsetAnimation,
          child: FadeTransition(
            opacity: animation,
            child: child,
          ),
        );
      },
      child: hasActiveShift
          ? KeyedSubtree(
              key: const ValueKey('active_route_slide'),
              child: activeRouteCard,
            )
          : KeyedSubtree(
              key: const ValueKey('empty_state_slide'),
              child: emptyState,
            ),
    );
  }
}
