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

export class HealthSyncConflict {
  id: number;
  conflictType: ConflictType;
  localRecord: WeightRecord;       // 本地记录
  healthRecord: WeightRecord;         // 鸿蒙健康记录（可能包含额外字段）
  createdTime: number;             // 冲突检测时间
  resolvedTime?: number;           // 冲突解决时间
  resolutionOption?: ResolutionOption; // 选择的解决方案
  description: string;             // 冲突描述

  constructor(
    conflictType: ConflictType,
    localRecord: WeightRecord,
    healthRecord: WeightRecord,
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

  resolve(option: ResolutionOption): WeightRecord {
    this.resolutionOption = option;
    this.resolvedTime = Date.now();

    switch (option) {
      case ResolutionOption.USE_LOCAL:
        return this.localRecord;
      case ResolutionOption.USE_HEALTH:
        return new WeightRecord(
          this.healthRecord.weight,
          this.healthRecord.date,
          this.localRecord.id,
          this.healthRecord.notes || this.localRecord.notes
        );
      case ResolutionOption.MERGE_AVERAGE:
        const avgWeight = (this.localRecord.weight + this.healthRecord.weight) / 2;
        return new WeightRecord(
          avgWeight,
          Math.max(this.localRecord.date, this.healthRecord.date),
          this.localRecord.id,
          `${this.localRecord.notes || ''} [合并]`
        );
      case ResolutionOption.SKIP:
      default:
        return this.localRecord;
    }
  }
}
