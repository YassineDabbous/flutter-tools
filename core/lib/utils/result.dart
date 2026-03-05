sealed class Result<S, E extends Object> {
  const Result();

  /// Returns true if the result is success.
  bool get isSuccess => this is Success<S, E>;

  /// Returns true if the result is failure.
  bool get isFailure => this is Failure<S, E>;

  /// Returns the value if success, or throws the error if failure.
  S get value {
    if (this is Success<S, E>) {
      return (this as Success<S, E>).data;
    }
    throw (this as Failure<S, E>).error;
  }

  /// Returns the error if failure, or null if success.
  E? get error {
    if (this is Failure<S, E>) {
      return (this as Failure<S, E>).error;
    }
    return null;
  }

  /// Pattern matching helper
  T when<T>({
    required T Function(S data) success,
    required T Function(E error) failure,
  }) {
    if (this is Success<S, E>) {
      return success((this as Success<S, E>).data);
    } else {
      return failure((this as Failure<S, E>).error);
    }
  }
}

class Success<S, E extends Object> extends Result<S, E> {
  final S data;
  const Success(this.data);
}

class Failure<S, E extends Object> extends Result<S, E> {
  @override
  final E error;
  const Failure(this.error);
}
