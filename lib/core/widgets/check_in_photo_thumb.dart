import 'package:flutter/material.dart';

/// A labeled check-in photo thumbnail — used for the before/after pair on
/// completed collection tasks (route detail + manager shift detail).
class CheckInPhotoThumb extends StatelessWidget {
  final String url;
  final String label;
  final Color labelColor;
  final VoidCallback onTap;
  final double height;

  const CheckInPhotoThumb({
    super.key,
    required this.url,
    required this.label,
    required this.labelColor,
    required this.onTap,
    this.height = 140,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Stack(
          children: [
            Image.network(
              url,
              height: height,
              width: double.infinity,
              fit: BoxFit.cover,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Container(
                  height: height,
                  color: Colors.grey.shade200,
                  child: const Center(
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                );
              },
              errorBuilder: (context, error, stack) {
                return Container(
                  height: height,
                  color: Colors.grey.shade100,
                  child: Center(
                    child: Icon(
                      Icons.broken_image_outlined,
                      size: 18,
                      color: Colors.grey.shade400,
                    ),
                  ),
                );
              },
            ),
            Positioned(
              left: 6,
              bottom: 6,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 6,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: labelColor,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
