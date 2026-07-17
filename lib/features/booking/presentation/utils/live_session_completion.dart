import 'package:orko_hubco/core/utils/app_storage/app_storage.dart';
import 'package:orko_hubco/features/booking/domain/entities/live_session_entity.dart';

/// Tracks the live-session id across polls — and across app kills, via
/// [AppStorage] — so both the bookings Active tab and the charging-status
/// screen can detect "the session I was watching just finished" and surface
/// the post-session summary.
class LiveSessionCompletion {
  LiveSessionCompletion._();

  /// Call with every successful `live-session/` payload.
  ///
  /// While [session] is active its id is persisted, so a kill/relaunch still
  /// remembers which session was running. When [session] reports inactive
  /// while an id is still persisted, that id is returned: the session has
  /// finished (possibly while the app was dead) and the summary should be
  /// shown. Returns null when there's nothing to surface. The persisted id is
  /// only cleared once the summary is actually shown (see SessionSummaryPage),
  /// so detection keeps re-firing until the user has seen it.
  static int? register(LiveSessionEntity session) {
    if (session.active) {
      final id = session.sessionId;
      if (id != null && AppStorage.activeChargeSessionId != id) {
        AppStorage.setActiveChargeSessionId(id);
      }
      return null;
    }
    return AppStorage.activeChargeSessionId;
  }
}
