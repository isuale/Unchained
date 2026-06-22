/// Pure helpers for the user-managed block / allow domain lists.
///
/// Domains are stored in the DB as a single newline-separated string. These
/// helpers parse that storage form and normalize whatever the user typed into
/// a bare host (lowercase, no scheme, no path, no `www.`).
library;

/// Splits the stored newline-separated string into a clean list of domains,
/// dropping blanks and duplicates while preserving order.
List<String> parseDomainList(String? stored) {
  if (stored == null || stored.trim().isEmpty) return const [];
  final seen = <String>{};
  final out = <String>[];
  for (final raw in stored.split('\n')) {
    final d = raw.trim().toLowerCase();
    if (d.isEmpty) continue;
    if (seen.add(d)) out.add(d);
  }
  return out;
}

/// Normalizes free-typed input into a bare registrable host, e.g.
/// `https://www.PornHub.com/foo` -> `pornhub.com`. Returns null when the
/// input has no usable host (so the UI can reject it).
String? normalizeDomain(String input) {
  var s = input.trim().toLowerCase();
  if (s.isEmpty) return null;
  // Strip scheme.
  final scheme = s.indexOf('://');
  if (scheme != -1) s = s.substring(scheme + 3);
  // Strip any path / query / port.
  s = s.split('/').first.split('?').first.split('#').first.split(':').first;
  // Strip a leading www.
  if (s.startsWith('www.')) s = s.substring(4);
  s = s.trim();
  if (s.isEmpty) return null;
  // Must look like a domain: at least one dot, only valid host characters.
  if (!s.contains('.')) return null;
  final valid = RegExp(r'^[a-z0-9.-]+$');
  if (!valid.hasMatch(s)) return null;
  return s;
}
