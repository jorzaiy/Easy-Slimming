/**
 * 健康数据同步冲突模型
 * 处理本地数据与鸿蒙运动健康应用的数据冲突
 */

import { WeightRecord } from './WeightRecord';

export enum ConflictType {
  DUPLICATE = 'DUPLICATE',         // 重复数据
  VERSION_MISMATCH = 'VERSION_MISMATCH', // 版本不匹配
  TIMESTAMP_CONFLICT = 'TIMESTAMP_CONFLICT', // 时间戳冲突
  DATA_INCONSISTENCY = 'DATA_INCONSISTENCY'  // 数据不一致
}

export enum ResolutionOption {
  USE_LOCAL = 'USE_LOCAL',         // 使用本地数据
  USE_HEALTH = 'USE_HEALTH',       // 使用鸿蒙健康数据
  MERGE_AVERAGE = 'MERGE_AVERAGE', // 合并取平均值
  SKIP = 'SKIP'                    // 跳过
}

export interface HealthAppRecord {
  weight: number;
  date: number;
  notes?: string;
  id?: number | string;
  syncId?: string;
}

function isWeightRecord(record: WeightRecord | HealthAppRecord): record is WeightRecord {
  return record instanceof WeightRecord;
}

export function isHealthAppRecord(record: WeightRecord | HealthAppRecord): record is HealthAppRecord {
  if (record instanceof WeightRecord) {
    return false;
  }
  if (record === null || typeof record !== 'object') {
    return false;
  }
  const candidate = record as HealthAppRecord;
  return typeof candidate.weight === 'number' &&
    Number.isFinite(candidate.weight) &&
    typeof candidate.date === 'number' &&
    Number.isFinite(candidate.date);
}

export class HealthSyncConflict {
  id: number;
  conflictType: ConflictType;
  localRecord: WeightRecord;       // 本地记录
  healthRecord: WeightRecord | HealthAppRecord;  // 鸿蒙健康记录
  createdTime: number;             // 冲突检测时间
  resolvedTime?: number;           // 冲突解决时间
  resolutionOption?: ResolutionOption; // 选择的解决方案
  description: string;             // 冲突描述

  constructor(
    conflictType: ConflictType,
    localRecord: WeightRecord,
    healthRecord: WeightRecord | HealthAppRecord,
    description: string,
    id?: number
  ) {
    this.id = id ?? -1;
    this.conflictType = conflictType;
    this.localRecord = localRecord;
    this.healthRecord = healthRecord;
    this.createdTime = Date.now();
    this.description = description;
  }

  isResolved(): boolean {
    return this.resolvedTime !== undefined && this.resolutionOption !== undefined;
  }

  getTimeSinceCreated(): number {
    return Date.now() - this.createdTime;
  }

  getDetailedDescription(): string {
    let detail = `冲突类型: ${this.conflictType}\n`;
    detail += `本地体重: ${this.localRecord.weight}kg (${new Date(this.localRecord.date).toLocaleString()})\n`;
    detail += `鸿蒙体重: ${this.healthRecord.weight}kg (${new Date(this.healthRecord.date).toLocaleString()})\n`;
    detail += `描述: ${this.description}`;
    return detail;
  }

  resolve(option: ResolutionOption): WeightRecord | null {
    switch (option) {
      case ResolutionOption.USE_LOCAL:
        this.markResolved(option);
        return this.localRecord;
      case ResolutionOption.SKIP:
        this.markResolved(option);
        return this.localRecord;
      case ResolutionOption.USE_HEALTH: {
        const healthRecord = this.getNormalizedHealthRecord();
        if (!healthRecord) {
          return null;
        }
        this.markResolved(option);
        const notes = healthRecord.notes ?? this.localRecord.notes;
        return new WeightRecord(
          healthRecord.weight,
          healthRecord.date,
          this.localRecord.id,
          notes
        );
      }
      case ResolutionOption.MERGE_AVERAGE: {
        const healthRecord = this.getNormalizedHealthRecord();
        if (!healthRecord) {
          return null;
        }
        this.markResolved(option);
        const avgWeight = (this.localRecord.weight + healthRecord.weight) / 2;
        const mergedNotes = this.mergeNotes(this.localRecord.notes, healthRecord.notes);
        return new WeightRecord(
          avgWeight,
          Math.max(this.localRecord.date, healthRecord.date),
          this.localRecord.id,
          mergedNotes
        );
      }
      default:
        this.markResolved(option);
        return this.localRecord;
    }
  }

  private getNormalizedHealthRecord(): WeightRecord | null {
    const record = this.healthRecord;
    if (isWeightRecord(record)) {
      return record;
    }

    if (!isHealthAppRecord(record)) {
      return null;
    }

    const notes = typeof record.notes === 'string' ? record.notes : undefined;
    const resolvedId = typeof record.id === 'number' ? record.id : this.localRecord.id;

    try {
      return new WeightRecord(record.weight, record.date, resolvedId, notes);
    } catch (_error) {
      return null;
    }
  }

  private mergeNotes(localNotes?: string, healthNotes?: string): string | undefined {
    const normalizedLocal = localNotes?.trim() ?? '';
    const normalizedHealth = healthNotes?.trim() ?? '';
    const parts: string[] = [];

    if (normalizedLocal.length > 0) {
      parts.push(normalizedLocal);
    }

    if (normalizedHealth.length > 0 && normalizedHealth !== normalizedLocal) {
      parts.push(normalizedHealth);
    }

    parts.push('[合并]');
    const merged = parts.join(' ').trim();
    return merged.length > 0 ? merged : undefined;
  }

  private markResolved(option: ResolutionOption): void {
    this.resolutionOption = option;
    this.resolvedTime = Date.now();
  }
}
