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

/// Normalizes free-typed input into a bare host, e.g.
/// `https://www.PornHub.com/foo` -> `pornhub.com`. Returns null when the
/// input has no usable host (so the UI can reject it). Keeps the exact host
/// (minus scheme/path/`www.`); use [registrableDomain] on top of this to
/// reduce to the whole site.
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

/// Common two-label public suffixes (e.g. `co.uk`, `com.br`). Used so that
/// reducing a host to its registrable domain keeps three labels for these
/// (`bbc.co.uk`) instead of wrongly collapsing to `co.uk`. Not exhaustive —
/// covers the ccTLDs a user is realistically going to type. Anything not here
/// is treated as a single-label TLD (the `.com`/`.net`/`.xxx` common case).
const _twoLevelSuffixes = <String>{
  'co.uk', 'org.uk', 'me.uk', 'ac.uk', 'gov.uk', 'net.uk', 'ltd.uk',
  'com.au', 'net.au', 'org.au', 'com.br', 'com.mx', 'com.ar', 'com.co',
  'com.tr', 'com.pl', 'com.ua', 'com.ru', 'com.cn', 'com.hk', 'com.tw',
  'com.sg', 'com.my', 'com.ph', 'com.vn', 'com.pk', 'com.ng', 'com.eg',
  'co.jp', 'co.kr', 'co.in', 'co.za', 'co.nz', 'co.id', 'co.il', 'co.th',
  'com.es', 'com.pt', 'com.gr', 'com.sa', 'com.ec', 'com.pe', 'com.uy',
  'com.ve', 'com.do', 'com.gt', 'org.br', 'net.br', 'gob.mx', 'org.mx',
};

/// Reduces a host to the whole **registrable domain** (the site itself, aka
/// "eTLD+1"), so a user who blocks any part of a site blocks the whole thing:
/// `pt.xgroovy.com` / `www.xgroovy.com` / `xgroovy.com` all become
/// `xgroovy.com`. The native engine already blocks a domain *and everything
/// under it*, so storing the registrable domain covers every subdomain.
/// Multi-label ccTLDs (`bbc.co.uk`) are preserved via [_twoLevelSuffixes].
/// Input must be a host already cleaned by [normalizeDomain].
String registrableDomain(String host) {
  final labels = host.split('.');
  if (labels.length <= 2) return host;
  // Default public suffix is the single TLD; bump to two labels for the known
  // ccTLD second levels so we never collapse past the registrable label.
  var suffixLen = 1;
  final lastTwo = labels.sublist(labels.length - 2).join('.');
  if (_twoLevelSuffixes.contains(lastTwo)) suffixLen = 2;
  final keep = suffixLen + 1;
  if (labels.length <= keep) return host;
  return labels.sublist(labels.length - keep).join('.');
}

/// Normalizes free-typed input for the **blocklist**: a cleaned host reduced to
/// its whole registrable domain, or null if unusable. This is what makes
/// "block a site" block the entire site (every subdomain), which is what a user
/// expects from a porn/distraction blocker.
String? normalizeBlockDomain(String input) {
  final host = normalizeDomain(input);
  if (host == null) return null;
  return registrableDomain(host);
}
