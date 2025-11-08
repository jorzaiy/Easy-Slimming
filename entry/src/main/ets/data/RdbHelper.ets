import relationalStore from '@ohos.data.relationalStore';
import hilog from '@ohos.hilog';
import { common } from '@kit.AbilityKit';
import { LogConstants } from '../common/Constants';

const DOMAIN = LogConstants.DOMAIN;
const TAG = LogConstants.TAG_PREFIX + 'RdbHelper';

const DB_NAME = 'WEIGHT_DB.db';
const TABLE_NAME = 'weight_record';
const REMARKS_TABLE_NAME = 'remarks';
const HEALTH_SYNC_RECORD_TABLE = 'health_sync_record';
const SYNC_SETTINGS_TABLE = 'sync_settings';
const HEALTH_SYNC_CONFLICT_TABLE = 'health_sync_conflict';

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
const DDL_CREATE_HEALTH_SYNC_RECORD_TABLE = `
  CREATE TABLE IF NOT EXISTS ${HEALTH_SYNC_RECORD_TABLE} (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    weight_record_id INTEGER NOT NULL,
    sync_direction TEXT NOT NULL,
    status TEXT NOT NULL,
    start_time INTEGER NOT NULL,
    end_time INTEGER,
    error_message TEXT,
    health_app_record_id TEXT,
    data_hash TEXT,
    FOREIGN KEY (weight_record_id) REFERENCES ${TABLE_NAME}(id) ON DELETE CASCADE
  )
`;
const DDL_CREATE_SYNC_SETTINGS_TABLE = `
  CREATE TABLE IF NOT EXISTS ${SYNC_SETTINGS_TABLE} (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    sync_enabled INTEGER NOT NULL,
    sync_mode TEXT NOT NULL,
    auto_sync_interval_minutes INTEGER NOT NULL,
    auto_sync_enabled INTEGER NOT NULL,
    last_sync_time INTEGER,
    sync_on_app_start INTEGER NOT NULL,
    conflict_resolution TEXT NOT NULL,
    enable_detailed_logs INTEGER NOT NULL,
    max_sync_retries INTEGER NOT NULL,
    request_timeout INTEGER NOT NULL
  )
`;
const DDL_CREATE_HEALTH_SYNC_CONFLICT_TABLE = `
  CREATE TABLE IF NOT EXISTS ${HEALTH_SYNC_CONFLICT_TABLE} (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    conflict_type TEXT NOT NULL,
    local_record_id INTEGER NOT NULL,
    health_record_data TEXT NOT NULL,
    created_time INTEGER NOT NULL,
    resolved_time INTEGER,
    resolution_option TEXT,
    description TEXT NOT NULL,
    FOREIGN KEY (local_record_id) REFERENCES ${TABLE_NAME}(id) ON DELETE CASCADE
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
      await this.rdbStore.executeSql(DDL_CREATE_HEALTH_SYNC_RECORD_TABLE);
      await this.rdbStore.executeSql(DDL_CREATE_SYNC_SETTINGS_TABLE);
      await this.rdbStore.executeSql(DDL_CREATE_HEALTH_SYNC_CONFLICT_TABLE);
      hilog.info(DOMAIN, TAG, 'RDB store initialized and tables created.');
      return this.rdbStore;
    } catch (e) {
      hilog.error(DOMAIN, TAG, `Failed to initialize RDB store, cause: ${e}`);
      return null;
    }
  }
}

export const rdbHelper = new RdbHelper();
export { TABLE_NAME, REMARKS_TABLE_NAME, HEALTH_SYNC_RECORD_TABLE, SYNC_SETTINGS_TABLE, HEALTH_SYNC_CONFLICT_TABLE };