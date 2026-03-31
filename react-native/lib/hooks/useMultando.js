"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.MultandoContext = void 0;
exports.useMultando = useMultando;
exports.getTranslation = getTranslation;
const react_1 = require("react");
const enums_1 = require("../models/enums");
const en_json_1 = __importDefault(require("../i18n/en.json"));
const es_json_1 = __importDefault(require("../i18n/es.json"));
exports.MultandoContext = (0, react_1.createContext)(null);
function useMultando() {
    const context = (0, react_1.useContext)(exports.MultandoContext);
    if (!context) {
        throw new Error('useMultando must be used within a <MultandoProvider>. ' +
            'Wrap your component tree with <MultandoProvider config={...}>.');
    }
    return context;
}
const LOCALE_STRINGS = {
    [enums_1.Locale.En]: en_json_1.default,
    [enums_1.Locale.Es]: es_json_1.default,
};
function getTranslation(locale) {
    const strings = LOCALE_STRINGS[locale] || LOCALE_STRINGS[enums_1.Locale.En];
    return (key) => {
        const parts = key.split('.');
        let current = strings;
        for (const part of parts) {
            if (current && typeof current === 'object' && part in current) {
                current = current[part];
            }
            else {
                return key;
            }
        }
        return typeof current === 'string' ? current : key;
    };
}
//# sourceMappingURL=useMultando.js.map