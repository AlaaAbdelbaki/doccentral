import 'dart:math';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

const _keyAlias = 'docentral_db_key';

class DatabaseKeyService {
  const DatabaseKeyService(this._storage);

  final FlutterSecureStorage _storage;

  Future<String> getOrCreateKey() async {
    final existing = await _storage.read(key: _keyAlias);
    if (existing != null) return existing;

    final key = _generateKey();
    await _storage.write(key: _keyAlias, value: key);
    return key;
  }

  String _generateKey() {
    final random = Random.secure();
    return List.generate(64, (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0')).join();
  }
}
