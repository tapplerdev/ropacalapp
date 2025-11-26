import 'package:flutter/material.dart';
import 'package:ropacalapp/core/constants/bin_constants.dart';
import 'package:ropacalapp/core/theme/app_colors.dart';
import 'package:ropacalapp/models/bin.dart';

/// Utility methods for bin-related operations
class BinHelpers {
  // Prevent instantiation
  BinHelpers._();

  /// Returns the appropriate color for a bin based on its fill percentage
  ///
  /// - Red (alert): Above 75% - needs urgent attention
  /// - Orange (warning): Above 50% - should be monitored
  /// - Green (success): Below 50% - good condition
  static Color getFillColor(int fillPercentage) {
    if (fillPercentage > BinConstants.highFillThreshold) {
      return AppColors.alertRed;
    } else if (fillPercentage > BinConstants.mediumFillThreshold) {
      return AppColors.warningOrange;
    } else {
      return AppColors.successGreen;
    }
  }

  /// Returns a human-readable description of the bin's fill level
  static String getFillDescription(int fillPercentage) {
    if (fillPercentage >= BinConstants.urgentFillThreshold) {
      return 'Critical - needs immediate attention';
    } else if (fillPercentage >= BinConstants.criticalFillThreshold) {
      return 'High fill - service soon';
    } else if (fillPercentage >= BinConstants.mediumFillThreshold) {
      return 'Moderate fill - monitor';
    } else {
      return 'Low fill - good condition';
    }
  }

  /// Returns the appropriate icon for a bin based on its fill percentage
  static IconData getFillIcon(int fillPercentage) {
    if (fillPercentage >= BinConstants.criticalFillThreshold) {
      return Icons.delete_forever;
    } else if (fillPercentage >= BinConstants.mediumFillThreshold) {
      return Icons.delete_outline;
    } else {
      return Icons.delete;
    }
  }

  /// Counts bins by fill level category
  static BinFillStats calculateFillStats(List<Bin> bins) {
    var high = 0;
    var medium = 0;
    var low = 0;

    for (final bin in bins) {
      final fillPercentage = bin.fillPercentage ?? 0;
      if (fillPercentage > BinConstants.criticalFillThreshold) {
        high++;
      } else if (fillPercentage > BinConstants.mediumFillThreshold) {
        medium++;
      } else {
        low++;
      }
    }

    return BinFillStats(high: high, medium: medium, low: low);
  }

  /// Sorts bins by priority (highest fill percentage first)
  static List<Bin> sortByPriority(List<Bin> bins) {
    final sorted = List<Bin>.from(bins);
    sorted.sort((a, b) {
      final aFill = a.fillPercentage ?? 0;
      final bFill = b.fillPercentage ?? 0;
      return bFill.compareTo(aFill); // Descending order
    });
    return sorted;
  }

  /// Filters bins that need attention (above medium threshold)
  static List<Bin> getAlertBins(List<Bin> bins) {
    return bins
        .where(
          (bin) => (bin.fillPercentage ?? 0) > BinConstants.mediumFillThreshold,
        )
        .toList();
  }

  /// Filters bins that are critically full
  static List<Bin> getCriticalBins(List<Bin> bins) {
    return bins
        .where(
          (bin) =>
              (bin.fillPercentage ?? 0) > BinConstants.criticalFillThreshold,
        )
        .toList();
  }

  /// Formats bin number with leading zero if needed
  static String formatBinNumber(int binNumber) {
    return binNumber.toString().padLeft(2, '0');
  }

  /// Returns a summary text for a bin's current status
  static String getBinStatusSummary(Bin bin) {
    final fillPercentage = bin.fillPercentage ?? 0;
    final description = getFillDescription(fillPercentage);
    return 'Bin #${bin.binNumber} - $fillPercentage% - $description';
  }
}

/// Statistics about bin fill levels
class BinFillStats {
  final int high;
  final int medium;
  final int low;

  const BinFillStats({
    required this.high,
    required this.medium,
    required this.low,
  });

  int get total => high + medium + low;

  double get highPercentage => total > 0 ? (high / total) * 100 : 0;
  double get mediumPercentage => total > 0 ? (medium / total) * 100 : 0;
  double get lowPercentage => total > 0 ? (low / total) * 100 : 0;
}
