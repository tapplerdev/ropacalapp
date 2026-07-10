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

/// Compact dialog for placing a bin: either a brand-new bin (potential
/// location — the driver enters its number) or a specific existing bin from
/// the warehouse (redeployment — the number is known and shown read-only).
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
    final binNumberController = useTextEditingController();
    final isSubmitting = useState(false);
    final isRedeploy = task.isRedeployPlacement;

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
      // Redeployments place a specific known bin — its number rides on the
      // task. New-bin placements require the driver to enter the number.
      int? binNumber = task.binNumber;
      if (!isRedeploy) {
        if (binNumberController.text.trim().isEmpty) {
          EasyLoading.showError('Please enter a bin number');
          return;
        }

        binNumber = int.tryParse(binNumberController.text.trim());
        if (binNumber == null || binNumber <= 0) {
          EasyLoading.showError('Please enter a valid bin number');
          return;
        }
      }

      if (photoFile.value == null) {
        EasyLoading.showError('Please take a photo');
        return;
      }

      try {
        isSubmitting.value = true;
        EasyLoading.show(status: 'Uploading...');

        final cloudinaryService = CloudinaryService();
        await cloudinaryService.initialize();
        final photoUrl = await cloudinaryService.uploadImage(photoFile.value!);

        EasyLoading.show(status: 'Placing bin...');

        await ref.read(shiftNotifierProvider.notifier).completeTask(
              shiftBinId,
              task.binId ?? '',
              null,
              photoUrl: photoUrl,
              newBinNumber: binNumber,
              hasIncident: false,
              incidentType: null,
              incidentDescription: null,
              moveRequestId: isRedeploy ? task.moveRequestId : null,
            );

        EasyLoading.dismiss();

        if (context.mounted) {
          Navigator.of(context).pop();
          onPlacementComplete?.call();

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(binNumber != null
                  ? '✅ Bin #$binNumber placed successfully'
                  : '✅ Bin placed successfully'),
              backgroundColor: AppColors.primaryGreen,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } catch (e) {
        AppLogger.general('❌ Error: $e', level: AppLogger.error);
        isSubmitting.value = false;
        EasyLoading.dismiss();

        if (context.mounted) {
          EasyLoading.showError('Failed to complete placement');
        }
      }
    }

    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        constraints: const BoxConstraints(maxHeight: 580),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header — teal truck for a redeployment (placing a specific
            // warehouse bin), orange pin for installing a brand-new bin.
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isRedeploy
                        ? Colors.teal.shade100
                        : Colors.orange.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    isRedeploy ? Icons.local_shipping : Icons.add_location,
                    size: 28,
                    color: isRedeploy
                        ? Colors.teal.shade700
                        : Colors.orange.shade700,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    isRedeploy
                        ? (task.binNumber != null
                            ? 'Place Bin #${task.binNumber}'
                            : 'Place Bin')
                        : 'Place New Bin',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Bin number: known for redeployments (read-only card), entered
            // by the driver for new-bin placements.
            if (isRedeploy)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: Colors.teal.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.teal.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.tag, size: 20, color: Colors.teal.shade700),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            task.binNumber != null
                                ? 'Bin #${task.binNumber}'
                                : 'Warehouse bin',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'From warehouse — place this bin here',
                            style: TextStyle(
                              fontSize: 10.5,
                              color: Colors.teal.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              )
            else
              TextField(
                controller: binNumberController,
                enabled: !isSubmitting.value,
                keyboardType: TextInputType.number,
                autofocus: true,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                decoration: InputDecoration(
                  labelText: 'Bin Number *',
                  hintText: 'Enter bin number',
                  prefixIcon: Icon(Icons.tag, color: AppColors.primaryGreen),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: AppColors.primaryGreen,
                      width: 2,
                    ),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
              ),

            const SizedBox(height: 16),

            // Photo section
            if (photoFile.value == null)
              InkWell(
                onTap: isSubmitting.value ? null : takePhoto,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  height: 180,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.grey.shade300,
                      width: 2,
                      style: BorderStyle.solid,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade100,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.camera_alt,
                          size: 36,
                          color: Colors.orange.shade700,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Take Photo *',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade800,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(
                      photoFile.value!,
                      height: 180,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed:
                            isSubmitting.value ? null : () => photoFile.value = null,
                      ),
                    ),
                  ),
                ],
              ),

            const SizedBox(height: 20),

            // Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: isSubmitting.value
                        ? null
                        : () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: BorderSide(color: Colors.grey.shade300, width: 1.5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: isSubmitting.value ? null : handlePlacement,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      backgroundColor: AppColors.primaryGreen,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: Colors.grey.shade300,
                      elevation: 2,
                      shadowColor: AppColors.primaryGreen.withOpacity(0.3),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: isSubmitting.value
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text(
                            'Confirm Placement',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
