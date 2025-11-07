import relationalStore from '@ohos.data.relationalStore';
import { WeightRecord } from '../model/WeightRecord';
import { rdbHelper, TABLE_NAME } from './RdbHelper';
import hilog from '@ohos.hilog';

const DOMAIN = 0x0000;
const TAG = 'WeightRecordDao';

class WeightRecordDao {
  private rdbStore: relationalStore.RdbStore;

  constructor(rdbStore: relationalStore.RdbStore) {
    this.rdbStore = rdbStore;
  }

  // 插入数据
  async insert(record: WeightRecord): Promise<number> {
    const valueBucket: relationalStore.ValuesBucket = {
      'weight': record.weight,
      'date': record.date,
      'notes': record.notes || ''
    };
    try {
      let id = await this.rdbStore.insert(TABLE_NAME, valueBucket);
      hilog.info(DOMAIN, TAG, `Inserted record with id: ${id}`);
      return id;
    } catch (e) {
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
      if (resultSet.rowCount > 0) {
        while (resultSet.goToNextRow()) {
          let id = resultSet.getLong(resultSet.getColumnIndex('id'));
          let weight = resultSet.getDouble(resultSet.getColumnIndex('weight'));
          let date = resultSet.getLong(resultSet.getColumnIndex('date'));
          let notes = resultSet.getString(resultSet.getColumnIndex('notes'));
          records.push(new WeightRecord(weight, date, id, notes));
        }
      }
      resultSet.close();
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
}

let weightRecordDao: WeightRecordDao | null = null;

export async function getWeightRecordDao(context): Promise<WeightRecordDao> {
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