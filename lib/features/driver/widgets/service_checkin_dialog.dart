import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:ropacalapp/core/services/cloudinary_service.dart';
import 'package:ropacalapp/core/theme/app_colors.dart';
import 'package:ropacalapp/core/utils/app_logger.dart';
import 'package:ropacalapp/models/route_task.dart';
import 'package:ropacalapp/providers/shift_provider.dart';

/// Check-in dialog for service tasks (custom one-off shifts)
/// Flow: Photo capture (required if photo_required) → Optional notes → Submit
class ServiceCheckinDialog extends HookConsumerWidget {
  final RouteTask task;
  final VoidCallback? onCompleted;

  const ServiceCheckinDialog({
    super.key,
    required this.task,
    this.onCompleted,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final capturedImage = useState<XFile?>(null);
    final isSubmitting = useState(false);
    final notesController = useTextEditingController();
    final showNotes = useState(false);

    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
      child: Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(
          horizontal: 16,
        ),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 500),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withValues(alpha: 0.95),
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
                color: AppColors.primaryGreen
                    .withValues(alpha: 0.1),
                blurRadius: 40,
                offset: const Offset(0, 20),
                spreadRadius: -5,
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                _ServiceHeader(task: task),

                // Content
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                  ),
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      // Task description
                      if (task.taskDescription != null) ...[
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius:
                                BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.blue.shade100,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Instructions',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.blue.shade700,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                task.taskDescription!,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.blue.shade900,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Location
                      if (task.address != null)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius:
                                BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.grey.shade200,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.location_on,
                                color: Colors.grey.shade600,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  task.address!,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color:
                                        Colors.grey.shade700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                      const SizedBox(height: 16),

                      // Photo capture section
                      _PhotoSection(
                        capturedImage: capturedImage,
                        isRequired: task.photoRequired,
                      ),

                      const SizedBox(height: 12),

                      // Notes toggle and field
                      if (!showNotes.value)
                        TextButton.icon(
                          onPressed: () =>
                              showNotes.value = true,
                          icon: Icon(
                            Icons.notes,
                            size: 18,
                            color: Colors.grey.shade600,
                          ),
                          label: Text(
                            'Add notes',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      if (showNotes.value)
                        TextField(
                          controller: notesController,
                          maxLines: 3,
                          textCapitalization:
                              TextCapitalization.sentences,
                          decoration: InputDecoration(
                            hintText:
                                'Add notes about this stop...',
                            border: OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: Colors.grey.shade300,
                              ),
                            ),
                            contentPadding:
                                const EdgeInsets.all(12),
                          ),
                        ),

                      const SizedBox(height: 20),
                    ],
                  ),
                ),

                // Action buttons
                _ActionButtons(
                  task: task,
                  capturedImage: capturedImage,
                  isSubmitting: isSubmitting,
                  notesController: notesController,
                  onCompleted: onCompleted,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ServiceHeader extends StatelessWidget {
  final RouteTask task;

  const _ServiceHeader({required this.task});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primaryGreen.withValues(alpha: 0.08),
            Colors.blue.withValues(alpha: 0.04),
          ],
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primaryGreen
                  .withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              Icons.assignment_outlined,
              size: 28,
              color: AppColors.primaryGreen,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task.taskLabel ?? 'Service Stop',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
                if (task.photoRequired)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Row(
                      children: [
                        Icon(
                          Icons.camera_alt,
                          size: 14,
                          color: Colors.orange.shade700,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Photo required',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.orange.shade700,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          // Close button
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.close,
                size: 20,
                color: Colors.grey.shade600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PhotoSection extends HookWidget {
  final ValueNotifier<XFile?> capturedImage;
  final bool isRequired;

  const _PhotoSection({
    required this.capturedImage,
    required this.isRequired,
  });

  @override
  Widget build(BuildContext context) {
    if (capturedImage.value != null) {
      return Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.file(
              File(capturedImage.value!.path),
              height: 180,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
          Positioned(
            top: 8,
            right: 8,
            child: GestureDetector(
              onTap: () => capturedImage.value = null,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.close,
                  color: Colors.white,
                  size: 18,
                ),
              ),
            ),
          ),
        ],
      );
    }

    return GestureDetector(
      onTap: () => _takePhoto(context),
      child: Container(
        height: 120,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isRequired
                ? AppColors.primaryGreen.withValues(alpha: 0.5)
                : Colors.grey.shade200,
            width: isRequired ? 1.5 : 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.camera_alt_outlined,
              size: 36,
              color: isRequired
                  ? AppColors.primaryGreen
                  : Colors.grey.shade400,
            ),
            const SizedBox(height: 8),
            Text(
              isRequired ? 'Take Photo (Required)' : 'Take Photo (Optional)',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: isRequired
                    ? AppColors.primaryGreen
                    : Colors.grey.shade500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _takePhoto(BuildContext context) async {
    final picker = ImagePicker();
    final image = await picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 80,
      maxWidth: 1920,
    );
    if (image != null) {
      capturedImage.value = image;
    }
  }
}

class _ActionButtons extends HookConsumerWidget {
  final RouteTask task;
  final ValueNotifier<XFile?> capturedImage;
  final ValueNotifier<bool> isSubmitting;
  final TextEditingController notesController;
  final VoidCallback? onCompleted;

  const _ActionButtons({
    required this.task,
    required this.capturedImage,
    required this.isSubmitting,
    required this.notesController,
    this.onCompleted,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final canSubmit = !isSubmitting.value &&
        (!task.photoRequired ||
            capturedImage.value != null);

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: isSubmitting.value
                  ? null
                  : () => Navigator.of(context).pop(),
              style: OutlinedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(vertical: 16),
                side: BorderSide(
                  color: Colors.grey.shade300,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
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
              onPressed: canSubmit
                  ? () => _handleSubmit(context, ref)
                  : null,
              style: ElevatedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: AppColors.primaryGreen,
                foregroundColor: Colors.white,
                disabledBackgroundColor:
                    Colors.grey.shade300,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: isSubmitting.value
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      'Complete',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleSubmit(
    BuildContext context,
    WidgetRef ref,
  ) async {
    isSubmitting.value = true;

    try {
      // Upload photo if captured
      String? photoUrl;
      if (capturedImage.value != null) {
        AppLogger.general(
          'Uploading service task photo to Cloudinary...',
        );
        final cloudinary = CloudinaryService();
        photoUrl = await cloudinary.uploadImage(
          File(capturedImage.value!.path),
        );
        AppLogger.general(
          'Photo uploaded: $photoUrl',
        );
      }

      // Get notes
      final notes = notesController.text.trim().isEmpty
          ? null
          : notesController.text.trim();

      // Complete the service task
      await ref
          .read(shiftNotifierProvider.notifier)
          .completeTask(
            task.id,
            '', // No bin ID for service tasks
            null, // No fill percentage
            photoUrl: photoUrl,
            hasIncident: false,
            completionNotes: notes,
          );

      if (context.mounted) {
        Navigator.of(context).pop();
        onCompleted?.call();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Completed: ${task.taskLabel ?? "Service stop"}',
            ),
            backgroundColor: AppColors.primaryGreen,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      isSubmitting.value = false;
      AppLogger.general(
        'Error completing service task: $e',
        level: AppLogger.error,
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }
}
