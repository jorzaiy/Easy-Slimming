/**
 * 健康数据同步记录DAO
 * 管理与鸿蒙运动健康应用的同步历史
 */
import relationalStore from '@ohos.data.relationalStore';
import { HealthSyncRecord, SyncDirection, SyncStatus } from '../model/HealthSyncRecord';
import { HEALTH_SYNC_RECORD_TABLE } from './RdbHelper';
import hilog from '@ohos.hilog';
import { LogConstants } from '../common/Constants';
import { common } from '@kit.AbilityKit';

const DOMAIN = LogConstants.DOMAIN;
const TAG = LogConstants.TAG_PREFIX + 'HealthSyncRecordDao';

export class HealthSyncRecordDao {
  rdbStore: relationalStore.RdbStore;

  constructor(rdbStore: relationalStore.RdbStore) {
    this.rdbStore = rdbStore;
  }

  /**
   * 插入同步记录
   */
  async insert(record: HealthSyncRecord): Promise<number> {
    try {
      const valueBucket: relationalStore.ValuesBucket = {
        'weight_record_id': record.weightRecordId,
        'sync_direction': record.syncDirection,
        'status': record.status,
        'start_time': record.startTime,
        'end_time': record.endTime || 0,
        'error_message': record.errorMessage || '',
        'health_app_record_id': record.healthAppRecordId || '',
        'data_hash': record.dataHash || ''
      };

      await this.rdbStore.executeSql('BEGIN TRANSACTION');
      let id = await this.rdbStore.insert(HEALTH_SYNC_RECORD_TABLE, valueBucket);
      await this.rdbStore.executeSql('COMMIT');
      hilog.info(DOMAIN, TAG, `Successfully inserted sync record with id: ${id}`);
      return id;
    } catch (e) {
      try {
        await this.rdbStore.executeSql('ROLLBACK');
      } catch (rollbackError) {
        hilog.error(DOMAIN, TAG, `Failed to rollback transaction: ${rollbackError}`);
      }
      hilog.error(DOMAIN, TAG, `Failed to insert sync record, cause: ${e}`);
      return -1;
    }
  }

  /**
   * 更新同步记录
   */
  async update(record: HealthSyncRecord): Promise<number> {
    const valueBucket: relationalStore.ValuesBucket = {
      'status': record.status,
      'end_time': record.endTime || 0,
      'error_message': record.errorMessage || '',
      'health_app_record_id': record.healthAppRecordId || '',
      'data_hash': record.dataHash || ''
    };

    let predicates = new relationalStore.RdbPredicates(HEALTH_SYNC_RECORD_TABLE);
    predicates.equalTo('id', record.id);

    try {
      let rows = await this.rdbStore.update(valueBucket, predicates);
      hilog.info(DOMAIN, TAG, `Updated ${rows} sync records.`);
      return rows;
    } catch (e) {
      hilog.error(DOMAIN, TAG, `Failed to update sync record, cause: ${e}`);
      return 0;
    }
  }

  /**
   * 查询所有同步记录
   */
  async queryAll(): Promise<HealthSyncRecord[]> {
    let predicates = new relationalStore.RdbPredicates(HEALTH_SYNC_RECORD_TABLE);
    predicates.orderByDesc('start_time');

    try {
      let resultSet = await this.rdbStore.query(predicates);
      let records: HealthSyncRecord[] = [];

      if (resultSet && resultSet.rowCount > 0) {
        while (resultSet.goToNextRow()) {
          let id = resultSet.getLong(resultSet.getColumnIndex('id'));
          let weightRecordId = resultSet.getLong(resultSet.getColumnIndex('weight_record_id'));
          let syncDirection = resultSet.getString(resultSet.getColumnIndex('sync_direction')) as SyncDirection;
          let status = resultSet.getString(resultSet.getColumnIndex('status')) as SyncStatus;
          let startTime = resultSet.getLong(resultSet.getColumnIndex('start_time'));
          let endTime = resultSet.getLong(resultSet.getColumnIndex('end_time'));
          let errorMessage = resultSet.getString(resultSet.getColumnIndex('error_message'));
          let healthAppRecordId = resultSet.getString(resultSet.getColumnIndex('health_app_record_id'));
          let dataHash = resultSet.getString(resultSet.getColumnIndex('data_hash'));

          let record = new HealthSyncRecord(
            weightRecordId,
            syncDirection,
            id,
            status,
            startTime,
            healthAppRecordId,
            dataHash
          );
          record.endTime = endTime > 0 ? endTime : undefined;
          record.errorMessage = errorMessage || undefined;

          records.push(record);
        }
      }

      if (resultSet) {
        resultSet.close();
      }

      hilog.info(DOMAIN, TAG, `Queried ${records.length} sync records.`);
      return records;
    } catch (e) {
      hilog.error(DOMAIN, TAG, `Failed to query sync records, cause: ${e}`);
      return [];
    }
  }

