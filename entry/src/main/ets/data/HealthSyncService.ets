/**
 * 健康数据同步服务
 * 与鸿蒙运动健康应用进行双向数据同步
 */

import { WeightRecord } from '../model/WeightRecord';
import { HealthSyncRecord, SyncDirection, SyncStatus, SyncProgress } from '../model/HealthSyncRecord';
import { SyncSettings, SyncMode } from '../model/SyncSettings';
import { HealthSyncConflict, ConflictType, ResolutionOption } from '../model/HealthSyncConflict';
import { WeightRecordDao } from './WeightRecordDao';
import { HealthSyncRecordDao } from './HealthSyncRecordDao';
import { SyncSettingsDao } from './SyncSettingsDao';
import hilog from '@ohos.hilog';
import { LogConstants } from '../common/Constants';

const DOMAIN = LogConstants.DOMAIN;
const TAG = LogConstants.TAG_PREFIX + 'HealthSyncService';

export interface SyncResult {
  success: boolean;
  syncedCount: number;
  failedCount: number;
  conflictCount: number;
  errors: string[];
  duration: number;
  status: SyncStatus;
  direction: SyncDirection;
  message: string;
}

export class HealthSyncService {
  private weightRecordDao: WeightRecordDao;
  private syncRecordDao: HealthSyncRecordDao;
  private syncSettingsDao: SyncSettingsDao;
  private isSyncing: boolean = false;
  private syncProgress: SyncProgress = { total: 0, completed: 0, failed: 0, percentage: 0 };
  private syncSettings: SyncSettings | null = null;
  private conflicts: Map<number, HealthSyncConflict> = new Map();

  constructor(
    weightRecordDao: WeightRecordDao,
    syncRecordDao: HealthSyncRecordDao,
    syncSettingsDao: SyncSettingsDao
  ) {
    this.weightRecordDao = weightRecordDao;
    this.syncRecordDao = syncRecordDao;
    this.syncSettingsDao = syncSettingsDao;
  }

  /**
   * 初始化服务
   */
  async initialize(): Promise<boolean> {
    try {
      this.syncSettings = await this.syncSettingsDao.queryDefault();
      if (!this.syncSettings) {
        this.syncSettings = await this.syncSettingsDao.initializeDefaultSettings();
      }
      hilog.info(DOMAIN, TAG, 'Health sync service initialized successfully');
      return true;
    } catch (e) {
      hilog.error(DOMAIN, TAG, `Failed to initialize health sync service, cause: ${e}`);
      return false;
    }
  }

  /**
   * 获取同步设置
   */
  getSyncSettings(): SyncSettings | null {
    return this.syncSettings;
  }

  /**
   * 更新同步设置
   */
  async updateSyncSettings(settings: Partial<SyncSettings>): Promise<boolean> {
    try {
      if (!this.syncSettings) {
        return false;
      }

      Object.assign(this.syncSettings, settings);
      await this.syncSettingsDao.update(this.syncSettings);
      hilog.info(DOMAIN, TAG, 'Sync settings updated');
      return true;
    } catch (e) {
      hilog.error(DOMAIN, TAG, `Failed to update sync settings, cause: ${e}`);
      return false;
    }
  }

  /**
   * 获取同步进度
   */
  getSyncProgress(): SyncProgress {
    return this.syncProgress;
  }

  /**
   * 是否正在同步
   */
  getIsSyncing(): boolean {
    return this.isSyncing;
  }

