import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'shared_preferences_provider.g.dart';

/// Injected at app startup via ProviderScope override.
/// Never resolves on its own — always overridden in main().
@riverpod
SharedPreferences sharedPreferences(Ref ref) => throw UnimplementedError();
