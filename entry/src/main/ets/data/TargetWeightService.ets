/**
 * 目标体重服务
 * 管理目标体重的持久化存储和检索
 */
import relationalStore from '@ohos.data.relationalStore';
import { rdbHelper } from './RdbHelper';
import hilog from '@ohos.hilog';
import { LogConstants } from '../common/Constants';
import { common } from '@kit.AbilityKit';

const DOMAIN = LogConstants.DOMAIN;
const TAG = LogConstants.TAG_PREFIX + 'TargetWeightService';

const TARGET_WEIGHT_TABLE = 'target_weight';

export interface TargetWeightRecord {
  id: number;
  targetWeight: number;
  setDate: number;
  targetDate?: number;
  notes?: string;
}

const DDL_CREATE_TARGET_WEIGHT_TABLE = `
  CREATE TABLE IF NOT EXISTS ${TARGET_WEIGHT_TABLE} (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    targetWeight REAL NOT NULL,
    setDate INTEGER NOT NULL,
    targetDate INTEGER,
    notes TEXT
  )
`;

export class TargetWeightService {
  private rdbStore: relationalStore.RdbStore;
  private currentTarget: TargetWeightRecord | null = null;

  constructor(rdbStore: relationalStore.RdbStore) {
    this.rdbStore = rdbStore;
  }

  async setTargetWeight(weight: number, targetDate?: number, notes?: string): Promise<boolean> {
    try {
      if (weight <= 0 || weight > 200) {
        throw new Error(`Invalid target weight value: ${weight}. Must be greater than 0 and up to 200.`);
      }

      const valueBucket: relationalStore.ValuesBucket = {
        'targetWeight': weight,
        'setDate': Date.now(),
        'targetDate': targetDate || null,
        'notes': notes || ''
      };

      await this.rdbStore.executeSql('BEGIN TRANSACTION');
      const id = await this.rdbStore.insert(TARGET_WEIGHT_TABLE, valueBucket);
      await this.rdbStore.executeSql('COMMIT');

      // 更新缓存
      this.currentTarget = {
        id,
        targetWeight: weight,
        setDate: Date.now(),
        targetDate: targetDate,
        notes: notes
      };

      hilog.info(DOMAIN, TAG, `Successfully set target weight: ${weight}`);
      return true;
    } catch (e) {
      try {
        await this.rdbStore.executeSql('ROLLBACK');
      } catch (rollbackError) {
        hilog.error(DOMAIN, TAG, `Failed to rollback transaction: ${rollbackError}`);
      }
      hilog.error(DOMAIN, TAG, `Failed to set target weight, cause: ${e}`);
      return false;
    }
  }

  async getCurrentTarget(): Promise<TargetWeightRecord | null> {
    if (this.currentTarget) {
      return this.currentTarget;
    }

    try {
      let predicates = new relationalStore.RdbPredicates(TARGET_WEIGHT_TABLE);
      predicates.orderByDesc('setDate');
      predicates.limitAs(1);

      let resultSet = await this.rdbStore.query(predicates);
      let target: TargetWeightRecord | null = null;

      if (resultSet && resultSet.rowCount > 0) {
        if (resultSet.goToFirstRow()) {
          const id = resultSet.getLong(resultSet.getColumnIndex('id'));
          const targetWeight = resultSet.getDouble(resultSet.getColumnIndex('targetWeight'));
          const setDate = resultSet.getLong(resultSet.getColumnIndex('setDate'));
          const targetDate = resultSet.getLong(resultSet.getColumnIndex('targetDate'));
          const notes = resultSet.getString(resultSet.getColumnIndex('notes'));

          target = {
            id,
            targetWeight,
            setDate,
            targetDate: targetDate || undefined,
            notes: notes || undefined
          };
        }
      }

      if (resultSet) {
        resultSet.close();
      }

      this.currentTarget = target;
      hilog.info(DOMAIN, TAG, `Queried current target weight: ${target ? target.targetWeight : 'none'}`);
      return target;
    } catch (e) {
      hilog.error(DOMAIN, TAG, `Failed to query current target weight, cause: ${e}`);
      return null;
    }
  }

  async getAllTargets(): Promise<TargetWeightRecord[]> {
    try {
      let predicates = new relationalStore.RdbPredicates(TARGET_WEIGHT_TABLE);
      predicates.orderByDesc('setDate');

      let resultSet = await this.rdbStore.query(predicates);
      let targets: TargetWeightRecord[] = [];

      if (resultSet && resultSet.rowCount > 0) {
        while (resultSet.goToNextRow()) {
          const id = resultSet.getLong(resultSet.getColumnIndex('id'));
          const targetWeight = resultSet.getDouble(resultSet.getColumnIndex('targetWeight'));
          const setDate = resultSet.getLong(resultSet.getColumnIndex('setDate'));
          const targetDate = resultSet.getLong(resultSet.getColumnIndex('targetDate'));
          const notes = resultSet.getString(resultSet.getColumnIndex('notes'));

          targets.push({
            id,
            targetWeight,
            setDate,
            targetDate: targetDate || undefined,
            notes: notes || undefined
          });
        }
      }

      if (resultSet) {
        resultSet.close();
      }

      hilog.info(DOMAIN, TAG, `Queried ${targets.length} target weights.`);
      return targets;
    } catch (e) {
      hilog.error(DOMAIN, TAG, `Failed to query all target weights, cause: ${e}`);
      return [];
    }
  }

