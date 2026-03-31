"use strict";
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    var desc = Object.getOwnPropertyDescriptor(m, k);
    if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
      desc = { enumerable: true, get: function() { return m[k]; } };
    }
    Object.defineProperty(o, k2, desc);
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __setModuleDefault = (this && this.__setModuleDefault) || (Object.create ? (function(o, v) {
    Object.defineProperty(o, "default", { enumerable: true, value: v });
}) : function(o, v) {
    o["default"] = v;
});
var __importStar = (this && this.__importStar) || (function () {
    var ownKeys = function(o) {
        ownKeys = Object.getOwnPropertyNames || function (o) {
            var ar = [];
            for (var k in o) if (Object.prototype.hasOwnProperty.call(o, k)) ar[ar.length] = k;
            return ar;
        };
        return ownKeys(o);
    };
    return function (mod) {
        if (mod && mod.__esModule) return mod;
        var result = {};
        if (mod != null) for (var k = ownKeys(mod), i = 0; i < k.length; i++) if (k[i] !== "default") __createBinding(result, mod, k[i]);
        __setModuleDefault(result, mod);
        return result;
    };
})();
Object.defineProperty(exports, "__esModule", { value: true });
exports.ReportForm = ReportForm;
const react_1 = __importStar(require("react"));
const react_native_1 = require("react-native");
const useMultando_1 = require("../hooks/useMultando");
const useReports_1 = require("../hooks/useReports");
const useInfractions_1 = require("../hooks/useInfractions");
const useVehicleTypes_1 = require("../hooks/useVehicleTypes");
function ReportForm({ location, onSuccess, onCancel, onError, style, }) {
    const { t } = (0, useMultando_1.useMultando)();
    const { create, isLoading: isSubmitting } = (0, useReports_1.useReports)();
    const { infractions, isLoading: loadingInfractions } = (0, useInfractions_1.useInfractions)();
    const { vehicleTypes, isLoading: loadingVehicleTypes } = (0, useVehicleTypes_1.useVehicleTypes)();
    const [step, setStep] = (0, react_1.useState)('capture');
    const [formData, setFormData] = (0, react_1.useState)({
        plateNumber: '',
        vehicleTypeId: '',
        infractionId: '',
        description: '',
    });
    const [errors, setErrors] = (0, react_1.useState)({});
    const [submitResult, setSubmitResult] = (0, react_1.useState)(null);
    const [selectedInfraction, setSelectedInfraction] = (0, react_1.useState)(null);
    const [selectedVehicleType, setSelectedVehicleType] = (0, react_1.useState)(null);
    (0, react_1.useEffect)(() => {
        if (formData.infractionId) {
            const found = infractions.find((i) => i.id === formData.infractionId);
            setSelectedInfraction(found ?? null);
        }
    }, [formData.infractionId, infractions]);
    (0, react_1.useEffect)(() => {
        if (formData.vehicleTypeId) {
            const found = vehicleTypes.find((v) => v.id === formData.vehicleTypeId);
            setSelectedVehicleType(found ?? null);
        }
    }, [formData.vehicleTypeId, vehicleTypes]);
    const updateField = (0, react_1.useCallback)((field, value) => {
        setFormData((prev) => ({ ...prev, [field]: value }));
        setErrors((prev) => ({ ...prev, [field]: undefined }));
    }, []);
    const validate = (0, react_1.useCallback)(() => {
        const newErrors = {};
        if (!formData.plateNumber.trim()) {
            newErrors.plateNumber = t('validation.plateRequired');
        }
        if (!formData.vehicleTypeId) {
            newErrors.vehicleTypeId = t('validation.vehicleTypeRequired');
        }
        if (!formData.infractionId) {
            newErrors.infractionId = t('validation.infractionRequired');
        }
        if (!formData.description.trim()) {
            newErrors.description = t('validation.descriptionRequired');
        }
        setErrors(newErrors);
        return Object.keys(newErrors).length === 0;
    }, [formData, t]);
    const handleNext = (0, react_1.useCallback)(() => {
        if (step === 'capture') {
            if (validate()) {
                setStep('confirm');
            }
        }
        else if (step === 'confirm') {
            setStep('submit');
            handleSubmit();
        }
    }, [step, validate]);
    const handleBack = (0, react_1.useCallback)(() => {
        if (step === 'confirm') {
            setStep('capture');
        }
        else if (step === 'submit' && submitResult === null) {
            setStep('confirm');
        }
    }, [step, submitResult]);
    const handleSubmit = (0, react_1.useCallback)(async () => {
        const reportData = {
            plateNumber: formData.plateNumber.trim(),
            vehicleTypeId: formData.vehicleTypeId,
            infractionId: formData.infractionId,
            description: formData.description.trim(),
            location,
        };
        try {
            const result = await create(reportData);
            setSubmitResult(result);
            onSuccess?.(result);
        }
        catch (err) {
            const error = err instanceof Error ? err : new Error(String(err));
            onError?.(error);
            react_native_1.Alert.alert(t('common.error'), t('report.submitFailed'));
            setStep('confirm');
        }
    }, [formData, location, create, onSuccess, onError, t]);
    const isLoading = loadingInfractions || loadingVehicleTypes;
    if (isLoading) {
        return (react_1.default.createElement(react_native_1.View, { style: [styles.container, styles.centered, style] },
            react_1.default.createElement(react_native_1.ActivityIndicator, { size: "large", color: "#4A90D9" }),
            react_1.default.createElement(react_native_1.Text, { style: styles.loadingText }, t('common.loading'))));
    }
    return (react_1.default.createElement(react_native_1.View, { style: [styles.container, style] },
        react_1.default.createElement(react_native_1.View, { style: styles.stepIndicator },
            react_1.default.createElement(StepDot, { label: t('report.stepCapture'), active: step === 'capture', completed: step === 'confirm' || step === 'submit' }),
            react_1.default.createElement(react_native_1.View, { style: styles.stepLine }),
            react_1.default.createElement(StepDot, { label: t('report.stepConfirm'), active: step === 'confirm', completed: step === 'submit' }),
            react_1.default.createElement(react_native_1.View, { style: styles.stepLine }),
            react_1.default.createElement(StepDot, { label: t('report.stepSubmit'), active: step === 'submit', completed: submitResult !== null })),
        react_1.default.createElement(react_native_1.ScrollView, { style: styles.scrollContent, keyboardShouldPersistTaps: "handled" },
            step === 'capture' && (react_1.default.createElement(CaptureStep, { formData: formData, errors: errors, infractions: infractions, vehicleTypes: vehicleTypes, updateField: updateField, t: t })),
            step === 'confirm' && (react_1.default.createElement(ConfirmStep, { formData: formData, location: location, selectedInfraction: selectedInfraction, selectedVehicleType: selectedVehicleType, t: t })),
            step === 'submit' && (react_1.default.createElement(SubmitStep, { isSubmitting: isSubmitting, submitResult: submitResult, t: t }))),
        react_1.default.createElement(react_native_1.View, { style: styles.actions },
            step !== 'submit' && (react_1.default.createElement(react_native_1.TouchableOpacity, { style: styles.cancelButton, onPress: step === 'capture' ? onCancel : handleBack },
                react_1.default.createElement(react_native_1.Text, { style: styles.cancelButtonText }, step === 'capture' ? t('common.cancel') : t('common.back')))),
            step !== 'submit' && (react_1.default.createElement(react_native_1.TouchableOpacity, { style: styles.nextButton, onPress: handleNext },
                react_1.default.createElement(react_native_1.Text, { style: styles.nextButtonText }, step === 'capture' ? t('common.next') : t('common.submit')))),
            step === 'submit' && submitResult !== null && (react_1.default.createElement(react_native_1.TouchableOpacity, { style: styles.nextButton, onPress: () => onSuccess?.(submitResult) },
                react_1.default.createElement(react_native_1.Text, { style: styles.nextButtonText }, t('common.done')))))));
}
function StepDot({ label, active, completed }) {
    return (react_1.default.createElement(react_native_1.View, { style: styles.stepDotContainer },
        react_1.default.createElement(react_native_1.View, { style: [
                styles.stepDot,
                active && styles.stepDotActive,
                completed && styles.stepDotCompleted,
            ] }),
        react_1.default.createElement(react_native_1.Text, { style: [
                styles.stepLabel,
                (active || completed) && styles.stepLabelActive,
            ] }, label)));
}
function CaptureStep({ formData, errors, infractions, vehicleTypes, updateField, t, }) {
    return (react_1.default.createElement(react_native_1.View, null,
        react_1.default.createElement(react_native_1.Text, { style: styles.label }, t('report.plateNumber')),
        react_1.default.createElement(react_native_1.TextInput, { style: [styles.input, errors.plateNumber ? styles.inputError : null], value: formData.plateNumber, onChangeText: (v) => updateField('plateNumber', v), placeholder: t('report.plateNumber'), autoCapitalize: "characters" }),
        errors.plateNumber && (react_1.default.createElement(react_native_1.Text, { style: styles.errorText }, errors.plateNumber)),
        react_1.default.createElement(react_native_1.Text, { style: styles.label }, t('report.vehicleType')),
        react_1.default.createElement(react_native_1.View, { style: styles.selectorContainer }, vehicleTypes.map((vt) => (react_1.default.createElement(react_native_1.TouchableOpacity, { key: vt.id, style: [
                styles.selectorItem,
                formData.vehicleTypeId === vt.id && styles.selectorItemActive,
            ], onPress: () => updateField('vehicleTypeId', vt.id) },
            react_1.default.createElement(react_native_1.Text, { style: [
                    styles.selectorItemText,
                    formData.vehicleTypeId === vt.id &&
                        styles.selectorItemTextActive,
                ] }, vt.name))))),
        errors.vehicleTypeId && (react_1.default.createElement(react_native_1.Text, { style: styles.errorText }, errors.vehicleTypeId)),
        react_1.default.createElement(react_native_1.Text, { style: styles.label }, t('report.infraction')),
        react_1.default.createElement(react_native_1.View, { style: styles.selectorContainer }, infractions.map((inf) => (react_1.default.createElement(react_native_1.TouchableOpacity, { key: inf.id, style: [
                styles.selectorItem,
                formData.infractionId === inf.id && styles.selectorItemActive,
            ], onPress: () => updateField('infractionId', inf.id) },
            react_1.default.createElement(react_native_1.Text, { style: [
                    styles.selectorItemText,
                    formData.infractionId === inf.id &&
                        styles.selectorItemTextActive,
                ] }, inf.name))))),
        errors.infractionId && (react_1.default.createElement(react_native_1.Text, { style: styles.errorText }, errors.infractionId)),
        react_1.default.createElement(react_native_1.Text, { style: styles.label }, t('report.description')),
        react_1.default.createElement(react_native_1.TextInput, { style: [
                styles.input,
                styles.textArea,
                errors.description ? styles.inputError : null,
            ], value: formData.description, onChangeText: (v) => updateField('description', v), placeholder: t('report.descriptionPlaceholder'), multiline: true, numberOfLines: 4, textAlignVertical: "top" }),
        errors.description && (react_1.default.createElement(react_native_1.Text, { style: styles.errorText }, errors.description))));
}
function ConfirmStep({ formData, location, selectedInfraction, selectedVehicleType, t, }) {
    return (react_1.default.createElement(react_native_1.View, null,
        react_1.default.createElement(react_native_1.View, { style: styles.confirmRow },
            react_1.default.createElement(react_native_1.Text, { style: styles.confirmLabel }, t('report.plateNumber')),
            react_1.default.createElement(react_native_1.Text, { style: styles.confirmValue }, formData.plateNumber)),
        react_1.default.createElement(react_native_1.View, { style: styles.confirmRow },
            react_1.default.createElement(react_native_1.Text, { style: styles.confirmLabel }, t('report.vehicleType')),
            react_1.default.createElement(react_native_1.Text, { style: styles.confirmValue }, selectedVehicleType?.name ?? formData.vehicleTypeId)),
        react_1.default.createElement(react_native_1.View, { style: styles.confirmRow },
            react_1.default.createElement(react_native_1.Text, { style: styles.confirmLabel }, t('report.infraction')),
            react_1.default.createElement(react_native_1.Text, { style: styles.confirmValue }, selectedInfraction?.name ?? formData.infractionId)),
        selectedInfraction && (react_1.default.createElement(react_native_1.View, { style: styles.confirmRow },
            react_1.default.createElement(react_native_1.Text, { style: styles.confirmLabel }, "Severity"),
            react_1.default.createElement(react_native_1.Text, { style: styles.confirmValue }, selectedInfraction.severity))),
        react_1.default.createElement(react_native_1.View, { style: styles.confirmRow },
            react_1.default.createElement(react_native_1.Text, { style: styles.confirmLabel }, t('report.description')),
            react_1.default.createElement(react_native_1.Text, { style: styles.confirmValue }, formData.description)),
        react_1.default.createElement(react_native_1.View, { style: styles.confirmRow },
            react_1.default.createElement(react_native_1.Text, { style: styles.confirmLabel }, t('report.location')),
            react_1.default.createElement(react_native_1.Text, { style: styles.confirmValue }, location.address ??
                `${location.latitude.toFixed(6)}, ${location.longitude.toFixed(6)}`))));
}
function SubmitStep({ isSubmitting, submitResult, t, }) {
    if (isSubmitting) {
        return (react_1.default.createElement(react_native_1.View, { style: styles.centered },
            react_1.default.createElement(react_native_1.ActivityIndicator, { size: "large", color: "#4A90D9" }),
            react_1.default.createElement(react_native_1.Text, { style: styles.loadingText }, t('common.loading'))));
    }
    if (submitResult !== null) {
        const isQueued = typeof submitResult === 'string';
        return (react_1.default.createElement(react_native_1.View, { style: styles.centered },
            react_1.default.createElement(react_native_1.Text, { style: styles.successIcon }, '[OK]'),
            react_1.default.createElement(react_native_1.Text, { style: styles.successText }, isQueued ? t('report.submitQueued') : t('report.submitSuccess'))));
    }
    return (react_1.default.createElement(react_native_1.View, { style: styles.centered },
        react_1.default.createElement(react_native_1.Text, null, t('common.loading'))));
}
const styles = react_native_1.StyleSheet.create({
    container: {
        flex: 1,
        backgroundColor: '#FFFFFF',
    },
    centered: {
        flex: 1,
        justifyContent: 'center',
        alignItems: 'center',
        padding: 24,
    },
    loadingText: {
        marginTop: 12,
        fontSize: 16,
        color: '#666666',
    },
    stepIndicator: {
        flexDirection: 'row',
        alignItems: 'center',
        justifyContent: 'center',
        paddingVertical: 16,
        paddingHorizontal: 24,
    },
    stepDotContainer: {
        alignItems: 'center',
    },
    stepDot: {
        width: 12,
        height: 12,
        borderRadius: 6,
        backgroundColor: '#DDDDDD',
    },
    stepDotActive: {
        backgroundColor: '#4A90D9',
        width: 16,
        height: 16,
        borderRadius: 8,
    },
    stepDotCompleted: {
        backgroundColor: '#4CAF50',
    },
    stepLine: {
        flex: 1,
        height: 2,
        backgroundColor: '#DDDDDD',
        marginHorizontal: 8,
    },
    stepLabel: {
        fontSize: 11,
        color: '#999999',
        marginTop: 4,
    },
    stepLabelActive: {
        color: '#333333',
        fontWeight: '600',
    },
    scrollContent: {
        flex: 1,
        paddingHorizontal: 16,
    },
    label: {
        fontSize: 14,
        fontWeight: '600',
        color: '#333333',
        marginTop: 16,
        marginBottom: 6,
    },
    input: {
        borderWidth: 1,
        borderColor: '#DDDDDD',
        borderRadius: 8,
        paddingHorizontal: 12,
        paddingVertical: 10,
        fontSize: 16,
        color: '#333333',
        backgroundColor: '#FAFAFA',
    },
    inputError: {
        borderColor: '#E53935',
    },
    textArea: {
        minHeight: 100,
    },
    errorText: {
        color: '#E53935',
        fontSize: 12,
        marginTop: 4,
    },
    selectorContainer: {
        flexDirection: 'row',
        flexWrap: 'wrap',
        gap: 8,
    },
    selectorItem: {
        paddingHorizontal: 14,
        paddingVertical: 8,
        borderRadius: 20,
        borderWidth: 1,
        borderColor: '#DDDDDD',
        backgroundColor: '#FAFAFA',
    },
    selectorItemActive: {
        backgroundColor: '#4A90D9',
        borderColor: '#4A90D9',
    },
    selectorItemText: {
        fontSize: 13,
        color: '#666666',
    },
    selectorItemTextActive: {
        color: '#FFFFFF',
        fontWeight: '600',
    },
    confirmRow: {
        paddingVertical: 12,
        borderBottomWidth: 1,
        borderBottomColor: '#F0F0F0',
    },
    confirmLabel: {
        fontSize: 12,
        color: '#999999',
        marginBottom: 2,
    },
    confirmValue: {
        fontSize: 16,
        color: '#333333',
    },
    actions: {
        flexDirection: 'row',
        padding: 16,
        gap: 12,
        borderTopWidth: 1,
        borderTopColor: '#F0F0F0',
    },
    cancelButton: {
        flex: 1,
        paddingVertical: 14,
        borderRadius: 8,
        borderWidth: 1,
        borderColor: '#DDDDDD',
        alignItems: 'center',
    },
    cancelButtonText: {
        fontSize: 16,
        color: '#666666',
        fontWeight: '600',
    },
    nextButton: {
        flex: 1,
        paddingVertical: 14,
        borderRadius: 8,
        backgroundColor: '#4A90D9',
        alignItems: 'center',
    },
    nextButtonText: {
        fontSize: 16,
        color: '#FFFFFF',
        fontWeight: '600',
    },
    successIcon: {
        fontSize: 24,
        fontWeight: '700',
        color: '#4CAF50',
        marginBottom: 12,
    },
    successText: {
        fontSize: 18,
        color: '#333333',
        textAlign: 'center',
    },
});
//# sourceMappingURL=ReportForm.js.map