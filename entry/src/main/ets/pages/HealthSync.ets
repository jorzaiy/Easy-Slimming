/**
 * 健康数据同步页面
 * 显示与鸿蒙运动健康应用的同步状态和历史
 */

import hilog from '@ohos.hilog';
import router from '@ohos.router';
import { HealthSyncService, SyncResult } from '../data/HealthSyncService';
import { HealthSyncRecordDao } from '../data/HealthSyncRecordDao';
import { SyncSettingsDao } from '../data/SyncSettingsDao';
import { WeightRecordDao } from '../data/WeightRecordDao';
import { HealthSyncRecord, SyncStatus, SyncDirection } from '../model/HealthSyncRecord';
import { SyncSettings } from '../model/SyncSettings';
import { AppColors, AppDimensions, AppText, LogConstants } from '../common/Constants';
import { getAppDao } from '../common/Global';
import { common } from '@kit.AbilityKit';
import { resolveAbilityContext } from '../common/ContextUtils';
import promptAction from '@ohos.promptAction';

const DOMAIN = LogConstants.DOMAIN;
const TAG = LogConstants.TAG_PREFIX + 'HealthSync';

@Entry
@Component
struct HealthSync {
  @State syncHistory: HealthSyncRecord[] = [];
  @State syncSettings: SyncSettings | null = null;
  @State isSyncing: boolean = false;
  @State syncProgress: number = 0;
  @State lastSyncTime: string = '从未同步';
  @State syncStatus: string = '未同步';
  private healthSyncService: HealthSyncService | null = null;
  private syncSettingsDao: SyncSettingsDao | null = null;
  private syncRecordDao: HealthSyncRecordDao | null = null;
  private scroller: Scroller = new Scroller();

  private getCommonContext(): common.Context | null {
    const uiContext = this.getUIContext();
    return uiContext ? resolveAbilityContext(uiContext) : null;
  }

  async aboutToAppear() {
    await this.initializeServices();
    await this.loadSyncData();
  }

  private async initializeServices() {
    try {
      const weightRecordDao = getAppDao();
      if (!weightRecordDao) {
        throw new Error('Weight record DAO not initialized');
      }

      const context = this.getCommonContext();
      if (!context) {
        throw new Error('Context not available');
      }

      const syncSettingsService = await (await import('../data/SyncSettingsDao')).getSyncSettingsDao(context);
      const syncRecordService = await (await import('../data/HealthSyncRecordDao')).getHealthSyncRecordDao(context);

      if (syncSettingsService && syncRecordService) {
        this.syncSettingsDao = syncSettingsService;
        this.syncRecordDao = syncRecordService;

        this.healthSyncService = new HealthSyncService(
          weightRecordDao,
          syncRecordService,
          syncSettingsService
        );
        await this.healthSyncService.initialize();
      }
    } catch (e) {
      hilog.error(DOMAIN, TAG, `Failed to initialize services, cause: ${e}`);
    }
  }

  private async loadSyncData() {
    try {
      if (this.syncSettingsDao) {
        this.syncSettings = await this.syncSettingsDao.queryDefault();
        if (this.syncSettings?.lastSyncTime) {
          const date = new Date(this.syncSettings.lastSyncTime);
          this.lastSyncTime = date.toLocaleString();
        }
      }

      if (this.syncRecordDao) {
        this.syncHistory = await this.syncRecordDao.queryAll();
      }

      this.updateSyncStatus();
    } catch (e) {
      hilog.error(DOMAIN, TAG, `Failed to load sync data, cause: ${e}`);
    }
  }

  private updateSyncStatus() {
    if (this.isSyncing) {
      this.syncStatus = '同步中...';
      return;
    }

    if (this.syncHistory.length > 0) {
      const lastSync = this.syncHistory[0];
      switch (lastSync.status) {
        case SyncStatus.SUCCESS:
          this.syncStatus = '已同步';
          break;
        case SyncStatus.FAILED:
          this.syncStatus = '同步失败';
          break;
        case SyncStatus.SYNCING:
          this.syncStatus = '同步中...';
          break;
        case SyncStatus.CONFLICT:
          this.syncStatus = '同步冲突';
          break;
        case SyncStatus.PENDING:
          this.syncStatus = '待同步';
          break;
        default:
          this.syncStatus = this.getSyncStatusText(lastSync.status);
      }
      return;
    }

    this.syncStatus = '未同步';
  }

