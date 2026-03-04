import 'package:equatable/equatable.dart';

/// Tracks the progress of a batch of actions.
class BatchProgress extends Equatable {
  final int total;
  final int completed;
  final int failed;
  final String? currentActionLabel;

  const BatchProgress({
    required this.total,
    this.completed = 0,
    this.failed = 0,
    this.currentActionLabel,
  });

  double get progress => total == 0 ? 0 : (completed + failed) / total;
  bool get isFinished => (completed + failed) >= total;

  BatchProgress copyWith({
    int? completed,
    int? failed,
    String? currentActionLabel,
  }) {
    return BatchProgress(
      total: total,
      completed: completed ?? this.completed,
      failed: failed ?? this.failed,
      currentActionLabel: currentActionLabel ?? this.currentActionLabel,
    );
  }

  @override
  List<Object?> get props => [total, completed, failed, currentActionLabel];
}
