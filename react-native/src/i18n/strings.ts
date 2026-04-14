/**
 * Responsible-reporting localized strings.
 *
 * These strings are kept as a dedicated module (rather than in the
 * existing en.json / es.json) so they can be consumed without requiring
 * JSON resolution — the info button and error-mapping code need a
 * lightweight, synchronous lookup that works even when the host app has
 * not wired up any i18n framework.
 *
 * Keys mirror the Flutter SDK's responsible-reporting key set so the
 * two SDKs stay aligned. Translations in ES use "reportar" (never
 * "denunciar") to match the tone of the multando-backend chatbot.
 */

export type SupportedLocale = 'en' | 'es';

export type StringKey =
  | 'rate_limit_hour'
  | 'rate_limit_day'
  | 'plate_cooldown'
  | 'rejection_rate_warning'
  | 'anonymity_notice'
  | 'responsible_reporting_title'
  | 'responsible_reporting_body_1'
  | 'responsible_reporting_body_2'
  | 'responsible_reporting_body_3'
  | 'responsible_reporting_body_4'
  | 'responsible_reporting_body_5'
  | 'info_button_tooltip'
  | 'learn_more'
  | 'close';

export const STRINGS: Record<SupportedLocale, Record<StringKey, string>> = {
  en: {
    rate_limit_hour:
      "You've reached the hourly report limit. Try again later.",
    rate_limit_day: "You've reached the daily report limit.",
    plate_cooldown:
      "This plate was recently reported nearby. If it's a different incident, please describe it.",
    rejection_rate_warning:
      "Your rejection rate is above 30%. Review Multando's responsible reporting guidelines.",
    anonymity_notice:
      'Your identity is never shared with the reported party.',
    responsible_reporting_title:
      'How Multando protects responsible reporting',
    responsible_reporting_body_1:
      'Reports document public behavior, not people.',
    responsible_reporting_body_2:
      'Reporter identity is never shared with the reported party.',
    responsible_reporting_body_3:
      'A legal citation requires authority validation — the community can only flag, never accuse.',
    responsible_reporting_body_4:
      'Rate limits and plate cooldowns prevent harassment.',
    responsible_reporting_body_5:
      'False reports reduce your points and reputation.',
    info_button_tooltip: 'About responsible reporting',
    learn_more: 'Learn more',
    close: 'Close',
  },
  es: {
    rate_limit_hour:
      'Has alcanzado el límite de reportes por hora. Intenta más tarde.',
    rate_limit_day: 'Has alcanzado el límite diario de reportes.',
    plate_cooldown:
      'Esta placa fue reportada recientemente cerca. Si es un incidente diferente, descríbelo.',
    rejection_rate_warning:
      'Tu tasa de rechazo supera el 30%. Revisa las guías de reporte responsable de Multando.',
    anonymity_notice:
      'Tu identidad nunca se comparte con la parte reportada.',
    responsible_reporting_title:
      'Cómo Multando protege el reporte responsable',
    responsible_reporting_body_1:
      'Los reportes documentan conductas públicas, no personas.',
    responsible_reporting_body_2:
      'La identidad de quien reporta nunca se comparte con la parte reportada.',
    responsible_reporting_body_3:
      'Una sanción legal requiere validación de la autoridad — la comunidad solo puede señalar, nunca acusar.',
    responsible_reporting_body_4:
      'Los límites de frecuencia y los tiempos de espera por placa previenen el acoso.',
    responsible_reporting_body_5:
      'Los reportes falsos reducen tus puntos y tu reputación.',
    info_button_tooltip: 'Sobre el reporte responsable',
    learn_more: 'Saber más',
    close: 'Cerrar',
  },
};

/**
 * Lookup a responsible-reporting string for the given locale.
 *
 * Falls back to English when the locale is not supported, and returns
 * the key itself when the key is unknown — that way a missing string
 * shows up loudly in development rather than silently rendering empty.
 */
export function t(key: StringKey, locale: SupportedLocale = 'en'): string {
  const bundle = STRINGS[locale] ?? STRINGS.en;
  return bundle[key] ?? STRINGS.en[key] ?? key;
}

/**
 * Convenience getter for the 5-bullet responsible-reporting body.
 */
export function responsibleReportingBullets(
  locale: SupportedLocale = 'en',
): string[] {
  return [
    t('responsible_reporting_body_1', locale),
    t('responsible_reporting_body_2', locale),
    t('responsible_reporting_body_3', locale),
    t('responsible_reporting_body_4', locale),
    t('responsible_reporting_body_5', locale),
  ];
}