  /**
   * 同步数据到鸿蒙健康应用
   */
  async syncToHealth(weightRecordIds?: number[]): Promise<SyncResult> {
    const startTime = Date.now();
    const result: SyncResult = {
      success: false,
      syncedCount: 0,
      failedCount: 0,
      conflictCount: 0,
      errors: [],
      duration: 0,
      status: SyncStatus.PENDING,
      direction: SyncDirection.TO_HEALTH,
      message: ''
    };

    if (this.isSyncing) {
      result.status = SyncStatus.SYNCING;
      result.message = '同步正在进行中';
      return result;
    }

    this.isSyncing = true;
    this.syncProgress = { total: 0, completed: 0, failed: 0, percentage: 0 };

    try {
      let records: WeightRecord[] = [];
      if (weightRecordIds && weightRecordIds.length > 0) {
        for (const id of weightRecordIds) {
          const record = await this.weightRecordDao.queryById(id);
          if (record) {
            records.push(record);
          }
        }
      } else {
        records = await this.weightRecordDao.queryAll();
      }

      this.syncProgress.total = records.length;

      for (const record of records) {
        const syncRecord = new HealthSyncRecord(
          record.id,
          SyncDirection.TO_HEALTH,
          undefined,
          SyncStatus.SYNCING,
          Date.now()
        );
        let insertedId = -1;

        try {
          insertedId = await this.syncRecordDao.insert(syncRecord);
          if (insertedId > 0) {
            syncRecord.id = insertedId;
          }

          const syncSuccess = await this.performHealthAppSync(record, syncRecord);
          syncRecord.endTime = Date.now();

          if (syncSuccess) {
            syncRecord.status = SyncStatus.SUCCESS;
            result.syncedCount++;
          } else {
            syncRecord.status = SyncStatus.FAILED;
            syncRecord.errorMessage = '同步到鸿蒙健康应用失败';
            result.failedCount++;
            result.errors.push(`Record ${record.id}: ${syncRecord.errorMessage}`);
            this.syncProgress.failed++;
          }
        } catch (error) {
          syncRecord.status = SyncStatus.FAILED;
          syncRecord.endTime = Date.now();
          const errorMessage = `同步到鸿蒙健康应用失败: ${error}`;
          syncRecord.errorMessage = errorMessage;
          result.failedCount++;
          result.errors.push(`Record ${record.id}: ${error}`);
          this.syncProgress.failed++;
          hilog.error(DOMAIN, TAG, errorMessage);
        } finally {
          try {
            if (syncRecord.id > 0) {
              await this.syncRecordDao.update(syncRecord);
            } else if (insertedId <= 0) {
              const fallbackId = await this.syncRecordDao.insert(syncRecord);
              if (fallbackId > 0) {
                syncRecord.id = fallbackId;
              }
            }
          } catch (persistError) {
            hilog.error(DOMAIN, TAG, `Failed to persist sync record, cause: ${persistError}`);
          }

          this.syncProgress.completed++;
          this.syncProgress.percentage = this.syncProgress.total > 0
            ? Math.round((this.syncProgress.completed / this.syncProgress.total) * 100)
            : 0;
        }
      }

      if (this.syncSettings) {
        this.syncSettings.lastSyncTime = Date.now();
        await this.syncSettingsDao.update(this.syncSettings);
      }

      result.success = result.failedCount === 0;
      result.duration = Date.now() - startTime;
      result.status = result.success ? SyncStatus.SUCCESS : SyncStatus.FAILED;
      result.message = `同步完成: ${result.syncedCount}条成功, ${result.failedCount}条失败`;
      hilog.info(DOMAIN, TAG, `Sync to health completed: ${result.message}`);
    } catch (e) {
      result.errors.push(`Sync failed: ${e}`);
      result.message = `同步失败: ${e}`;
      result.status = SyncStatus.FAILED;
      result.duration = Date.now() - startTime;
      hilog.error(DOMAIN, TAG, `Failed to sync to health, cause: ${e}`);
    } finally {
      this.isSyncing = false;
      if (result.duration === 0) {
        result.duration = Date.now() - startTime;
      }
    }

    return result;
  }

