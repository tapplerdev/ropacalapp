import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:ropacalapp/core/constants/bin_constants.dart';
import 'package:ropacalapp/core/services/cloudinary_service.dart';
import 'package:ropacalapp/core/theme/app_colors.dart';
import 'package:ropacalapp/core/utils/app_logger.dart';
import 'package:ropacalapp/models/route_bin.dart';
import 'package:ropacalapp/providers/shift_provider.dart';
import 'package:ropacalapp/features/driver/widgets/incident_components.dart';

/// Modern check-in dialog with incident reporting support
/// Normal flow: Step 1 (photo) → Step 2 (fill level) → Submit
/// Incident flow: Step 1 (photo) → Report Issue → Step 2 (incident type) → Step 3 (incident details) → Submit
class CheckInDialogV2 extends HookConsumerWidget {
  final RouteBin bin;
  final VoidCallback? onCheckedIn;

  const CheckInDialogV2({
    super.key,
    required this.bin,
    this.onCheckedIn,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Main flow state
    final currentStep = useState(1); // 1=photo, 2=fill/incident_type, 3=incident_details
    final capturedImage = useState<XFile?>(null);
    final fillPercentage = useState(bin.fillPercentage);
    final isSubmitting = useState(false);

    // Incident state
    final hasIncident = useState(false);
    final selectedIncidentType = useState<String?>(null);
    final incidentPhoto = useState<XFile?>(null);
    final incidentDescription = useState<String>('');

    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
      child: Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 16),
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
                color: AppColors.primaryGreen.withValues(alpha: 0.1),
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
                // Modern header with progress
                _buildModernHeader(
                  context,
                  bin,
                  currentStep.value,
                  hasIncident.value,
                  selectedIncidentType.value,
                ),

                // Animated content switcher
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  transitionBuilder: (child, animation) {
                    return FadeTransition(
                      opacity: animation,
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0.1, 0),
                          end: Offset.zero,
                        ).animate(animation),
                        child: child,
                      ),
                    );
                  },
                  child: _buildStepContent(
                    context,
                    currentStep.value,
                    capturedImage,
                    fillPercentage,
                    hasIncident.value,
                    selectedIncidentType,
                    incidentPhoto,
                    incidentDescription,
                  ),
                ),

                // Modern footer with action buttons
                _buildModernFooter(
                  context,
                  ref,
                  currentStep,
                  capturedImage,
                  fillPercentage,
                  isSubmitting,
                  hasIncident,
                  selectedIncidentType,
                  incidentPhoto,
                  incidentDescription,
                  onCheckedIn,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Route to correct step content
  Widget _buildStepContent(
    BuildContext context,
    int step,
    ValueNotifier<XFile?> capturedImage,
    ValueNotifier<int> fillPercentage,
    bool hasIncident,
    ValueNotifier<String?> selectedIncidentType,
    ValueNotifier<XFile?> incidentPhoto,
    ValueNotifier<String> incidentDescription,
  ) {
    // Step 1: Always photo capture
    if (step == 1) {
      return _buildModernPhotoCapture(context, capturedImage);
    }

    // Step 2: Incident type selection OR fill level
    if (step == 2) {
      if (hasIncident) {
        return IncidentTypeSelector(selectedIncidentType: selectedIncidentType);
      } else {
        return _buildModernFillLevel(context, bin, capturedImage.value, fillPercentage);
      }
    }

    // Step 3: Incident details (only if hasIncident)
    if (step == 3 && hasIncident) {
      return IncidentDetailsForm(
        incidentPhoto: incidentPhoto,
        incidentDescription: incidentDescription,
        incidentType: selectedIncidentType.value,
      );
    }

    return Container();
  }

  /// Build modern header with gradient and animated progress
  Widget _buildModernHeader(
    BuildContext context,
    RouteBin bin,
    int step,
    bool hasIncident,
    String? incidentType,
  ) {
    // Calculate dynamic subtitle based on current state
    String subtitle;
    if (step == 1) {
      subtitle = 'Take bin photo';
    } else if (step == 2 && hasIncident) {
      subtitle = 'Report an issue';
    } else if (step == 3 && hasIncident) {
      subtitle = incidentType != null ? _formatIncidentType(incidentType) : 'Add incident details';
    } else {
      subtitle = 'Update fill level';
    }

    // Calculate total steps dynamically
    int totalSteps = hasIncident ? 3 : 2;

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primaryGreen.withValues(alpha: 0.08),
            AppColors.primaryGreen.withValues(alpha: 0.03),
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Bin number with icon
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.primaryGreen,
                          AppColors.primaryGreen.withValues(alpha: 0.8),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primaryGreen.withValues(alpha: 0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.delete_outline,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Bin #${bin.binNumber}',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              // Modern progress indicator
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primaryGreen,
                      AppColors.primaryGreen.withValues(alpha: 0.85),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryGreen.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  '$step/$totalSteps',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: step / totalSteps,
              minHeight: 6,
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation<Color>(
                AppColors.primaryGreen,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Format incident type for display
  String _formatIncidentType(String type) {
    switch (type) {
      case 'missing':
        return 'Missing Bin';
      case 'damaged':
        return 'Damaged';
      case 'vandalized':
        return 'Vandalized';
      case 'inaccessible':
        return 'Inaccessible';
      default:
        return type;
    }
  }

  /// Build modern photo capture UI with camera and gallery options
  Widget _buildModernPhotoCapture(
    BuildContext context,
    ValueNotifier<XFile?> capturedImage,
  ) {
    final imagePicker = ImagePicker();

    Future<void> pickImageFromCamera() async {
      try {
        final image = await imagePicker.pickImage(
          source: ImageSource.camera,
          imageQuality: 85,
          maxWidth: 1920,
          maxHeight: 1080,
        );
        if (image != null) {
          capturedImage.value = image;
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.error_outline, color: Colors.white),
                  const SizedBox(width: 12),
                  Expanded(child: Text('Camera error: $e')),
                ],
              ),
              backgroundColor: Colors.red.shade600,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        }
      }
    }

    Future<void> pickImageFromGallery() async {
      try {
        final image = await imagePicker.pickImage(
          source: ImageSource.gallery,
          imageQuality: 85,
          maxWidth: 1920,
          maxHeight: 1080,
        );
        if (image != null) {
          capturedImage.value = image;
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.error_outline, color: Colors.white),
                  const SizedBox(width: 12),
                  Expanded(child: Text('Gallery error: $e')),
                ],
              ),
              backgroundColor: Colors.red.shade600,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        }
      }
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
      child: Column(
        children: [
          if (capturedImage.value == null)
            // No photo yet - show camera button
            GestureDetector(
              onTap: pickImageFromCamera,
              child: Container(
                height: 320,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.primaryGreen.withValues(alpha: 0.08),
                      AppColors.primaryGreen.withValues(alpha: 0.04),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: AppColors.primaryGreen.withValues(alpha: 0.2),
                    width: 2,
                  ),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppColors.primaryGreen,
                              AppColors.primaryGreen.withValues(alpha: 0.8),
                            ],
                          ),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primaryGreen.withValues(alpha: 0.3),
                              blurRadius: 24,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.camera_alt_rounded,
                          size: 48,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Tap to take photo',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryGreen,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Take a clear photo of the bin',
                        style: TextStyle(
                          fontSize: 15,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else
            // Photo captured - show preview
            Column(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: Stack(
                    children: [
                      Image.file(
                        File(capturedImage.value!.path),
                        height: 320,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                      // Gradient overlay
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: Container(
                          height: 100,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.black.withValues(alpha: 0.6),
                              ],
                            ),
                          ),
                        ),
                      ),
                      // Check mark
                      Positioned(
                        top: 16,
                        right: 16,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.green,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.green.withValues(alpha: 0.4),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.check,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Retake and gallery buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: pickImageFromCamera,
                        icon: const Icon(Icons.refresh, size: 20),
                        label: const Text(
                          'Retake',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primaryGreen,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          side: BorderSide(
                            color: AppColors.primaryGreen.withValues(alpha: 0.3),
                            width: 2,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: pickImageFromGallery,
                        icon: const Icon(Icons.photo_library_outlined, size: 20),
                        label: const Text(
                          'Gallery',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primaryGreen,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          side: BorderSide(
                            color: AppColors.primaryGreen.withValues(alpha: 0.3),
                            width: 2,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
        ],
      ),
    );
  }

  /// Build modern fill level UI with gradient slider
  Widget _buildModernFillLevel(
    BuildContext context,
    RouteBin bin,
    XFile? photo,
    ValueNotifier<int> fillPercentage,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Fill level header with large percentage
          Center(
            child: Column(
              children: [
                Text(
                  '${fillPercentage.value}%',
                  style: TextStyle(
                    fontSize: 56,
                    fontWeight: FontWeight.bold,
                    color: _getSliderColor(fillPercentage.value),
                    letterSpacing: -2,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Fill Level',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black54,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 28),

          // Modern gradient slider
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 12,
              thumbShape: const RoundSliderThumbShape(
                enabledThumbRadius: 16,
                elevation: 4,
              ),
              overlayShape: const RoundSliderOverlayShape(
                overlayRadius: 28,
              ),
              activeTrackColor: _getSliderColor(fillPercentage.value),
              inactiveTrackColor: Colors.grey.shade200,
              thumbColor: _getSliderColor(fillPercentage.value),
              overlayColor: _getSliderColor(fillPercentage.value).withValues(alpha: 0.2),
            ),
            child: Slider(
              value: fillPercentage.value.toDouble(),
              min: 0,
              max: 100,
              divisions: 20,
              onChanged: (value) => fillPercentage.value = value.round(),
            ),
          ),

          // Labels
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Empty',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade500,
                  ),
                ),
                Text(
                  'Full',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Modern before/after comparison cards
          Row(
            children: [
              // Previous fill level card
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        _getSliderColor(bin.fillPercentage).withValues(alpha: 0.08),
                        _getSliderColor(bin.fillPercentage).withValues(alpha: 0.04),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: _getSliderColor(bin.fillPercentage).withValues(alpha: 0.2),
                      width: 1.5,
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'PREVIOUS',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade600,
                          letterSpacing: 0.8,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${bin.fillPercentage}%',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: _getSliderColor(bin.fillPercentage),
                          letterSpacing: -1,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Arrow indicator
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Icon(
                  Icons.arrow_forward,
                  size: 28,
                  color: Colors.grey.shade400,
                ),
              ),

              // New fill level card
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        _getSliderColor(fillPercentage.value).withValues(alpha: 0.12),
                        _getSliderColor(fillPercentage.value).withValues(alpha: 0.06),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: _getSliderColor(fillPercentage.value).withValues(alpha: 0.3),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: _getSliderColor(fillPercentage.value).withValues(alpha: 0.15),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Text(
                        'UPDATED',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: _getSliderColor(fillPercentage.value),
                          letterSpacing: 0.8,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${fillPercentage.value}%',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: _getSliderColor(fillPercentage.value),
                          letterSpacing: -1,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Build modern footer with gradient buttons
  Widget _buildModernFooter(
    BuildContext context,
    WidgetRef ref,
    ValueNotifier<int> currentStep,
    ValueNotifier<XFile?> capturedImage,
    ValueNotifier<int> fillPercentage,
    ValueNotifier<bool> isSubmitting,
    ValueNotifier<bool> hasIncident,
    ValueNotifier<String?> selectedIncidentType,
    ValueNotifier<XFile?> incidentPhoto,
    ValueNotifier<String> incidentDescription,
    VoidCallback? onCheckedIn,
  ) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.grey.shade50.withValues(alpha: 0.5),
        border: Border(
          top: BorderSide(
            color: Colors.grey.shade200,
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          // Report Issue button (available immediately on step 1, not already reporting)
          if (currentStep.value == 1 && !hasIncident.value)
            ReportIssueButton(
              onPressed: () {
                hasIncident.value = true;
                currentStep.value = 2;
              },
            ),

          // Navigation buttons
          Row(
            children: [
              // Back / Cancel button
              Expanded(
                child: OutlinedButton(
                  onPressed: isSubmitting.value
                      ? null
                      : () {
                          if (currentStep.value == 1) {
                            Navigator.pop(context);
                          } else if (currentStep.value == 2 && hasIncident.value) {
                            // Going back from incident type selection
                            hasIncident.value = false;
                            currentStep.value = 1;
                          } else {
                            currentStep.value--;
                          }
                        },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.grey.shade700,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    side: BorderSide(
                      color: Colors.grey.shade300,
                      width: 2,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    currentStep.value == 1 ? 'Cancel' : 'Back',
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 12),

              // Continue / Next / Submit button
              Expanded(
                child: _buildPrimaryButton(
                  context,
                  ref,
                  currentStep,
                  capturedImage,
                  fillPercentage,
                  isSubmitting,
                  hasIncident,
                  selectedIncidentType,
                  incidentPhoto,
                  incidentDescription,
                  onCheckedIn,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Build primary action button (Continue/Next/Submit)
  Widget _buildPrimaryButton(
    BuildContext context,
    WidgetRef ref,
    ValueNotifier<int> currentStep,
    ValueNotifier<XFile?> capturedImage,
    ValueNotifier<int> fillPercentage,
    ValueNotifier<bool> isSubmitting,
    ValueNotifier<bool> hasIncident,
    ValueNotifier<String?> selectedIncidentType,
    ValueNotifier<XFile?> incidentPhoto,
    ValueNotifier<String> incidentDescription,
    VoidCallback? onCheckedIn,
  ) {
    // Determine if can proceed
    bool canProceed = false;
    String buttonText = 'Continue';

    if (currentStep.value == 1) {
      canProceed = capturedImage.value != null;
      buttonText = 'Continue';
    } else if (currentStep.value == 2 && hasIncident.value) {
      canProceed = selectedIncidentType.value != null;
      buttonText = 'Next';
    } else if (currentStep.value == 3 && hasIncident.value) {
      // Incident details - at least photo OR description required
      canProceed = incidentPhoto.value != null || incidentDescription.value.isNotEmpty;
      buttonText = 'Submit Report';
    } else if (currentStep.value == 2 && !hasIncident.value) {
      // Normal flow - fill level
      canProceed = true;
      buttonText = 'Complete Bin';
    }

    return Container(
      decoration: BoxDecoration(
        gradient: canProceed && !isSubmitting.value
            ? LinearGradient(
                colors: [
                  AppColors.primaryGreen,
                  AppColors.primaryGreen.withValues(alpha: 0.85),
                ],
              )
            : null,
        borderRadius: BorderRadius.circular(16),
        boxShadow: canProceed && !isSubmitting.value
            ? [
                BoxShadow(
                  color: AppColors.primaryGreen.withValues(alpha: 0.4),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ]
            : null,
      ),
      child: ElevatedButton(
        onPressed: canProceed && !isSubmitting.value
            ? () => _handlePrimaryAction(
                  context,
                  ref,
                  currentStep,
                  capturedImage,
                  fillPercentage,
                  isSubmitting,
                  hasIncident,
                  selectedIncidentType,
                  incidentPhoto,
                  incidentDescription,
                  onCheckedIn,
                )
            : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: canProceed ? Colors.transparent : Colors.grey.shade300,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: isSubmitting.value
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Colors.white,
                ),
              )
            : Text(
                buttonText,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.2,
                ),
              ),
      ),
    );
  }

  /// Handle primary action button click
  Future<void> _handlePrimaryAction(
    BuildContext context,
    WidgetRef ref,
    ValueNotifier<int> currentStep,
    ValueNotifier<XFile?> capturedImage,
    ValueNotifier<int> fillPercentage,
    ValueNotifier<bool> isSubmitting,
    ValueNotifier<bool> hasIncident,
    ValueNotifier<String?> selectedIncidentType,
    ValueNotifier<XFile?> incidentPhoto,
    ValueNotifier<String> incidentDescription,
    VoidCallback? onCheckedIn,
  ) async {
    // Step 1: Continue to next step
    if (currentStep.value == 1 && !hasIncident.value) {
      currentStep.value = 2;
      return;
    }

    // Step 2 (incident): Continue to details
    if (currentStep.value == 2 && hasIncident.value) {
      currentStep.value = 3;
      return;
    }

    // Final submit (either step 2 normal or step 3 incident)
    isSubmitting.value = true;

    try {
      AppLogger.general('[DIAGNOSTIC] ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      AppLogger.general('[DIAGNOSTIC] 📸 CHECK-IN DIALOG: Submit button pressed');
      AppLogger.general('[DIAGNOSTIC]    Bin ID: ${bin.binId}');
      AppLogger.general('[DIAGNOSTIC]    Has Incident: ${hasIncident.value}');

      final cloudinaryService = CloudinaryService();
      if (!cloudinaryService.isInitialized) {
        await cloudinaryService.initialize();
      }

      // Upload bin photo
      String? binPhotoUrl;
      if (capturedImage.value != null) {
        AppLogger.general('[DIAGNOSTIC] 🌥️ Uploading bin photo...');
        binPhotoUrl = await cloudinaryService.uploadImage(File(capturedImage.value!.path));
        AppLogger.general('[DIAGNOSTIC]    Bin photo URL: $binPhotoUrl');
      }

      // Upload incident photo if present
      String? incidentPhotoUrl;
      if (incidentPhoto.value != null) {
        AppLogger.general('[DIAGNOSTIC] 🌥️ Uploading incident photo...');
        incidentPhotoUrl = await cloudinaryService.uploadImage(File(incidentPhoto.value!.path));
        AppLogger.general('[DIAGNOSTIC]    Incident photo URL: $incidentPhotoUrl');
      }

      // Call completeBin with incident data
      AppLogger.general('[DIAGNOSTIC] 📡 Calling completeBin API...');
      await ref.read(shiftNotifierProvider.notifier).completeTask(
            bin.id, // NEW: shift_bin_id (properly identifies this specific waypoint)
            bin.binId, // DEPRECATED: kept for backward compatibility
            hasIncident.value ? null : fillPercentage.value, // NULL if incident
            photoUrl: binPhotoUrl,
            hasIncident: hasIncident.value,
            incidentType: selectedIncidentType.value,
            incidentPhotoUrl: incidentPhotoUrl,
            incidentDescription: incidentDescription.value.isEmpty ? null : incidentDescription.value,
          );

      AppLogger.general('[DIAGNOSTIC] ✅ API call successful');

      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_outline, color: Colors.white),
                const SizedBox(width: 12),
                Text(
                  hasIncident.value ? 'Incident reported successfully' : 'Bin completed successfully',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );

        onCheckedIn?.call();
      }
    } catch (e, stack) {
      AppLogger.general('[DIAGNOSTIC] ❌ Error: $e');
      AppLogger.general('[DIAGNOSTIC]    Stack: $stack');

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(child: Text('Error: $e')),
              ],
            ),
            backgroundColor: Colors.red.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } finally {
      isSubmitting.value = false;
      AppLogger.general('[DIAGNOSTIC] ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    }
  }

  /// Get slider color based on fill percentage
  Color _getSliderColor(int percentage) {
    if (percentage <= 50) {
      return const Color(0xFF4CAF50); // Green
    } else if (percentage <= 75) {
      return const Color(0xFFFF9800); // Orange
    } else {
      return const Color(0xFFEF5350); // Red
    }
  }
}

/// Custom painter for dot pattern background
class _DotPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.primaryGreen.withValues(alpha: 0.08)
      ..style = PaintingStyle.fill;

    const spacing = 20.0;
    const radius = 2.0;

    for (double x = 0; x < size.width; x += spacing) {
      for (double y = 0; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), radius, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
