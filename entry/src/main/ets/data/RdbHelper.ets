import relationalStore from '@ohos.data.relationalStore';
import hilog from '@ohos.hilog';
import { common } from '@kit.AbilityKit';
import { LogConstants } from '../common/Constants';

const DOMAIN = LogConstants.DOMAIN;
const TAG = LogConstants.TAG_PREFIX + 'RdbHelper';

const DB_NAME = 'WEIGHT_DB.db';
const TABLE_NAME = 'weight_record';
const REMARKS_TABLE_NAME = 'remarks';
const DDL_CREATE_TABLE = `
  CREATE TABLE IF NOT EXISTS ${TABLE_NAME} (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    weight REAL NOT NULL,
    date INTEGER NOT NULL,
    notes TEXT
  )
`;
const DDL_CREATE_REMARKS_TABLE = `
  CREATE TABLE IF NOT EXISTS ${REMARKS_TABLE_NAME} (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    record_id INTEGER NOT NULL,
    type TEXT NOT NULL,
    content TEXT NOT NULL,
    timestamp INTEGER NOT NULL,
    FOREIGN KEY (record_id) REFERENCES ${TABLE_NAME}(id) ON DELETE CASCADE
  )
`;

class RdbHelper {
  private rdbStore: relationalStore.RdbStore | null = null;

  async initRdbStore(context: common.Context) {
    if (this.rdbStore) {
      hilog.info(DOMAIN, TAG, 'RDB store already initialized.');
      return this.rdbStore;
    }
    let config: relationalStore.StoreConfig = {
      name: DB_NAME,
      securityLevel: relationalStore.SecurityLevel.S1
    };
    try {
      this.rdbStore = await relationalStore.getRdbStore(context, config);
      await this.rdbStore.executeSql(DDL_CREATE_TABLE);
      await this.rdbStore.executeSql(DDL_CREATE_REMARKS_TABLE);
      hilog.info(DOMAIN, TAG, 'RDB store initialized and tables created.');
      return this.rdbStore;
    } catch (e) {
      hilog.error(DOMAIN, TAG, `Failed to initialize RDB store, cause: ${e}`);
      return null;
    }
  }
}

export const rdbHelper = new RdbHelper();
export { TABLE_NAME, REMARKS_TABLE_NAME };