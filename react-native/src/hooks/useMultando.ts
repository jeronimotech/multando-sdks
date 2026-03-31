import { createContext, useContext } from 'react';
import { MultandoClient } from '../core/MultandoClient';
import { Locale } from '../models/enums';
import enStrings from '../i18n/en.json';
import esStrings from '../i18n/es.json';

export interface MultandoContextValue {
  client: MultandoClient;
  locale: Locale;
  t: (key: string) => string;
}

export const MultandoContext = createContext<MultandoContextValue | null>(null);

export function useMultando(): MultandoContextValue {
  const context = useContext(MultandoContext);
  if (!context) {
    throw new Error(
      'useMultando must be used within a <MultandoProvider>. ' +
        'Wrap your component tree with <MultandoProvider config={...}>.',
    );
  }
  return context;
}

type StringMap = Record<string, unknown>;

const LOCALE_STRINGS: Record<Locale, StringMap> = {
  [Locale.En]: enStrings as unknown as StringMap,
  [Locale.Es]: esStrings as unknown as StringMap,
};

export function getTranslation(locale: Locale): (key: string) => string {
  const strings = LOCALE_STRINGS[locale] || LOCALE_STRINGS[Locale.En];

  return (key: string): string => {
    const parts = key.split('.');
    let current: unknown = strings;

    for (const part of parts) {
      if (current && typeof current === 'object' && part in current) {
        current = (current as Record<string, unknown>)[part];
      } else {
        return key;
      }
    }

    return typeof current === 'string' ? current : key;
  };
}
