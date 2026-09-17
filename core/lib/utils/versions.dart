/// Semantic-version comparison shared by the bootstrap force-update gate.
///
/// # Ownership rule
/// **Core is the only home** — `compareVersions` must not be re-written in an
/// app/module. If a new comparison need appears (force-update, min-API, feature
/// gating), import from `package:core/core.dart`.
library;

/// Compares two dotted version strings (`a`, `b`) numerically, per segment.
///
/// Returns `-1` when `a < b`, `1` when `a > b`, `0` when equal. Non-numeric
/// segments count as `0`, and a longer version with equal prefix sorts
/// newer (`1.2` < `1.2.1`).
int compareVersions(String a, String b) {
  final partsA = a.split('.').map((e) => int.tryParse(e) ?? 0).toList();
  final partsB = b.split('.').map((e) => int.tryParse(e) ?? 0).toList();
  for (int i = 0; i < partsA.length && i < partsB.length; i++) {
    if (partsA[i] < partsB[i]) return -1;
    if (partsA[i] > partsB[i]) return 1;
  }
  return partsA.length.compareTo(partsB.length);
}