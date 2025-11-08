/**
 * 全局目标体重管理器
 * 用于在应用程序中同步和管理目标体重
 */
import { getTargetWeightService, TargetWeightRecord } from '../data/TargetWeightService';
import { WeightRecord } from '../model/WeightRecord';
import { common } from '@kit.AbilityKit';
import hilog from '@ohos.hilog';
import { LogConstants } from './Constants';

const DOMAIN = LogConstants.DOMAIN;
const TAG = LogConstants.TAG_PREFIX + 'TargetWeightManager';

class TargetWeightManager {
  private currentTarget: TargetWeightRecord | null = null;
  private observers: ((target: TargetWeightRecord | null) => void)[] = [];

  async initialize(context: common.Context): Promise<void> {
    try {
      const service = await getTargetWeightService(context);
      if (service) {
        this.currentTarget = await service.getCurrentTarget();
        if (this.currentTarget) {
          WeightRecord.setTargetWeight(this.currentTarget.targetWeight);
          hilog.info(DOMAIN, TAG, `Initialized with target weight: ${this.currentTarget.targetWeight}`);
        }
      }
    } catch (e) {
      hilog.error(DOMAIN, TAG, `Failed to initialize target weight manager: ${e}`);
    }
  }

  getCurrentTarget(): TargetWeightRecord | null {
    return this.currentTarget;
  }

  async updateTarget(context: common.Context, target: TargetWeightRecord): Promise<void> {
    this.currentTarget = target;
    WeightRecord.setTargetWeight(target.targetWeight);
    this.notifyObservers();
    hilog.info(DOMAIN, TAG, `Updated target weight to: ${target.targetWeight}`);
  }

  addObserver(callback: (target: TargetWeightRecord | null) => void): void {
    this.observers.push(callback);
  }

  removeObserver(callback: (target: TargetWeightRecord | null) => void): void {
    const index = this.observers.indexOf(callback);
    if (index > -1) {
      this.observers.splice(index, 1);
    }
  }

  private notifyObservers(): void {
    this.observers.forEach(callback => {
      try {
        callback(this.currentTarget);
      } catch (e) {
        hilog.error(DOMAIN, TAG, `Error notifying observer: ${e}`);
      }
    });
  }

  clear(): void {
    this.currentTarget = null;
    this.observers = [];
  }
}

let targetWeightManager: TargetWeightManager | null = null;

export function getTargetWeightManager(): TargetWeightManager {
  if (!targetWeightManager) {
    targetWeightManager = new TargetWeightManager();
  }
  return targetWeightManager;
}
