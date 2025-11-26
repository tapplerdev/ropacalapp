import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ropacalapp/core/constants/bin_constants.dart';
import 'package:ropacalapp/models/bin.dart';

class CheckInDialog extends HookConsumerWidget {
  final Bin bin;

  const CheckInDialog({super.key, required this.bin});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fillPercentage = useState(
      bin.fillPercentage ?? BinConstants.mediumFillThreshold,
    );
    final isSubmitting = useState(false);

    return AlertDialog(
      title: Text('Check In - Bin #${bin.binNumber}'),
      content: Column(
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
      actions: [
        TextButton(
          onPressed: isSubmitting.value ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: isSubmitting.value
              ? null
              : () async {
                  isSubmitting.value = true;
                  try {
                    // TODO: Call API to create check-in
                    await Future.delayed(const Duration(seconds: 1));
                    if (context.mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Check-in recorded successfully'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  } catch (e) {
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
                  }
                },
          child: isSubmitting.value
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Submit'),
        ),
      ],
    );
  }
}
