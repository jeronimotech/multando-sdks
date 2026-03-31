import React from 'react';
import { ViewStyle } from 'react-native';
import { LocationData, ReportDetail } from '../models/report';
export interface ReportFormProps {
    location: LocationData;
    onSuccess?: (result: ReportDetail | string) => void;
    onCancel?: () => void;
    onError?: (error: Error) => void;
    style?: ViewStyle;
}
export declare function ReportForm({ location, onSuccess, onCancel, onError, style, }: ReportFormProps): React.ReactElement;
//# sourceMappingURL=ReportForm.d.ts.map