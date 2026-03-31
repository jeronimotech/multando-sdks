import { InfractionCategory, InfractionSeverity } from './enums';

export interface InfractionResponse {
  id: string;
  name: string;
  description: string;
  category: InfractionCategory;
  severity: InfractionSeverity;
  fineAmount: number;
  points: number;
  isActive: boolean;
}

export { InfractionCategory, InfractionSeverity };
