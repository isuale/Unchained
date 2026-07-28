import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_pt.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('es'),
    Locale('pt'),
  ];

  /// No description provided for @app_title.
  ///
  /// In es, this message translates to:
  /// **'Be Unchained'**
  String get app_title;

  /// No description provided for @welcome_tagline.
  ///
  /// In es, this message translates to:
  /// **'Break Free. Live Free.'**
  String get welcome_tagline;

  /// No description provided for @welcome_get_started.
  ///
  /// In es, this message translates to:
  /// **'Get Started'**
  String get welcome_get_started;

  /// No description provided for @welcome_have_account.
  ///
  /// In es, this message translates to:
  /// **'¿Ya tienes una cuenta?'**
  String get welcome_have_account;

  /// No description provided for @welcome_sign_in.
  ///
  /// In es, this message translates to:
  /// **'Iniciar sesión'**
  String get welcome_sign_in;

  /// No description provided for @ai_plan_recommended_label.
  ///
  /// In es, this message translates to:
  /// **'Recomendado para ti'**
  String get ai_plan_recommended_label;

  /// No description provided for @ai_plan_title.
  ///
  /// In es, this message translates to:
  /// **'Plan IA'**
  String get ai_plan_title;

  /// No description provided for @ai_plan_subtitle.
  ///
  /// In es, this message translates to:
  /// **'Personalizado a tu situación'**
  String get ai_plan_subtitle;

  /// No description provided for @ai_plan_price_period.
  ///
  /// In es, this message translates to:
  /// **'al mes'**
  String get ai_plan_price_period;

  /// No description provided for @ai_plan_currency.
  ///
  /// In es, this message translates to:
  /// **'EUR'**
  String get ai_plan_currency;

  /// No description provided for @ai_plan_feature_1.
  ///
  /// In es, this message translates to:
  /// **'Bloquea todos los sitios pornográficos'**
  String get ai_plan_feature_1;

  /// No description provided for @ai_plan_feature_2.
  ///
  /// In es, this message translates to:
  /// **'Sin anuncios'**
  String get ai_plan_feature_2;

  /// No description provided for @ai_plan_feature_3.
  ///
  /// In es, this message translates to:
  /// **'Elige la duración de tu bloqueo'**
  String get ai_plan_feature_3;

  /// No description provided for @ai_plan_feature_4.
  ///
  /// In es, this message translates to:
  /// **'Bloquea apps con temporizador'**
  String get ai_plan_feature_4;

  /// No description provided for @ai_plan_feature_5.
  ///
  /// In es, this message translates to:
  /// **'La IA personalizada calcula los días exactos'**
  String get ai_plan_feature_5;

  /// No description provided for @ai_plan_cta.
  ///
  /// In es, this message translates to:
  /// **'Empezar Plan IA'**
  String get ai_plan_cta;

  /// No description provided for @ai_plan_view_others.
  ///
  /// In es, this message translates to:
  /// **'Ver otros planes'**
  String get ai_plan_view_others;

  /// No description provided for @analyzing_title.
  ///
  /// In es, this message translates to:
  /// **'Analizando tu perfil'**
  String get analyzing_title;

  /// No description provided for @analyzing_step_1.
  ///
  /// In es, this message translates to:
  /// **'Analizando tus detonantes...'**
  String get analyzing_step_1;

  /// No description provided for @analyzing_step_2.
  ///
  /// In es, this message translates to:
  /// **'Evaluando frecuencia...'**
  String get analyzing_step_2;

  /// No description provided for @analyzing_step_3.
  ///
  /// In es, this message translates to:
  /// **'Calculando severidad...'**
  String get analyzing_step_3;

  /// No description provided for @analyzing_step_4.
  ///
  /// In es, this message translates to:
  /// **'Preparando tu plan...'**
  String get analyzing_step_4;

  /// No description provided for @analyzing_addicted_label.
  ///
  /// In es, this message translates to:
  /// **'% de adicción'**
  String get analyzing_addicted_label;

  /// No description provided for @analyzing_recommend_label.
  ///
  /// In es, this message translates to:
  /// **'Te recomendamos'**
  String get analyzing_recommend_label;

  /// No description provided for @analyzing_plan_free_trial_name.
  ///
  /// In es, this message translates to:
  /// **'Prueba Gratis'**
  String get analyzing_plan_free_trial_name;

  /// No description provided for @analyzing_plan_free_trial_desc.
  ///
  /// In es, this message translates to:
  /// **'Pruébalo sin compromiso, gratis por 1 mes'**
  String get analyzing_plan_free_trial_desc;

  /// No description provided for @analyzing_plan_monthly_name.
  ///
  /// In es, this message translates to:
  /// **'Mensual'**
  String get analyzing_plan_monthly_name;

  /// No description provided for @analyzing_plan_monthly_desc.
  ///
  /// In es, this message translates to:
  /// **'Control personalizado de tu bloqueo'**
  String get analyzing_plan_monthly_desc;

  /// No description provided for @analyzing_plan_ai_plan_name.
  ///
  /// In es, this message translates to:
  /// **'Plan IA'**
  String get analyzing_plan_ai_plan_name;

  /// No description provided for @analyzing_plan_ai_plan_desc.
  ///
  /// In es, this message translates to:
  /// **'La IA personalizada calcula los días exactos para ti'**
  String get analyzing_plan_ai_plan_desc;

  /// No description provided for @analyzing_plan_forever_name.
  ///
  /// In es, this message translates to:
  /// **'Para Siempre'**
  String get analyzing_plan_forever_name;

  /// No description provided for @analyzing_plan_forever_desc.
  ///
  /// In es, this message translates to:
  /// **'Bloqueo permanente y total de todo lo que elijas'**
  String get analyzing_plan_forever_desc;

  /// No description provided for @analyzing_see_plan_button.
  ///
  /// In es, this message translates to:
  /// **'Ver Mi Plan'**
  String get analyzing_see_plan_button;

  /// No description provided for @analyzing_view_others_button.
  ///
  /// In es, this message translates to:
  /// **'Ver otros planes'**
  String get analyzing_view_others_button;

  /// No description provided for @free_trial_name.
  ///
  /// In es, this message translates to:
  /// **'Prueba Gratis'**
  String get free_trial_name;

  /// No description provided for @free_trial_price.
  ///
  /// In es, this message translates to:
  /// **'Gratis por 1 mes'**
  String get free_trial_price;

  /// No description provided for @free_trial_feature_1.
  ///
  /// In es, this message translates to:
  /// **'Bloqueo de sitios pornográficos'**
  String get free_trial_feature_1;

  /// No description provided for @free_trial_feature_2.
  ///
  /// In es, this message translates to:
  /// **'Sin anuncios'**
  String get free_trial_feature_2;

  /// No description provided for @free_trial_feature_3.
  ///
  /// In es, this message translates to:
  /// **'Seguimiento básico del progreso'**
  String get free_trial_feature_3;

  /// No description provided for @free_trial_cta.
  ///
  /// In es, this message translates to:
  /// **'Comenzar prueba gratis'**
  String get free_trial_cta;

  /// No description provided for @monthly_name.
  ///
  /// In es, this message translates to:
  /// **'Mensual'**
  String get monthly_name;

  /// No description provided for @monthly_price.
  ///
  /// In es, this message translates to:
  /// **'5,99 € / mes'**
  String get monthly_price;

  /// No description provided for @monthly_feature_1.
  ///
  /// In es, this message translates to:
  /// **'Todo lo del plan gratuito'**
  String get monthly_feature_1;

  /// No description provided for @monthly_feature_2.
  ///
  /// In es, this message translates to:
  /// **'Elige tus días de recuperación'**
  String get monthly_feature_2;

  /// No description provided for @monthly_feature_3.
  ///
  /// In es, this message translates to:
  /// **'Bloquea apps con temporizador'**
  String get monthly_feature_3;

  /// No description provided for @monthly_cta.
  ///
  /// In es, this message translates to:
  /// **'Obtener mensual'**
  String get monthly_cta;

  /// No description provided for @forever_name.
  ///
  /// In es, this message translates to:
  /// **'Para Siempre'**
  String get forever_name;

  /// No description provided for @forever_price.
  ///
  /// In es, this message translates to:
  /// **'15,99 € / mes'**
  String get forever_price;

  /// No description provided for @forever_feature_1.
  ///
  /// In es, this message translates to:
  /// **'Todo lo del plan Mensual'**
  String get forever_feature_1;

  /// No description provided for @forever_feature_2.
  ///
  /// In es, this message translates to:
  /// **'Modo de bloqueo permanente: la protección queda siempre activada'**
  String get forever_feature_2;

  /// No description provided for @forever_feature_3.
  ///
  /// In es, this message translates to:
  /// **'Lista personalizada de webs bloqueadas y permitidas'**
  String get forever_feature_3;

  /// No description provided for @forever_feature_4.
  ///
  /// In es, this message translates to:
  /// **'Bloquea feeds que distraen: Reels, Shorts, TikTok e Historias de Snapchat'**
  String get forever_feature_4;

  /// No description provided for @forever_feature_5.
  ///
  /// In es, this message translates to:
  /// **'Protección contra desinstalación: no se puede eliminar la app mientras está bloqueada'**
  String get forever_feature_5;

  /// No description provided for @forever_tagline.
  ///
  /// In es, this message translates to:
  /// **'Nuestro plan más fuerte: una protección que no se desactiva.'**
  String get forever_tagline;

  /// No description provided for @forever_cta.
  ///
  /// In es, this message translates to:
  /// **'Obtener Forever'**
  String get forever_cta;

  /// No description provided for @ai_plan_price_short.
  ///
  /// In es, this message translates to:
  /// **'9,99 € / mes'**
  String get ai_plan_price_short;

  /// No description provided for @plans_all_title.
  ///
  /// In es, this message translates to:
  /// **'Todos los planes'**
  String get plans_all_title;

  /// No description provided for @plans_recommended_badge.
  ///
  /// In es, this message translates to:
  /// **'Recomendado'**
  String get plans_recommended_badge;

  /// No description provided for @plans_card_cta.
  ///
  /// In es, this message translates to:
  /// **'Ver plan'**
  String get plans_card_cta;

  /// No description provided for @common_coming_soon.
  ///
  /// In es, this message translates to:
  /// **'Próximamente'**
  String get common_coming_soon;

  /// No description provided for @common_working_on_it.
  ///
  /// In es, this message translates to:
  /// **'En desarrollo'**
  String get common_working_on_it;

  /// No description provided for @protection_activate.
  ///
  /// In es, this message translates to:
  /// **'Activar protección'**
  String get protection_activate;

  /// No description provided for @protection_stop.
  ///
  /// In es, this message translates to:
  /// **'Detener protección'**
  String get protection_stop;

  /// No description provided for @protection_status_on.
  ///
  /// In es, this message translates to:
  /// **'Protegido'**
  String get protection_status_on;

  /// No description provided for @protection_status_off.
  ///
  /// In es, this message translates to:
  /// **'No activo'**
  String get protection_status_off;

  /// No description provided for @dashboard_plan_pill_free_trial.
  ///
  /// In es, this message translates to:
  /// **'Prueba Gratis'**
  String get dashboard_plan_pill_free_trial;

  /// No description provided for @dashboard_plan_pill_monthly.
  ///
  /// In es, this message translates to:
  /// **'Mensual'**
  String get dashboard_plan_pill_monthly;

  /// No description provided for @dashboard_plan_pill_ai_plan.
  ///
  /// In es, this message translates to:
  /// **'Plan IA'**
  String get dashboard_plan_pill_ai_plan;

  /// No description provided for @dashboard_plan_pill_forever.
  ///
  /// In es, this message translates to:
  /// **'Forever'**
  String get dashboard_plan_pill_forever;

  /// No description provided for @dashboard_streak.
  ///
  /// In es, this message translates to:
  /// **'{days} días protegido'**
  String dashboard_streak(int days);

  /// No description provided for @dashboard_protection_title.
  ///
  /// In es, this message translates to:
  /// **'Protección'**
  String get dashboard_protection_title;

  /// No description provided for @dashboard_protection_active.
  ///
  /// In es, this message translates to:
  /// **'Activa'**
  String get dashboard_protection_active;

  /// No description provided for @dashboard_protection_off.
  ///
  /// In es, this message translates to:
  /// **'Desactivada'**
  String get dashboard_protection_off;

  /// No description provided for @dashboard_strictness_title.
  ///
  /// In es, this message translates to:
  /// **'NIVEL DE PROTECCIÓN'**
  String get dashboard_strictness_title;

  /// No description provided for @dashboard_strictness_basic.
  ///
  /// In es, this message translates to:
  /// **'Básico'**
  String get dashboard_strictness_basic;

  /// No description provided for @dashboard_strictness_strict.
  ///
  /// In es, this message translates to:
  /// **'Estricto'**
  String get dashboard_strictness_strict;

  /// No description provided for @dashboard_section_core.
  ///
  /// In es, this message translates to:
  /// **'Protección principal'**
  String get dashboard_section_core;

  /// No description provided for @dashboard_section_social.
  ///
  /// In es, this message translates to:
  /// **'Bloqueo social'**
  String get dashboard_section_social;

  /// No description provided for @dashboard_section_content.
  ///
  /// In es, this message translates to:
  /// **'Filtros de contenido'**
  String get dashboard_section_content;

  /// No description provided for @dashboard_section_app.
  ///
  /// In es, this message translates to:
  /// **'Control de apps'**
  String get dashboard_section_app;

  /// No description provided for @dashboard_section_advanced.
  ///
  /// In es, this message translates to:
  /// **'Avanzado'**
  String get dashboard_section_advanced;

  /// No description provided for @dashboard_advanced_subtitle.
  ///
  /// In es, this message translates to:
  /// **'Aumenta el nivel de protección'**
  String get dashboard_advanced_subtitle;

  /// No description provided for @dashboard_coming_soon.
  ///
  /// In es, this message translates to:
  /// **'En desarrollo'**
  String get dashboard_coming_soon;

  /// No description provided for @dashboard_porn_websites_blocked.
  ///
  /// In es, this message translates to:
  /// **'Webs porno bloqueadas'**
  String get dashboard_porn_websites_blocked;

  /// No description provided for @dashboard_porn_always_on.
  ///
  /// In es, this message translates to:
  /// **'Siempre activa con Protección'**
  String get dashboard_porn_always_on;

  /// No description provided for @dashboard_search_filtering.
  ///
  /// In es, this message translates to:
  /// **'Filtrado de resultados de búsqueda'**
  String get dashboard_search_filtering;

  /// No description provided for @dashboard_social_mode_reels_shorts.
  ///
  /// In es, this message translates to:
  /// **'Reels y Shorts'**
  String get dashboard_social_mode_reels_shorts;

  /// No description provided for @dashboard_social_mode_all.
  ///
  /// In es, this message translates to:
  /// **'Toda red social'**
  String get dashboard_social_mode_all;

  /// No description provided for @social_mode_all_warning_title.
  ///
  /// In es, this message translates to:
  /// **'¿Bloquear la app entera?'**
  String get social_mode_all_warning_title;

  /// No description provided for @social_mode_all_warning_body.
  ///
  /// In es, this message translates to:
  /// **'Ahora mismo, Instagram y YouTube solo se bloquean mientras estás viendo Reels o Shorts — el resto de la app sigue abierto. Cambiar a \"Toda red social\" cambia eso: cuando se acabe el límite diario de hoy, TODA la app se bloqueará por el resto del día, no solo Reels o Shorts — igual que funciona Límites de tiempo en apps. ¿Estás seguro?'**
  String get social_mode_all_warning_body;

  /// No description provided for @social_mode_all_warning_confirm.
  ///
  /// In es, this message translates to:
  /// **'Bloquear la app entera'**
  String get social_mode_all_warning_confirm;

  /// No description provided for @dashboard_block_reels.
  ///
  /// In es, this message translates to:
  /// **'Bloquear Reels de Instagram'**
  String get dashboard_block_reels;

  /// No description provided for @dashboard_block_shorts.
  ///
  /// In es, this message translates to:
  /// **'Bloquear YouTube Shorts'**
  String get dashboard_block_shorts;

  /// No description provided for @dashboard_block_tiktok.
  ///
  /// In es, this message translates to:
  /// **'Bloquear TikTok'**
  String get dashboard_block_tiktok;

  /// No description provided for @dashboard_block_snapchat.
  ///
  /// In es, this message translates to:
  /// **'Bloquear Historias de Snapchat'**
  String get dashboard_block_snapchat;

  /// No description provided for @feed_guard_locked_tooltip.
  ///
  /// In es, this message translates to:
  /// **'Bloqueo 24h'**
  String get feed_guard_locked_tooltip;

  /// No description provided for @feed_guard_locked_sublabel.
  ///
  /// In es, this message translates to:
  /// **'Bloqueado · quedan {time}'**
  String feed_guard_locked_sublabel(String time);

  /// No description provided for @feed_guard_locked_message.
  ///
  /// In es, this message translates to:
  /// **'Límite diario alcanzado. Bloqueado por 24 horas — se desbloquea en {time}.'**
  String feed_guard_locked_message(String time);

  /// No description provided for @feed_guard_locked_refused.
  ///
  /// In es, this message translates to:
  /// **'No se puede cambiar — todavía en su bloqueo de 24 horas.'**
  String get feed_guard_locked_refused;

  /// No description provided for @dashboard_block_shopping.
  ///
  /// In es, this message translates to:
  /// **'Bloquear webs de compras'**
  String get dashboard_block_shopping;

  /// No description provided for @dashboard_block_gambling.
  ///
  /// In es, this message translates to:
  /// **'Bloquear apuestas'**
  String get dashboard_block_gambling;

  /// No description provided for @dashboard_block_image_search.
  ///
  /// In es, this message translates to:
  /// **'Bloquear búsqueda de imágenes y vídeos'**
  String get dashboard_block_image_search;

  /// No description provided for @dashboard_app_time_limits.
  ///
  /// In es, this message translates to:
  /// **'Límites de tiempo en apps'**
  String get dashboard_app_time_limits;

  /// No description provided for @dashboard_custom_apps_blocklist.
  ///
  /// In es, this message translates to:
  /// **'Lista personalizada de apps'**
  String get dashboard_custom_apps_blocklist;

  /// No description provided for @dashboard_block_in_app_browsers.
  ///
  /// In es, this message translates to:
  /// **'Bloquear navegadores en apps'**
  String get dashboard_block_in_app_browsers;

  /// No description provided for @dashboard_prevent_uninstall.
  ///
  /// In es, this message translates to:
  /// **'Prevenir desinstalación'**
  String get dashboard_prevent_uninstall;

  /// No description provided for @dashboard_accountability_partner.
  ///
  /// In es, this message translates to:
  /// **'Compañero de responsabilidad'**
  String get dashboard_accountability_partner;

  /// No description provided for @dashboard_custom_block_screen.
  ///
  /// In es, this message translates to:
  /// **'Pantalla de bloqueo personalizada'**
  String get dashboard_custom_block_screen;

  /// No description provided for @dashboard_custom_websites_blocklist.
  ///
  /// In es, this message translates to:
  /// **'Lista personalizada de webs'**
  String get dashboard_custom_websites_blocklist;

  /// No description provided for @app_limits_screen_title.
  ///
  /// In es, this message translates to:
  /// **'Límites de tiempo en apps'**
  String get app_limits_screen_title;

  /// No description provided for @app_limits_manage_row_label.
  ///
  /// In es, this message translates to:
  /// **'Gestionar apps limitadas'**
  String get app_limits_manage_row_label;

  /// No description provided for @app_limits_manage_row_sublabel_none.
  ///
  /// In es, this message translates to:
  /// **'Toca para elegir apps'**
  String get app_limits_manage_row_sublabel_none;

  /// No description provided for @app_limits_manage_row_sublabel_count.
  ///
  /// In es, this message translates to:
  /// **'{count} apps limitadas'**
  String app_limits_manage_row_sublabel_count(int count);

  /// No description provided for @app_limits_search_hint.
  ///
  /// In es, this message translates to:
  /// **'Buscar apps…'**
  String get app_limits_search_hint;

  /// No description provided for @app_limits_section_limited.
  ///
  /// In es, this message translates to:
  /// **'Limitadas'**
  String get app_limits_section_limited;

  /// No description provided for @app_limits_section_all.
  ///
  /// In es, this message translates to:
  /// **'Todas las apps'**
  String get app_limits_section_all;

  /// No description provided for @app_limits_empty_search.
  ///
  /// In es, this message translates to:
  /// **'No se encontraron apps.'**
  String get app_limits_empty_search;

  /// No description provided for @app_limits_permission_banner.
  ///
  /// In es, this message translates to:
  /// **'Activa el acceso de Accesibilidad para aplicar estos límites diarios.'**
  String get app_limits_permission_banner;

  /// No description provided for @app_limits_permission_enable.
  ///
  /// In es, this message translates to:
  /// **'Activar'**
  String get app_limits_permission_enable;

  /// No description provided for @app_limits_remove_title.
  ///
  /// In es, this message translates to:
  /// **'¿Quitar el límite?'**
  String get app_limits_remove_title;

  /// No description provided for @app_limits_remove_body.
  ///
  /// In es, this message translates to:
  /// **'{app} ya no tendrá un límite de tiempo diario.'**
  String app_limits_remove_body(String app);

  /// No description provided for @app_limits_remove_confirm.
  ///
  /// In es, this message translates to:
  /// **'Quitar'**
  String get app_limits_remove_confirm;

  /// No description provided for @app_limits_minutes_title.
  ///
  /// In es, this message translates to:
  /// **'Minutos al día'**
  String get app_limits_minutes_title;

  /// No description provided for @app_limits_minutes_body.
  ///
  /// In es, this message translates to:
  /// **'Permitido hoy antes de bloquearse por el resto del día.'**
  String get app_limits_minutes_body;

  /// No description provided for @app_limits_add.
  ///
  /// In es, this message translates to:
  /// **'Añadir'**
  String get app_limits_add;

  /// No description provided for @nav_blocking.
  ///
  /// In es, this message translates to:
  /// **'Bloqueo'**
  String get nav_blocking;

  /// No description provided for @nav_prayer.
  ///
  /// In es, this message translates to:
  /// **'Oración'**
  String get nav_prayer;

  /// No description provided for @nav_blocklist.
  ///
  /// In es, this message translates to:
  /// **'Lista'**
  String get nav_blocklist;

  /// No description provided for @nav_progress.
  ///
  /// In es, this message translates to:
  /// **'Progreso'**
  String get nav_progress;

  /// No description provided for @nav_settings.
  ///
  /// In es, this message translates to:
  /// **'Ajustes'**
  String get nav_settings;

  /// No description provided for @plan_activating.
  ///
  /// In es, this message translates to:
  /// **'Activando tu plan...'**
  String get plan_activating;

  /// No description provided for @plan_activated.
  ///
  /// In es, this message translates to:
  /// **'Plan activado'**
  String get plan_activated;

  /// No description provided for @analyzing_skip_to_plans.
  ///
  /// In es, this message translates to:
  /// **'Saltar y elegir un plan'**
  String get analyzing_skip_to_plans;

  /// No description provided for @lock_forever_only.
  ///
  /// In es, this message translates to:
  /// **'Solo Forever'**
  String get lock_forever_only;

  /// No description provided for @lock_monthly_plus.
  ///
  /// In es, this message translates to:
  /// **'Mensual+'**
  String get lock_monthly_plus;

  /// No description provided for @stub_blocklist_title.
  ///
  /// In es, this message translates to:
  /// **'Lista'**
  String get stub_blocklist_title;

  /// No description provided for @blocklist_tab_block.
  ///
  /// In es, this message translates to:
  /// **'Lista de bloqueo'**
  String get blocklist_tab_block;

  /// No description provided for @blocklist_tab_allow.
  ///
  /// In es, this message translates to:
  /// **'Lista blanca'**
  String get blocklist_tab_allow;

  /// No description provided for @blocklist_block_header.
  ///
  /// In es, this message translates to:
  /// **'Webs bloqueadas'**
  String get blocklist_block_header;

  /// No description provided for @blocklist_block_sub.
  ///
  /// In es, this message translates to:
  /// **'Estos sitios están bloqueados. Añade cualquier web porno o que te distraiga que se escape.'**
  String get blocklist_block_sub;

  /// No description provided for @blocklist_block_permanent_note.
  ///
  /// In es, this message translates to:
  /// **'Los sitios que añades aquí no se pueden eliminar. Revisa bien la dirección antes de añadirla.'**
  String get blocklist_block_permanent_note;

  /// No description provided for @blocklist_allow_header.
  ///
  /// In es, this message translates to:
  /// **'Webs permitidas'**
  String get blocklist_allow_header;

  /// No description provided for @blocklist_allow_sub.
  ///
  /// In es, this message translates to:
  /// **'Los sitios que añadas aquí nunca se bloquean. Las webs populares y seguras ya están permitidas automáticamente.'**
  String get blocklist_allow_sub;

  /// No description provided for @blocklist_builtin.
  ///
  /// In es, this message translates to:
  /// **'Predefinido'**
  String get blocklist_builtin;

  /// No description provided for @blocklist_builtin_summary.
  ///
  /// In es, this message translates to:
  /// **'{count} sitios porno conocidos se bloquean automáticamente'**
  String blocklist_builtin_summary(int count);

  /// No description provided for @blocklist_add_block_hint.
  ///
  /// In es, this message translates to:
  /// **'Añade un sitio para bloquear (ej. ejemplo.com)'**
  String get blocklist_add_block_hint;

  /// No description provided for @blocklist_add_allow_hint.
  ///
  /// In es, this message translates to:
  /// **'Añade un sitio para desbloquear (ej. ejemplo.com)'**
  String get blocklist_add_allow_hint;

  /// No description provided for @blocklist_add.
  ///
  /// In es, this message translates to:
  /// **'Añadir'**
  String get blocklist_add;

  /// No description provided for @blocklist_block_empty.
  ///
  /// In es, this message translates to:
  /// **'Aún no has añadido sitios bloqueados.'**
  String get blocklist_block_empty;

  /// No description provided for @blocklist_allow_empty.
  ///
  /// In es, this message translates to:
  /// **'Aún no has permitido ningún sitio.'**
  String get blocklist_allow_empty;

  /// No description provided for @blocklist_invalid.
  ///
  /// In es, this message translates to:
  /// **'Introduce un sitio válido como ejemplo.com'**
  String get blocklist_invalid;

  /// No description provided for @blocklist_duplicate.
  ///
  /// In es, this message translates to:
  /// **'Ese sitio ya está en la lista'**
  String get blocklist_duplicate;

  /// No description provided for @blocklist_blocked_added.
  ///
  /// In es, this message translates to:
  /// **'{domain} ahora está bloqueado'**
  String blocklist_blocked_added(String domain);

  /// No description provided for @blocklist_allowed_added.
  ///
  /// In es, this message translates to:
  /// **'{domain} ahora está permitido'**
  String blocklist_allowed_added(String domain);

  /// No description provided for @blocklist_remove.
  ///
  /// In es, this message translates to:
  /// **'Eliminar'**
  String get blocklist_remove;

  /// No description provided for @stub_progress_title.
  ///
  /// In es, this message translates to:
  /// **'Progreso'**
  String get stub_progress_title;

  /// No description provided for @progress_days_label.
  ///
  /// In es, this message translates to:
  /// **'días protegido'**
  String get progress_days_label;

  /// No description provided for @progress_since.
  ///
  /// In es, this message translates to:
  /// **'desde {date}'**
  String progress_since(String date);

  /// No description provided for @progress_weekly_section.
  ///
  /// In es, this message translates to:
  /// **'Progreso semanal'**
  String get progress_weekly_section;

  /// No description provided for @progress_milestones_section.
  ///
  /// In es, this message translates to:
  /// **'Hitos'**
  String get progress_milestones_section;

  /// No description provided for @progress_off_title.
  ///
  /// In es, this message translates to:
  /// **'La protección está desactivada'**
  String get progress_off_title;

  /// No description provided for @progress_off_subtitle.
  ///
  /// In es, this message translates to:
  /// **'Activa la protección para empezar a construir tu racha'**
  String get progress_off_subtitle;

  /// No description provided for @progress_week_tooltip.
  ///
  /// In es, this message translates to:
  /// **'Semana {week}: {days}/7 días'**
  String progress_week_tooltip(int week, int days);

  /// No description provided for @progress_journey_section.
  ///
  /// In es, this message translates to:
  /// **'Días protegido vs. tentaciones'**
  String get progress_journey_section;

  /// No description provided for @progress_journey_temptations_label.
  ///
  /// In es, this message translates to:
  /// **'tentaciones bloqueadas'**
  String get progress_journey_temptations_label;

  /// No description provided for @progress_journey_legend_days.
  ///
  /// In es, this message translates to:
  /// **'Días protegido'**
  String get progress_journey_legend_days;

  /// No description provided for @progress_journey_legend_temptations.
  ///
  /// In es, this message translates to:
  /// **'Tentaciones'**
  String get progress_journey_legend_temptations;

  /// No description provided for @progress_journey_down.
  ///
  /// In es, this message translates to:
  /// **'A medida que crece tu racha, las tentaciones bajaron {percent}%'**
  String progress_journey_down(int percent);

  /// No description provided for @progress_journey_up.
  ///
  /// In es, this message translates to:
  /// **'Las tentaciones subieron {percent}% — no aflojes'**
  String progress_journey_up(int percent);

  /// No description provided for @progress_journey_flat.
  ///
  /// In es, this message translates to:
  /// **'Se mantiene estable mientras crece tu racha'**
  String get progress_journey_flat;

  /// No description provided for @progress_journey_building.
  ///
  /// In es, this message translates to:
  /// **'Sigue así — la relación aparece después de una semana'**
  String get progress_journey_building;

  /// No description provided for @progress_journey_tooltip_day.
  ///
  /// In es, this message translates to:
  /// **'Día {day} protegido'**
  String progress_journey_tooltip_day(int day);

  /// No description provided for @progress_journey_tooltip_blocked.
  ///
  /// In es, this message translates to:
  /// **'{count} bloqueadas'**
  String progress_journey_tooltip_blocked(int count);

  /// No description provided for @progress_trends_section.
  ///
  /// In es, this message translates to:
  /// **'Tus tendencias'**
  String get progress_trends_section;

  /// No description provided for @progress_blocked_trend_title.
  ///
  /// In es, this message translates to:
  /// **'Tentaciones bloqueadas'**
  String get progress_blocked_trend_title;

  /// No description provided for @progress_trend_down.
  ///
  /// In es, this message translates to:
  /// **'Bajó {percent}% respecto a tu primera semana'**
  String progress_trend_down(int percent);

  /// No description provided for @progress_trend_up.
  ///
  /// In es, this message translates to:
  /// **'Subió {percent}% respecto a tu primera semana'**
  String progress_trend_up(int percent);

  /// No description provided for @progress_trend_flat.
  ///
  /// In es, this message translates to:
  /// **'Se mantiene estable'**
  String get progress_trend_flat;

  /// No description provided for @progress_trend_need_data.
  ///
  /// In es, this message translates to:
  /// **'Sigue así — tu tendencia aparecerá después de una semana'**
  String get progress_trend_need_data;

  /// No description provided for @progress_trend_unit_blocked.
  ///
  /// In es, this message translates to:
  /// **'bloqueados'**
  String get progress_trend_unit_blocked;

  /// No description provided for @progress_trend_unit_minutes.
  ///
  /// In es, this message translates to:
  /// **'min'**
  String get progress_trend_unit_minutes;

  /// No description provided for @stub_settings_title.
  ///
  /// In es, this message translates to:
  /// **'Ajustes'**
  String get stub_settings_title;

  /// No description provided for @stub_accountability_title.
  ///
  /// In es, this message translates to:
  /// **'Responsabilidad'**
  String get stub_accountability_title;

  /// No description provided for @settings_section_session.
  ///
  /// In es, this message translates to:
  /// **'Sesión'**
  String get settings_section_session;

  /// No description provided for @settings_leave_session_title.
  ///
  /// In es, this message translates to:
  /// **'Salir de la sesión'**
  String get settings_leave_session_title;

  /// No description provided for @settings_leave_session_subtitle.
  ///
  /// In es, this message translates to:
  /// **'Empezar de nuevo como usuario nuevo'**
  String get settings_leave_session_subtitle;

  /// No description provided for @settings_leave_session_dialog_title.
  ///
  /// In es, this message translates to:
  /// **'¿Salir de la sesión?'**
  String get settings_leave_session_dialog_title;

  /// No description provided for @settings_leave_session_dialog_body.
  ///
  /// In es, this message translates to:
  /// **'Esto borrará tu plan y tus respuestas y te llevará al inicio. La protección se desactivará.'**
  String get settings_leave_session_dialog_body;

  /// No description provided for @settings_leave_session_action.
  ///
  /// In es, this message translates to:
  /// **'Salir'**
  String get settings_leave_session_action;

  /// No description provided for @common_cancel.
  ///
  /// In es, this message translates to:
  /// **'Cancelar'**
  String get common_cancel;

  /// No description provided for @protection_permission_needed.
  ///
  /// In es, this message translates to:
  /// **'Se necesita permiso para activar la Protección'**
  String get protection_permission_needed;

  /// No description provided for @protection_start_failed.
  ///
  /// In es, this message translates to:
  /// **'No se pudo iniciar la Protección'**
  String get protection_start_failed;

  /// No description provided for @commitment_warning_title.
  ///
  /// In es, this message translates to:
  /// **'Modo Compromiso'**
  String get commitment_warning_title;

  /// No description provided for @commitment_warning_body.
  ///
  /// In es, this message translates to:
  /// **'La Protección quedará ACTIVADA y NO podrás desactivarla durante {days} días. Ese es el punto: te quita la decisión en un momento de debilidad. Después tendrás una pausa corta y volverá a bloquearse por aún más tiempo. ¿Estás seguro?'**
  String commitment_warning_body(int days);

  /// No description provided for @commitment_warning_confirm.
  ///
  /// In es, this message translates to:
  /// **'Comprométeme'**
  String get commitment_warning_confirm;

  /// No description provided for @commitment_locked_banner.
  ///
  /// In es, this message translates to:
  /// **'Comprometido · quedan {days} días'**
  String commitment_locked_banner(int days);

  /// No description provided for @commitment_locked_sub.
  ///
  /// In es, this message translates to:
  /// **'La Protección no se puede desactivar hasta el {date}'**
  String commitment_locked_sub(String date);

  /// No description provided for @commitment_break_banner.
  ///
  /// In es, this message translates to:
  /// **'Pausa abierta · quedan {minutes} min'**
  String commitment_break_banner(int minutes);

  /// No description provided for @commitment_break_sub.
  ///
  /// In es, this message translates to:
  /// **'La protección se vuelve a activar sola cuando termine la pausa.'**
  String get commitment_break_sub;

  /// No description provided for @commitment_break_available_banner.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, =1{Tienes 1 pausa disponible} other{Tienes {count} pausas disponibles}}'**
  String commitment_break_available_banner(int count);

  /// No description provided for @commitment_break_available_sub.
  ///
  /// In es, this message translates to:
  /// **'Desactiva la protección cuando quieras usarla: dura 30 min y luego se vuelve a activar sola.'**
  String get commitment_break_available_sub;

  /// No description provided for @commitment_locked_toast.
  ///
  /// In es, this message translates to:
  /// **'Bloqueado por {days} días más. Te comprometiste a esto.'**
  String commitment_locked_toast(int days);

  /// No description provided for @commitment_cannot_leave.
  ///
  /// In es, this message translates to:
  /// **'No puedes salir mientras la Protección está bloqueada.'**
  String get commitment_cannot_leave;

  /// No description provided for @commitment_warning_forever_title.
  ///
  /// In es, this message translates to:
  /// **'Bloqueo Para Siempre'**
  String get commitment_warning_forever_title;

  /// No description provided for @commitment_warning_forever_body.
  ///
  /// In es, this message translates to:
  /// **'La Protección quedará ACTIVADA de forma permanente y NO podrás desactivarla nunca. Es para siempre. ¿Estás seguro?'**
  String get commitment_warning_forever_body;

  /// No description provided for @commitment_warning_fixed_body.
  ///
  /// In es, this message translates to:
  /// **'La Protección quedará ACTIVADA y no podrás desactivarla durante {days} días (salvo en las pausas). Cuando termine el periodo, volverás a controlarla. ¿Estás seguro?'**
  String commitment_warning_fixed_body(int days);

  /// No description provided for @commitment_warning_cycle_body.
  ///
  /// In es, this message translates to:
  /// **'La Protección quedará ACTIVADA en un ciclo de {days} días que se repite para siempre. Solo podrás desactivarla durante las pausas. ¿Estás seguro?'**
  String commitment_warning_cycle_body(int days);

  /// No description provided for @commitment_forever_banner.
  ///
  /// In es, this message translates to:
  /// **'Comprometido para siempre'**
  String get commitment_forever_banner;

  /// No description provided for @commitment_forever_sub.
  ///
  /// In es, this message translates to:
  /// **'La Protección está bloqueada de forma permanente.'**
  String get commitment_forever_sub;

  /// No description provided for @commitment_forever_toast.
  ///
  /// In es, this message translates to:
  /// **'Esto es para siempre. La Protección no se puede desactivar.'**
  String get commitment_forever_toast;

  /// No description provided for @schedule_summary_days.
  ///
  /// In es, this message translates to:
  /// **'{days} días de protección'**
  String schedule_summary_days(int days);

  /// No description provided for @schedule_summary_breaks.
  ///
  /// In es, this message translates to:
  /// **'{count} pausas de 30 min'**
  String schedule_summary_breaks(int count);

  /// No description provided for @schedule_summary_no_breaks.
  ///
  /// In es, this message translates to:
  /// **'Sin pausas'**
  String get schedule_summary_no_breaks;

  /// No description provided for @schedule_summary_constant.
  ///
  /// In es, this message translates to:
  /// **'Se repite para siempre (ciclo)'**
  String get schedule_summary_constant;

  /// No description provided for @schedule_summary_once.
  ///
  /// In es, this message translates to:
  /// **'Termina al completarse'**
  String get schedule_summary_once;

  /// No description provided for @monthly_setup_title.
  ///
  /// In es, this message translates to:
  /// **'Configura tu plan'**
  String get monthly_setup_title;

  /// No description provided for @monthly_setup_subtitle.
  ///
  /// In es, this message translates to:
  /// **'Elige cuántos días quieres proteger y si quieres pausas.'**
  String get monthly_setup_subtitle;

  /// No description provided for @monthly_setup_days_label.
  ///
  /// In es, this message translates to:
  /// **'Días de protección'**
  String get monthly_setup_days_label;

  /// No description provided for @monthly_setup_breaks_label.
  ///
  /// In es, this message translates to:
  /// **'Pausas'**
  String get monthly_setup_breaks_label;

  /// No description provided for @monthly_setup_breaks_with.
  ///
  /// In es, this message translates to:
  /// **'Con pausas'**
  String get monthly_setup_breaks_with;

  /// No description provided for @monthly_setup_breaks_without.
  ///
  /// In es, this message translates to:
  /// **'Sin pausas'**
  String get monthly_setup_breaks_without;

  /// No description provided for @monthly_setup_break_count_label.
  ///
  /// In es, this message translates to:
  /// **'Número de pausas'**
  String get monthly_setup_break_count_label;

  /// No description provided for @monthly_setup_break_note.
  ///
  /// In es, this message translates to:
  /// **'Cada pausa dura 30 minutos y se reparte de forma uniforme.'**
  String get monthly_setup_break_note;

  /// No description provided for @monthly_setup_constant_label.
  ///
  /// In es, this message translates to:
  /// **'Constante (sin fin)'**
  String get monthly_setup_constant_label;

  /// No description provided for @monthly_setup_constant_sub.
  ///
  /// In es, this message translates to:
  /// **'Nunca termina: al completarse, vuelve a empezar en bucle.'**
  String get monthly_setup_constant_sub;

  /// No description provided for @monthly_setup_summary_label.
  ///
  /// In es, this message translates to:
  /// **'RESUMEN'**
  String get monthly_setup_summary_label;

  /// No description provided for @monthly_setup_activate.
  ///
  /// In es, this message translates to:
  /// **'Activar plan'**
  String get monthly_setup_activate;

  /// No description provided for @ai_plan_computed_label.
  ///
  /// In es, this message translates to:
  /// **'TU PLAN CALCULADO POR IA'**
  String get ai_plan_computed_label;

  /// No description provided for @onboarding_continue.
  ///
  /// In es, this message translates to:
  /// **'Continuar'**
  String get onboarding_continue;

  /// No description provided for @onboarding_back.
  ///
  /// In es, this message translates to:
  /// **'Atrás'**
  String get onboarding_back;

  /// No description provided for @onboarding_question_progress.
  ///
  /// In es, this message translates to:
  /// **'Pregunta {current} de {total}'**
  String onboarding_question_progress(int current, int total);

  /// No description provided for @onboarding_q1_text.
  ///
  /// In es, this message translates to:
  /// **'¿Qué edad tenías cuando viste pornografía por primera vez?'**
  String get onboarding_q1_text;

  /// No description provided for @onboarding_q1_a1.
  ///
  /// In es, this message translates to:
  /// **'Menos de 12 años'**
  String get onboarding_q1_a1;

  /// No description provided for @onboarding_q1_a2.
  ///
  /// In es, this message translates to:
  /// **'Entre 12 y 15 años'**
  String get onboarding_q1_a2;

  /// No description provided for @onboarding_q1_a3.
  ///
  /// In es, this message translates to:
  /// **'Entre 16 y 18 años'**
  String get onboarding_q1_a3;

  /// No description provided for @onboarding_q1_a4.
  ///
  /// In es, this message translates to:
  /// **'Más de 18 años'**
  String get onboarding_q1_a4;

  /// No description provided for @onboarding_q2_text.
  ///
  /// In es, this message translates to:
  /// **'¿Con qué frecuencia ves pornografía?'**
  String get onboarding_q2_text;

  /// No description provided for @onboarding_q2_a1.
  ///
  /// In es, this message translates to:
  /// **'Todos los días'**
  String get onboarding_q2_a1;

  /// No description provided for @onboarding_q2_a2.
  ///
  /// In es, this message translates to:
  /// **'Varias veces a la semana'**
  String get onboarding_q2_a2;

  /// No description provided for @onboarding_q2_a3.
  ///
  /// In es, this message translates to:
  /// **'Una vez a la semana'**
  String get onboarding_q2_a3;

  /// No description provided for @onboarding_q2_a4.
  ///
  /// In es, this message translates to:
  /// **'Menos de una vez a la semana'**
  String get onboarding_q2_a4;

  /// No description provided for @onboarding_q3_text.
  ///
  /// In es, this message translates to:
  /// **'¿Cuántas horas por semana pasas viendo pornografía?'**
  String get onboarding_q3_text;

  /// No description provided for @onboarding_q3_a1.
  ///
  /// In es, this message translates to:
  /// **'Más de 10 horas'**
  String get onboarding_q3_a1;

  /// No description provided for @onboarding_q3_a2.
  ///
  /// In es, this message translates to:
  /// **'Entre 5 y 10 horas'**
  String get onboarding_q3_a2;

  /// No description provided for @onboarding_q3_a3.
  ///
  /// In es, this message translates to:
  /// **'Entre 2 y 5 horas'**
  String get onboarding_q3_a3;

  /// No description provided for @onboarding_q3_a4.
  ///
  /// In es, this message translates to:
  /// **'Menos de 2 horas'**
  String get onboarding_q3_a4;

  /// No description provided for @onboarding_q4_text.
  ///
  /// In es, this message translates to:
  /// **'¿Has intentado dejarlo antes?'**
  String get onboarding_q4_text;

  /// No description provided for @onboarding_q4_a1.
  ///
  /// In es, this message translates to:
  /// **'Sí, muchas veces'**
  String get onboarding_q4_a1;

  /// No description provided for @onboarding_q4_a2.
  ///
  /// In es, this message translates to:
  /// **'Sí, a veces'**
  String get onboarding_q4_a2;

  /// No description provided for @onboarding_q4_a3.
  ///
  /// In es, this message translates to:
  /// **'Sí, una o dos veces'**
  String get onboarding_q4_a3;

  /// No description provided for @onboarding_q4_a4.
  ///
  /// In es, this message translates to:
  /// **'No, nunca'**
  String get onboarding_q4_a4;

  /// No description provided for @onboarding_q5_text.
  ///
  /// In es, this message translates to:
  /// **'¿Ha afectado tus relaciones personales?'**
  String get onboarding_q5_text;

  /// No description provided for @onboarding_q5_a1.
  ///
  /// In es, this message translates to:
  /// **'Significativamente'**
  String get onboarding_q5_a1;

  /// No description provided for @onboarding_q5_a2.
  ///
  /// In es, this message translates to:
  /// **'Considerablemente'**
  String get onboarding_q5_a2;

  /// No description provided for @onboarding_q5_a3.
  ///
  /// In es, this message translates to:
  /// **'Un poco'**
  String get onboarding_q5_a3;

  /// No description provided for @onboarding_q5_a4.
  ///
  /// In es, this message translates to:
  /// **'Nada'**
  String get onboarding_q5_a4;

  /// No description provided for @onboarding_q6_text.
  ///
  /// In es, this message translates to:
  /// **'¿Ha afectado tu trabajo o tus estudios?'**
  String get onboarding_q6_text;

  /// No description provided for @onboarding_q6_a1.
  ///
  /// In es, this message translates to:
  /// **'Significativamente'**
  String get onboarding_q6_a1;

  /// No description provided for @onboarding_q6_a2.
  ///
  /// In es, this message translates to:
  /// **'Considerablemente'**
  String get onboarding_q6_a2;

  /// No description provided for @onboarding_q6_a3.
  ///
  /// In es, this message translates to:
  /// **'Un poco'**
  String get onboarding_q6_a3;

  /// No description provided for @onboarding_q6_a4.
  ///
  /// In es, this message translates to:
  /// **'Nada'**
  String get onboarding_q6_a4;

  /// No description provided for @onboarding_q7_text.
  ///
  /// In es, this message translates to:
  /// **'¿Cuál es tu principal detonante?'**
  String get onboarding_q7_text;

  /// No description provided for @onboarding_q7_a1.
  ///
  /// In es, this message translates to:
  /// **'Estrés'**
  String get onboarding_q7_a1;

  /// No description provided for @onboarding_q7_a2.
  ///
  /// In es, this message translates to:
  /// **'Soledad'**
  String get onboarding_q7_a2;

  /// No description provided for @onboarding_q7_a3.
  ///
  /// In es, this message translates to:
  /// **'Aburrimiento'**
  String get onboarding_q7_a3;

  /// No description provided for @onboarding_q7_a4.
  ///
  /// In es, this message translates to:
  /// **'Costumbre, lo hago sin pensarlo'**
  String get onboarding_q7_a4;

  /// No description provided for @onboarding_q7_a5.
  ///
  /// In es, this message translates to:
  /// **'Otro'**
  String get onboarding_q7_a5;

  /// No description provided for @onboarding_q8_text.
  ///
  /// In es, this message translates to:
  /// **'¿Cómo te sientes después de verlo?'**
  String get onboarding_q8_text;

  /// No description provided for @onboarding_q8_a1.
  ///
  /// In es, this message translates to:
  /// **'Muy culpable / Me odio a mí mismo'**
  String get onboarding_q8_a1;

  /// No description provided for @onboarding_q8_a2.
  ///
  /// In es, this message translates to:
  /// **'Culpable'**
  String get onboarding_q8_a2;

  /// No description provided for @onboarding_q8_a3.
  ///
  /// In es, this message translates to:
  /// **'Indiferente'**
  String get onboarding_q8_a3;

  /// No description provided for @onboarding_q8_a4.
  ///
  /// In es, this message translates to:
  /// **'Bien'**
  String get onboarding_q8_a4;

  /// No description provided for @footer_inspired_by.
  ///
  /// In es, this message translates to:
  /// **'Inspirado en BlockerX'**
  String get footer_inspired_by;

  /// No description provided for @guard_card_title.
  ///
  /// In es, this message translates to:
  /// **'Protección contra desinstalación'**
  String get guard_card_title;

  /// No description provided for @guard_explainer.
  ///
  /// In es, this message translates to:
  /// **'Cuando intentes forzar la detención o desinstalar la app, Be Unchained cubre la pantalla y te pide copiar 800 letras de la Escritura en cuatro minutos. Con el administrador de dispositivo activado, el sistema también se niega a desinstalar hasta que lo desactives aquí, lo cual está protegido por el mismo desafío.'**
  String get guard_explainer;

  /// No description provided for @guard_req_overlay.
  ///
  /// In es, this message translates to:
  /// **'Mostrar sobre otras apps'**
  String get guard_req_overlay;

  /// No description provided for @guard_action_allow.
  ///
  /// In es, this message translates to:
  /// **'Permitir'**
  String get guard_action_allow;

  /// No description provided for @guard_req_accessibility.
  ///
  /// In es, this message translates to:
  /// **'Vigilante de accesibilidad'**
  String get guard_req_accessibility;

  /// No description provided for @guard_action_enable.
  ///
  /// In es, this message translates to:
  /// **'Activar'**
  String get guard_action_enable;

  /// No description provided for @guard_req_device_admin.
  ///
  /// In es, this message translates to:
  /// **'Administrador de dispositivo (bloqueo estricto)'**
  String get guard_req_device_admin;

  /// No description provided for @guard_action_activate.
  ///
  /// In es, this message translates to:
  /// **'Activar'**
  String get guard_action_activate;

  /// No description provided for @guard_device_owner_note.
  ///
  /// In es, this message translates to:
  /// **'Propietario del dispositivo: la desinstalación queda bloqueada por completo.'**
  String get guard_device_owner_note;

  /// No description provided for @guard_grant_both_hint.
  ///
  /// In es, this message translates to:
  /// **'Concede ambos permisos arriba para activar la protección.'**
  String get guard_grant_both_hint;

  /// No description provided for @guard_turn_on.
  ///
  /// In es, this message translates to:
  /// **'Activar protección'**
  String get guard_turn_on;

  /// No description provided for @guard_turn_off.
  ///
  /// In es, this message translates to:
  /// **'Desactivar protección'**
  String get guard_turn_off;

  /// No description provided for @guard_status_partial.
  ///
  /// In es, this message translates to:
  /// **'Activa (limitada)'**
  String get guard_status_partial;

  /// No description provided for @guard_partial_warning.
  ///
  /// In es, this message translates to:
  /// **'La protección está activa y sigue bloqueando la desinstalación, pero faltan permisos arriba, así que no está a máxima potencia. Concédelos, o desactívala abajo.'**
  String get guard_partial_warning;

  /// No description provided for @welcome_language.
  ///
  /// In es, this message translates to:
  /// **'Idioma'**
  String get welcome_language;

  /// No description provided for @payment_confirming_title.
  ///
  /// In es, this message translates to:
  /// **'Confirmando tu pago…'**
  String get payment_confirming_title;

  /// No description provided for @payment_confirming_body.
  ///
  /// In es, this message translates to:
  /// **'Esto puede tardar unos segundos mientras Stripe nos avisa.'**
  String get payment_confirming_body;

  /// No description provided for @payment_not_confirmed_title.
  ///
  /// In es, this message translates to:
  /// **'Aún no pudimos confirmar tu pago'**
  String get payment_not_confirmed_title;

  /// No description provided for @payment_not_confirmed_body.
  ///
  /// In es, this message translates to:
  /// **'Si completaste el pago, asegúrate de que coincida con el correo que usaste en la página de pago de Stripe y vuelve a intentarlo.'**
  String get payment_not_confirmed_body;

  /// No description provided for @payment_check_again.
  ///
  /// In es, this message translates to:
  /// **'Comprobar de nuevo'**
  String get payment_check_again;

  /// No description provided for @common_email_hint.
  ///
  /// In es, this message translates to:
  /// **'tucorreo@ejemplo.com'**
  String get common_email_hint;

  /// No description provided for @email_dialog_invalid.
  ///
  /// In es, this message translates to:
  /// **'Introduce una dirección de correo válida.'**
  String get email_dialog_invalid;

  /// No description provided for @email_dialog_title.
  ///
  /// In es, this message translates to:
  /// **'Tu correo'**
  String get email_dialog_title;

  /// No description provided for @email_dialog_body.
  ///
  /// In es, this message translates to:
  /// **'Lo usaremos para confirmar tu pago con Stripe y desbloquear el plan en cuanto se complete.'**
  String get email_dialog_body;

  /// No description provided for @common_continue.
  ///
  /// In es, this message translates to:
  /// **'Continuar'**
  String get common_continue;

  /// No description provided for @owner_dialog_wrong_email.
  ///
  /// In es, this message translates to:
  /// **'Correo incorrecto'**
  String get owner_dialog_wrong_email;

  /// No description provided for @owner_dialog_send_failed.
  ///
  /// In es, this message translates to:
  /// **'No se pudo enviar el código; inténtalo de nuevo'**
  String get owner_dialog_send_failed;

  /// No description provided for @owner_dialog_resend_failed.
  ///
  /// In es, this message translates to:
  /// **'No se pudo reenviar el código; inténtalo de nuevo'**
  String get owner_dialog_resend_failed;

  /// No description provided for @owner_dialog_wrong_code.
  ///
  /// In es, this message translates to:
  /// **'Código incorrecto o caducado'**
  String get owner_dialog_wrong_code;

  /// No description provided for @owner_dialog_title.
  ///
  /// In es, this message translates to:
  /// **'Propietario'**
  String get owner_dialog_title;

  /// No description provided for @owner_dialog_email_hint_text.
  ///
  /// In es, this message translates to:
  /// **'Introduce el correo del propietario para continuar.'**
  String get owner_dialog_email_hint_text;

  /// No description provided for @owner_dialog_email_field_hint.
  ///
  /// In es, this message translates to:
  /// **'propietario@correo.com'**
  String get owner_dialog_email_field_hint;

  /// No description provided for @owner_dialog_check_email_title.
  ///
  /// In es, this message translates to:
  /// **'Revisa tu correo'**
  String get owner_dialog_check_email_title;

  /// No description provided for @owner_dialog_code_hint_text.
  ///
  /// In es, this message translates to:
  /// **'Introduce el código que acabamos de enviarte.'**
  String get owner_dialog_code_hint_text;

  /// No description provided for @owner_dialog_resend_code.
  ///
  /// In es, this message translates to:
  /// **'Reenviar código'**
  String get owner_dialog_resend_code;

  /// No description provided for @owner_dialog_unlock.
  ///
  /// In es, this message translates to:
  /// **'Desbloquear'**
  String get owner_dialog_unlock;

  /// No description provided for @owner_dialog_next.
  ///
  /// In es, this message translates to:
  /// **'Siguiente'**
  String get owner_dialog_next;

  /// No description provided for @owner_entry_label.
  ///
  /// In es, this message translates to:
  /// **'Propietario'**
  String get owner_entry_label;

  /// No description provided for @error_loading_settings.
  ///
  /// In es, this message translates to:
  /// **'Error al cargar la configuración: {error}'**
  String error_loading_settings(String error);

  /// No description provided for @common_confirm.
  ///
  /// In es, this message translates to:
  /// **'Confirmar'**
  String get common_confirm;

  /// No description provided for @dev_reset_budget_title.
  ///
  /// In es, this message translates to:
  /// **'¿Reiniciar el presupuesto diario?'**
  String get dev_reset_budget_title;

  /// No description provided for @dev_reset_budget_body.
  ///
  /// In es, this message translates to:
  /// **'DEV: borra el uso de hoy y el bloqueo de 24h para \"{label}\" para que vuelva a estar disponible de inmediato.'**
  String dev_reset_budget_body(String label);

  /// No description provided for @dev_reset_budget_body_kept_history.
  ///
  /// In es, this message translates to:
  /// **'DEV: borra el uso de hoy y el bloqueo de 24h para \"{label}\" para que vuelva a estar disponible de inmediato. Se conserva el historial de días anteriores.'**
  String dev_reset_budget_body_kept_history(String label);

  /// No description provided for @dev_reset_confirm.
  ///
  /// In es, this message translates to:
  /// **'Reiniciar'**
  String get dev_reset_confirm;

  /// No description provided for @dev_reset_snackbar_success.
  ///
  /// In es, this message translates to:
  /// **'Presupuesto de {label} reiniciado'**
  String dev_reset_snackbar_success(String label);

  /// No description provided for @dev_reset_snackbar_failed.
  ///
  /// In es, this message translates to:
  /// **'No se pudo reiniciar'**
  String get dev_reset_snackbar_failed;

  /// No description provided for @blocklist_add_success.
  ///
  /// In es, this message translates to:
  /// **'«{value}» ✓'**
  String blocklist_add_success(String value);

  /// No description provided for @month_jan.
  ///
  /// In es, this message translates to:
  /// **'ene'**
  String get month_jan;

  /// No description provided for @month_feb.
  ///
  /// In es, this message translates to:
  /// **'feb'**
  String get month_feb;

  /// No description provided for @month_mar.
  ///
  /// In es, this message translates to:
  /// **'mar'**
  String get month_mar;

  /// No description provided for @month_apr.
  ///
  /// In es, this message translates to:
  /// **'abr'**
  String get month_apr;

  /// No description provided for @month_may.
  ///
  /// In es, this message translates to:
  /// **'may'**
  String get month_may;

  /// No description provided for @month_jun.
  ///
  /// In es, this message translates to:
  /// **'jun'**
  String get month_jun;

  /// No description provided for @month_jul.
  ///
  /// In es, this message translates to:
  /// **'jul'**
  String get month_jul;

  /// No description provided for @month_aug.
  ///
  /// In es, this message translates to:
  /// **'ago'**
  String get month_aug;

  /// No description provided for @month_sep.
  ///
  /// In es, this message translates to:
  /// **'sep'**
  String get month_sep;

  /// No description provided for @month_oct.
  ///
  /// In es, this message translates to:
  /// **'oct'**
  String get month_oct;

  /// No description provided for @month_nov.
  ///
  /// In es, this message translates to:
  /// **'nov'**
  String get month_nov;

  /// No description provided for @month_dec.
  ///
  /// In es, this message translates to:
  /// **'dic'**
  String get month_dec;

  /// No description provided for @settings_section_about.
  ///
  /// In es, this message translates to:
  /// **'Acerca de'**
  String get settings_section_about;

  /// No description provided for @settings_report_bug_title.
  ///
  /// In es, this message translates to:
  /// **'Reportar un error'**
  String get settings_report_bug_title;

  /// No description provided for @settings_designed_by.
  ///
  /// In es, this message translates to:
  /// **'Diseñado y desarrollado por\n{name}'**
  String settings_designed_by(String name);

  /// No description provided for @settings_section_language.
  ///
  /// In es, this message translates to:
  /// **'Idioma'**
  String get settings_section_language;

  /// No description provided for @terms_title.
  ///
  /// In es, this message translates to:
  /// **'Términos y Condiciones'**
  String get terms_title;

  /// No description provided for @terms_gate_banner.
  ///
  /// In es, this message translates to:
  /// **'Por favor, lee estos Términos y Condiciones antes de usar el panel de control. Si decides no leerlos, usas esta aplicación bajo tu entera responsabilidad.'**
  String get terms_gate_banner;

  /// No description provided for @terms_footer_note.
  ///
  /// In es, this message translates to:
  /// **'Al continuar, confirmas que has leído, entendido y aceptas estos Términos y Condiciones.'**
  String get terms_footer_note;

  /// No description provided for @terms_agree_button.
  ///
  /// In es, this message translates to:
  /// **'He leído y acepto'**
  String get terms_agree_button;

  /// No description provided for @terms_continue_risk_button.
  ///
  /// In es, this message translates to:
  /// **'No quiero leer: continuar bajo mi propio riesgo'**
  String get terms_continue_risk_button;

  /// No description provided for @terms_dialog_title.
  ///
  /// In es, this message translates to:
  /// **'¿Continuar sin leer?'**
  String get terms_dialog_title;

  /// No description provided for @terms_dialog_body.
  ///
  /// In es, this message translates to:
  /// **'Se recomienda encarecidamente leer los Términos y Condiciones. Si decides continuar sin leerlos, lo haces bajo tu entera responsabilidad y los aceptas en su totalidad.'**
  String get terms_dialog_body;

  /// No description provided for @terms_dialog_go_back.
  ///
  /// In es, this message translates to:
  /// **'Volver'**
  String get terms_dialog_go_back;

  /// No description provided for @terms_dialog_take_responsibility.
  ///
  /// In es, this message translates to:
  /// **'Asumo la responsabilidad'**
  String get terms_dialog_take_responsibility;

  /// No description provided for @terms_owner_credit_label.
  ///
  /// In es, this message translates to:
  /// **'Propietario y desarrollador'**
  String get terms_owner_credit_label;

  /// No description provided for @terms_owner_contact.
  ///
  /// In es, this message translates to:
  /// **'{email}  (reportar un error)'**
  String terms_owner_contact(String email);

  /// No description provided for @terms_section1_title.
  ///
  /// In es, this message translates to:
  /// **'1. Aceptación de estos Términos'**
  String get terms_section1_title;

  /// No description provided for @terms_section1_body.
  ///
  /// In es, this message translates to:
  /// **'Be Unchained («la aplicación») es una herramienta personal que te ayuda a bloquear contenido para adultos y contenido que distrae. Al usar la aplicación, aceptas estos Términos y Condiciones. Si no estás de acuerdo con alguna parte de ellos, no debes usar la aplicación.'**
  String get terms_section1_body;

  /// No description provided for @terms_section2_title.
  ///
  /// In es, this message translates to:
  /// **'2. Finalidad y uso previsto'**
  String get terms_section2_title;

  /// No description provided for @terms_section2_body.
  ///
  /// In es, this message translates to:
  /// **'La aplicación tiene como fin apoyar hábitos digitales saludables filtrando contenido a nivel de red en tu propio dispositivo, y ayudándote a gestionar y limitar el tiempo dedicado a aplicaciones que distraen. Es únicamente una ayuda de autoayuda y no sustituye el asesoramiento o tratamiento profesional, médico o psicológico.'**
  String get terms_section2_body;

  /// No description provided for @terms_section3_title.
  ///
  /// In es, this message translates to:
  /// **'3. Redes sociales y límites de tiempo de uso'**
  String get terms_section3_title;

  /// No description provided for @terms_section3_body.
  ///
  /// In es, this message translates to:
  /// **'Además de bloquear contenido para adultos, la aplicación puede imponer un límite de tiempo diario en Instagram Reels, YouTube Shorts, TikTok, Historias de Snapchat, o cualquier otra aplicación que elijas («Límites de tiempo de aplicaciones»). Esto funciona detectando la aplicación en tu pantalla mediante el Servicio de Accesibilidad de Android; la aplicación no monitorea tu actividad en ningún otro lugar ni la envía fuera de tu dispositivo. Si activas el modo «Todas las redes sociales», una vez que se agote tu límite diario de Instagram o YouTube, se bloqueará la aplicación entera por el resto del día, no solo los Reels o Shorts. En cuanto se agota cualquier límite diario, esa aplicación o feed queda bloqueado durante 24 horas completas como medida contra los intentos de evadir el límite, y este no se puede cambiar ni eliminar durante ese tiempo.'**
  String get terms_section3_body;

  /// No description provided for @terms_section4_title.
  ///
  /// In es, this message translates to:
  /// **'4. Bloqueo de aplicaciones mediante oración (función opcional, de carácter religioso)'**
  String get terms_section4_title;

  /// No description provided for @terms_section4_body.
  ///
  /// In es, this message translates to:
  /// **'La aplicación incluye una función opcional que bloquea las aplicaciones que elijas (o todas) detrás de una breve oración cristiana —una oración de acción de gracias o el Rosario— que debe completarse antes de que la aplicación vuelva a estar accesible durante un número determinado de horas. Esta función es opcional y debes activarla tú mismo; su contenido es de carácter religioso y se ofrece únicamente como una herramienta personal de responsabilidad, no como instrucción o consejo religioso. Dado que su contenido es específicamente cristiano, puedes desactivar la función por completo en cualquier momento —sea cual sea tu fe o si no tienes ninguna— usando el interruptor «Bloqueo con oración» al final de la pestaña de oración. Al desactivarla, se detiene todo bloqueo basado en oración y se elimina el contenido religioso de esa pestaña; esto no afecta al bloqueo de contenido ni a ninguna otra protección. También puedes dejarla activada y elegir exactamente a qué aplicaciones (si acaso) se aplica.'**
  String get terms_section4_body;

  /// No description provided for @terms_section5_title.
  ///
  /// In es, this message translates to:
  /// **'5. Sin garantía de eficacia'**
  String get terms_section5_title;

  /// No description provided for @terms_section5_body.
  ///
  /// In es, this message translates to:
  /// **'El bloqueo de contenido se basa en el filtrado de dominios a nivel de DNS. Ningún filtro es perfecto: es posible que algo de contenido no deseado llegue a pasar, y que ocasionalmente se bloquee contenido legítimo. La aplicación no puede garantizar que todo sitio o aplicación dañina quede bloqueada en todo momento. Las funciones que dependen del Servicio de Accesibilidad de Android —Límites de tiempo de aplicaciones, el modo «Todas las redes sociales» y el bloqueo con oración— requieren que ese servicio permanezca activado; desactivarlo en la configuración de tu dispositivo hará que esas funciones dejen de funcionar.'**
  String get terms_section5_body;

  /// No description provided for @terms_section6_title.
  ///
  /// In es, this message translates to:
  /// **'6. Uso bajo tu propia responsabilidad'**
  String get terms_section6_title;

  /// No description provided for @terms_section6_body.
  ///
  /// In es, this message translates to:
  /// **'Usas la aplicación bajo tu propia responsabilidad y riesgo. Leer estos términos es responsabilidad tuya. Si decides continuar sin leerlos, los aceptas en su totalidad y asumes toda la responsabilidad por el uso que hagas de la aplicación y cualquier resultado que se derive de ello.'**
  String get terms_section6_body;

  /// No description provided for @terms_section7_title.
  ///
  /// In es, this message translates to:
  /// **'7. Tus datos y tu privacidad'**
  String get terms_section7_title;

  /// No description provided for @terms_section7_body.
  ///
  /// In es, this message translates to:
  /// **'La aplicación almacena tu configuración y los resultados de tu evaluación localmente en tu dispositivo. Esto incluye las aplicaciones que elijas para los Límites de tiempo o el bloqueo con oración, y el historial local de oraciones completadas que se usa para mostrar tu racha. No vende tus datos personales. Las solicitudes de red se procesan en el propio dispositivo para decidir qué bloquear; la aplicación no requiere una cuenta para funcionar.'**
  String get terms_section7_body;

  /// No description provided for @terms_section8_title.
  ///
  /// In es, this message translates to:
  /// **'8. Permisos del dispositivo'**
  String get terms_section8_title;

  /// No description provided for @terms_section8_body.
  ///
  /// In es, this message translates to:
  /// **'Para funcionar, la aplicación puede usar un servicio VPN local para el filtrado de DNS y, si los activas, el Servicio de Accesibilidad y las funciones de administración de dispositivo de Android. El Servicio de Accesibilidad se usa para la protección contra desinstalación, para hacer cumplir los Límites de tiempo de redes sociales/aplicaciones, y para el bloqueo con oración. Puedes revisar o revocar estos permisos en la configuración de tu dispositivo en cualquier momento, lo cual puede reducir o desactivar la protección correspondiente.'**
  String get terms_section8_body;

  /// No description provided for @terms_section9_title.
  ///
  /// In es, this message translates to:
  /// **'9. Limitación de responsabilidad'**
  String get terms_section9_title;

  /// No description provided for @terms_section9_body.
  ///
  /// In es, this message translates to:
  /// **'En la máxima medida permitida por la ley, el propietario y desarrollador de la aplicación no será responsable de ningún daño directo, indirecto o incidental derivado del uso, o de la imposibilidad de uso, de la aplicación, incluyendo cualquier contenido que sea o no bloqueado.'**
  String get terms_section9_body;

  /// No description provided for @terms_section10_title.
  ///
  /// In es, this message translates to:
  /// **'10. Cambios en estos Términos'**
  String get terms_section10_title;

  /// No description provided for @terms_section10_body.
  ///
  /// In es, this message translates to:
  /// **'Estos Términos pueden actualizarse a medida que la aplicación evolucione. Seguir usando la aplicación después de una actualización significa que aceptas los Términos revisados.'**
  String get terms_section10_body;

  /// No description provided for @terms_section11_title.
  ///
  /// In es, this message translates to:
  /// **'11. Contacto y soporte'**
  String get terms_section11_title;

  /// No description provided for @terms_section11_body.
  ///
  /// In es, this message translates to:
  /// **'Para preguntas, reportes de errores o soporte, contacta al propietario y desarrollador {name} en {email}.'**
  String terms_section11_body(String name, String email);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'es', 'pt'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'pt':
      return AppLocalizationsPt();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
