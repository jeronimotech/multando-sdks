import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// A small circular info button that, when tapped, opens a modal bottom
/// sheet explaining Multando's responsible-reporting principles.
///
/// Use this widget next to any report-submission UI so reporters always
/// have one tap of context on anonymity, rate limits, and the
/// consequences of false reports. Third-party apps integrating the SDK
/// are expected to surface this (or equivalent copy) per the developer
/// guidelines.
///
/// Localization is handled in-line for the SDK's supported locales
/// (`'en'`, `'es'`). Unknown locales fall back to English.
class MultandoInfoButton extends StatelessWidget {
  const MultandoInfoButton({
    super.key,
    this.locale = 'en',
    this.primaryColor = const Color(0xFF3B5EEF),
    this.iconSize = 20,
  });

  /// Locale code. Supported: `'en'`, `'es'`. Anything else falls back
  /// to English.
  final String locale;

  /// Brand color for the icon, links and close button.
  final Color primaryColor;

  /// Size of the info icon in logical pixels.
  final double iconSize;

  static const String principlesUrl = 'https://multando.com/principles';

  @override
  Widget build(BuildContext context) {
    final strings = _stringsFor(locale);
    return IconButton(
      tooltip: strings['info_button_tooltip'],
      icon: Icon(
        Icons.info_outline,
        size: iconSize,
        color: primaryColor,
      ),
      visualDensity: VisualDensity.compact,
      onPressed: () => _showSheet(context, strings),
    );
  }

  void _showSheet(BuildContext context, Map<String, String> strings) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _InfoSheet(
        strings: strings,
        primaryColor: primaryColor,
      ),
    );
  }

  static Map<String, String> _stringsFor(String locale) {
    if (locale.toLowerCase().startsWith('es')) {
      return const {
        'responsible_reporting_title':
            'Como Multando protege el reporte responsable',
        'responsible_reporting_body':
            '- Los reportes documentan comportamientos en espacios publicos, no a personas.\n'
            '- La identidad del reportante se mantiene anonima y nunca se comparte con la parte reportada.\n'
            '- Un comparendo legal solo puede ser emitido tras la validacion de la autoridad competente.\n'
            '- Los limites de frecuencia y cooldowns de placa previenen el acoso dirigido y los ataques coordinados.\n'
            '- Los reportes falsos o de mala fe penalizan la reputacion y recompensas del reportante, no a la parte reportada.',
        'info_button_tooltip': 'Sobre el reporte responsable',
        'learn_more': 'Saber mas',
        'close': 'Cerrar',
        'copy_link': 'Copiar enlace',
        'link_copied': 'Enlace copiado',
      };
    }
    return const {
      'responsible_reporting_title':
          'How Multando protects responsible reporting',
      'responsible_reporting_body':
          '- Reports document public behavior in public spaces, not individual people.\n'
          '- Reporter identity is kept anonymous and never shared with the reported party.\n'
          '- A legal comparendo can only be issued after validation by the competent authority.\n'
          '- Rate limits and plate cooldowns prevent targeted harassment and coordinated pile-ons.\n'
          "- False or bad-faith reports penalize the reporter's reputation and rewards, not the reported party.",
      'info_button_tooltip': 'About responsible reporting',
      'learn_more': 'Learn more',
      'close': 'Close',
      'copy_link': 'Copy link',
      'link_copied': 'Link copied',
    };
  }
}

class _InfoSheet extends StatelessWidget {
  const _InfoSheet({
    required this.strings,
    required this.primaryColor,
  });

  final Map<String, String> strings;
  final Color primaryColor;

  @override
  Widget build(BuildContext context) {
    final bullets = (strings['responsible_reporting_body'] ?? '')
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .map((line) => line.startsWith('- ') ? line.substring(2) : line)
        .toList();

    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 8,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.shield_outlined, color: primaryColor),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    strings['responsible_reporting_title'] ?? '',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...bullets.map(
              (b) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: primaryColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        b,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Learn more: SelectableText because url_launcher is not a dep
            // of this SDK. Also offer a "copy link" action for easy sharing.
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: primaryColor.withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Icon(Icons.link, size: 18, color: primaryColor),
                  const SizedBox(width: 8),
                  Expanded(
                    child: SelectableText(
                      MultandoInfoButton.principlesUrl,
                      style: TextStyle(
                        color: primaryColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () async {
                      await Clipboard.setData(const ClipboardData(
                        text: MultandoInfoButton.principlesUrl,
                      ));
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(strings['link_copied'] ?? 'Copied'),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      }
                    },
                    icon: const Icon(Icons.copy, size: 16),
                    label: Text(strings['learn_more'] ?? 'Learn more'),
                    style: TextButton.styleFrom(foregroundColor: primaryColor),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(),
                style: TextButton.styleFrom(foregroundColor: primaryColor),
                child: Text(strings['close'] ?? 'Close'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