  private async startSync() {
    if (!this.healthSyncService) {
      promptAction.showToast({ message: '同步服务未初始化' });
      return;
    }

    this.isSyncing = true;
    this.syncProgress = 0;

    try {
      const result = await this.healthSyncService.syncToHealth();

      promptAction.showToast({
        message: result.message,
        duration: 2000
      });

      await this.loadSyncData();
    } catch (e) {
      hilog.error(DOMAIN, TAG, `Sync failed, cause: ${e}`);
      promptAction.showToast({ message: '同步失败' });
    } finally {
      this.isSyncing = false;
    }
  }

  private getSyncStatusColor(status: SyncStatus): string {
    switch (status) {
      case SyncStatus.SUCCESS:
        return AppColors.SUCCESS;
      case SyncStatus.FAILED:
        return AppColors.ERROR;
      case SyncStatus.CONFLICT:
        return AppColors.WARNING;
      case SyncStatus.SYNCING:
        return AppColors.PRIMARY;
      default:
        return AppColors.GRAY;
    }
  }

  private getSyncStatusText(status: SyncStatus): string {
    switch (status) {
      case SyncStatus.SUCCESS:
        return '成功';
      case SyncStatus.FAILED:
        return '失败';
      case SyncStatus.SYNCING:
        return '进行中';
      case SyncStatus.PENDING:
        return '待同步';
      case SyncStatus.CONFLICT:
        return '冲突';
      default:
        return status;
    }
  }

  private getSyncDirectionText(direction: SyncDirection): string {
    switch (direction) {
      case SyncDirection.TO_HEALTH:
        return '→ 鸿蒙';
      case SyncDirection.FROM_HEALTH:
        return '← 鸿蒙';
      case SyncDirection.BIDIRECTIONAL:
        return '↔ 双向';
      default:
        return direction;
    }
  }

