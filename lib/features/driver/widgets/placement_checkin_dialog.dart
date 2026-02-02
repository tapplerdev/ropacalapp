import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:ropacalapp/core/utils/app_logger.dart';
import 'package:ropacalapp/models/route_task.dart';
import 'package:ropacalapp/core/services/cloudinary_service.dart';
import 'package:ropacalapp/providers/shift_provider.dart';
import 'package:ropacalapp/core/theme/app_colors.dart';

/// Dialog for placing a new bin at a potential location
///
/// Displayed when driver arrives at placement location (within 100m geofence)
/// Requires photo capture (mandatory) and allows reporting location suitability issues
class PlacementCheckinDialog extends HookConsumerWidget {
  final RouteTask task;
  final String shiftBinId;
  final VoidCallback? onPlacementComplete;

  const PlacementCheckinDialog({
    required this.task,
    required this.shiftBinId,
    this.onPlacementComplete,
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final photoFile = useState<File?>(null);
    final hasLimitedAccess = useState(false);
    final notIdealLocation = useState(false);
    final notesController = useTextEditingController();
    final isSubmitting = useState(false);

    Future<void> takePhoto() async {
      try {
        final picker = ImagePicker();
        final image = await picker.pickImage(
          source: ImageSource.camera,
          imageQuality: 80,
          maxWidth: 1920,
        );

        if (image != null) {
          photoFile.value = File(image.path);
          AppLogger.general('📸 Placement photo captured: ${image.path}');
        }
      } catch (e) {
        AppLogger.general('❌ Error taking photo: $e', level: AppLogger.error);
        EasyLoading.showError('Failed to take photo');
      }
    }

    Future<void> selectFromGallery() async {
      try {
        final picker = ImagePicker();
        final image = await picker.pickImage(
          source: ImageSource.gallery,
          imageQuality: 80,
          maxWidth: 1920,
        );

        if (image != null) {
          photoFile.value = File(image.path);
          AppLogger.general('📸 Placement photo selected from gallery: ${image.path}');
        }
      } catch (e) {
        AppLogger.general('❌ Error selecting photo: $e', level: AppLogger.error);
        EasyLoading.showError('Failed to select photo');
      }
    }

    Future<void> handlePlacement() async {
      if (photoFile.value == null) {
        EasyLoading.showError('Please take a photo of the placement location');
        return;
      }

      try {
        isSubmitting.value = true;
        EasyLoading.show(status: 'Uploading photo...');

        // Upload photo to Cloudinary
        final cloudinaryService = CloudinaryService();
        await cloudinaryService.initialize();
        final photoUrl = await cloudinaryService.uploadImage(photoFile.value!);

        AppLogger.general('✅ Placement photo uploaded: $photoUrl');

        EasyLoading.show(status: 'Placing new bin...');

        // Call completeBin API with placement details
        // For placements: no fill percentage (new empty bin), photo required
        final hasAnyIssue = hasLimitedAccess.value || notIdealLocation.value;
        String? incidentType;
        if (hasAnyIssue) {
          incidentType = 'inaccessible'; // Location suitability issues map to inaccessible
        }

        await ref.read(shiftNotifierProvider.notifier).completeTask(
          shiftBinId,
          task.binId ?? '', // May be empty/null for placements
          null, // No fill percentage for new bins (backend will set to 0)
          photoUrl: photoUrl,
          hasIncident: hasAnyIssue,
          incidentType: incidentType,
          incidentDescription: notesController.text.isEmpty
              ? null
              : notesController.text,
          moveRequestId: null, // Not a move request
        );

        AppLogger.general('✅ Placement completed successfully');

        EasyLoading.dismiss();

        if (context.mounted) {
          Navigator.of(context).pop();
          onPlacementComplete?.call();

          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '✅ Bin #${task.newBinNumber} placed successfully',
              ),
              backgroundColor: AppColors.primaryGreen,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      } catch (e) {
        AppLogger.general('❌ Error completing placement: $e',
            level: AppLogger.error);
        isSubmitting.value = false;
        EasyLoading.dismiss();

        if (context.mounted) {
          EasyLoading.showError('Failed to complete placement');
        }
      }
    }

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.add_location,
                      size: 32,
                      color: Colors.orange.shade600,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '📍 Place New Bin',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Bin #${task.newBinNumber ?? '?'}',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.orange.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Location info
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.location_on,
                      color: Colors.orange.shade600,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        task.address ?? 'Placement Location',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Photo section
              Text(
                'Placement Photo (Required)',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade800,
                ),
              ),
              const SizedBox(height: 12),

              if (photoFile.value == null) ...[
                // Photo capture buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: isSubmitting.value ? null : takePhoto,
                        icon: const Icon(Icons.camera_alt),
                        label: const Text('Take Photo'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: BorderSide(color: Colors.grey.shade300),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: isSubmitting.value ? null : selectFromGallery,
                        icon: const Icon(Icons.photo_library),
                        label: const Text('Gallery'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: BorderSide(color: Colors.grey.shade300),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ] else ...[
                // Photo preview
                Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(
                        photoFile.value!,
                        height: 200,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: CircleAvatar(
                        backgroundColor: Colors.black54,
                        child: IconButton(
                          icon: const Icon(Icons.close, color: Colors.white),
                          onPressed: isSubmitting.value
                              ? null
                              : () => photoFile.value = null,
                        ),
                      ),
                    ),
                  ],
                ),
              ],

              const SizedBox(height: 24),

              // Location suitability issues
              Text(
                'Location Suitability',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade800,
                ),
              ),
              const SizedBox(height: 12),

              CheckboxListTile(
                title: const Text('Limited access'),
                subtitle: const Text(
                  'Difficult to reach or restricted access',
                  style: TextStyle(fontSize: 12),
                ),
                value: hasLimitedAccess.value,
                onChanged: isSubmitting.value
                    ? null
                    : (val) => hasLimitedAccess.value = val ?? false,
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
                activeColor: Colors.orange.shade600,
              ),

              CheckboxListTile(
                title: const Text('Not ideal location'),
                subtitle: const Text(
                  'Location not suitable for bin placement',
                  style: TextStyle(fontSize: 12),
                ),
                value: notIdealLocation.value,
                onChanged: isSubmitting.value
                    ? null
                    : (val) => notIdealLocation.value = val ?? false,
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
                activeColor: Colors.orange.shade600,
              ),

              const SizedBox(height: 16),

              // Optional notes
              TextField(
                controller: notesController,
                maxLines: 3,
                enabled: !isSubmitting.value,
                decoration: InputDecoration(
                  labelText: 'Notes (optional)',
                  hintText: 'Add any additional details about the placement...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                ),
              ),

              const SizedBox(height: 24),

              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: isSubmitting.value
                          ? null
                          : () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: BorderSide(color: Colors.grey.shade300),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Cancel',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed:
                          isSubmitting.value || photoFile.value == null
                              ? null
                              : handlePlacement,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: Colors.orange.shade600,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: Colors.grey.shade300,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Confirm Placement',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
