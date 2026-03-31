import { ReportService } from '../src/services/reportService';
import { Logger } from '../src/core/logger';
import { OfflineQueue } from '../src/core/offlineQueue';
import { LogLevel } from '../src/models/enums';
import type { ReportCreate, ReportDetail, ReportList } from '../src/models/report';

// Mock AsyncStorage
jest.mock('@react-native-async-storage/async-storage', () => ({
  getItem: jest.fn(() => Promise.resolve(null)),
  setItem: jest.fn(() => Promise.resolve()),
  removeItem: jest.fn(() => Promise.resolve()),
}));

// Mock NetInfo
jest.mock('@react-native-community/netinfo', () => ({
  addEventListener: jest.fn(() => jest.fn()),
  fetch: jest.fn(() =>
    Promise.resolve({ isConnected: true, isInternetReachable: true }),
  ),
}));

const sampleDetail: ReportDetail = {
  id: 'rpt-001',
  plateNumber: 'ABC1234',
  vehicleTypeId: 'vt-car',
  vehicleTypeName: 'Car',
  infractionId: 'inf-001',
  infractionName: 'Illegal Parking',
  severity: 'medium' as any,
  description: 'Double parked on main street',
  status: 'submitted' as any,
  location: { latitude: 40.4168, longitude: -3.7038, address: 'Test St' },
  occurredAt: '2025-01-15T10:00:00Z',
  createdAt: '2025-01-15T10:05:00Z',
  updatedAt: '2025-01-15T10:05:00Z',
  reporter: { id: 'user-001', fullName: 'Test User', email: 'test@example.com' } as any,
  evidence: [],
  verificationCount: 0,
  rejectionCount: 0,
};

const sampleList: ReportList = {
  items: [
    {
      id: 'rpt-001',
      plateNumber: 'ABC1234',
      infractionName: 'Illegal Parking',
      severity: 'medium' as any,
      status: 'submitted' as any,
      location: { latitude: 40.4168, longitude: -3.7038 },
      occurredAt: '2025-01-15T10:00:00Z',
      createdAt: '2025-01-15T10:05:00Z',
      evidenceCount: 0,
    },
  ],
  total: 1,
  page: 1,
  pageSize: 20,
  totalPages: 1,
};

describe('ReportService', () => {
  let service: ReportService;
  let mockHttp: any;
  let logger: Logger;
  let offlineQueue: OfflineQueue;

  beforeEach(() => {
    mockHttp = {
      get: jest.fn(),
      post: jest.fn(),
      put: jest.fn(),
      delete: jest.fn(),
    };
    logger = new Logger(LogLevel.None);
    offlineQueue = new OfflineQueue(logger, false);
    service = new ReportService(mockHttp, offlineQueue, logger);
  });

  describe('create', () => {
    it('sends POST /reports and returns ReportDetail', async () => {
      mockHttp.post.mockResolvedValue({ data: sampleDetail });

      const report: ReportCreate = {
        plateNumber: 'ABC1234',
        vehicleTypeId: 'vt-car',
        infractionId: 'inf-001',
        description: 'Double parked',
        location: { latitude: 40.4168, longitude: -3.7038 },
      };

      const result = await service.create(report);

      expect(mockHttp.post).toHaveBeenCalledWith('/reports', report);
      expect(result).toEqual(sampleDetail);
    });

    it('returns the result from the API', async () => {
      mockHttp.post.mockResolvedValue({ data: sampleDetail });

      const result = await service.create({
        plateNumber: 'XYZ',
        vehicleTypeId: 'vt-car',
        infractionId: 'inf-002',
        description: 'Test',
        location: { latitude: 0, longitude: 0 },
      });

      expect((result as ReportDetail).id).toBe('rpt-001');
    });
  });

  describe('list', () => {
    it('sends GET /reports and returns ReportList', async () => {
      mockHttp.get.mockResolvedValue({ data: sampleList });

      const result = await service.list();

      expect(mockHttp.get).toHaveBeenCalledWith('/reports', { params: undefined });
      expect(result.items).toHaveLength(1);
      expect(result.total).toBe(1);
    });

    it('passes pagination parameters', async () => {
      mockHttp.get.mockResolvedValue({ data: sampleList });

      await service.list({ page: 2, pageSize: 10 });

      expect(mockHttp.get).toHaveBeenCalledWith('/reports', {
        params: { page: 2, pageSize: 10 },
      });
    });

    it('passes status filter', async () => {
      mockHttp.get.mockResolvedValue({ data: sampleList });

      await service.list({ status: 'verified' });

      expect(mockHttp.get).toHaveBeenCalledWith('/reports', {
        params: { status: 'verified' },
      });
    });
  });

  describe('getById', () => {
    it('sends GET /reports/:id and returns ReportDetail', async () => {
      mockHttp.get.mockResolvedValue({ data: sampleDetail });

      const result = await service.getById('rpt-001');

      expect(mockHttp.get).toHaveBeenCalledWith('/reports/rpt-001');
      expect(result.id).toBe('rpt-001');
      expect(result.plateNumber).toBe('ABC1234');
    });
  });

  describe('getByPlate', () => {
    it('sends GET /reports/by-plate/:plate', async () => {
      mockHttp.get.mockResolvedValue({ data: sampleList });

      await service.getByPlate('ABC1234');

      expect(mockHttp.get).toHaveBeenCalledWith('/reports/by-plate/ABC1234');
    });

    it('encodes special characters in plate', async () => {
      mockHttp.get.mockResolvedValue({ data: sampleList });

      await service.getByPlate('AB CD');

      expect(mockHttp.get).toHaveBeenCalledWith('/reports/by-plate/AB%20CD');
    });
  });

  describe('delete', () => {
    it('sends DELETE /reports/:id', async () => {
      mockHttp.delete.mockResolvedValue({});

      await service.delete('rpt-001');

      expect(mockHttp.delete).toHaveBeenCalledWith('/reports/rpt-001');
    });
  });
});
