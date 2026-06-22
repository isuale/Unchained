import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:unchained/features/dashboard/providers/domain_lists_provider.dart';
import 'package:unchained/l10n/app_localizations.dart';

/// The "Blocklist" tab. Two sub-tabs:
///  - Blocklist: built-in blocked sites (read-only) + the user's own blocked
///    sites. Adding a domain blocks it via the native DNS engine.
///  - Whitelist: the user's allowed (un-blocked) sites. Starts empty; the
///    hidden built-in ~1000-site safelist lives natively and is not shown.
class BlocklistScreen extends ConsumerWidget {
  const BlocklistScreen({super.key});

  static const _bg = Colors.black;
  static const _blue = Color(0xFF1E5FFF);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: _bg,
        appBar: AppBar(
          backgroundColor: _bg,
          surfaceTintColor: _bg,
          automaticallyImplyLeading: false,
          title: Text(
            l.nav_blocklist,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          bottom: TabBar(
            indicatorColor: _blue,
            labelColor: Colors.white,
            unselectedLabelColor: const Color(0xFF888888),
            labelStyle: const TextStyle(fontWeight: FontWeight.w600),
            tabs: [
              Tab(text: l.blocklist_tab_block),
              Tab(text: l.blocklist_tab_allow),
            ],
          ),
        ),
        body: const SafeArea(
          top: false,
          child: TabBarView(
            children: [
              _BlocklistTab(),
              _WhitelistTab(),
            ],
          ),
        ),
      ),
    );
  }
}

/// Shared list-editing UI used by both tabs.
class _DomainListView extends StatefulWidget {
  const _DomainListView({
    required this.header,
    required this.subtitle,
    required this.inputHint,
    required this.emptyText,
    required this.builtin,
    required this.custom,
    required this.onAdd,
    required this.onRemove,
    required this.accent,
    required this.icon,
  });

  final String header;
  final String subtitle;
  final String inputHint;
  final String emptyText;

  /// Read-only entries shown first (the built-in blocked domains). Empty for
  /// the whitelist tab.
  final List<String> builtin;
  final List<String> custom;

  /// Returns the result so we can show the right snackbar. Receives raw input.
  final Future<DomainListResult> Function(String raw) onAdd;
  final Future<void> Function(String domain) onRemove;
  final Color accent;
  final IconData icon;

  @override
  State<_DomainListView> createState() => _DomainListViewState();
}

class _DomainListViewState extends State<_DomainListView> {
  final _controller = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_submitting) return;
    final raw = _controller.text.trim();
    if (raw.isEmpty) return;
    setState(() => _submitting = true);
    final result = await widget.onAdd(raw);
    if (!mounted) return;
    setState(() => _submitting = false);
    final l = AppLocalizations.of(context)!;
    String msg;
    switch (result) {
      case DomainListResult.ok:
        _controller.clear();
        msg = '"$raw" ✓';
      case DomainListResult.invalid:
        msg = l.blocklist_invalid;
      case DomainListResult.duplicate:
        msg = l.blocklist_duplicate;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF0A0F1C),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
      children: [
        Text(
          widget.header,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          widget.subtitle,
          style: const TextStyle(color: Color(0xFF9AA3B2), height: 1.4),
        ),
        const SizedBox(height: 16),
        // Input row
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                enabled: !_submitting,
                onSubmitted: (_) => _submit(),
                autocorrect: false,
                keyboardType: TextInputType.url,
                textInputAction: TextInputAction.done,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: widget.inputHint,
                  hintStyle: const TextStyle(color: Color(0xFF666666)),
                  filled: true,
                  fillColor: const Color(0xFF0A0E18),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF1C2233)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: widget.accent),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: _submitting ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: widget.accent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _submitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : Text(l.blocklist_add),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        // Built-in (read-only) entries
        for (final domain in widget.builtin)
          _DomainTile(
            domain: domain,
            icon: widget.icon,
            accent: widget.accent,
            badge: l.blocklist_builtin,
          ),
        // Custom entries (removable)
        if (widget.custom.isEmpty && widget.builtin.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 24),
            child: Center(
              child: Text(
                widget.emptyText,
                style: const TextStyle(color: Color(0xFF666666)),
              ),
            ),
          ),
        for (final domain in widget.custom)
          _DomainTile(
            domain: domain,
            icon: widget.icon,
            accent: widget.accent,
            onRemove: () => widget.onRemove(domain),
          ),
      ],
    );
  }
}

class _DomainTile extends StatelessWidget {
  const _DomainTile({
    required this.domain,
    required this.icon,
    required this.accent,
    this.badge,
    this.onRemove,
  });

  final String domain;
  final IconData icon;
  final Color accent;
  final String? badge;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF0A0E18),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF161B2A)),
      ),
      child: Row(
        children: [
          Icon(icon, color: accent, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              domain,
              style: const TextStyle(color: Colors.white, fontSize: 15),
            ),
          ),
          if (badge != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                badge!,
                style: TextStyle(
                    color: accent,
                    fontSize: 11,
                    fontWeight: FontWeight.w600),
              ),
            ),
          if (onRemove != null)
            IconButton(
              onPressed: onRemove,
              icon: const Icon(Icons.close, color: Color(0xFF888888), size: 20),
              splashRadius: 20,
            ),
        ],
      ),
    );
  }
}

class _BlocklistTab extends ConsumerWidget {
  const _BlocklistTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final actions = ref.read(domainListsActionsProvider);
    final custom = ref.watch(customBlocklistProvider);
    final builtin = ref.watch(builtinBlocklistProvider).asData?.value ?? const [];
    return _DomainListView(
      header: l.blocklist_block_header,
      subtitle: l.blocklist_block_sub,
      inputHint: l.blocklist_add_block_hint,
      emptyText: l.blocklist_block_empty,
      builtin: builtin,
      custom: custom,
      accent: const Color(0xFFE5484D),
      icon: Icons.block,
      onAdd: actions.addToBlocklist,
      onRemove: actions.removeFromBlocklist,
    );
  }
}

class _WhitelistTab extends ConsumerWidget {
  const _WhitelistTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final actions = ref.read(domainListsActionsProvider);
    final custom = ref.watch(customAllowlistProvider);
    return _DomainListView(
      header: l.blocklist_allow_header,
      subtitle: l.blocklist_allow_sub,
      inputHint: l.blocklist_add_allow_hint,
      emptyText: l.blocklist_allow_empty,
      builtin: const [],
      custom: custom,
      accent: const Color(0xFF30A46C),
      icon: Icons.check_circle_outline,
      onAdd: actions.addToAllowlist,
      onRemove: actions.removeFromAllowlist,
    );
  }
}