  /**
   * 查询特定体重记录的同步历史
   */
  async queryByWeightRecordId(weightRecordId: number): Promise<HealthSyncRecord[]> {
    let predicates = new relationalStore.RdbPredicates(HEALTH_SYNC_RECORD_TABLE);
    predicates.equalTo('weight_record_id', weightRecordId);
    predicates.orderByDesc('start_time');

    try {
      let resultSet = await this.rdbStore.query(predicates);
      let records: HealthSyncRecord[] = [];

      if (resultSet && resultSet.rowCount > 0) {
        while (resultSet.goToNextRow()) {
          let id = resultSet.getLong(resultSet.getColumnIndex('id'));
          let syncDirection = resultSet.getString(resultSet.getColumnIndex('sync_direction')) as SyncDirection;
          let status = resultSet.getString(resultSet.getColumnIndex('status')) as SyncStatus;
          let startTime = resultSet.getLong(resultSet.getColumnIndex('start_time'));
          let endTime = resultSet.getLong(resultSet.getColumnIndex('end_time'));
          let errorMessage = resultSet.getString(resultSet.getColumnIndex('error_message'));
          let healthAppRecordId = resultSet.getString(resultSet.getColumnIndex('health_app_record_id'));
          let dataHash = resultSet.getString(resultSet.getColumnIndex('data_hash'));

          let record = new HealthSyncRecord(
            weightRecordId,
            syncDirection,
            id,
            status,
            startTime,
            healthAppRecordId,
            dataHash
          );
          record.endTime = endTime > 0 ? endTime : undefined;
          record.errorMessage = errorMessage || undefined;

          records.push(record);
        }
      }

      if (resultSet) {
        resultSet.close();
      }

      return records;
    } catch (e) {
      hilog.error(DOMAIN, TAG, `Failed to query sync records by weight record id, cause: ${e}`);
      return [];
    }
  }

  /**
   * 查询失败的同步记录
   */
  async queryFailedRecords(): Promise<HealthSyncRecord[]> {
    let predicates = new relationalStore.RdbPredicates(HEALTH_SYNC_RECORD_TABLE);
    predicates.equalTo('status', SyncStatus.FAILED);
    predicates.orderByDesc('start_time');

    try {
      let resultSet = await this.rdbStore.query(predicates);
      let records: HealthSyncRecord[] = [];

      if (resultSet && resultSet.rowCount > 0) {
        while (resultSet.goToNextRow()) {
          let id = resultSet.getLong(resultSet.getColumnIndex('id'));
          let weightRecordId = resultSet.getLong(resultSet.getColumnIndex('weight_record_id'));
          let syncDirection = resultSet.getString(resultSet.getColumnIndex('sync_direction')) as SyncDirection;
          let status = resultSet.getString(resultSet.getColumnIndex('status')) as SyncStatus;
          let startTime = resultSet.getLong(resultSet.getColumnIndex('start_time'));
          let endTime = resultSet.getLong(resultSet.getColumnIndex('end_time'));
          let errorMessage = resultSet.getString(resultSet.getColumnIndex('error_message'));
          let healthAppRecordId = resultSet.getString(resultSet.getColumnIndex('health_app_record_id'));
          let dataHash = resultSet.getString(resultSet.getColumnIndex('data_hash'));

          let record = new HealthSyncRecord(
            weightRecordId,
            syncDirection,
            id,
            status,
            startTime,
            healthAppRecordId,
            dataHash
          );
          record.endTime = endTime > 0 ? endTime : undefined;
          record.errorMessage = errorMessage || undefined;

          records.push(record);
        }
      }

      if (resultSet) {
        resultSet.close();
      }

      return records;
    } catch (e) {
      hilog.error(DOMAIN, TAG, `Failed to query failed sync records, cause: ${e}`);
      return [];
    }
  }

  /**
   * 删除同步记录
   */
  async delete(id: number): Promise<number> {
    let predicates = new relationalStore.RdbPredicates(HEALTH_SYNC_RECORD_TABLE);
    predicates.equalTo('id', id);

    try {
      let rows = await this.rdbStore.delete(predicates);
      hilog.info(DOMAIN, TAG, `Deleted ${rows} sync records.`);
      return rows;
    } catch (e) {
      hilog.error(DOMAIN, TAG, `Failed to delete sync record, cause: ${e}`);
      return 0;
    }
  }

  /**
   * 清空所有同步记录
   */
  async clear(): Promise<number> {
    let predicates = new relationalStore.RdbPredicates(HEALTH_SYNC_RECORD_TABLE);

    try {
      let rows = await this.rdbStore.delete(predicates);
      hilog.info(DOMAIN, TAG, `Cleared ${rows} sync records.`);
      return rows;
    } catch (e) {
      hilog.error(DOMAIN, TAG, `Failed to clear sync records, cause: ${e}`);
      return 0;
    }
  }
}

let healthSyncRecordDao: HealthSyncRecordDao | null = null;
export async function getHealthSyncRecordDao(context: common.Context): Promise<HealthSyncRecordDao | null> {
  if (healthSyncRecordDao) {
    return healthSyncRecordDao;
  }

  try {
    const { rdbHelper } = await import('./RdbHelper');
    const rdbStore = await rdbHelper.initRdbStore(context);
    if (rdbStore) {
      healthSyncRecordDao = new HealthSyncRecordDao(rdbStore);
      return healthSyncRecordDao;
    }
  } catch (e) {
    hilog.error(DOMAIN, TAG, `Failed to get HealthSyncRecordDao, cause: ${e}`);
  }

  return null;
}
