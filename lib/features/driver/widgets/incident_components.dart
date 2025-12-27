import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:image_picker/image_picker.dart';
import 'package:ropacalapp/core/theme/app_colors.dart';

/// Incident type selector - displays 2x2 grid of incident types
class IncidentTypeSelector extends HookWidget {
  final ValueNotifier<String?> selectedIncidentType;

  const IncidentTypeSelector({
    super.key,
    required this.selectedIncidentType,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
      child: GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 2,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 1.1,
        children: [
          _IncidentTypeCard(
            type: 'missing',
            label: 'Missing',
            icon: Icons.help_outline_rounded,
            selectedIncidentType: selectedIncidentType,
          ),
          _IncidentTypeCard(
            type: 'damaged',
            label: 'Damaged',
            icon: Icons.warning_amber_rounded,
            selectedIncidentType: selectedIncidentType,
          ),
          _IncidentTypeCard(
            type: 'vandalized',
            label: 'Vandalized',
            icon: Icons.auto_fix_off_rounded,
            selectedIncidentType: selectedIncidentType,
          ),
          _IncidentTypeCard(
            type: 'inaccessible',
            label: 'Inaccessible',
            icon: Icons.lock_outline_rounded,
            selectedIncidentType: selectedIncidentType,
          ),
        ],
      ),
    );
  }
}

/// Individual incident type card
class _IncidentTypeCard extends HookWidget {
  final String type;
  final String label;
  final IconData icon;
  final ValueNotifier<String?> selectedIncidentType;

  const _IncidentTypeCard({
    required this.type,
    required this.label,
    required this.icon,
    required this.selectedIncidentType,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = selectedIncidentType.value == type;

    return GestureDetector(
      onTap: () => selectedIncidentType.value = type,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.red.shade400,
              Colors.red.shade500,
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? Colors.red.shade700 : Colors.transparent,
            width: 3,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.red.shade300.withValues(alpha: 0.4),
              blurRadius: isSelected ? 16 : 8,
              offset: Offset(0, isSelected ? 8 : 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 48,
              color: Colors.white,
            ),
            const SizedBox(height: 12),
            Text(
              label,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Incident details form - photo + notes
class IncidentDetailsForm extends HookWidget {
  final ValueNotifier<XFile?> incidentPhoto;
  final ValueNotifier<String> incidentDescription;
  final String? incidentType;

  const IncidentDetailsForm({
    super.key,
    required this.incidentPhoto,
    required this.incidentDescription,
    this.incidentType,
  });

  @override
  Widget build(BuildContext context) {
    final imagePicker = ImagePicker();

    Future<void> pickIncidentPhoto() async {
      try {
        final image = await imagePicker.pickImage(
          source: ImageSource.camera,
          imageQuality: 85,
          maxWidth: 1920,
          maxHeight: 1080,
        );
        if (image != null) {
          incidentPhoto.value = image;
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

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Photo capture button
          GestureDetector(
            onTap: pickIncidentPhoto,
            child: Container(
              height: 180,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.grey.shade300,
                  width: 2,
                ),
              ),
              child: incidentPhoto.value == null
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.camera_alt_rounded,
                            size: 48,
                            color: Colors.grey.shade600,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Take Photo of Issue',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '(Optional)',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: Image.file(
                        File(incidentPhoto.value!.path),
                        width: double.infinity,
                        height: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
            ),
          ),

          const SizedBox(height: 20),

          // Notes field
          TextField(
            onChanged: (value) => incidentDescription.value = value,
            maxLines: 4,
            decoration: InputDecoration(
              hintText: 'Add notes...',
              hintStyle: TextStyle(
                color: Colors.grey.shade400,
              ),
              filled: true,
              fillColor: Colors.grey.shade50,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                  color: Colors.grey.shade300,
                  width: 2,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                  color: Colors.grey.shade300,
                  width: 2,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                  color: AppColors.primaryGreen,
                  width: 2,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Report Issue button - shown on step 1 after photo is captured
class ReportIssueButton extends StatelessWidget {
  final VoidCallback onPressed;

  const ReportIssueButton({
    super.key,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red.shade500,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 4,
            shadowColor: Colors.red.shade300.withValues(alpha: 0.5),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.warning_amber_rounded,
                size: 24,
                color: Colors.white,
              ),
              const SizedBox(width: 12),
              const Text(
                'Report Issue',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