  /**
   * 从鸿蒙健康应用导入数据
   */
  async syncFromHealth(): Promise<SyncResult> {
    const startTime = Date.now();
    const result: SyncResult = {
      success: false,
      syncedCount: 0,
      failedCount: 0,
      conflictCount: 0,
      errors: [],
      duration: 0,
      status: SyncStatus.PENDING,
      direction: SyncDirection.FROM_HEALTH,
      message: ''
    };

    if (this.isSyncing) {
      result.status = SyncStatus.SYNCING;
      result.message = '同步正在进行中';
      return result;
    }

    this.isSyncing = true;
    this.syncProgress = { total: 0, completed: 0, failed: 0, percentage: 0 };

    try {
      const healthRecords = await this.fetchFromHealthApp();
      this.syncProgress.total = healthRecords.length;

      for (const healthRecord of healthRecords) {
        try {
          const localRecord = await this.findDuplicateRecord(healthRecord);

          if (localRecord) {
            const conflict = this.detectConflict(localRecord, healthRecord);
            if (conflict) {
              this.conflicts.set(localRecord.id, conflict);
              result.conflictCount++;

              const conflictRecord = new HealthSyncRecord(
                localRecord.id,
                SyncDirection.FROM_HEALTH,
                undefined,
                SyncStatus.CONFLICT,
                Date.now()
              );
              conflictRecord.endTime = Date.now();
              conflictRecord.errorMessage = conflict.description;
              await this.syncRecordDao.insert(conflictRecord);
              hilog.info(DOMAIN, TAG, `Conflict detected for record ${localRecord.id}`);
            } else {
              healthRecord.id = localRecord.id;
              await this.weightRecordDao.update(healthRecord);
              const successRecord = new HealthSyncRecord(
                localRecord.id,
                SyncDirection.FROM_HEALTH,
                undefined,
                SyncStatus.SUCCESS,
                Date.now()
              );
              successRecord.endTime = Date.now();
              await this.syncRecordDao.insert(successRecord);
              result.syncedCount++;
            }
          } else {
            const insertId = await this.weightRecordDao.insert(healthRecord);
            if (insertId > 0) {
              const syncRecord = new HealthSyncRecord(
                insertId,
                SyncDirection.FROM_HEALTH,
                undefined,
                SyncStatus.SUCCESS,
                Date.now()
              );
              syncRecord.endTime = Date.now();
              await this.syncRecordDao.insert(syncRecord);
              result.syncedCount++;
            } else {
              result.failedCount++;
              result.errors.push('Failed to insert record from health app');
              this.syncProgress.failed++;
            }
          }
        } catch (error) {
          result.failedCount++;
          result.errors.push(`Record processing failed: ${error}`);
          this.syncProgress.failed++;
          hilog.error(DOMAIN, TAG, `Sync from health processing failed, cause: ${error}`);
        }

        this.syncProgress.completed++;
        this.syncProgress.percentage = this.syncProgress.total > 0
          ? Math.round((this.syncProgress.completed / this.syncProgress.total) * 100)
          : 0;
      }

      if (this.syncSettings) {
        this.syncSettings.lastSyncTime = Date.now();
        await this.syncSettingsDao.update(this.syncSettings);
      }

      result.success = result.failedCount === 0;
      result.duration = Date.now() - startTime;
      if (result.conflictCount > 0) {
        result.status = SyncStatus.CONFLICT;
      } else {
        result.status = result.success ? SyncStatus.SUCCESS : SyncStatus.FAILED;
      }
      result.message = `导入完成: ${result.syncedCount}条成功, ${result.failedCount}条失败, ${result.conflictCount}条冲突`;
      hilog.info(DOMAIN, TAG, `Sync from health completed: ${result.message}`);
    } catch (e) {
      result.errors.push(`Sync failed: ${e}`);
      result.message = `导入失败: ${e}`;
      result.status = SyncStatus.FAILED;
      result.duration = Date.now() - startTime;
      hilog.error(DOMAIN, TAG, `Failed to sync from health, cause: ${e}`);
    } finally {
      this.isSyncing = false;
      if (result.duration === 0) {
        result.duration = Date.now() - startTime;
      }
    }

    return result;
  }

