import relationalStore from '@ohos.data.relationalStore';
import hilog from '@ohos.hilog';

const DOMAIN = 0x0000;
const TAG = 'RdbHelper';

const DB_NAME = 'WEIGHT_DB.db';
const TABLE_NAME = 'weight_record';
const DDL_CREATE_TABLE = `
  CREATE TABLE IF NOT EXISTS ${TABLE_NAME} (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    weight REAL NOT NULL,
    date INTEGER NOT NULL,
    notes TEXT
  )
`;

class RdbHelper {
  private rdbStore: relationalStore.RdbStore | null = null;

  async initRdbStore(context) {
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
      hilog.info(DOMAIN, TAG, 'RDB store initialized and table created.');
      return this.rdbStore;
    } catch (e) {
      hilog.error(DOMAIN, TAG, `Failed to initialize RDB store, cause: ${e}`);
      return null;
    }
  }
}

export const rdbHelper = new RdbHelper();
export { TABLE_NAME };