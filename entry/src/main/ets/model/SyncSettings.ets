/**
 * 健康数据同步设置模型
 * 管理与鸿蒙运动健康应用的同步配置
 */

import { ResolutionOption } from './HealthSyncConflict';

export enum SyncMode {
  MANUAL = 'MANUAL',           // 手动同步
  AUTO = 'AUTO',               // 自动同步
  AUTO_BACKGROUND = 'AUTO_BACKGROUND' // 后台自动同步
}

export interface SyncFrequency {
  intervalMinutes: number;     // 同步间隔（分钟）
  enabled: boolean;            // 是否启用定时同步
}

export class SyncSettings {
  id: number;
  syncEnabled: boolean;        // 是否启用同步功能
  syncMode: SyncMode;          // 同步模式
  autoSyncFrequency: SyncFrequency; // 自动同步频率
  lastSyncTime?: number;       // 最后同步时间
  syncOnAppStart: boolean;     // 应用启动时同步
  conflictResolution: ResolutionOption; // 冲突解决策略
  enableDetailedLogs: boolean; // 是否启用详细日志
  maxSyncRetries: number;      // 最大重试次数
  requestTimeout: number;      // 请求超时时间（毫秒）

  constructor(
    id?: number,
    syncEnabled: boolean = false,
    syncMode: SyncMode = SyncMode.MANUAL,
    syncOnAppStart: boolean = false,
    conflictResolution: ResolutionOption = ResolutionOption.USE_LOCAL,
    maxSyncRetries: number = 3,
    requestTimeout: number = 30000
  ) {
    this.id = id ?? -1;
    this.syncEnabled = syncEnabled;
    this.syncMode = syncMode;
    this.autoSyncFrequency = {
      intervalMinutes: 60,
      enabled: syncMode !== SyncMode.MANUAL
    };
    this.syncOnAppStart = syncOnAppStart;
    this.conflictResolution = conflictResolution;
    this.enableDetailedLogs = false;
    this.maxSyncRetries = maxSyncRetries;
    this.requestTimeout = requestTimeout;
  }

  updateAutoSyncFrequency(intervalMinutes: number): void {
    if (intervalMinutes > 0) {
      this.autoSyncFrequency.intervalMinutes = intervalMinutes;
    }
  }

  getLastSyncTimeFormatted(): string {
    if (!this.lastSyncTime) {
      return '从未同步';
    }
    const date = new Date(this.lastSyncTime);
    const year = date.getFullYear();
    const month = (date.getMonth() + 1).toString().padStart(2, '0');
    const day = date.getDate().toString().padStart(2, '0');
    const hour = date.getHours().toString().padStart(2, '0');
    const minute = date.getMinutes().toString().padStart(2, '0');
    return `${year}/${month}/${day} ${hour}:${minute}`;
  }

  getTimeSinceLastSync(): number {
    if (!this.lastSyncTime) {
      return -1;
    }
    return Date.now() - this.lastSyncTime;
  }

  static normalizeConflictResolution(value: string): ResolutionOption {
    switch (value) {
      case ResolutionOption.USE_LOCAL:
      case 'LOCAL':
        return ResolutionOption.USE_LOCAL;
      case ResolutionOption.USE_HEALTH:
      case 'HEALTH':
        return ResolutionOption.USE_HEALTH;
      case ResolutionOption.MERGE_AVERAGE:
      case 'MERGE':
        return ResolutionOption.MERGE_AVERAGE;
      case ResolutionOption.SKIP:
      case 'SKIP':
        return ResolutionOption.SKIP;
      default:
        return ResolutionOption.USE_LOCAL;
    }
  }
}
