import { WeightRecordDao } from '../data/WeightRecordDao';

let appDao: WeightRecordDao | null = null;

export function initDao(dao: WeightRecordDao): void {
  appDao = dao;
}

export function getAppDao(): WeightRecordDao | null {
  return appDao;
}