  /**
   * 双向同步
   */
  async bidirectionalSync(): Promise<SyncResult> {
    const startTime = Date.now();
    try {
      const syncToResult = await this.syncToHealth();
      const syncFromResult = await this.syncFromHealth();

      const success = syncToResult.success && syncFromResult.success;
      const totalConflicts = syncToResult.conflictCount + syncFromResult.conflictCount;
      const totalFailed = syncToResult.failedCount + syncFromResult.failedCount;
      const mergedErrors = [...syncToResult.errors, ...syncFromResult.errors];
      const mergedDuration = syncToResult.duration + syncFromResult.duration;

      const result: SyncResult = {
        success,
        syncedCount: syncToResult.syncedCount + syncFromResult.syncedCount,
        failedCount: totalFailed,
        conflictCount: totalConflicts,
        errors: mergedErrors,
        duration: mergedDuration,
        status: SyncStatus.PENDING,
        direction: SyncDirection.BIDIRECTIONAL,
        message: ''
      };

      if (totalFailed > 0) {
        result.status = SyncStatus.FAILED;
      } else if (totalConflicts > 0) {
        result.status = SyncStatus.CONFLICT;
      } else if (success) {
        result.status = SyncStatus.SUCCESS;
      } else {
        result.status = SyncStatus.FAILED;
      }

      result.message = success
        ? `双向同步完成: ${syncToResult.message}; ${syncFromResult.message}`
        : `双向同步完成但存在问题: ${syncToResult.message}; ${syncFromResult.message}`;

      try {
        const summaryRecord = new HealthSyncRecord(
          0,
          SyncDirection.BIDIRECTIONAL,
          undefined,
          result.status,
          startTime
        );
        summaryRecord.endTime = startTime + result.duration;
        if (result.status === SyncStatus.FAILED && result.errors.length > 0) {
          summaryRecord.errorMessage = result.errors.join('; ');
        } else if (result.status === SyncStatus.CONFLICT) {
          summaryRecord.errorMessage = '同步过程中存在冲突，需手动处理';
        }
        await this.syncRecordDao.insert(summaryRecord);
      } catch (persistError) {
        hilog.error(DOMAIN, TAG, `Failed to persist bidirectional sync summary, cause: ${persistError}`);
      }

      return result;
    } catch (e) {
      const errorResult: SyncResult = {
        success: false,
        syncedCount: 0,
        failedCount: 0,
        conflictCount: 0,
        errors: [`Bidirectional sync failed: ${e}`],
        duration: Date.now() - startTime,
        status: SyncStatus.FAILED,
        direction: SyncDirection.BIDIRECTIONAL,
        message: `双向同步失败: ${e}`
      };

      try {
        const summaryRecord = new HealthSyncRecord(
          0,
          SyncDirection.BIDIRECTIONAL,
          undefined,
          SyncStatus.FAILED,
          startTime
        );
        summaryRecord.endTime = Date.now();
        summaryRecord.errorMessage = `双向同步失败: ${e}`;
        await this.syncRecordDao.insert(summaryRecord);
      } catch (persistError) {
        hilog.error(DOMAIN, TAG, `Failed to record bidirectional sync failure, cause: ${persistError}`);
      }

      return errorResult;
    }
  }

  /**
   * 解决同步冲突
   */
  async resolveConflict(conflictId: number, option: ResolutionOption): Promise<boolean> {
    try {
      const conflict = this.conflicts.get(conflictId);
      if (!conflict) {
        return false;
      }

      const resolvedRecord = conflict.resolve(option);

      if (!resolvedRecord) {
        if (option === ResolutionOption.SKIP) {
          this.conflicts.delete(conflictId);
          hilog.info(DOMAIN, TAG, `Conflict ${conflictId} skipped.`);
          return true;
        }
        hilog.warn(DOMAIN, TAG, `Conflict ${conflictId} could not produce a resolved record for option ${option}`);
        return false;
      }

      await this.weightRecordDao.update(resolvedRecord);
      this.conflicts.delete(conflictId);
      hilog.info(DOMAIN, TAG, `Conflict ${conflictId} resolved with option ${option}`);
      return true;
    } catch (e) {
      hilog.error(DOMAIN, TAG, `Failed to resolve conflict, cause: ${e}`);
      return false;
    }
  }

