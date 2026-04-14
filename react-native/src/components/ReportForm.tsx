import React, { useState, useCallback, useEffect } from 'react';
import {
  View,
  Text,
  TextInput,
  TouchableOpacity,
  ActivityIndicator,
  ScrollView,
  StyleSheet,
  Alert,
  ViewStyle,
  TextStyle,
} from 'react-native';
import { useMultando } from '../hooks/useMultando';
import { useReports } from '../hooks/useReports';
import { useInfractions } from '../hooks/useInfractions';
import { useVehicleTypes } from '../hooks/useVehicleTypes';
import { ReportCreate, LocationData, ReportDetail } from '../models/report';
import { InfractionResponse } from '../models/infraction';
import { VehicleTypeResponse } from '../models/vehicleType';
import { MultandoInfoButton } from './MultandoInfoButton';
import { SupportedLocale } from '../i18n/strings';

type ReportFormStep = 'capture' | 'confirm' | 'submit';

export interface ReportFormProps {
  location: LocationData;
  onSuccess?: (result: ReportDetail | string) => void;
  onCancel?: () => void;
  onError?: (error: Error) => void;
  style?: ViewStyle;
  /**
   * Locale used by the embedded responsible-reporting info button.
   * Defaults to 'en'.
   */
  infoLocale?: SupportedLocale;
}

interface FormData {
  plateNumber: string;
  vehicleTypeId: string;
  infractionId: string;
  description: string;
}

interface FormErrors {
  plateNumber?: string;
  vehicleTypeId?: string;
  infractionId?: string;
  description?: string;
}

