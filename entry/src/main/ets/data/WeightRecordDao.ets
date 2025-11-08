import relationalStore from '@ohos.data.relationalStore';
import { WeightRecord, ValidationResult } from '../model/WeightRecord';
import { rdbHelper, TABLE_NAME } from './RdbHelper';
import hilog from '@ohos.hilog';
import { LogConstants } from '../common/Constants';
import { Context } from '@ohos.app.ability.common';

const DOMAIN = LogConstants.DOMAIN;
const TAG = LogConstants.TAG_PREFIX + 'WeightRecordDao';

class WeightRecordDao {
  private rdbStore: relationalStore.RdbStore;

  constructor(rdbStore: relationalStore.RdbStore) {
    this.rdbStore = rdbStore;
  }

  /**
   * 插入数据
   * @param record 要插入的体重记录
   * @returns 插入记录的ID，失败返回-1
   */
  async insert(record: WeightRecord): Promise<number> {
    try {
      // 验证记录数据
      const validation = record.validate();
      if (!validation.isValid) {
        hilog.error(DOMAIN, TAG, `Invalid record data: ${validation.errors.join(', ')}`);
        return -1;
      }

      const valueBucket: relationalStore.ValuesBucket = {
        'weight': record.weight,
        'date': record.date,
        'notes': record.notes || ''
      };
      
      await this.rdbStore.executeSql('BEGIN TRANSACTION');
      let id = await this.rdbStore.insert(TABLE_NAME, valueBucket);
      await this.rdbStore.executeSql('COMMIT');
      hilog.info(DOMAIN, TAG, `Successfully inserted record with id: ${id}`);
      return id;
    } catch (e) {
      try {
        await this.rdbStore.executeSql('ROLLBACK');
      } catch (rollbackError) {
        hilog.error(DOMAIN, TAG, `Failed to rollback transaction: ${rollbackError}`);
      }
      hilog.error(DOMAIN, TAG, `Failed to insert record, cause: ${e}`);
      return -1;
    }
  }

  // 查询所有数据
  async queryAll(): Promise<WeightRecord[]> {
    let predicates = new relationalStore.RdbPredicates(TABLE_NAME);
    predicates.orderByDesc('date');
    try {
      let resultSet = await this.rdbStore.query(predicates);
      let records: WeightRecord[] = [];
      if (resultSet && resultSet.rowCount > 0) {
        while (resultSet.goToNextRow()) {
          let id = resultSet.getLong(resultSet.getColumnIndex('id'));
          let weight = resultSet.getDouble(resultSet.getColumnIndex('weight'));
          let date = resultSet.getLong(resultSet.getColumnIndex('date'));
          let notes = resultSet.getString(resultSet.getColumnIndex('notes'));
          records.push(new WeightRecord(weight, date, id, notes));
        }
      }
      if (resultSet) {
        resultSet.close();
      }
      hilog.info(DOMAIN, TAG, `Queried ${records.length} records.`);
      return records;
    } catch (e) {
      hilog.error(DOMAIN, TAG, `Failed to query records, cause: ${e}`);
      return [];
    }
  }

  // 更新数据
  async update(record: WeightRecord): Promise<number> {
    const valueBucket: relationalStore.ValuesBucket = {
      'weight': record.weight,
      'date': record.date,
      'notes': record.notes || ''
    };
    let predicates = new relationalStore.RdbPredicates(TABLE_NAME);
    predicates.equalTo('id', record.id);
    try {
      let rows = await this.rdbStore.update(valueBucket, predicates);
      hilog.info(DOMAIN, TAG, `Updated ${rows} records.`);
      return rows;
    } catch (e) {
      hilog.error(DOMAIN, TAG, `Failed to update record, cause: ${e}`);
      return 0;
    }
  }

  // 删除数据
  async deleteById(id: number): Promise<number> {
    let predicates = new relationalStore.RdbPredicates(TABLE_NAME);
    predicates.equalTo('id', id);
    try {
      let rows = await this.rdbStore.delete(predicates);
      hilog.info(DOMAIN, TAG, `Deleted ${rows} records.`);
      return rows;
    } catch (e) {
      hilog.error(DOMAIN, TAG, `Failed to delete record, cause: ${e}`);
      return 0;
    }
  }

