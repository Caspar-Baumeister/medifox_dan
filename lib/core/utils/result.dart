/// A generic result type for handling success and failure cases.
/// Follows the Result pattern for explicit error handling.
sealed class Result<T, E> {
  const Result();

  /// Returns true if the result is a success.
  bool get isSuccess => this is Success<T, E>;

  /// Returns true if the result is a failure.
  bool get isFailure => this is Failure<T, E>;

  /// Returns the success value or null if it's a failure.
  T? get valueOrNull {
    return switch (this) {
      Success<T, E>(value: final value) => value,
      Failure<T, E>() => null,
    };
  }

  /// Returns the error or null if it's a success.
  E? get errorOrNull {
    return switch (this) {
      Success<T, E>() => null,
      Failure<T, E>(error: final error) => error,
    };
  }

  /// Transforms the success value using the provided function.
  Result<U, E> map<U>(U Function(T value) transform) {
    return switch (this) {
      Success<T, E>(value: final value) => Success(transform(value)),
      Failure<T, E>(error: final error) => Failure(error),
    };
  }

  /// Transforms the error using the provided function.
  Result<T, F> mapError<F>(F Function(E error) transform) {
    return switch (this) {
      Success<T, E>(value: final value) => Success(value),
      Failure<T, E>(error: final error) => Failure(transform(error)),
    };
  }

  /// Executes the appropriate callback based on the result type.
  R when<R>({
    required R Function(T value) success,
    required R Function(E error) failure,
  }) {
    return switch (this) {
      Success<T, E>(value: final value) => success(value),
      Failure<T, E>(error: final error) => failure(error),
    };
  }
}

/// Represents a successful result containing a value.
final class Success<T, E> extends Result<T, E> {
  const Success(this.value);

  /// The success value.
  final T value;
}

/// Represents a failed result containing an error.
final class Failure<T, E> extends Result<T, E> {
  const Failure(this.error);

  /// The error value.
  final E error;
}
