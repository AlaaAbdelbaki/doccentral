import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'current_user_id_provider.g.dart';

/// Holds the local Users.id of the currently signed-in user, for the
/// lifetime of the app session — used to attribute audit/edit-log entries.
/// Must stay keepAlive for the same reason as CurrentRole (see
/// feedback_router_provider_keepalive memory): it's set imperatively by
/// sign-in/sign-up and read later without a guaranteed continuous watcher.
@Riverpod(keepAlive: true)
class CurrentUserId extends _$CurrentUserId {
  @override
  String? build() => null;

  void setUserId(String userId) => state = userId;

  void clear() => state = null;
}