  // 根据ID查询单条记录
  async queryById(id: number): Promise<WeightRecord | null> {
    let predicates = new relationalStore.RdbPredicates(TABLE_NAME);
    predicates.equalTo('id', id);
    try {
      let resultSet = await this.rdbStore.query(predicates);
      let record: WeightRecord | null = null;
      if (resultSet && resultSet.rowCount > 0) {
        if (resultSet.goToFirstRow()) {
          let recordId = resultSet.getLong(resultSet.getColumnIndex('id'));
          let weight = resultSet.getDouble(resultSet.getColumnIndex('weight'));
          let date = resultSet.getLong(resultSet.getColumnIndex('date'));
          let notes = resultSet.getString(resultSet.getColumnIndex('notes'));
          record = new WeightRecord(weight, date, recordId, notes);
        }
      }
      if (resultSet) {
        resultSet.close();
      }
      hilog.info(DOMAIN, TAG, `Queried record with id: ${id}, found: ${record ? 'yes' : 'no'}`);
      return record;
    } catch (e) {
      hilog.error(DOMAIN, TAG, `Failed to query record by id, cause: ${e}`);
      return null;
    }
  }

  // 根据日期范围查询记录
  async queryByDateRange(startDate: number, endDate: number): Promise<WeightRecord[]> {
    let predicates = new relationalStore.RdbPredicates(TABLE_NAME);
    predicates.between('date', startDate, endDate);
    predicates.orderByAsc('date');
    try {
      let resultSet = await this.rdbStore.query(predicates);
      let records: WeightRecord[] = [];
      if (resultSet && resultSet.rowCount > 0) {
        while (resultSet.goToNextRow()) {
          let id = resultSet.getLong(resultSet.getColumnIndex('id'));
          let weight = resultSet.getDouble(resultSet.getColumnIndex('weight'));
          let date = resultSet.getLong(resultSet.getColumnIndex('date'));
          let notes = resultSet.getString(resultSet.getColumnIndex('notes'));
          records.push(new WeightRecord(weight, date, id, notes));
        }
      }
      if (resultSet) {
        resultSet.close();
      }
      hilog.info(DOMAIN, TAG, `Queried ${records.length} records for date range.`);
      return records;
    } catch (e) {
      hilog.error(DOMAIN, TAG, `Failed to query records by date range, cause: ${e}`);
      return [];
    }
  }

  // 获取最近的N条记录
  async queryRecentRecords(limit: number): Promise<WeightRecord[]> {
    let predicates = new relationalStore.RdbPredicates(TABLE_NAME);
    predicates.orderByDesc('date');
    predicates.limitAs(limit);
    try {
      let resultSet = await this.rdbStore.query(predicates);
      let records: WeightRecord[] = [];
      if (resultSet && resultSet.rowCount > 0) {
        while (resultSet.goToNextRow()) {
          let id = resultSet.getLong(resultSet.getColumnIndex('id'));
          let weight = resultSet.getDouble(resultSet.getColumnIndex('weight'));
          let date = resultSet.getLong(resultSet.getColumnIndex('date'));
          let notes = resultSet.getString(resultSet.getColumnIndex('notes'));
          records.push(new WeightRecord(weight, date, id, notes));
        }
      }
      if (resultSet) {
        resultSet.close();
      }
      hilog.info(DOMAIN, TAG, `Queried ${records.length} recent records.`);
      return records.reverse(); // 返回按时间正序排列的记录
    } catch (e) {
      hilog.error(DOMAIN, TAG, `Failed to query recent records, cause: ${e}`);
      return [];
    }
  }
}

let weightRecordDao: WeightRecordDao | null = null;

export async function getWeightRecordDao(context: Context): Promise<WeightRecordDao> {
  if (weightRecordDao) {
    return weightRecordDao;
  }
  let rdbStore = await rdbHelper.initRdbStore(context);
  if (rdbStore) {
    weightRecordDao = new WeightRecordDao(rdbStore);
    return weightRecordDao;
  }
  return null;
}