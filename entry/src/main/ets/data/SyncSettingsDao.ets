/**
 * 健康数据同步设置DAO
 * 管理同步配置的持久化
 */
import relationalStore from '@ohos.data.relationalStore';
import { ResolutionOption } from '../model/HealthSyncConflict';
import { SyncSettings, SyncMode } from '../model/SyncSettings';
import { SYNC_SETTINGS_TABLE } from './RdbHelper';
import hilog from '@ohos.hilog';
import { LogConstants } from '../common/Constants';
import { common } from '@kit.AbilityKit';

const DOMAIN = LogConstants.DOMAIN;
const TAG = LogConstants.TAG_PREFIX + 'SyncSettingsDao';

export class SyncSettingsDao {
  rdbStore: relationalStore.RdbStore;

  constructor(rdbStore: relationalStore.RdbStore) {
    this.rdbStore = rdbStore;
  }

  /**
   * 保存或更新同步设置
   */
  async save(settings: SyncSettings): Promise<number> {
    try {
      // 首先检查是否存在设置
      const existing = await this.queryDefault();

      if (existing) {
        // 更新现有设置
        return await this.update(settings);
      } else {
        // 插入新设置
        return await this.insert(settings);
      }
    } catch (e) {
      hilog.error(DOMAIN, TAG, `Failed to save sync settings, cause: ${e}`);
      return -1;
    }
  }

  /**
   * 插入同步设置
   */
  async insert(settings: SyncSettings): Promise<number> {
    try {
      const valueBucket: relationalStore.ValuesBucket = {
        'sync_enabled': settings.syncEnabled ? 1 : 0,
        'sync_mode': settings.syncMode,
        'auto_sync_interval_minutes': settings.autoSyncFrequency.intervalMinutes,
        'auto_sync_enabled': settings.autoSyncFrequency.enabled ? 1 : 0,
        'last_sync_time': settings.lastSyncTime || 0,
        'sync_on_app_start': settings.syncOnAppStart ? 1 : 0,
        'conflict_resolution': settings.conflictResolution,
        'enable_detailed_logs': settings.enableDetailedLogs ? 1 : 0,
        'max_sync_retries': settings.maxSyncRetries,
        'request_timeout': settings.requestTimeout
      };

      await this.rdbStore.executeSql('BEGIN TRANSACTION');
      let id = await this.rdbStore.insert(SYNC_SETTINGS_TABLE, valueBucket);
      await this.rdbStore.executeSql('COMMIT');
      hilog.info(DOMAIN, TAG, `Successfully inserted sync settings with id: ${id}`);
      return id;
    } catch (e) {
      try {
        await this.rdbStore.executeSql('ROLLBACK');
      } catch (rollbackError) {
        hilog.error(DOMAIN, TAG, `Failed to rollback transaction: ${rollbackError}`);
      }
      hilog.error(DOMAIN, TAG, `Failed to insert sync settings, cause: ${e}`);
      return -1;
    }
  }

  /**
   * 更新同步设置
   */
  async update(settings: SyncSettings): Promise<number> {
    const valueBucket: relationalStore.ValuesBucket = {
      'sync_enabled': settings.syncEnabled ? 1 : 0,
      'sync_mode': settings.syncMode,
      'auto_sync_interval_minutes': settings.autoSyncFrequency.intervalMinutes,
      'auto_sync_enabled': settings.autoSyncFrequency.enabled ? 1 : 0,
      'last_sync_time': settings.lastSyncTime || 0,
      'sync_on_app_start': settings.syncOnAppStart ? 1 : 0,
      'conflict_resolution': settings.conflictResolution,
      'enable_detailed_logs': settings.enableDetailedLogs ? 1 : 0,
      'max_sync_retries': settings.maxSyncRetries,
      'request_timeout': settings.requestTimeout
    };

    let predicates = new relationalStore.RdbPredicates(SYNC_SETTINGS_TABLE);
    predicates.equalTo('id', settings.id);

    try {
      let rows = await this.rdbStore.update(valueBucket, predicates);
      hilog.info(DOMAIN, TAG, `Updated ${rows} sync settings records.`);
      return rows;
    } catch (e) {
      hilog.error(DOMAIN, TAG, `Failed to update sync settings, cause: ${e}`);
      return 0;
    }
  }

