import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:ropacalapp/core/utils/app_logger.dart';
import 'package:ropacalapp/models/route_bin.dart';
import 'package:ropacalapp/core/services/cloudinary_service.dart';
import 'package:ropacalapp/providers/shift_provider.dart';

/// Dialog for placing a bin at new location
///
/// Displayed when driver arrives at drop-off location (within 100m geofence)
class MoveRequestPlacementDialog extends HookConsumerWidget {
  final RouteBin bin;
  final VoidCallback onPlacementComplete;

  const MoveRequestPlacementDialog({
    required this.bin,
    required this.onPlacementComplete,
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

    Future<void> handlePlacement() async {
      if (photoFile.value == null) {
        EasyLoading.showError('Please take a photo of the placement');
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

        EasyLoading.show(status: 'Completing placement...');

        // Call completeBin API with placement details
        // For move request dropoffs, we don't update fill percentage (set to null)
        // and we pass the move_request_id to link this check to the move request
        final hasAnyIssue = hasLimitedAccess.value || notIdealLocation.value;
        String? incidentType;
        if (hasAnyIssue) {
          if (hasLimitedAccess.value) {
            incidentType = 'inaccessible';
          } else if (notIdealLocation.value) {
            incidentType = 'inaccessible'; // Not ideal location maps to inaccessible
          }
        }

        await ref.read(shiftNotifierProvider.notifier).completeBin(
          bin.binId,
          null, // No fill percentage for move request dropoffs
          photoUrl: photoUrl,
          hasIncident: hasAnyIssue,
          incidentType: incidentType,
          incidentDescription: notesController.text.isEmpty
              ? null
              : notesController.text,
          moveRequestId: bin.moveRequestId,
        );

        AppLogger.general('✅ Placement completed successfully');
        onPlacementComplete();

        EasyLoading.dismiss();
        if (context.mounted) {
          Navigator.of(context).pop();
        }
      } catch (e) {
        AppLogger.general(
          '❌ Error completing placement: $e',
          level: AppLogger.error,
        );
        EasyLoading.showError('Failed to complete placement');
      } finally {
        isSubmitting.value = false;
      }
    }

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.green.shade600,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.place,
                          color: Colors.white,
                          size: 32,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '📍 Place Bin',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'Bin #${bin.binNumber}',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.9),
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.location_on,
                            color: Colors.white,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Placement Location: ${bin.currentStreet}, ${bin.city}',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Content
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Photo capture
                    GestureDetector(
                      onTap: isSubmitting.value ? null : takePhoto,
                      child: Container(
                        height: 200,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: photoFile.value == null
                                ? Colors.grey.shade300
                                : Colors.green.shade600,
                            width: 2,
                          ),
                        ),
                        child: photoFile.value == null
                            ? Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.camera_alt,
                                    size: 48,
                                    color: Colors.grey.shade400,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Tap to take photo',
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: 16,
                                    ),
                                  ),
                                  Text(
                                    'Show bin placement',
                                    style: TextStyle(
                                      color: Colors.grey.shade500,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              )
                            : ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: Image.file(
                                  photoFile.value!,
                                  fit: BoxFit.cover,
                                ),
                              ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Placement issues checkboxes
                    Text(
                      'Issues (if any):',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(height: 8),

                    CheckboxListTile(
                      value: hasLimitedAccess.value,
                      onChanged: isSubmitting.value
                          ? null
                          : (value) => hasLimitedAccess.value = value ?? false,
                      title: Text('Limited access'),
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      activeColor: Colors.green.shade600,
                    ),

                    CheckboxListTile(
                      value: notIdealLocation.value,
                      onChanged: isSubmitting.value
                          ? null
                          : (value) => notIdealLocation.value = value ?? false,
                      title: Text('Not ideal location'),
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      activeColor: Colors.green.shade600,
                    ),

                    const SizedBox(height: 12),

                    // Placement notes
                    TextField(
                      controller: notesController,
                      maxLines: 3,
                      enabled: !isSubmitting.value,
                      decoration: InputDecoration(
                        labelText: 'Placement Notes (optional)',
                        hintText:
                            'e.g., Placed near front entrance, next to garage door...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Confirm button
                    ElevatedButton(
                      onPressed: isSubmitting.value ? null : handlePlacement,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade600,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Confirm Placement',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),

                    const SizedBox(height: 8),

                    // Cancel button
                    TextButton(
                      onPressed: isSubmitting.value
                          ? null
                          : () => Navigator.of(context).pop(),
                      child: Text(
                        'Cancel',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
