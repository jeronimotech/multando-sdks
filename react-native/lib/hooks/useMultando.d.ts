import { MultandoClient } from '../core/MultandoClient';
import { Locale } from '../models/enums';
export interface MultandoContextValue {
    client: MultandoClient;
    locale: Locale;
    t: (key: string) => string;
}
export declare const MultandoContext: import("react").Context<MultandoContextValue | null>;
export declare function useMultando(): MultandoContextValue;
export declare function getTranslation(locale: Locale): (key: string) => string;
//# sourceMappingURL=useMultando.d.ts.map