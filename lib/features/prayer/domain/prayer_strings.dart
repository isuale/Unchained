import 'package:unchained/features/prayer/domain/prayers.dart';

/// UI strings for the prayer screens (home, gate, chooser, picker) in the three
/// supported languages. Pure data; interpolated values are passed as arguments.
class PS {
  const PS._();

  static String _p(Lang l, String en, String es, String pt) => switch (l) {
        Lang.en => en,
        Lang.pt => pt,
        Lang.es => es,
      };

  // Home
  static String thanksTitle(Lang l) => _p(l, 'Thanks be to God', 'Gracias a Dios', 'Graças a Deus');
  static String verse(Lang l) => _p(
        l,
        'Give thanks in all circumstances; this is God’s will.\n— 1 Thessalonians 5:18',
        'Dad gracias en todo, porque esta es la voluntad de Dios.\n— 1 Tesalonicenses 5:18',
        'Em tudo dai graças, pois esta é a vontade de Deus.\n— 1 Tessalonicenses 5:18',
      );
  static String streak(Lang l, int n) {
    final unit = _p(l, n == 1 ? 'day' : 'days', n == 1 ? 'día' : 'días', n == 1 ? 'dia' : 'dias');
    final tail = _p(l, 'giving thanks', 'dando gracias', 'dando graças');
    return '$n $unit $tail';
  }

  static String totalPrayers(Lang l, int n) {
    final unit = _p(l, n == 1 ? 'prayer' : 'prayers', n == 1 ? 'oración' : 'oraciones', n == 1 ? 'oração' : 'orações');
    final tail = _p(l, 'in total', 'en total', 'no total');
    return '$n $unit $tail';
  }

  static String prayNow(Lang l) => _p(l, 'Pray now', 'Rezar ahora', 'Rezar agora');
  static String blockedApps(Lang l) => _p(l, 'Blocked apps', 'Apps bloqueadas', 'Apps bloqueadas');
  static String allWord(Lang l) => _p(l, 'All', 'Todas', 'Todas');
  static String noAppsYet(Lang l) => _p(l, 'You haven’t blocked any app yet.', 'Aún no has bloqueado ninguna app.', 'Ainda não bloqueaste nenhuma app.');
  static String allBlocked(Lang l) => _p(l, 'All apps are locked behind prayer.', 'Todas las apps están bloqueadas tras la oración.', 'Todas as apps estão bloqueadas após a oração.');
  static String someBlocked(Lang l, int n) => _p(l, '$n app(s) locked behind prayer.', '$n app(s) bloqueada(s) tras la oración.', '$n app(s) bloqueada(s) após a oração.');

  // Chooser
  static String whatToPray(Lang l) => _p(l, 'What do you want to pray?', '¿Qué quieres rezar?', 'O que queres rezar?');
  static String rosaryTitle(Lang l) => _p(l, 'Holy Rosary', 'Santo Rosario', 'Santo Rosário');
  static String rosarySub(Lang l) => _p(l, 'Full prayer · 20 min', 'Oración completa · 20 min', 'Oração completa · 20 min');
  static String thanksChoice(Lang l) => _p(l, 'Thanksgiving', 'Acción de Gracias', 'Ação de Graças');
  static String thanksSub(Lang l) => _p(l, 'Psalms and gratitude · 5 min', 'Salmos y gratitud · 5 min', 'Salmos e gratidão · 5 min');

  // Gate
  static String prayAtLeast(Lang l, int minutes) => _p(
        l,
        'Pray for at least $minutes minutes. The timer pauses if you leave the app.',
        'Ora al menos $minutes minutos. El tiempo se pausa si sales de la app.',
        'Reza pelo menos $minutes minutos. O tempo pausa se saíres da app.',
      );
  static String canFinishNow(Lang l) => _p(l, 'You may finish whenever you wish. The timer pauses if you leave.', 'Puedes terminar cuando quieras. El tiempo se pausa si sales.', 'Podes terminar quando quiseres. O tempo pausa se saíres.');
  static String completedHint(Lang l) => _p(l, 'Prayer complete. Tap Amen to continue.', 'Oración completada. Pulsa Amén para continuar.', 'Oração concluída. Toca Amém para continuar.');
  static String amen(Lang l) => _p(l, 'Amen', 'Amén', 'Amém');
  static String finishedAmen(Lang l) => _p(l, 'I’m done · Amen', 'He terminado · Amén', 'Terminei · Amém');
  static String prayToContinue(Lang l, int seconds) => _p(l, 'Pray to continue · ${seconds}s', 'Ora para continuar · ${seconds}s', 'Reza para continuar · ${seconds}s');
  static String completedToast(Lang l) => _p(l, 'Thanks be to God · Prayer completed', 'Gracias a Dios · Oración completada', 'Graças a Deus · Oração concluída');
  static String changeMysteries(Lang l) => _p(l, 'Mysteries', 'Misterios', 'Mistérios');
  static String today(Lang l) => _p(l, 'Today', 'Hoy', 'Hoje');

  // Uninstall-protection scripture lock screen
  static String stayUnchained(Lang l) => _p(l, 'Stay unchained', 'Permanece libre', 'Permanece livre');
  static String turnOffProtection(Lang l) => _p(l, 'Turn off protection', 'Desactivar la protección', 'Desativar a proteção');
  static String copyScripture(Lang l) => _p(
        l,
        'Copy these 800 letters of Scripture exactly to continue. If the timer runs out, it clears and you start over.',
        'Copia exactamente estas 800 letras de la Escritura para continuar. Si el tiempo se agota, se borra y vuelves a empezar.',
        'Copia exatamente estas 800 letras da Escritura para continuar. Se o tempo acabar, apaga-se e recomeças.',
      );
  static String typePassageHere(Lang l) => _p(l, 'Type the passage here…', 'Escribe el pasaje aquí…', 'Escreve a passagem aqui…');
  static String charactersCount(Lang l, int matched, int total) => _p(l, '$matched / $total characters', '$matched / $total caracteres', '$matched / $total caracteres');
  static String cancel(Lang l) => _p(l, 'Cancel', 'Cancelar', 'Cancelar');

  // Language picker
  static String language(Lang l) => _p(l, 'Language', 'Idioma', 'Idioma');
  static String langName(Lang l) => switch (l) {
        Lang.en => 'English',
        Lang.es => 'Español',
        Lang.pt => 'Português',
      };
}