export function ReportForm({
  location,
  onSuccess,
  onCancel,
  onError,
  style,
  infoLocale = 'en',
}: ReportFormProps): React.ReactElement {
  const { t } = useMultando();
  const { create, isLoading: isSubmitting } = useReports();
  const { infractions, isLoading: loadingInfractions } = useInfractions();
  const { vehicleTypes, isLoading: loadingVehicleTypes } = useVehicleTypes();

  const [step, setStep] = useState<ReportFormStep>('capture');
  const [formData, setFormData] = useState<FormData>({
    plateNumber: '',
    vehicleTypeId: '',
    infractionId: '',
    description: '',
  });
  const [errors, setErrors] = useState<FormErrors>({});
  const [submitResult, setSubmitResult] = useState<ReportDetail | string | null>(null);

  const [selectedInfraction, setSelectedInfraction] =
    useState<InfractionResponse | null>(null);
  const [selectedVehicleType, setSelectedVehicleType] =
    useState<VehicleTypeResponse | null>(null);

  useEffect(() => {
    if (formData.infractionId) {
      const found = infractions.find((i) => i.id === formData.infractionId);
      setSelectedInfraction(found ?? null);
    }
  }, [formData.infractionId, infractions]);

  useEffect(() => {
    if (formData.vehicleTypeId) {
      const found = vehicleTypes.find((v) => v.id === formData.vehicleTypeId);
      setSelectedVehicleType(found ?? null);
    }
  }, [formData.vehicleTypeId, vehicleTypes]);

  const updateField = useCallback(
    <K extends keyof FormData>(field: K, value: FormData[K]) => {
      setFormData((prev) => ({ ...prev, [field]: value }));
      setErrors((prev) => ({ ...prev, [field]: undefined }));
    },
    [],
  );

  const validate = useCallback((): boolean => {
    const newErrors: FormErrors = {};

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

  const handleNext = useCallback(() => {
    if (step === 'capture') {
      if (validate()) {
        setStep('confirm');
      }
    } else if (step === 'confirm') {
      setStep('submit');
      handleSubmit();
    }
  }, [step, validate]);

  const handleBack = useCallback(() => {
    if (step === 'confirm') {
      setStep('capture');
    } else if (step === 'submit' && submitResult === null) {
      setStep('confirm');
    }
  }, [step, submitResult]);

  const handleSubmit = useCallback(async () => {
    const reportData: ReportCreate = {
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
    } catch (err) {
      const error = err instanceof Error ? err : new Error(String(err));
      onError?.(error);
      Alert.alert(t('common.error'), t('report.submitFailed'));
      setStep('confirm');
    }
  }, [formData, location, create, onSuccess, onError, t]);

  const isLoading = loadingInfractions || loadingVehicleTypes;

  if (isLoading) {
    return (
      <View style={[styles.container, styles.centered, style]}>
        <ActivityIndicator size="large" color="#4A90D9" />
        <Text style={styles.loadingText}>{t('common.loading')}</Text>
      </View>
    );
  }

  return (
    <View style={[styles.container, style]}>
      {/* Responsible-reporting info button — placed in the header so
          reporters can access Multando's principles at any step. */}
      <View style={styles.headerRow}>
        <MultandoInfoButton locale={infoLocale} />
      </View>

      {/* Step indicators */}
      <View style={styles.stepIndicator}>
        <StepDot
          label={t('report.stepCapture')}
          active={step === 'capture'}
          completed={step === 'confirm' || step === 'submit'}
        />
        <View style={styles.stepLine} />
        <StepDot
          label={t('report.stepConfirm')}
          active={step === 'confirm'}
          completed={step === 'submit'}
        />
        <View style={styles.stepLine} />
        <StepDot
          label={t('report.stepSubmit')}
          active={step === 'submit'}
          completed={submitResult !== null}
        />
      </View>

      <ScrollView style={styles.scrollContent} keyboardShouldPersistTaps="handled">
        {step === 'capture' && (
          <CaptureStep
            formData={formData}
            errors={errors}
            infractions={infractions}
            vehicleTypes={vehicleTypes}
            updateField={updateField}
            t={t}
          />
        )}

        {step === 'confirm' && (
          <ConfirmStep
            formData={formData}
            location={location}
            selectedInfraction={selectedInfraction}
            selectedVehicleType={selectedVehicleType}
            t={t}
          />
        )}

        {step === 'submit' && (
          <SubmitStep
            isSubmitting={isSubmitting}
            submitResult={submitResult}
            t={t}
          />
        )}
      </ScrollView>

      {/* Action buttons */}
      <View style={styles.actions}>
        {step !== 'submit' && (
          <TouchableOpacity
            style={styles.cancelButton}
            onPress={step === 'capture' ? onCancel : handleBack}
          >
            <Text style={styles.cancelButtonText}>
              {step === 'capture' ? t('common.cancel') : t('common.back')}
            </Text>
          </TouchableOpacity>
        )}

        {step !== 'submit' && (
          <TouchableOpacity
            style={styles.nextButton}
            onPress={handleNext}
          >
            <Text style={styles.nextButtonText}>
              {step === 'capture' ? t('common.next') : t('common.submit')}
            </Text>
          </TouchableOpacity>
        )}

        {step === 'submit' && submitResult !== null && (
          <TouchableOpacity
            style={styles.nextButton}
            onPress={() => onSuccess?.(submitResult)}
          >
            <Text style={styles.nextButtonText}>{t('common.done')}</Text>
          </TouchableOpacity>
        )}
      </View>
    </View>
  );
}

// --- Sub-components ---

interface StepDotProps {
  label: string;
  active: boolean;
  completed: boolean;
}

function StepDot({ label, active, completed }: StepDotProps): React.ReactElement {
  return (
    <View style={styles.stepDotContainer}>
      <View
        style={[
          styles.stepDot,
          active && styles.stepDotActive,
          completed && styles.stepDotCompleted,
        ]}
      />
      <Text
        style={[
          styles.stepLabel,
          (active || completed) && styles.stepLabelActive,
        ]}
      >
        {label}
      </Text>
    </View>
  );
}

interface CaptureStepProps {
  formData: FormData;
  errors: FormErrors;
  infractions: InfractionResponse[];
  vehicleTypes: VehicleTypeResponse[];
  updateField: <K extends keyof FormData>(field: K, value: FormData[K]) => void;
  t: (key: string) => string;
}

function CaptureStep({
  formData,
  errors,
  infractions,
  vehicleTypes,
  updateField,
  t,
}: CaptureStepProps): React.ReactElement {
  return (
    <View>
      {/* Plate Number */}
      <Text style={styles.label}>{t('report.plateNumber')}</Text>
      <TextInput
        style={[styles.input, errors.plateNumber ? styles.inputError : null]}
        value={formData.plateNumber}
        onChangeText={(v) => updateField('plateNumber', v)}
        placeholder={t('report.plateNumber')}
        autoCapitalize="characters"
      />
      {errors.plateNumber && (
        <Text style={styles.errorText}>{errors.plateNumber}</Text>
      )}

      {/* Vehicle Type Selector */}
      <Text style={styles.label}>{t('report.vehicleType')}</Text>
      <View style={styles.selectorContainer}>
        {vehicleTypes.map((vt) => (
          <TouchableOpacity
            key={vt.id}
            style={[
              styles.selectorItem,
              formData.vehicleTypeId === vt.id && styles.selectorItemActive,
            ]}
            onPress={() => updateField('vehicleTypeId', vt.id)}
          >
            <Text
              style={[
                styles.selectorItemText,
                formData.vehicleTypeId === vt.id &&
                  styles.selectorItemTextActive,
              ]}
            >
              {vt.name}
            </Text>
          </TouchableOpacity>
        ))}
      </View>
      {errors.vehicleTypeId && (
        <Text style={styles.errorText}>{errors.vehicleTypeId}</Text>
      )}

      {/* Infraction Selector */}
      <Text style={styles.label}>{t('report.infraction')}</Text>
      <View style={styles.selectorContainer}>
        {infractions.map((inf) => (
          <TouchableOpacity
            key={inf.id}
            style={[
              styles.selectorItem,
              formData.infractionId === inf.id && styles.selectorItemActive,
            ]}
            onPress={() => updateField('infractionId', inf.id)}
          >
            <Text
              style={[
                styles.selectorItemText,
                formData.infractionId === inf.id &&
                  styles.selectorItemTextActive,
              ]}
            >
              {inf.name}
            </Text>
          </TouchableOpacity>
        ))}
      </View>
      {errors.infractionId && (
        <Text style={styles.errorText}>{errors.infractionId}</Text>
      )}

      {/* Description */}
      <Text style={styles.label}>{t('report.description')}</Text>
      <TextInput
        style={[
          styles.input,
          styles.textArea,
          errors.description ? styles.inputError : null,
        ]}
        value={formData.description}
        onChangeText={(v) => updateField('description', v)}
        placeholder={t('report.descriptionPlaceholder')}
        multiline
        numberOfLines={4}
        textAlignVertical="top"
      />
      {errors.description && (
        <Text style={styles.errorText}>{errors.description}</Text>
      )}
    </View>
  );
}

interface ConfirmStepProps {
  formData: FormData;
  location: LocationData;
  selectedInfraction: InfractionResponse | null;
  selectedVehicleType: VehicleTypeResponse | null;
  t: (key: string) => string;
}

function ConfirmStep({
  formData,
  location,
  selectedInfraction,
  selectedVehicleType,
  t,
}: ConfirmStepProps): React.ReactElement {
  return (
    <View>
      <View style={styles.confirmRow}>
        <Text style={styles.confirmLabel}>{t('report.plateNumber')}</Text>
        <Text style={styles.confirmValue}>{formData.plateNumber}</Text>
      </View>
      <View style={styles.confirmRow}>
        <Text style={styles.confirmLabel}>{t('report.vehicleType')}</Text>
        <Text style={styles.confirmValue}>
          {selectedVehicleType?.name ?? formData.vehicleTypeId}
        </Text>
      </View>
      <View style={styles.confirmRow}>
        <Text style={styles.confirmLabel}>{t('report.infraction')}</Text>
        <Text style={styles.confirmValue}>
          {selectedInfraction?.name ?? formData.infractionId}
        </Text>
      </View>
      {selectedInfraction && (
        <View style={styles.confirmRow}>
          <Text style={styles.confirmLabel}>Severity</Text>
          <Text style={styles.confirmValue}>
            {selectedInfraction.severity}
          </Text>
        </View>
      )}
      <View style={styles.confirmRow}>
        <Text style={styles.confirmLabel}>{t('report.description')}</Text>
        <Text style={styles.confirmValue}>{formData.description}</Text>
      </View>
      <View style={styles.confirmRow}>
        <Text style={styles.confirmLabel}>{t('report.location')}</Text>
        <Text style={styles.confirmValue}>
          {location.address ??
            `${location.latitude.toFixed(6)}, ${location.longitude.toFixed(6)}`}
        </Text>
      </View>
    </View>
  );
}

interface SubmitStepProps {
  isSubmitting: boolean;
  submitResult: ReportDetail | string | null;
  t: (key: string) => string;
}

function SubmitStep({
  isSubmitting,
  submitResult,
  t,
}: SubmitStepProps): React.ReactElement {
  if (isSubmitting) {
    return (
      <View style={styles.centered}>
        <ActivityIndicator size="large" color="#4A90D9" />
        <Text style={styles.loadingText}>{t('common.loading')}</Text>
      </View>
    );
  }

  if (submitResult !== null) {
    const isQueued = typeof submitResult === 'string';
    return (
      <View style={styles.centered}>
        <Text style={styles.successIcon}>{'[OK]'}</Text>
        <Text style={styles.successText}>
          {isQueued ? t('report.submitQueued') : t('report.submitSuccess')}
        </Text>
      </View>
    );
  }

  return (
    <View style={styles.centered}>
      <Text>{t('common.loading')}</Text>
    </View>
  );
}

// --- Styles ---

interface Styles {
  container: ViewStyle;
  centered: ViewStyle;
  loadingText: TextStyle;
  headerRow: ViewStyle;
  stepIndicator: ViewStyle;
  stepDotContainer: ViewStyle;
  stepDot: ViewStyle;
  stepDotActive: ViewStyle;
  stepDotCompleted: ViewStyle;
  stepLine: ViewStyle;
  stepLabel: TextStyle;
  stepLabelActive: TextStyle;
  scrollContent: ViewStyle;
  label: TextStyle;
  input: TextStyle;
  inputError: ViewStyle;
  textArea: TextStyle;
  errorText: TextStyle;
  selectorContainer: ViewStyle;
  selectorItem: ViewStyle;
  selectorItemActive: ViewStyle;
  selectorItemText: TextStyle;
  selectorItemTextActive: TextStyle;
  confirmRow: ViewStyle;
  confirmLabel: TextStyle;
  confirmValue: TextStyle;
  actions: ViewStyle;
  cancelButton: ViewStyle;
  cancelButtonText: TextStyle;
  nextButton: ViewStyle;
  nextButtonText: TextStyle;
  successIcon: TextStyle;
  successText: TextStyle;
}

const styles = StyleSheet.create<Styles>({
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
  headerRow: {
    flexDirection: 'row',
    justifyContent: 'flex-end',
    paddingHorizontal: 16,
    paddingTop: 12,
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
