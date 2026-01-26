import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:ropacalapp/core/theme/app_colors.dart';
import 'package:ropacalapp/core/utils/app_logger.dart';
import 'package:ropacalapp/models/route_bin.dart';
import 'package:ropacalapp/core/services/cloudinary_service.dart';
import 'package:ropacalapp/providers/cloudinary_provider.dart';

/// Dialog for picking up a bin for relocation
///
/// Displayed when driver arrives at pickup location (within 100m geofence)
class MoveRequestPickupDialog extends HookConsumerWidget {
  final RouteBinWithDetails bin;
  final VoidCallback onPickupComplete;

  const MoveRequestPickupDialog({
    required this.bin,
    required this.onPickupComplete,
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final photoFile = useState<File?>(null);
    final hasDamage = useState(false);
    final cannotLocate = useState(false);
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
          AppLogger.general('📸 Pickup photo captured: ${image.path}');
        }
      } catch (e) {
        AppLogger.general('❌ Error taking photo: $e', level: AppLogger.error);
        EasyLoading.showError('Failed to take photo');
      }
    }

    Future<void> handlePickup() async {
      if (photoFile.value == null) {
        EasyLoading.showError('Please take a photo of the bin');
        return;
      }

      try {
        isSubmitting.value = true;
        EasyLoading.show(status: 'Uploading photo...');

        // Upload photo to Cloudinary
        final cloudinaryService = ref.read(cloudinaryProvider);
        final photoUrl = await cloudinaryService.uploadImage(photoFile.value!);

        AppLogger.general('✅ Pickup photo uploaded: $photoUrl');

        EasyLoading.show(status: 'Completing pickup...');

        // TODO: Call backend API to complete pickup with photoUrl, hasDamage, notes
        // For now, just call the completion callback
        onPickupComplete();

        EasyLoading.dismiss();
        if (context.mounted) {
          Navigator.of(context).pop();
        }
      } catch (e) {
        AppLogger.general(
          '❌ Error completing pickup: $e',
          level: AppLogger.error,
        );
        EasyLoading.showError('Failed to complete pickup');
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
                  color: Colors.orange.shade600,
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
                          Icons.upload,
                          color: Colors.white,
                          size: 32,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '🚚 Pick Up Bin',
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
                              'Current Location: ${bin.currentStreet}, ${bin.city}',
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
                                : Colors.orange.shade600,
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

                    // Bin Condition checkboxes
                    Text(
                      'Bin Condition:',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(height: 8),

                    CheckboxListTile(
                      value: hasDamage.value,
                      onChanged: isSubmitting.value
                          ? null
                          : (value) => hasDamage.value = value ?? false,
                      title: Text('Bin is damaged'),
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      activeColor: Colors.orange.shade600,
                    ),

                    CheckboxListTile(
                      value: cannotLocate.value,
                      onChanged: isSubmitting.value
                          ? null
                          : (value) => cannotLocate.value = value ?? false,
                      title: Text('Cannot locate bin'),
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      activeColor: Colors.orange.shade600,
                    ),

                    const SizedBox(height: 12),

                    // Notes (optional)
                    TextField(
                      controller: notesController,
                      maxLines: 2,
                      enabled: !isSubmitting.value,
                      decoration: InputDecoration(
                        labelText: 'Notes (optional)',
                        hintText: 'Any issues or observations...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Confirm button
                    ElevatedButton(
                      onPressed: isSubmitting.value ? null : handlePickup,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange.shade600,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Confirm Pickup',
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