  build() {
    Column({ space: 16 }) {
      // 顶部标题栏
      Row() {
        Image($r('app.media.ic_back'))
          .width(24)
          .height(24)
          .fillColor(Color.Black)
          .onClick(() => {
            try {
              router.back();
            } catch (e) {
              hilog.error(DOMAIN, TAG, `Failed to navigate back, cause: ${e}`);
            }
          })

        Text('健康数据同步')
          .fontSize(24)
          .fontWeight(FontWeight.Bold)
          .layoutWeight(1)
          .textAlign(TextAlign.Start)
          .margin({ left: 16 })
      }
      .width('100%')
      .height(56)
      .padding({ left: 16, right: 16 })
      .alignItems(VerticalAlign.Center)

      Scroll(this.scroller) {
        Column({ space: 16 }) {
          // 同步状态卡片
          Column({ space: 12 }) {
            Row() {
              Column({ space: 4 }) {
                Text('同步状态')
                  .fontSize(14)
                  .fontColor(AppColors.GRAY)
                Text(this.syncStatus)
                  .fontSize(18)
                  .fontWeight(FontWeight.Bold)
                  .fontColor(
                    this.isSyncing ? AppColors.PRIMARY : AppColors.SECONDARY
                  )
              }
              .alignItems(HorizontalAlign.Start)
              .layoutWeight(1)

              Column({ space: 4 }) {
                Text('最后同步')
                  .fontSize(14)
                  .fontColor(AppColors.GRAY)
                Text(this.lastSyncTime)
                  .fontSize(14)
                  .fontColor(AppColors.GRAY)
              }
              .alignItems(HorizontalAlign.End)
            }
            .width('100%')
            .justifyContent(FlexAlign.SpaceBetween)

            if (this.isSyncing) {
              Column() {
                Progress({ value: this.syncProgress, total: 100 })
                  .color(AppColors.PRIMARY)
                  .width('100%')
                  .height(4)

                Text(`${this.syncProgress}%`)
                  .fontSize(12)
                  .fontColor(AppColors.GRAY)
                  .margin({ top: 4 })
              }
              .width('100%')
            }
          }
          .width('90%')
          .padding(AppDimensions.PADDING_MEDIUM)
          .backgroundColor(AppColors.WHITE)
          .borderRadius(AppDimensions.BORDER_RADIUS)
          .shadow({ radius: 3, color: Color.Gray, offsetX: 0, offsetY: 1 })

          // 操作按钮
          Row({ space: 12 }) {
            Button('同步到鸿蒙')
              .layoutWeight(1)
              .height(44)
              .fontSize(AppText.FONT_SIZE_BODY)
              .fontColor(Color.White)
              .backgroundColor(AppColors.PRIMARY)
              .enabled(!this.isSyncing)
              .onClick(() => {
                this.startSync();
              })

            Button('同步设置')
              .layoutWeight(1)
              .height(44)
              .fontSize(AppText.FONT_SIZE_BODY)
              .fontColor(AppColors.PRIMARY)
              .backgroundColor(Color.White)
              .border({ width: 1, color: AppColors.PRIMARY })
              .onClick(() => {
                try {
                  router.pushUrl({ url: 'pages/HealthSyncSettings' });
                } catch (e) {
                  hilog.error(DOMAIN, TAG, `Failed to navigate, cause: ${e}`);
                }
              })
          }
          .width('90%')

          // 同步历史
          Column({ space: 8 }) {
            Text('同步历史')
              .fontSize(16)
              .fontWeight(FontWeight.Bold)
              .fontColor(Color.Black)

            if (this.syncHistory.length > 0) {
              ForEach(this.syncHistory.slice(), (record: HealthSyncRecord, index?: number) => {
                Column({ space: 8 }) {
                  Row() {
                    Column({ space: 4 }) {
                      Text(this.getSyncDirectionText(record.syncDirection))
                        .fontSize(14)
                        .fontWeight(FontWeight.Bold)
                        .fontColor(AppColors.PRIMARY)
                      Text(record.getFormattedStartTime())
                        .fontSize(12)
                        .fontColor(AppColors.GRAY)
                    }
                    .layoutWeight(1)
                    .alignItems(HorizontalAlign.Start)

                    Column({ space: 4 }) {
                      Text(this.getSyncStatusText(record.status))
                        .fontSize(14)
                        .fontWeight(FontWeight.Bold)
                        .fontColor(this.getSyncStatusColor(record.status))

                      if (record.endTime) {
                        Text(`${Math.round(record.getDuration() / 1000)}秒`)
                          .fontSize(12)
                          .fontColor(AppColors.GRAY)
                      }
                    }
                    .alignItems(HorizontalAlign.End)
                  }
                  .width('100%')

                  if (record.errorMessage) {
                    Text(record.errorMessage)
                      .fontSize(12)
                      .fontColor(AppColors.WARNING)
                      .maxLines(2)
                      .textOverflow({ overflow: TextOverflow.Ellipsis })
                  }
                }
                .width('100%')
                .padding(12)
                .backgroundColor(Color.White)
                .borderRadius(8)
                .border({
                  width: 1,
                  color: Color.Gray,
                  radius: 8
                })
              })
            } else {
              Text('暂无同步历史')
                .fontSize(14)
                .fontColor(AppColors.GRAY)
                .width('100%')
                .textAlign(TextAlign.Center)
                .padding(20)
                .backgroundColor(Color.White)
                .borderRadius(8)
            }
          }
          .width('90%')
          .alignItems(HorizontalAlign.Start)
        }
        .width('100%')
        .alignItems(HorizontalAlign.Center)
        .padding({ bottom: 20 })
      }
      .layoutWeight(1)
      .width('100%')
    }
    .width('100%')
    .height('100%')
    .backgroundColor(AppColors.BACKGROUND)
    .padding({ top: 8, bottom: 8 })
  }
}
