import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ropacalapp/core/theme/app_colors.dart';
import 'package:ropacalapp/models/potential_location.dart';
import 'package:ropacalapp/providers/potential_locations_list_provider.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

class PotentialLocationBottomSheet extends HookConsumerWidget {
  final PotentialLocation location;

  const PotentialLocationBottomSheet({
    super.key,
    required this.location,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isSubmitting = useState(false);
    final binNumberController = useTextEditingController();

    final isPending = location.convertedToBinId == null;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isPending
                          ? const Color(0xFFFF9500).withValues(alpha: 0.1)
                          : Colors.grey.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.add_location_alt,
                      color: isPending
                          ? const Color(0xFFFF9500)
                          : Colors.grey.shade600,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Potential Location',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: isPending
                                ? const Color(0xFFFF9500)
                                : Colors.grey.shade600,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            isPending ? 'PENDING' : 'CONVERTED',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Location info
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.location_on,
                          color: Colors.grey.shade600,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            location.street,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(
                          Icons.location_city,
                          color: Colors.grey.shade600,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${location.city}, ${location.zip}',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                    if (location.notes != null && location.notes!.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.note_outlined,
                            color: Colors.grey.shade600,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              location.notes!,
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // Submitted by
              Row(
                children: [
                  Icon(
                    Icons.person_outline,
                    size: 16,
                    color: Colors.grey.shade600,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Submitted by ${location.requestedByName}',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),

              if (isPending) ...[
                const SizedBox(height: 20),
                const Divider(),
                const SizedBox(height: 16),

                // Convert section
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Convert to Bin',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Enter a bin number or leave empty to auto-assign the next available number.',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Bin number input
                    TextField(
                      controller: binNumberController,
                      enabled: !isSubmitting.value,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                      decoration: InputDecoration(
                        labelText: 'Bin Number (Optional)',
                        hintText: 'Leave empty for auto-assignment',
                        prefixIcon: Icon(
                          Icons.tag,
                          color: AppColors.primaryGreen,
                        ),
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

                    // Convert button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: isSubmitting.value
                            ? null
                            : () async {
                                // Parse bin number if provided
                                int? binNumber;
                                if (binNumberController.text.trim().isNotEmpty) {
                                  binNumber = int.tryParse(binNumberController.text.trim());
                                  if (binNumber == null || binNumber <= 0) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Please enter a valid bin number'),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                    return;
                                  }
                                }

                                isSubmitting.value = true;
                                try {
                                  await ref
                                      .read(
                                        potentialLocationsListNotifierProvider.notifier,
                                      )
                                      .convertToBin(
                                        potentialLocationId: location.id,
                                        binNumber: binNumber,
                                      );

                                  if (context.mounted) {
                                    Navigator.pop(context);
                                    ScaffoldMessenger.of(context)
                                        .showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          binNumber != null
                                              ? 'Successfully converted to Bin #$binNumber'
                                              : 'Successfully converted to bin',
                                        ),
                                        backgroundColor: AppColors.successGreen,
                                      ),
                                    );
                                  }
                                } catch (e) {
                                  if (context.mounted) {
                                    final errorMessage = e.toString().contains('already exists')
                                        ? 'Bin number already exists'
                                        : 'Error: $e';
                                    ScaffoldMessenger.of(context)
                                        .showSnackBar(
                                      SnackBar(
                                        content: Text(errorMessage),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  }
                                } finally {
                                  isSubmitting.value = false;
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          backgroundColor: AppColors.primaryGreen,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: isSubmitting.value
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              )
                            : const Text(
                                'Convert to Bin',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ] else if (location.binNumber != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.green.shade200,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.check_circle,
                        color: Colors.green.shade700,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Converted to Bin #${location.binNumber}',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.green.shade900,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
