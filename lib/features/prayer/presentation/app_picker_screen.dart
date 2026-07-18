import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:unchained/features/prayer/data/installed_apps_service.dart';
import 'package:unchained/features/prayer/data/prayer_repository.dart';

/// Lets the user choose what the prayer gate guards: either EVERY app, or a
/// hand-picked set. The choice and the per-app selection are persisted live
/// (LockedApps + the prayerLockAllApps flag); native enforcement reads them in
/// a later phase.
class AppPickerScreen extends ConsumerStatefulWidget {
  const AppPickerScreen({super.key});

  @override
  ConsumerState<AppPickerScreen> createState() => _AppPickerScreenState();
}

class _AppPickerScreenState extends ConsumerState<AppPickerScreen> {
  static const _accent = Color(0xFF1E5FFF);
  static const _card = Color(0xFF0A0E18);
  static const _border = Color(0xFF1B2435);
  static const _dim = Color(0xFF8A94A6);

  String _query = '';

  @override
  Widget build(BuildContext context) {
    final lockAll = ref.watch(lockAllAppsProvider).asData?.value ?? false;
    final locked = ref.watch(lockedAppsProvider).asData?.value ?? const [];
    final lockedPkgs = {for (final a in locked) a.packageName};

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(
          'Apps bloqueadas',
          style: GoogleFonts.dmSerifDisplay(color: Colors.white, fontSize: 22),
        ),
      ),
      body: Column(
        children: [
          _lockAllCard(lockAll),
          if (!lockAll) ...[
            _searchField(),
            Expanded(child: _appList(lockedPkgs)),
          ] else
            Expanded(child: _lockAllExplainer()),
        ],
      ),
    );
  }

  Widget _lockAllCard(bool lockAll) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _border),
      ),
      child: SwitchListTile(
        value: lockAll,
        activeThumbColor: _accent,
        onChanged: (v) =>
            ref.read(prayerRepositoryProvider).setLockAllApps(v),
        title: Text(
          'Bloquear TODAS las apps',
          style: GoogleFonts.inter(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          lockAll
              ? 'Toda app abierta pedirá oración.'
              : 'Elige abajo qué apps bloquear.',
          style: GoogleFonts.inter(color: _dim, fontSize: 13),
        ),
      ),
    );
  }

  Widget _lockAllExplainer() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.lock, color: _accent, size: 48),
            const SizedBox(height: 16),
            Text(
              'Todas las apps quedarán bloqueadas',
              style:
                  GoogleFonts.inter(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Al abrir cualquier app tendrás que orar para desbloquearlas '
              'todas durante 24 horas. Desactiva esta opción para elegir apps '
              'concretas.',
              style: GoogleFonts.inter(color: _dim, fontSize: 14, height: 1.5),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _searchField() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: TextField(
        onChanged: (v) => setState(() => _query = v.trim().toLowerCase()),
        style: GoogleFonts.inter(color: Colors.white),
        cursorColor: _accent,
        decoration: InputDecoration(
          hintText: 'Buscar app…',
          hintStyle: GoogleFonts.inter(color: _dim),
          prefixIcon: const Icon(Icons.search, color: _dim),
          filled: true,
          fillColor: _card,
          contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: _border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: _border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: _accent),
          ),
        ),
      ),
    );
  }

  Widget _appList(Set<String> lockedPkgs) {
    final asyncApps = ref.watch(installedAppsProvider);
    return asyncApps.when(
      loading: () => const Center(
        child: CircularProgressIndicator(color: _accent),
      ),
      error: (e, _) => Center(
        child: Text(
          'No se pudieron cargar las apps.',
          style: GoogleFonts.inter(color: _dim),
        ),
      ),
      data: (apps) {
        final filtered = _query.isEmpty
            ? apps
            : apps
                .where((a) => a.label.toLowerCase().contains(_query))
                .toList();
        if (filtered.isEmpty) {
          return Center(
            child: Text(
              'Sin resultados.',
              style: GoogleFonts.inter(color: _dim),
            ),
          );
        }
        return ListView.builder(
          itemCount: filtered.length,
          itemBuilder: (context, i) {
            final app = filtered[i];
            final checked = lockedPkgs.contains(app.packageName);
            return CheckboxListTile(
              value: checked,
              activeColor: _accent,
              controlAffinity: ListTileControlAffinity.trailing,
              secondary: _appIcon(app),
              title: Text(
                app.label,
                style: GoogleFonts.inter(color: Colors.white, fontSize: 15),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              onChanged: (v) {
                final repo = ref.read(prayerRepositoryProvider);
                if (v == true) {
                  repo.addLockedApp(app.packageName, app.label);
                } else {
                  repo.removeLockedApp(app.packageName);
                }
              },
            );
          },
        );
      },
    );
  }

  Widget _appIcon(InstalledApp app) {
    if (app.icon == null) {
      return const CircleAvatar(
        backgroundColor: _card,
        child: Icon(Icons.android, color: _dim),
      );
    }
    return SizedBox(
      width: 40,
      height: 40,
      child: Image.memory(app.icon!, gaplessPlayback: true),
    );
  }
}