  /**
   * 查询默认设置
   */
  async queryDefault(): Promise<SyncSettings | null> {
    let predicates = new relationalStore.RdbPredicates(SYNC_SETTINGS_TABLE);
    predicates.orderByAsc('id');
    predicates.limitAs(1);

    try {
      let resultSet = await this.rdbStore.query(predicates);

      if (resultSet && resultSet.rowCount > 0) {
        resultSet.goToFirstRow();

        let id = resultSet.getLong(resultSet.getColumnIndex('id'));
        let syncEnabled = resultSet.getLong(resultSet.getColumnIndex('sync_enabled')) === 1;
        let syncMode = resultSet.getString(resultSet.getColumnIndex('sync_mode')) as SyncMode;
        let autoSyncIntervalMinutes = resultSet.getLong(resultSet.getColumnIndex('auto_sync_interval_minutes'));
        let autoSyncEnabled = resultSet.getLong(resultSet.getColumnIndex('auto_sync_enabled')) === 1;
        let lastSyncTime = resultSet.getLong(resultSet.getColumnIndex('last_sync_time'));
        let syncOnAppStart = resultSet.getLong(resultSet.getColumnIndex('sync_on_app_start')) === 1;
        const conflictResolutionValue = resultSet.getString(resultSet.getColumnIndex('conflict_resolution')) || '';
        const conflictResolution: ResolutionOption = SyncSettings.normalizeConflictResolution(conflictResolutionValue);
        let enableDetailedLogs = resultSet.getLong(resultSet.getColumnIndex('enable_detailed_logs')) === 1;
        let maxSyncRetries = resultSet.getLong(resultSet.getColumnIndex('max_sync_retries'));
        let requestTimeout = resultSet.getLong(resultSet.getColumnIndex('request_timeout'));

        let settings = new SyncSettings(
          id,
          syncEnabled,
          syncMode,
          syncOnAppStart,
          conflictResolution,
          maxSyncRetries,
          requestTimeout
        );
        settings.autoSyncFrequency.intervalMinutes = autoSyncIntervalMinutes;
        settings.autoSyncFrequency.enabled = autoSyncEnabled;
        settings.lastSyncTime = lastSyncTime > 0 ? lastSyncTime : undefined;
        settings.enableDetailedLogs = enableDetailedLogs;

        if (resultSet) {
          resultSet.close();
        }

        hilog.info(DOMAIN, TAG, 'Queried default sync settings.');
        return settings;
      }

      if (resultSet) {
        resultSet.close();
      }

      return null;
    } catch (e) {
      hilog.error(DOMAIN, TAG, `Failed to query sync settings, cause: ${e}`);
      return null;
    }
  }

  /**
   * 查询所有设置
   */
  async queryAll(): Promise<SyncSettings[]> {
    let predicates = new relationalStore.RdbPredicates(SYNC_SETTINGS_TABLE);

    try {
      let resultSet = await this.rdbStore.query(predicates);
      let settings: SyncSettings[] = [];

      if (resultSet && resultSet.rowCount > 0) {
        while (resultSet.goToNextRow()) {
          let id = resultSet.getLong(resultSet.getColumnIndex('id'));
          let syncEnabled = resultSet.getLong(resultSet.getColumnIndex('sync_enabled')) === 1;
          let syncMode = resultSet.getString(resultSet.getColumnIndex('sync_mode')) as SyncMode;
          let autoSyncIntervalMinutes = resultSet.getLong(resultSet.getColumnIndex('auto_sync_interval_minutes'));
          let autoSyncEnabled = resultSet.getLong(resultSet.getColumnIndex('auto_sync_enabled')) === 1;
          let lastSyncTime = resultSet.getLong(resultSet.getColumnIndex('last_sync_time'));
          let syncOnAppStart = resultSet.getLong(resultSet.getColumnIndex('sync_on_app_start')) === 1;
          const conflictResolutionValue = resultSet.getString(resultSet.getColumnIndex('conflict_resolution')) || '';
          const conflictResolution: ResolutionOption = SyncSettings.normalizeConflictResolution(conflictResolutionValue);
          let enableDetailedLogs = resultSet.getLong(resultSet.getColumnIndex('enable_detailed_logs')) === 1;
          let maxSyncRetries = resultSet.getLong(resultSet.getColumnIndex('max_sync_retries'));
          let requestTimeout = resultSet.getLong(resultSet.getColumnIndex('request_timeout'));

          let setting = new SyncSettings(
            id,
            syncEnabled,
            syncMode,
            syncOnAppStart,
            conflictResolution,
            maxSyncRetries,
            requestTimeout
          );
          setting.autoSyncFrequency.intervalMinutes = autoSyncIntervalMinutes;
          setting.autoSyncFrequency.enabled = autoSyncEnabled;
          setting.lastSyncTime = lastSyncTime > 0 ? lastSyncTime : undefined;
          setting.enableDetailedLogs = enableDetailedLogs;

          settings.push(setting);
        }
      }

      if (resultSet) {
        resultSet.close();
      }

      hilog.info(DOMAIN, TAG, `Queried ${settings.length} sync settings.`);
      return settings;
    } catch (e) {
      hilog.error(DOMAIN, TAG, `Failed to query all sync settings, cause: ${e}`);
      return [];
    }
  }

  /**
   * 初始化默认设置
   */
  async initializeDefaultSettings(): Promise<SyncSettings | null> {
    try {
      const existing = await this.queryDefault();
      if (existing) {
        return existing;
      }

      const defaultSettings = new SyncSettings();
      const id = await this.insert(defaultSettings);

      if (id > 0) {
        defaultSettings.id = id;
        return defaultSettings;
      }

      return null;
    } catch (e) {
      hilog.error(DOMAIN, TAG, `Failed to initialize default settings, cause: ${e}`);
      return null;
    }
  }
}

let syncSettingsDao: SyncSettingsDao | null = null;
export async function getSyncSettingsDao(context: common.Context): Promise<SyncSettingsDao | null> {
  if (syncSettingsDao) {
    return syncSettingsDao;
  }

  try {
    const helperModule = await import('./RdbHelper');
    const rdbStore = await helperModule.rdbHelper.initRdbStore(context);
    if (rdbStore) {
      syncSettingsDao = new SyncSettingsDao(rdbStore);
      return syncSettingsDao;
    }
  } catch (e) {
    hilog.error(DOMAIN, TAG, `Failed to get SyncSettingsDao, cause: ${e}`);
  }

  return null;
}
