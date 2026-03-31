import {
  ReportStatus,
  InfractionSeverity,
  InfractionCategory,
  EvidenceType,
  LogLevel,
  Locale,
} from '../src/models/enums';
import type { ReportCreate, ReportDetail, ReportSummary, LocationData } from '../src/models/report';
import type { InfractionResponse } from '../src/models/infraction';
import type { TokenResponse, LoginRequest, RegisterRequest } from '../src/models/auth';

describe('Enum values', () => {
  describe('ReportStatus', () => {
    it('has correct string values', () => {
      expect(ReportStatus.Draft).toBe('draft');
      expect(ReportStatus.Submitted).toBe('submitted');
      expect(ReportStatus.UnderReview).toBe('under_review');
      expect(ReportStatus.Verified).toBe('verified');
      expect(ReportStatus.Rejected).toBe('rejected');
      expect(ReportStatus.Resolved).toBe('resolved');
    });

    it('has exactly 6 members', () => {
      const values = Object.values(ReportStatus);
      expect(values).toHaveLength(6);
    });
  });

  describe('InfractionSeverity', () => {
    it('has correct string values', () => {
      expect(InfractionSeverity.Low).toBe('low');
      expect(InfractionSeverity.Medium).toBe('medium');
      expect(InfractionSeverity.High).toBe('high');
      expect(InfractionSeverity.Critical).toBe('critical');
    });
  });

  describe('InfractionCategory', () => {
    it('has correct string values', () => {
      expect(InfractionCategory.Parking).toBe('parking');
      expect(InfractionCategory.Traffic).toBe('traffic');
      expect(InfractionCategory.Safety).toBe('safety');
      expect(InfractionCategory.Environmental).toBe('environmental');
      expect(InfractionCategory.Documentation).toBe('documentation');
      expect(InfractionCategory.Other).toBe('other');
    });
  });

  describe('EvidenceType', () => {
    it('has correct string values', () => {
      expect(EvidenceType.Photo).toBe('photo');
      expect(EvidenceType.Video).toBe('video');
      expect(EvidenceType.Document).toBe('document');
    });
  });

  describe('LogLevel', () => {
    it('has correct string values', () => {
      expect(LogLevel.None).toBe('none');
      expect(LogLevel.Error).toBe('error');
      expect(LogLevel.Warn).toBe('warn');
      expect(LogLevel.Info).toBe('info');
      expect(LogLevel.Debug).toBe('debug');
    });
  });

  describe('Locale', () => {
    it('has correct string values', () => {
      expect(Locale.En).toBe('en');
      expect(Locale.Es).toBe('es');
    });
  });
});

describe('Interface shape validation', () => {
  describe('LocationData', () => {
    it('accepts required fields only', () => {
      const location: LocationData = {
        latitude: 40.4168,
        longitude: -3.7038,
      };
      expect(location.latitude).toBe(40.4168);
      expect(location.longitude).toBe(-3.7038);
      expect(location.address).toBeUndefined();
    });

    it('accepts all optional fields', () => {
      const location: LocationData = {
        latitude: 40.4168,
        longitude: -3.7038,
        address: '123 Main St',
        city: 'Madrid',
        state: 'Madrid',
        country: 'Spain',
        postalCode: '28013',
      };
      expect(location.address).toBe('123 Main St');
      expect(location.postalCode).toBe('28013');
    });
  });

  describe('ReportCreate', () => {
    it('accepts a valid report creation payload', () => {
      const report: ReportCreate = {
        plateNumber: 'ABC1234',
        vehicleTypeId: 'vt-car',
        infractionId: 'inf-001',
        description: 'Double parked on main street',
        location: { latitude: 40.4168, longitude: -3.7038 },
      };
      expect(report.plateNumber).toBe('ABC1234');
      expect(report.infractionId).toBe('inf-001');
      expect(report.occurredAt).toBeUndefined();
    });

    it('accepts optional occurredAt', () => {
      const report: ReportCreate = {
        plateNumber: 'XYZ',
        vehicleTypeId: 'vt-moto',
        infractionId: 'inf-002',
        description: 'Red light',
        location: { latitude: 0, longitude: 0 },
        occurredAt: '2025-06-15T08:00:00Z',
      };
      expect(report.occurredAt).toBe('2025-06-15T08:00:00Z');
    });
  });

  describe('ReportSummary', () => {
    it('has all expected fields', () => {
      const summary: ReportSummary = {
        id: 'rpt-001',
        plateNumber: 'ABC1234',
        infractionName: 'Illegal Parking',
        severity: InfractionSeverity.Medium,
        status: ReportStatus.Submitted,
        location: { latitude: 40.4168, longitude: -3.7038 },
        occurredAt: '2025-01-15T10:00:00Z',
        createdAt: '2025-01-15T10:05:00Z',
        evidenceCount: 2,
      };
      expect(summary.id).toBe('rpt-001');
      expect(summary.status).toBe(ReportStatus.Submitted);
      expect(summary.evidenceCount).toBe(2);
    });
  });

  describe('InfractionResponse', () => {
    it('has all expected fields', () => {
      const infraction: InfractionResponse = {
        id: 'inf-001',
        name: 'Illegal Parking',
        description: 'Parking in a no-parking zone',
        category: InfractionCategory.Parking,
        severity: InfractionSeverity.Medium,
        fineAmount: 150.0,
        points: 2,
        isActive: true,
      };
      expect(infraction.id).toBe('inf-001');
      expect(infraction.category).toBe(InfractionCategory.Parking);
      expect(infraction.fineAmount).toBe(150.0);
    });
  });

  describe('TokenResponse', () => {
    it('has all expected fields', () => {
      const token: TokenResponse = {
        accessToken: 'access-123',
        refreshToken: 'refresh-456',
        tokenType: 'Bearer',
        expiresIn: 3600,
      };
      expect(token.accessToken).toBe('access-123');
      expect(token.expiresIn).toBe(3600);
    });
  });

  describe('LoginRequest', () => {
    it('has email and password', () => {
      const req: LoginRequest = {
        email: 'test@example.com',
        password: 'secret',
      };
      expect(req.email).toBe('test@example.com');
    });
  });

  describe('RegisterRequest', () => {
    it('has all required fields', () => {
      const req: RegisterRequest = {
        email: 'new@example.com',
        password: 'secret123',
        fullName: 'Test User',
      };
      expect(req.fullName).toBe('Test User');
    });

    it('accepts optional phoneNumber', () => {
      const req: RegisterRequest = {
        email: 'new@example.com',
        password: 'secret123',
        fullName: 'Test User',
        phoneNumber: '+1234567890',
      };
      expect(req.phoneNumber).toBe('+1234567890');
    });
  });
});