  /**
   * 获取所有冲突
   */
  getConflicts(): Map<number, HealthSyncConflict> {
    return this.conflicts;
  }

  /**
   * 清空冲突
   */
  clearConflicts(): void {
    this.conflicts.clear();
  }

  /**
   * 执行与健康应用的同步
   */
  private async performHealthAppSync(record: WeightRecord, syncRecord: HealthSyncRecord): Promise<boolean> {
    try {
      // 这里应该调用真实的鸿蒙健康API
      // 目前使用模拟实现
      hilog.info(DOMAIN, TAG, `Performing sync for record ${record.id}`);

      // 计算数据哈希值用于冲突检测
      syncRecord.dataHash = this.calculateDataHash(record);

      // 模拟API调用延迟
      await new Promise(resolve => setTimeout(resolve, 100));

      return true;
    } catch (e) {
      hilog.error(DOMAIN, TAG, `Health app sync failed, cause: ${e}`);
      return false;
    }
  }

  /**
   * 从健康应用获取数据
   */
  private async fetchFromHealthApp(): Promise<WeightRecord[]> {
    try {
      // 这里应该调用真实的鸿蒙健康API
      // 目前返回空数组
      hilog.info(DOMAIN, TAG, 'Fetching data from health app');

      // 模拟API调用
      await new Promise(resolve => setTimeout(resolve, 500));

      return [];
    } catch (e) {
      hilog.error(DOMAIN, TAG, `Failed to fetch from health app, cause: ${e}`);
      return [];
    }
  }

  /**
   * 查找重复记录
   */
  private async findDuplicateRecord(healthRecord: WeightRecord): Promise<WeightRecord | null> {
    try {
      const allRecords = await this.weightRecordDao.queryAll();

      for (const localRecord of allRecords) {
        // 检查是否为同一天的记录
        const localDate = new Date(localRecord.date);
        const healthDate = new Date(healthRecord.date);

        if (
          localDate.getFullYear() === healthDate.getFullYear() &&
          localDate.getMonth() === healthDate.getMonth() &&
          localDate.getDate() === healthDate.getDate()
        ) {
          return localRecord;
        }
      }

      return null;
    } catch (e) {
      hilog.error(DOMAIN, TAG, `Failed to find duplicate record, cause: ${e}`);
      return null;
    }
  }

  /**
   * 检测冲突
   */
  private detectConflict(localRecord: WeightRecord, healthRecord: WeightRecord): HealthSyncConflict | null {
    // 检查权重是否不同
    if (Math.abs(localRecord.weight - healthRecord.weight) > 0.1) {
      const description = `本地: ${localRecord.weight}kg, 鸿蒙: ${healthRecord.weight}kg`;
      return new HealthSyncConflict(
        ConflictType.DATA_INCONSISTENCY,
        localRecord,
        healthRecord,
        description,
        localRecord.id
      );
    }

    return null;
  }

  /**
   * 计算数据哈希值
   */
  private calculateDataHash(record: WeightRecord): string {
    const dataStr = `${record.weight}${record.date}${record.notes || ''}`;
    return this.simpleHash(dataStr);
  }

  /**
   * 简单哈希函数
   */
  private simpleHash(str: string): string {
    let hash = 0;
    for (let i = 0; i < str.length; i++) {
      const char = str.charCodeAt(i);
      hash = ((hash << 5) - hash) + char;
      hash = hash & hash;
    }
    return Math.abs(hash).toString(16);
  }
}

let healthSyncService: HealthSyncService | null = null;

export async function getHealthSyncService(
  weightRecordDao: WeightRecordDao,
  syncRecordDao: HealthSyncRecordDao,
  syncSettingsDao: SyncSettingsDao
): Promise<HealthSyncService> {
  if (!healthSyncService) {
    healthSyncService = new HealthSyncService(
      weightRecordDao,
      syncRecordDao,
      syncSettingsDao
    );
    await healthSyncService.initialize();
  }
  return healthSyncService;
}
