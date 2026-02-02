import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:ropacalapp/core/constants/bin_constants.dart';
import 'package:ropacalapp/core/services/cloudinary_service.dart';
import 'package:ropacalapp/models/bin.dart';
import 'package:ropacalapp/providers/shift_provider.dart';

class CheckInDialog extends HookConsumerWidget {
  final Bin bin;
  final VoidCallback? onCheckedIn; // Callback for when check-in completes

  const CheckInDialog({super.key, required this.bin, this.onCheckedIn});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fillPercentage = useState(
      bin.fillPercentage ?? BinConstants.mediumFillThreshold,
    );
    final isSubmitting = useState(false);
    final selectedImage = useState<File?>(null);
    final isUploadingImage = useState(false);
    final imagePicker = useMemoized(() => ImagePicker());
    final cloudinaryService = useMemoized(() => CloudinaryService());

    return AlertDialog(
      title: Text('Check In - Bin #${bin.binNumber}'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Current fill level: ${bin.fillPercentage ?? 0}%',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            Text(
              'New fill level: ${fillPercentage.value}%',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Slider(
              value: fillPercentage.value.toDouble(),
              min: 0,
              max: 100,
              divisions: 20,
              label: '${fillPercentage.value}%',
              onChanged: (value) => fillPercentage.value = value.round(),
            ),
            const SizedBox(height: 16),

            // Photo section
            if (selectedImage.value != null) ...[
              // Image preview
              Container(
                height: 200,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.file(
                        selectedImage.value!,
                        width: double.infinity,
                        height: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.black.withValues(alpha: 0.5),
                        ),
                        onPressed: () => selectedImage.value = null,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Photo button
            OutlinedButton.icon(
              onPressed: isSubmitting.value
                  ? null
                  : () async {
                      // Show choice dialog - camera or gallery
                      final source = await showDialog<ImageSource>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Choose photo source'),
                          content: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              ListTile(
                                leading: const Icon(Icons.camera_alt),
                                title: const Text('Camera'),
                                onTap: () =>
                                    Navigator.pop(context, ImageSource.camera),
                              ),
                              ListTile(
                                leading: const Icon(Icons.photo_library),
                                title: const Text('Gallery'),
                                onTap: () =>
                                    Navigator.pop(context, ImageSource.gallery),
                              ),
                            ],
                          ),
                        ),
                      );

                      if (source != null) {
                        final XFile? image =
                            await imagePicker.pickImage(source: source);
                        if (image != null) {
                          selectedImage.value = File(image.path);
                        }
                      }
                    },
              icon: Icon(
                selectedImage.value == null ? Icons.add_a_photo : Icons.edit,
              ),
              label: Text(
                selectedImage.value == null ? 'Add Photo (Optional)' : 'Change Photo',
              ),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
              ),
            ),

            const SizedBox(height: 16),

            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 20,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'This will update the bin\'s fill level and record a check-in.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: isSubmitting.value ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: isSubmitting.value
              ? null
              : () async {
                  print('[DIAGNOSTIC] ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
                  print('[DIAGNOSTIC] 📸 CHECK-IN DIALOG: Submit button pressed');
                  print('[DIAGNOSTIC]    Bin ID: ${bin.id}');
                  print('[DIAGNOSTIC]    Bin Number: ${bin.binNumber}');
                  print('[DIAGNOSTIC]    Fill Percentage: ${fillPercentage.value}%');
                  print('[DIAGNOSTIC]    Has Photo: ${selectedImage.value != null}');

                  isSubmitting.value = true;
                  String? photoUrl;

                  try {
                    // Step 1: Upload image to Cloudinary if selected
                    if (selectedImage.value != null) {
                      print('[DIAGNOSTIC] 🌥️ CHECK-IN DIALOG: Photo selected, starting upload...');
                      print('[DIAGNOSTIC]    Image path: ${selectedImage.value!.path}');

                      isUploadingImage.value = true;

                      // Initialize Cloudinary if not already
                      if (!cloudinaryService.isInitialized) {
                        print('[DIAGNOSTIC] 🔧 CHECK-IN DIALOG: Initializing Cloudinary...');
                        await cloudinaryService.initialize();
                        print('[DIAGNOSTIC] ✅ CHECK-IN DIALOG: Cloudinary initialized');
                      } else {
                        print('[DIAGNOSTIC] ℹ️  CHECK-IN DIALOG: Cloudinary already initialized');
                      }

                      // Upload image
                      print('[DIAGNOSTIC] 📤 CHECK-IN DIALOG: Calling cloudinaryService.uploadImage()...');
                      photoUrl = await cloudinaryService.uploadImage(
                        selectedImage.value!,
                      );
                      print('[DIAGNOSTIC] ✅ CHECK-IN DIALOG: Photo uploaded successfully!');
                      print('[DIAGNOSTIC]    Photo URL: $photoUrl');

                      isUploadingImage.value = false;
                    } else {
                      print('[DIAGNOSTIC] ℹ️  CHECK-IN DIALOG: No photo selected, skipping upload');
                    }

                    // Step 2: Complete bin via shift provider
                    print('[DIAGNOSTIC] 📡 CHECK-IN DIALOG: Calling completeBin API...');
                    print('[DIAGNOSTIC]    Parameters:');
                    print('[DIAGNOSTIC]      - binId: ${bin.id}');
                    print('[DIAGNOSTIC]      - fillPercentage: ${fillPercentage.value}');
                    print('[DIAGNOSTIC]      - photoUrl: ${photoUrl ?? 'null'}');

                    await ref.read(shiftNotifierProvider.notifier).completeTask(
                          bin.id,
                          fillPercentage.value,
                          photoUrl: photoUrl,
                        );

                    print('[DIAGNOSTIC] ✅ CHECK-IN DIALOG: completeBin API call successful');

                    if (context.mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            photoUrl != null
                                ? 'Bin completed with photo'
                                : 'Bin completed successfully',
                          ),
                          backgroundColor: Colors.green,
                        ),
                      );

                      print('[DIAGNOSTIC] 🎉 CHECK-IN DIALOG: Success! Dialog closed');

                      // Trigger callback to advance to next bin
                      onCheckedIn?.call();
                    }
                  } catch (e, stack) {
                    print('[DIAGNOSTIC] ❌ CHECK-IN DIALOG: Error occurred!');
                    print('[DIAGNOSTIC]    Error: $e');
                    print('[DIAGNOSTIC]    Stack trace: $stack');

                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Error: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  } finally {
                    isSubmitting.value = false;
                    isUploadingImage.value = false;
                    print('[DIAGNOSTIC] 🏁 CHECK-IN DIALOG: Submit flow completed');
                    print('[DIAGNOSTIC] ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
                  }
                },
          child: isSubmitting.value
              ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      isUploadingImage.value
                          ? 'Uploading photo...'
                          : 'Submitting...',
                    ),
                  ],
                )
              : const Text('Submit'),
        ),
      ],
    );
  }
}
