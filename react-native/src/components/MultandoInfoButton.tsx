import React, { useCallback, useState } from 'react';
import {
  FlatList,
  Linking,
  Modal,
  StyleSheet,
  Text,
  TouchableOpacity,
  View,
  ViewStyle,
} from 'react-native';
import {
  SupportedLocale,
  t,
  responsibleReportingBullets,
} from '../i18n/strings';

const PRINCIPLES_URL = 'https://multando.com/principles';
const DEFAULT_PRIMARY_COLOR = '#f97316';

export interface MultandoInfoButtonProps {
  /** Locale for the tooltip, title, bullets, and buttons. Defaults to 'en'. */
  locale?: SupportedLocale;
  /** Accent color used for the "Learn more" action. Defaults to #f97316. */
  primaryColor?: string;
  /** Additional style applied to the touchable wrapper. */
  style?: ViewStyle;
}

/**
 * Small circular "info" button that opens a modal explaining Multando's
 * responsible-reporting principles.
 *
 * Developers are required to surface this (or an equivalent) anywhere
 * users submit reports — it makes the platform's anti-harassment
 * design transparent to the reporter and documents the anonymity
 * guarantee that the reported party relies on.
 *
 * The modal renders the 5-bullet "responsible_reporting_body" from the
 * shared i18n bundle, a "Learn more" link to
 * https://multando.com/principles, and a close button.
 *
 * No external icon library is required — the button renders the
 * unicode "ⓘ" glyph so the component works on a vanilla React Native
 * install.
 */
export function MultandoInfoButton({
  locale = 'en',
  primaryColor = DEFAULT_PRIMARY_COLOR,
  style,
}: MultandoInfoButtonProps): React.ReactElement {
  const [visible, setVisible] = useState(false);

  const bullets = responsibleReportingBullets(locale);

  const handleOpen = useCallback(() => setVisible(true), []);
  const handleClose = useCallback(() => setVisible(false), []);
  const handleLearnMore = useCallback(() => {
    // Fire-and-forget: if the OS can't open the URL (no browser), we
    // still want the modal to stay usable rather than crashing.
    Linking.openURL(PRINCIPLES_URL).catch(() => {
      /* noop */
    });
  }, []);

  return (
    <>
      <TouchableOpacity
        accessible
        accessibilityRole="button"
        accessibilityLabel={t('info_button_tooltip', locale)}
        onPress={handleOpen}
        style={[styles.button, { borderColor: primaryColor }, style]}
        hitSlop={{ top: 8, bottom: 8, left: 8, right: 8 }}
      >
        <Text style={[styles.icon, { color: primaryColor }]}>{'\u24D8'}</Text>
      </TouchableOpacity>

      <Modal
        visible={visible}
        transparent
        animationType="fade"
        onRequestClose={handleClose}
      >
        <View style={styles.backdrop}>
          <View style={styles.card}>
            <Text style={styles.title}>
              {t('responsible_reporting_title', locale)}
            </Text>

            <FlatList
              data={bullets}
              keyExtractor={(_, idx) => String(idx)}
              renderItem={({ item }) => (
                <View style={styles.bulletRow}>
                  <Text style={[styles.bullet, { color: primaryColor }]}>
                    {'\u2022'}
                  </Text>
                  <Text style={styles.bulletText}>{item}</Text>
                </View>
              )}
              style={styles.bulletList}
            />

            <View style={styles.actions}>
              <TouchableOpacity
                onPress={handleClose}
                style={styles.closeButton}
                accessibilityRole="button"
              >
                <Text style={styles.closeButtonText}>
                  {t('close', locale)}
                </Text>
              </TouchableOpacity>

              <TouchableOpacity
                onPress={handleLearnMore}
                style={[
                  styles.learnMoreButton,
                  { backgroundColor: primaryColor },
                ]}
                accessibilityRole="link"
              >
                <Text style={styles.learnMoreText}>
                  {t('learn_more', locale)}
                </Text>
              </TouchableOpacity>
            </View>
          </View>
        </View>
      </Modal>
    </>
  );
}

const styles = StyleSheet.create({
  button: {
    width: 28,
    height: 28,
    borderRadius: 14,
    borderWidth: 1.5,
    alignItems: 'center',
    justifyContent: 'center',
    backgroundColor: 'transparent',
  },
  icon: {
    fontSize: 18,
    lineHeight: 20,
    fontWeight: '600',
  },
  backdrop: {
    flex: 1,
    backgroundColor: 'rgba(0,0,0,0.5)',
    alignItems: 'center',
    justifyContent: 'center',
    padding: 24,
  },
  card: {
    width: '100%',
    maxWidth: 480,
    backgroundColor: '#FFFFFF',
    borderRadius: 14,
    padding: 20,
    maxHeight: '80%',
  },
  title: {
    fontSize: 18,
    fontWeight: '700',
    color: '#111827',
    marginBottom: 12,
  },
  bulletList: {
    marginBottom: 16,
  },
  bulletRow: {
    flexDirection: 'row',
    alignItems: 'flex-start',
    marginBottom: 10,
  },
  bullet: {
    fontSize: 18,
    lineHeight: 22,
    marginRight: 8,
    fontWeight: '700',
  },
  bulletText: {
    flex: 1,
    fontSize: 14,
    lineHeight: 20,
    color: '#374151',
  },
  actions: {
    flexDirection: 'row',
    justifyContent: 'flex-end',
    gap: 10,
  },
  closeButton: {
    paddingHorizontal: 14,
    paddingVertical: 10,
    borderRadius: 8,
    borderWidth: 1,
    borderColor: '#D1D5DB',
  },
  closeButtonText: {
    color: '#374151',
    fontSize: 14,
    fontWeight: '600',
  },
  learnMoreButton: {
    paddingHorizontal: 14,
    paddingVertical: 10,
    borderRadius: 8,
  },
  learnMoreText: {
    color: '#FFFFFF',
    fontSize: 14,
    fontWeight: '600',
  },
});
