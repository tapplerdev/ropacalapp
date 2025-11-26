import 'package:flutter/material.dart';
import 'package:ropacalapp/core/utils/responsive_helper.dart';

class TabButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const TabButton({
    super.key,
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final responsive = ResponsiveHelper(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(responsive.borderRadius),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: responsive.tabButtonPadding),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).colorScheme.primaryContainer
              : Colors.grey[200],
          borderRadius: BorderRadius.circular(responsive.borderRadius),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: responsive.iconMedium,
              color: isSelected
                  ? Theme.of(context).colorScheme.primary
                  : Colors.grey[600],
            ),
            SizedBox(width: responsive.gapSmallMedium),
            Text(
              label,
              style: TextStyle(
                fontSize: responsive.fontSmall,
                color: isSelected
                    ? Theme.of(context).colorScheme.primary
                    : Colors.grey[600],
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
