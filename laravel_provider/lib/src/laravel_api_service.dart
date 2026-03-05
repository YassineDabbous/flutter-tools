import 'package:skeleton/skeleton.dart';
import '../mappers/error_mapper.dart';

/// Base class for Laravel service implementations.
/// Provides a standard way to handle async requests and map errors.
///
/// ID type defaults to [int] for Laravel.
abstract class LaravelApiService<Model, EditRequest, SearchRequest, ID>
    implements BaseApiService<Model, EditRequest, SearchRequest, ID> {
  /// Helper to catch exceptions and map them to Failures.
  Future<T> handle<T>(Future<T> Function() call) async {
    try {
      return await call();
    } catch (e) {
      throw LaravelErrorMapper.map(e);
    }
  }

  // Common implementation patterns for Laravel can be added here
}
