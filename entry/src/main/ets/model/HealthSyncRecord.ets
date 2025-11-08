/**
 * 健康数据同步记录模型
 * 记录与鸿蒙运动健康应用的同步历史
 */

export enum SyncDirection {
  TO_HEALTH = 'TO_HEALTH',       // 同步到鸿蒙健康应用
  FROM_HEALTH = 'FROM_HEALTH'    // 从鸿蒙健康应用导入
}

export enum SyncStatus {
  PENDING = 'PENDING',           // 待同步
  IN_PROGRESS = 'IN_PROGRESS',   // 同步中
  SUCCESS = 'SUCCESS',           // 成功
  FAILED = 'FAILED'              // 失败
}

export interface SyncProgress {
  total: number;                 // 总数
  completed: number;             // 已完成数
  failed: number;                // 失败数
  percentage: number;            // 完成百分比
}

export class HealthSyncRecord {
  id: number;
  weightRecordId: number;        // 体重记录ID
  syncDirection: SyncDirection;  // 同步方向
  status: SyncStatus;            // 同步状态
  startTime: number;             // 开始时间
  endTime?: number;              // 结束时间
  errorMessage?: string;         // 错误信息
  healthAppRecordId?: string;    // 鸿蒙健康应用中的记录ID
  dataHash?: string;             // 数据哈希值

  constructor(
    weightRecordId: number,
    syncDirection: SyncDirection,
    id?: number,
    status: SyncStatus = SyncStatus.PENDING,
    startTime?: number,
    healthAppRecordId?: string,
    dataHash?: string
  ) {
    this.id = id ?? -1;
    this.weightRecordId = weightRecordId;
    this.syncDirection = syncDirection;
    this.status = status;
    this.startTime = startTime ?? Date.now();
    this.healthAppRecordId = healthAppRecordId;
    this.dataHash = dataHash;
  }

  isCompleted(): boolean {
    return this.status === SyncStatus.SUCCESS || this.status === SyncStatus.FAILED;
  }

  isSuccess(): boolean {
    return this.status === SyncStatus.SUCCESS;
  }

  isFailed(): boolean {
    return this.status === SyncStatus.FAILED;
  }

  getDuration(): number {
    if (!this.endTime) {
      return 0;
    }
    return this.endTime - this.startTime;
  }

  getStatusText(): string {
    switch (this.status) {
      case SyncStatus.PENDING:
        return '待同步';
      case SyncStatus.IN_PROGRESS:
        return '同步中';
      case SyncStatus.SUCCESS:
        return '成功';
      case SyncStatus.FAILED:
        return '失败';
      default:
        return '未知';
    }
  }

  getDirectionText(): string {
    switch (this.syncDirection) {
      case SyncDirection.TO_HEALTH:
        return '同步到健康应用';
      case SyncDirection.FROM_HEALTH:
        return '从健康应用导入';
      default:
        return '未知方向';
    }
  }
}
