import relationalStore from '@ohos.data.relationalStore';
import { Remark, RemarkType, ValidationResult } from '../model/Remark';
import { REMARKS_TABLE_NAME } from './RdbHelper';
import hilog from '@ohos.hilog';
import { LogConstants } from '../common/Constants';
import { common } from '@kit.AbilityKit';

const DOMAIN = LogConstants.DOMAIN;
const TAG = LogConstants.TAG_PREFIX + 'RemarkDao';

export class RemarkDao {
  private rdbStore: relationalStore.RdbStore;

  constructor(rdbStore: relationalStore.RdbStore) {
    this.rdbStore = rdbStore;
  }

  /**
   * 插入备注
   * @param remark 要插入的备注
   * @returns 插入备注的ID，失败返回-1
   */
  async insert(remark: Remark): Promise<number> {
    try {
      // 验证备注数据
      const validation = remark.validate();
      if (!validation.isValid) {
        hilog.error(DOMAIN, TAG, `Invalid remark data: ${validation.errors.join(', ')}`);
        return -1;
      }

      const valueBucket: relationalStore.ValuesBucket = {
        'record_id': remark.recordId,
        'type': remark.type,
        'content': remark.content,
        'timestamp': remark.timestamp
      };
      
      await this.rdbStore.executeSql('BEGIN TRANSACTION');
      let id = await this.rdbStore.insert(REMARKS_TABLE_NAME, valueBucket);
      await this.rdbStore.executeSql('COMMIT');
      hilog.info(DOMAIN, TAG, `Successfully inserted remark with id: ${id}`);
      return id;
    } catch (e) {
      try {
        await this.rdbStore.executeSql('ROLLBACK');
      } catch (rollbackError) {
        hilog.error(DOMAIN, TAG, `Failed to rollback transaction: ${rollbackError}`);
      }
      hilog.error(DOMAIN, TAG, `Failed to insert remark, cause: ${e}`);
      return -1;
    }
  }

  /**
   * 查询某条体重记录的所有备注
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
   * 根据备注ID查询单条备注
   * @param id 备注ID
   * @returns 备注对象或null
   */
  async queryById(id: number): Promise<Remark | null> {
    let predicates = new relationalStore.RdbPredicates(REMARKS_TABLE_NAME);
    predicates.equalTo('id', id);
    try {
      let resultSet = await this.rdbStore.query(predicates);
      let remark: Remark | null = null;
      if (resultSet && resultSet.rowCount > 0) {
        if (resultSet.goToFirstRow()) {
          let remarkId = resultSet.getLong(resultSet.getColumnIndex('id'));
          let recordId = resultSet.getLong(resultSet.getColumnIndex('record_id'));
          let type = resultSet.getString(resultSet.getColumnIndex('type')) as RemarkType;
          let content = resultSet.getString(resultSet.getColumnIndex('content'));
          let timestamp = resultSet.getLong(resultSet.getColumnIndex('timestamp'));
          remark = new Remark(recordId, type, content, timestamp, remarkId);
        }
      }
      if (resultSet) {
        resultSet.close();
      }
      hilog.info(DOMAIN, TAG, `Queried remark with id: ${id}, found: ${remark ? 'yes' : 'no'}`);
      return remark;
    } catch (e) {
      hilog.error(DOMAIN, TAG, `Failed to query remark by id, cause: ${e}`);
      return null;
    }
  }

  /**
   * 更新备注
   * @param remark 要更新的备注
   * @returns 更新的行数
   */
  async update(remark: Remark): Promise<number> {
    try {
      // 验证备注数据
      const validation = remark.validate();
      if (!validation.isValid) {
        hilog.error(DOMAIN, TAG, `Invalid remark data: ${validation.errors.join(', ')}`);
        return 0;
      }

      const valueBucket: relationalStore.ValuesBucket = {
        'record_id': remark.recordId,
        'type': remark.type,
        'content': remark.content,
        'timestamp': remark.timestamp
      };
      let predicates = new relationalStore.RdbPredicates(REMARKS_TABLE_NAME);
      predicates.equalTo('id', remark.id);
      
      let rows = await this.rdbStore.update(valueBucket, predicates);
      hilog.info(DOMAIN, TAG, `Updated ${rows} remark(s).`);
      return rows;
    } catch (e) {
      hilog.error(DOMAIN, TAG, `Failed to update remark, cause: ${e}`);
      return 0;
    }
  }

