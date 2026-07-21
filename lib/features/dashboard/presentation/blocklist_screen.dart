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
    this.headerCard,
    this.permanentNote,
    required this.custom,
    required this.onAdd,
    this.onRemove,
    required this.accent,
    required this.icon,
  });

  final String header;
  final String subtitle;
  final String inputHint;
  final String emptyText;

  /// Optional summary card shown above the input (e.g. "1,000+ sites blocked").
  /// Null on the whitelist tab, which deliberately starts clear.
  final Widget? headerCard;

  /// Optional warning shown above the input, explaining that entries can't be
  /// removed. Null on the whitelist tab, which stays freely editable.
  final String? permanentNote;
  final List<String> custom;

  /// Returns the result so we can show the right snackbar. Receives raw input.
  final Future<DomainListResult> Function(String raw) onAdd;

  /// Null on the blocklist tab: entries there can never be removed (a
  /// deliberate commitment device), so no remove button is shown at all.
  final Future<void> Function(String domain)? onRemove;
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
        if (widget.headerCard != null) ...[
          const SizedBox(height: 16),
          widget.headerCard!,
        ],
        if (widget.permanentNote != null) ...[
          const SizedBox(height: 12),
          _PermanentNote(text: widget.permanentNote!),
        ],
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
        // Custom entries (removable)
        if (widget.custom.isEmpty)
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
            onRemove: widget.onRemove == null
                ? null
                : () => widget.onRemove!(domain),
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
    this.onRemove,
  });

  final String domain;
  final IconData icon;
  final Color accent;
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
    final count = ref.watch(builtinBlocklistCountProvider).asData?.value ?? 0;
    return _DomainListView(
      header: l.blocklist_block_header,
      subtitle: l.blocklist_block_sub,
      inputHint: l.blocklist_add_block_hint,
      emptyText: l.blocklist_block_empty,
      headerCard: count > 0
          ? _BuiltinSummaryCard(text: l.blocklist_builtin_summary(count))
          : null,
      permanentNote: l.blocklist_block_permanent_note,
      custom: custom,
      accent: const Color(0xFFE5484D),
      icon: Icons.block,
      onAdd: actions.addToBlocklist,
    );
  }
}

/// "🛡 N known porn sites are blocked automatically" — stands in for listing
/// the ~1000 built-in domains individually (which would be unusable to scroll).
class _BuiltinSummaryCard extends StatelessWidget {
  const _BuiltinSummaryCard({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF13101A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF3A1F22)),
      ),
      child: Row(
        children: [
          const Icon(Icons.shield, color: Color(0xFFE5484D), size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(color: Colors.white, height: 1.3),
            ),
          ),
        ],
      ),
    );
  }
}

/// "Sites you add here can't be removed" — warns before the user commits a
/// domain to the blocklist, since there is no way to undo it afterward.
class _PermanentNote extends StatelessWidget {
  const _PermanentNote({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1408),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF3A2F1F)),
      ),
      child: Row(
        children: [
          const Icon(Icons.lock_outline, color: Color(0xFFE5A93D), size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(color: Color(0xFFE5A93D), height: 1.3),
            ),
          ),
        ],
      ),
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
      custom: custom,
      accent: const Color(0xFF30A46C),
      icon: Icons.check_circle_outline,
      onAdd: actions.addToAllowlist,
      onRemove: actions.removeFromAllowlist,
    );
  }
}
