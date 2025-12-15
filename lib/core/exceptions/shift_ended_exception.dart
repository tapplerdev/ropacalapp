/// Exception thrown when a shift has ended and is no longer active
class ShiftEndedException implements Exception {
  final String driverId;
  final String? driverName;

  ShiftEndedException(this.driverId, {this.driverName});

  @override
  String toString() {
    if (driverName != null) {
      return 'ShiftEndedException: $driverName has completed their shift';
    }
    return 'ShiftEndedException: Driver $driverId has completed their shift';
  }
}