  /**
   * 删除备注
   * @param id 备注ID
   * @returns 删除的行数
   */
  async deleteById(id: number): Promise<number> {
    let predicates = new relationalStore.RdbPredicates(REMARKS_TABLE_NAME);
    predicates.equalTo('id', id);
    try {
      let rows = await this.rdbStore.delete(predicates);
      hilog.info(DOMAIN, TAG, `Deleted ${rows} remark(s).`);
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
  async deleteByRecordId(recordId: number): Promise<number> {
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
   * 按备注内容搜索
   * @param keyword 搜索关键词
   * @returns 包含关键词的备注列表
   */
  async searchRemarksByContent(keyword: string): Promise<Remark[]> {
    let predicates = new relationalStore.RdbPredicates(REMARKS_TABLE_NAME);
    predicates.contains('content', keyword);
    predicates.orderByDesc('timestamp');
    try {
      let resultSet = await this.rdbStore.query(predicates);
      let remarks: Remark[] = [];
      if (resultSet && resultSet.rowCount > 0) {
        while (resultSet.goToNextRow()) {
          let id = resultSet.getLong(resultSet.getColumnIndex('id'));
          let recordId = resultSet.getLong(resultSet.getColumnIndex('record_id'));
          let type = resultSet.getString(resultSet.getColumnIndex('type')) as RemarkType;
          let content = resultSet.getString(resultSet.getColumnIndex('content'));
          let timestamp = resultSet.getLong(resultSet.getColumnIndex('timestamp'));
          remarks.push(new Remark(recordId, type, content, timestamp, id));
        }
      }
      if (resultSet) {
        resultSet.close();
      }
      hilog.info(DOMAIN, TAG, `Found ${remarks.length} remarks matching keyword: ${keyword}.`);
      return remarks;
    } catch (e) {
      hilog.error(DOMAIN, TAG, `Failed to search remarks by content, cause: ${e}`);
      return [];
    }
  }

  /**
   * 获取所有备注
   * @returns 所有备注列表
   */
  async queryAll(): Promise<Remark[]> {
    let predicates = new relationalStore.RdbPredicates(REMARKS_TABLE_NAME);
    predicates.orderByDesc('timestamp');
    try {
      let resultSet = await this.rdbStore.query(predicates);
      let remarks: Remark[] = [];
      if (resultSet && resultSet.rowCount > 0) {
        while (resultSet.goToNextRow()) {
          let id = resultSet.getLong(resultSet.getColumnIndex('id'));
          let recordId = resultSet.getLong(resultSet.getColumnIndex('record_id'));
          let type = resultSet.getString(resultSet.getColumnIndex('type')) as RemarkType;
          let content = resultSet.getString(resultSet.getColumnIndex('content'));
          let timestamp = resultSet.getLong(resultSet.getColumnIndex('timestamp'));
          remarks.push(new Remark(recordId, type, content, timestamp, id));
        }
      }
      if (resultSet) {
        resultSet.close();
      }
      hilog.info(DOMAIN, TAG, `Queried ${remarks.length} remarks in total.`);
      return remarks;
    } catch (e) {
      hilog.error(DOMAIN, TAG, `Failed to query all remarks, cause: ${e}`);
      return [];
    }
  }
}

let remarkDao: RemarkDao | null = null;

export async function getRemarkDao(context: common.Context): Promise<RemarkDao | null> {
  if (remarkDao) {
    return remarkDao;
  }
  
  try {
    const helperModule = await import('./RdbHelper');
    const rdbStore = await helperModule.rdbHelper.initRdbStore(context);
    if (rdbStore) {
      remarkDao = new RemarkDao(rdbStore);
      return remarkDao;
    }
  } catch (e) {
    hilog.error(DOMAIN, TAG, `Failed to get RemarkDao, cause: ${e}`);
  }
  
  return null;
}