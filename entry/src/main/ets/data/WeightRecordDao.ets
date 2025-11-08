import relationalStore from '@ohos.data.relationalStore';
import { WeightRecord, ValidationResult } from '../model/WeightRecord';
import { Remark, RemarkType } from '../model/Remark';
import { rdbHelper, TABLE_NAME, REMARKS_TABLE_NAME } from './RdbHelper';
import hilog from '@ohos.hilog';
import { LogConstants } from '../common/Constants';
import { common } from '@kit.AbilityKit';

const DOMAIN = LogConstants.DOMAIN;
const TAG = LogConstants.TAG_PREFIX + 'WeightRecordDao';

export class WeightRecordDao {
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
    try {
      await this.rdbStore.executeSql('BEGIN TRANSACTION');
      
      // 先删除关联的备注
      let remarkPredicates = new relationalStore.RdbPredicates(REMARKS_TABLE_NAME);
      remarkPredicates.equalTo('record_id', id);
      await this.rdbStore.delete(remarkPredicates);
      
      // 再删除体重记录
      let predicates = new relationalStore.RdbPredicates(TABLE_NAME);
      predicates.equalTo('id', id);
      let rows = await this.rdbStore.delete(predicates);
      
      await this.rdbStore.executeSql('COMMIT');
      hilog.info(DOMAIN, TAG, `Deleted ${rows} records and associated remarks.`);
      return rows;
    } catch (e) {
      try {
        await this.rdbStore.executeSql('ROLLBACK');
      } catch (rollbackError) {
        hilog.error(DOMAIN, TAG, `Failed to rollback transaction: ${rollbackError}`);
      }
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

  // ===== 备注相关方法 =====

  /**
   * 为体重记录添加备注
   * @param recordId 体重记录ID
   * @param type 备注类型
   * @param content 备注内容
   * @returns 备注ID，失败返回-1
   */
  async addRemark(recordId: number, type: RemarkType, content: string): Promise<number> {
    try {
      const remark = new Remark(recordId, type, content);
      const valueBucket: relationalStore.ValuesBucket = {
        'record_id': recordId,
        'type': type,
        'content': content,
        'timestamp': remark.timestamp
      };
      
      await this.rdbStore.executeSql('BEGIN TRANSACTION');
      let id = await this.rdbStore.insert(REMARKS_TABLE_NAME, valueBucket);
      await this.rdbStore.executeSql('COMMIT');
      hilog.info(DOMAIN, TAG, `Successfully added remark with id: ${id} for record: ${recordId}`);
      return id;
    } catch (e) {
      try {
        await this.rdbStore.executeSql('ROLLBACK');
      } catch (rollbackError) {
        hilog.error(DOMAIN, TAG, `Failed to rollback transaction: ${rollbackError}`);
      }
      hilog.error(DOMAIN, TAG, `Failed to add remark, cause: ${e}`);
      return -1;
    }
  }

  /**
   * 查询某条记录的所有备注
   * @param recordId 体重记录ID
   * @returns 备注列表
   */
  async queryRemarksByRecordId(recordId: number): Promise<Remark[]> {
    let predicates = new relationalStore.RdbPredicates(REMARKS_TABLE_NAME);
    predicates.equalTo('record_id', recordId);
    predicates.orderByDesc('timestamp');
    try {
      let resultSet = await this.rdbStore.query(predicates);
      let remarks: Remark[] = [];
      if (resultSet && resultSet.rowCount > 0) {
        while (resultSet.goToNextRow()) {
          let id = resultSet.getLong(resultSet.getColumnIndex('id'));
          let rid = resultSet.getLong(resultSet.getColumnIndex('record_id'));
          let type = resultSet.getString(resultSet.getColumnIndex('type')) as RemarkType;
          let content = resultSet.getString(resultSet.getColumnIndex('content'));
          let timestamp = resultSet.getLong(resultSet.getColumnIndex('timestamp'));
          remarks.push(new Remark(rid, type, content, timestamp, id));
        }
      }
      if (resultSet) {
        resultSet.close();
      }
      hilog.info(DOMAIN, TAG, `Queried ${remarks.length} remarks for record id: ${recordId}.`);
      return remarks;
    } catch (e) {
      hilog.error(DOMAIN, TAG, `Failed to query remarks by record id, cause: ${e}`);
      return [];
    }
  }

  /**
   * 更新备注
   * @param remarkId 备注ID
   * @param type 新的备注类型
   * @param content 新的备注内容
   * @returns 更新的行数
   */
  async updateRemark(remarkId: number, type: RemarkType, content: string): Promise<number> {
    try {
      const timestamp = Date.now();
      const valueBucket: relationalStore.ValuesBucket = {
        'type': type,
        'content': content,
        'timestamp': timestamp
      };
      let predicates = new relationalStore.RdbPredicates(REMARKS_TABLE_NAME);
      predicates.equalTo('id', remarkId);
      
      let rows = await this.rdbStore.update(valueBucket, predicates);
      hilog.info(DOMAIN, TAG, `Updated ${rows} remark(s) with id: ${remarkId}.`);
      return rows;
    } catch (e) {
      hilog.error(DOMAIN, TAG, `Failed to update remark, cause: ${e}`);
      return 0;
    }
  }

  /**
   * 删除备注
   * @param remarkId 备注ID
   * @returns 删除的行数
   */
  async deleteRemark(remarkId: number): Promise<number> {
    let predicates = new relationalStore.RdbPredicates(REMARKS_TABLE_NAME);
    predicates.equalTo('id', remarkId);
    try {
      let rows = await this.rdbStore.delete(predicates);
      hilog.info(DOMAIN, TAG, `Deleted ${rows} remark(s) with id: ${remarkId}.`);
      return rows;
    } catch (e) {
      hilog.error(DOMAIN, TAG, `Failed to delete remark, cause: ${e}`);
      return 0;
    }
  }

  /**
   * 删除某条体重记录的所有备注
   * @param recordId 体重记录ID
   * @returns 删除的行数
   */
  async deleteRemarksByRecordId(recordId: number): Promise<number> {
    let predicates = new relationalStore.RdbPredicates(REMARKS_TABLE_NAME);
    predicates.equalTo('record_id', recordId);
    try {
      let rows = await this.rdbStore.delete(predicates);
      hilog.info(DOMAIN, TAG, `Deleted ${rows} remark(s) for record id: ${recordId}.`);
      return rows;
    } catch (e) {
      hilog.error(DOMAIN, TAG, `Failed to delete remarks by record id, cause: ${e}`);
      return 0;
    }
  }

  /**
   * 按备注类型筛选体重记录
   * @param type 备注类型
   * @returns 包含指定类型备注的体重记录ID列表
   */
  async queryRecordIdsByRemarkType(type: RemarkType): Promise<number[]> {
    let predicates = new relationalStore.RdbPredicates(REMARKS_TABLE_NAME);
    predicates.equalTo('type', type);
    predicates.distinct('record_id');
    try {
      let resultSet = await this.rdbStore.query(predicates);
      let recordIds: number[] = [];
      if (resultSet && resultSet.rowCount > 0) {
        while (resultSet.goToNextRow()) {
          let recordId = resultSet.getLong(resultSet.getColumnIndex('record_id'));
          recordIds.push(recordId);
        }
      }
      if (resultSet) {
        resultSet.close();
      }
      hilog.info(DOMAIN, TAG, `Found ${recordIds.length} records with remark type: ${type}.`);
      return recordIds;
    } catch (e) {
      hilog.error(DOMAIN, TAG, `Failed to query record ids by remark type, cause: ${e}`);
      return [];
    }
  }

  /**
   * 按备注内容搜索体重记录
   * @param keyword 搜索关键词
   * @returns 包含关键词的备注对应的体重记录ID列表
   */
  async searchRecordIdsByRemarkContent(keyword: string): Promise<number[]> {
    let predicates = new relationalStore.RdbPredicates(REMARKS_TABLE_NAME);
    predicates.contains('content', keyword);
    predicates.distinct('record_id');
    try {
      let resultSet = await this.rdbStore.query(predicates);
      let recordIds: number[] = [];
      if (resultSet && resultSet.rowCount > 0) {
        while (resultSet.goToNextRow()) {
          let recordId = resultSet.getLong(resultSet.getColumnIndex('record_id'));
          if (!recordIds.includes(recordId)) {
            recordIds.push(recordId);
          }
        }
      }
      if (resultSet) {
        resultSet.close();
      }
      hilog.info(DOMAIN, TAG, `Found ${recordIds.length} records with remarks containing: ${keyword}.`);
      return recordIds;
    } catch (e) {
      hilog.error(DOMAIN, TAG, `Failed to search record ids by remark content, cause: ${e}`);
      return [];
    }
  }

  /**
   * 获取体重记录及其备注
   * @param recordId 体重记录ID
   * @returns 包含备注的体重记录对象
   */
  async queryWithRemarks(recordId: number): Promise<{ record: WeightRecord | null; remarks: Remark[] }> {
    const record = await this.queryById(recordId);
    const remarks = await this.queryRemarksByRecordId(recordId);
    
    hilog.info(DOMAIN, TAG, `Queried record ${recordId} with ${remarks.length} remarks.`);
    return { record, remarks };
  }
}

let weightRecordDao: WeightRecordDao | null = null;

export async function getWeightRecordDao(context: common.Context): Promise<WeightRecordDao | null> {
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