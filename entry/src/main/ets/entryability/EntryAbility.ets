import { AbilityConstant, ConfigurationConstant, UIAbility, Want } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { window } from '@kit.ArkUI';
import { LogConstants } from '../common/Constants';
import { getWeightRecordDao } from '../data/WeightRecordDao';
import { initDao } from '../common/Global';
import { getTargetWeightManager } from '../common/TargetWeightManager';
import { getTargetWeightService } from '../data/TargetWeightService';
import { getHealthSyncRecordDao } from '../data/HealthSyncRecordDao';
import { getSyncSettingsDao } from '../data/SyncSettingsDao';
import { getHealthSyncService } from '../data/HealthSyncService';

const DOMAIN = LogConstants.DOMAIN;

export default class EntryAbility extends UIAbility {
  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    try {
      this.context.getApplicationContext().setColorMode(ConfigurationConstant.ColorMode.COLOR_MODE_NOT_SET);
    } catch (err) {
      hilog.error(DOMAIN, 'testTag', 'Failed to set colorMode. Cause: %{public}s', JSON.stringify(err));
    }
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onCreate');
    
    // Initialize global DAO instance
    this.initializeGlobalServices();
  }

  private async initializeGlobalServices() {
    try {
      const dao = await getWeightRecordDao(this.context);
      if (dao) {
        initDao(dao);
        hilog.info(DOMAIN, 'testTag', 'Global DAO initialized successfully');
      } else {
        hilog.error(DOMAIN, 'testTag', 'Failed to initialize global DAO: received null');
      }

      // Initialize target weight service
      const targetService = await getTargetWeightService(this.context);
      if (targetService) {
        const manager = getTargetWeightManager();
        await manager.initialize(this.context);
        hilog.info(DOMAIN, 'testTag', 'Target weight service initialized successfully');
      } else {
        hilog.error(DOMAIN, 'testTag', 'Failed to initialize target weight service: received null');
      }

      // Initialize health sync services
      const syncRecordDao = await getHealthSyncRecordDao(this.context);
      const syncSettingsDao = await getSyncSettingsDao(this.context);
      if (syncRecordDao && syncSettingsDao && dao) {
        const healthSyncService = await getHealthSyncService(dao, syncRecordDao, syncSettingsDao);
        hilog.info(DOMAIN, 'testTag', 'Health sync service initialized successfully');
      } else {
        hilog.error(DOMAIN, 'testTag', 'Failed to initialize health sync service: received null');
      }
    } catch (e) {
      hilog.error(DOMAIN, 'testTag', 'Failed to initialize global services, cause: %{public}s', JSON.stringify(e));
    }
  }

  onDestroy(): void {
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onDestroy');
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {
    // Main window is created, set main page for this ability
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onWindowStageCreate');

    windowStage.loadContent('pages/Index', (err) => {
      if (err.code) {
        hilog.error(DOMAIN, 'testTag', 'Failed to load the content. Cause: %{public}s', JSON.stringify(err));
        return;
      }
      hilog.info(DOMAIN, 'testTag', 'Succeeded in loading the content.');
    });
  }

  onWindowStageDestroy(): void {
    // Main window is destroyed, release UI related resources
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onWindowStageDestroy');
  }

  onForeground(): void {
    // Ability has brought to foreground
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onForeground');
  }

  onBackground(): void {
    // Ability has back to background
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onBackground');
  }
}