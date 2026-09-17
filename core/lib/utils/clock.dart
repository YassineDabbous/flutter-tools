/// Server-authoritative countdown math shared by every Rebelo surface.
///
/// No client-side durations live here: every countdown ticks from a backend
/// `*_expires_at` paired with `server_now` (same server clock), so device
/// clock drift (±minutes) is irrelevant. Client-only constants are limited to
/// infrastructure cadence (GPS stall / polling), never "how long will phase X
/// take".
///
/// # Ownership rule
/// **Core is the only home** — auth, orders, rides, trips and radar all import
/// `TrackingTimers` from here instead of mirroring the math inline.
library;

/// Server-authoritative countdown math for tracking surfaces.
abstract final class TrackingTimers {
  // Client-only: GPS position stall threshold.
  static const gpsStall = 15;
  // Client-only polling cadence for the live-tracking refetch.
  static const refetch = 30;

  /// Remaining milliseconds from [expiresAt] to [serverNow] (ISO-8601, both
  /// on the server clock). `null` when either side is missing/unparsable;
  /// clamps to 0 when the deadline already passed. Callers treat `null` as
  /// "no deadline → hide the chip" and `0` as "expired → refetch".
  static int? remainingMs(String? expiresAt, String? serverNow) {
    final expiry = DateTime.tryParse(expiresAt ?? '');
    final now = DateTime.tryParse(serverNow ?? '');
    if (expiry == null || now == null) return null;
    final ms = expiry.difference(now).inMilliseconds;
    return ms < 0 ? 0 : ms;
  }

  /// [remainingMs] as whole seconds (`ceil` so a 1.2s deadline shows `2`).
  static int? remainingSeconds(String? expiresAt, String? serverNow) {
    final ms = remainingMs(expiresAt, serverNow);
    return ms == null ? null : (ms / 1000).ceil();
  }
}