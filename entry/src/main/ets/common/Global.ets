import { WeightRecordDao } from '../data/WeightRecordDao';
import { TargetWeightService } from '../data/TargetWeightService';

let appDao: WeightRecordDao | null = null;
let targetWeightService: TargetWeightService | null = null;

export function initDao(dao: WeightRecordDao): void {
  appDao = dao;
}

export function getAppDao(): WeightRecordDao | null {
  return appDao;
}

export function initTargetWeightService(service: TargetWeightService): void {
  targetWeightService = service;
}

export function getAppTargetWeightService(): TargetWeightService | null {
  return targetWeightService;
}