  async deleteTarget(id: number): Promise<boolean> {
    try {
      let predicates = new relationalStore.RdbPredicates(TARGET_WEIGHT_TABLE);
      predicates.equalTo('id', id);

      const rows = await this.rdbStore.delete(predicates);

      if (this.currentTarget?.id === id) {
        this.currentTarget = await this.getCurrentTarget();
      }

      hilog.info(DOMAIN, TAG, `Deleted ${rows} target weight records.`);
      return rows > 0;
    } catch (e) {
      hilog.error(DOMAIN, TAG, `Failed to delete target weight, cause: ${e}`);
      return false;
    }
  }

  async updateTarget(id: number, weight: number, targetDate?: number, notes?: string): Promise<boolean> {
    try {
      if (weight <= 0 || weight > 200) {
        throw new Error(`Invalid target weight value: ${weight}. Must be greater than 0 and up to 200.`);
      }

      const valueBucket: relationalStore.ValuesBucket = {
        'targetWeight': weight,
        'targetDate': targetDate || null,
        'notes': notes || ''
      };

      let predicates = new relationalStore.RdbPredicates(TARGET_WEIGHT_TABLE);
      predicates.equalTo('id', id);

      const rows = await this.rdbStore.update(valueBucket, predicates);

      if (this.currentTarget?.id === id) {
        this.currentTarget = {
          id,
          targetWeight: weight,
          setDate: this.currentTarget.setDate,
          targetDate: targetDate,
          notes: notes
        };
      }

      hilog.info(DOMAIN, TAG, `Updated ${rows} target weight records.`);
      return rows > 0;
    } catch (e) {
      hilog.error(DOMAIN, TAG, `Failed to update target weight, cause: ${e}`);
      return false;
    }
  }

  async getTargetWeightHistory(limit: number): Promise<TargetWeightRecord[]> {
    try {
      let predicates = new relationalStore.RdbPredicates(TARGET_WEIGHT_TABLE);
      predicates.orderByDesc('setDate');
      predicates.limitAs(limit);

      let resultSet = await this.rdbStore.query(predicates);
      let targets: TargetWeightRecord[] = [];

      if (resultSet && resultSet.rowCount > 0) {
        while (resultSet.goToNextRow()) {
          const id = resultSet.getLong(resultSet.getColumnIndex('id'));
          const targetWeight = resultSet.getDouble(resultSet.getColumnIndex('targetWeight'));
          const setDate = resultSet.getLong(resultSet.getColumnIndex('setDate'));
          const targetDate = resultSet.getLong(resultSet.getColumnIndex('targetDate'));
          const notes = resultSet.getString(resultSet.getColumnIndex('notes'));

          targets.push({
            id,
            targetWeight,
            setDate,
            targetDate: targetDate || undefined,
            notes: notes || undefined
          });
        }
      }

      if (resultSet) {
        resultSet.close();
      }

      hilog.info(DOMAIN, TAG, `Queried ${targets.length} target weight records from history.`);
      return targets;
    } catch (e) {
      hilog.error(DOMAIN, TAG, `Failed to query target weight history, cause: ${e}`);
      return [];
    }
  }

  async updateTargetWeight(id: number, weight: number, targetDate?: number, notes?: string): Promise<boolean> {
    return this.updateTarget(id, weight, targetDate, notes);
  }

  async deleteTargetWeight(id: number): Promise<boolean> {
    return this.deleteTarget(id);
  }
}

let targetWeightService: TargetWeightService | null = null;

export async function getTargetWeightService(context: common.Context): Promise<TargetWeightService | null> {
  if (targetWeightService) {
    return targetWeightService;
  }

  try {
    let rdbStore = await rdbHelper.initRdbStore(context);
    if (rdbStore) {
      await rdbStore.executeSql(DDL_CREATE_TARGET_WEIGHT_TABLE);
      targetWeightService = new TargetWeightService(rdbStore);
      hilog.info(DOMAIN, TAG, 'TargetWeightService initialized.');
      return targetWeightService;
    }
  } catch (e) {
    hilog.error(DOMAIN, TAG, `Failed to initialize TargetWeightService, cause: ${e}`);
  }

  return null;
}
