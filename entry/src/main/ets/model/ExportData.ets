/**
 * 导出数据模型
 */
import { WeightRecord } from './WeightRecord';
import { TargetWeightRecord } from '../data/TargetWeightService';

export interface ExportFormat {
  type: 'csv' | 'excel' | 'json';
  extension: string;
  mimeType: string;
}

export interface ExportOptions {
  format: 'csv' | 'excel' | 'json';
  includeStatistics: boolean;
  startDate?: number;
  endDate?: number;
  timestamp: number;
}

export interface ExportResult {
  success: boolean;
  fileName: string;
  filePath?: string;
  recordCount: number;
  timestamp: number;
  error?: string;
}

export interface ImportOptions {
  conflictResolution: 'override' | 'merge' | 'skip';
}

export interface ImportResult {
  success: boolean;
  importedCount: number;
  skippedCount: number;
  failedCount: number;
  errors: string[];
  timestamp: number;
}

export interface ExportDataContent {
  exportDate: string;
  version: string;
  records: ExportRecordData[];
  targets?: ExportTargetData[];
  statistics?: ExportStatisticsData;
}

export interface ExportRecordData {
  id: number;
  weight: number;
  date: number;
  formattedDate: string;
  notes?: string;
}

export interface ExportTargetData {
  id: number;
  targetWeight: number;
  setDate: number;
  formattedDate: string;
  targetDate?: number;
  notes?: string;
}

export interface ExportStatisticsData {
  totalRecords: number;
  latestWeight?: number;
  averageWeight?: number;
  minWeight?: number;
  maxWeight?: number;
  currentTarget?: number;
}
