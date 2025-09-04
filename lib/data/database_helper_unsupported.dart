import 'database_helper_interface.dart';

// This file is used as a fallback to prevent compile errors on unsupported platforms.
Future<DatabaseHelperInterface> getInitializedDatabaseHelper() async {
  throw UnimplementedError('Platform not supported');
}
