/**
 * 健康数据同步设置页面
 * 配置与鸿蒙运动健康应用的同步参数
 */

import hilog from '@ohos.hilog';
import router from '@ohos.router';
import { SyncSettings, SyncMode } from '../model/SyncSettings';
import { ResolutionOption } from '../model/HealthSyncConflict';
import { SyncSettingsDao } from '../data/SyncSettingsDao';
import { AppColors, AppDimensions, AppText, LogConstants } from '../common/Constants';
import { common } from '@kit.AbilityKit';
import { resolveAbilityContext } from '../common/ContextUtils';
import promptAction from '@ohos.promptAction';

const DOMAIN = LogConstants.DOMAIN;
const TAG = LogConstants.TAG_PREFIX + 'HealthSyncSettings';

interface SyncOption<T> {
  label: string;
  value: T;
}

type SyncModeOption = SyncOption<SyncMode>;
type ConflictResolutionOption = SyncOption<ResolutionOption>;

@Entry
@Component
struct HealthSyncSettings {
  @State settings: SyncSettings | null = null;
  @State syncModeOptions: SyncModeOption[] = [
    { label: '手动同步', value: SyncMode.MANUAL },
    { label: '自动同步', value: SyncMode.AUTO },
    { label: '后台同步', value: SyncMode.AUTO_BACKGROUND }
  ];
  @State conflictResolutionOptions: ConflictResolutionOption[] = [
    { label: '保留本地数据', value: ResolutionOption.USE_LOCAL },
    { label: '使用鸿蒙数据', value: ResolutionOption.USE_HEALTH },
    { label: '合并数据', value: ResolutionOption.MERGE_AVERAGE }
  ];
  private syncSettingsDao: SyncSettingsDao | null = null;

  async aboutToAppear() {
    await this.initializeServices();
    await this.loadSettings();
  }

  private async initializeServices() {
    try {
      const uiContext = this.getUIContext();
      if (!uiContext) {
        throw new Error('Context not available');
      }
      const abilityContext = resolveAbilityContext(uiContext);
      if (!abilityContext) {
        throw new Error('Unable to resolve ability context');
      }
      const dao = await (await import('../data/SyncSettingsDao')).getSyncSettingsDao(
        abilityContext
      );
      if (dao) {
        this.syncSettingsDao = dao;
      }
    } catch (e) {
      hilog.error(DOMAIN, TAG, `Failed to initialize services, cause: ${e}`);
    }
  }

  private async loadSettings() {
    try {
      if (this.syncSettingsDao) {
        this.settings = await this.syncSettingsDao.queryDefault();
        if (!this.settings) {
          this.settings = await this.syncSettingsDao.initializeDefaultSettings();
        }
      }
    } catch (e) {
      hilog.error(DOMAIN, TAG, `Failed to load settings, cause: ${e}`);
    }
  }

  private async saveSettings() {
    try {
      if (this.settings && this.syncSettingsDao) {
        await this.syncSettingsDao.save(this.settings);
        promptAction.showToast({ message: '设置已保存' });
        setTimeout(() => {
          try {
            router.back();
          } catch (e) {
            hilog.error(DOMAIN, TAG, `Failed to navigate back, cause: ${e}`);
          }
        }, 500);
      }
    } catch (e) {
      hilog.error(DOMAIN, TAG, `Failed to save settings, cause: ${e}`);
      promptAction.showToast({ message: '保存失败' });
    }
  }

  build() {
    Column({ space: 0 }) {
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

        Text('同步设置')
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
      .backgroundColor(Color.White)
      .shadow({ radius: 2, color: Color.Gray, offsetX: 0, offsetY: 1 })

      Scroll() {
        Column({ space: 16 }) {
          if (this.settings) {
            // 启用同步
            Column() {
              Row() {
                Column({ space: 4 }) {
                  Text('启用同步')
                    .fontSize(AppText.FONT_SIZE_BODY)
                    .fontWeight(FontWeight.Bold)
                  Text('允许应用与鸿蒙运动健康应用同步数据')
                    .fontSize(12)
                    .fontColor(AppColors.GRAY)
                }
                .layoutWeight(1)

                Toggle({ type: ToggleType.Switch, isOn: this.settings.syncEnabled })
                  .onChange((isOn: boolean) => {
                    this.settings!.syncEnabled = isOn;
                  })
              }
              .width('100%')
              .padding(AppDimensions.PADDING_MEDIUM)
              .alignItems(VerticalAlign.Center)
            }
            .width('90%')
            .backgroundColor(Color.White)
            .borderRadius(AppDimensions.BORDER_RADIUS)
            .shadow({ radius: 2, color: Color.Gray, offsetX: 0, offsetY: 1 })

            if (this.settings.syncEnabled) {
              // 同步模式
              Column({ space: 8 }) {
                Text('同步模式')
                  .fontSize(AppText.FONT_SIZE_BODY)
                  .fontWeight(FontWeight.Bold)
                  .padding({ left: 8 })

                ForEach(this.syncModeOptions, (option: SyncModeOption) => {
                  Row() {
                    Radio({ value: option.value, group: 'syncMode' })
                      .checked(this.settings!.syncMode === option.value)
                      .onChange((isChecked: boolean) => {
                        if (isChecked) {
                          this.settings!.syncMode = option.value;
                          this.settings!.autoSyncFrequency.enabled =
                            option.value !== SyncMode.MANUAL;
                        }
                      })

                    Column({ space: 2 }) {
                      Text(option.label)
                        .fontSize(AppText.FONT_SIZE_BODY)
                        .fontColor(Color.Black)

                      if (option.value === SyncMode.MANUAL) {
                        Text('每次需要手动点击同步按钮')
                          .fontSize(12)
                          .fontColor(AppColors.GRAY)
                      } else if (option.value === SyncMode.AUTO) {
                        Text('自动定期同步数据')
                          .fontSize(12)
                          .fontColor(AppColors.GRAY)
                      } else {
                        Text('在后台定期自动同步')
                          .fontSize(12)
                          .fontColor(AppColors.GRAY)
                      }
                    }
                    .layoutWeight(1)
                    .alignItems(HorizontalAlign.Start)
                    .margin({ left: 8 })
                  }
                  .width('100%')
                  .padding(12)
                  .alignItems(VerticalAlign.Center)
                })
              }
              .width('90%')
              .padding(AppDimensions.PADDING_MEDIUM)
              .backgroundColor(Color.White)
              .borderRadius(AppDimensions.BORDER_RADIUS)
              .shadow({ radius: 2, color: Color.Gray, offsetX: 0, offsetY: 1 })

              // 同步频率
              if (this.settings.syncMode !== SyncMode.MANUAL) {
                Column({ space: 8 }) {
                  Text('同步频率')
                    .fontSize(AppText.FONT_SIZE_BODY)
                    .fontWeight(FontWeight.Bold)
                    .padding({ left: 8 })

                  Row() {
                    Slider({
                      value: this.settings.autoSyncFrequency.intervalMinutes,
                      min: 5,
                      max: 240,
                      step: 5
                    })
                    .onChange((value: number) => {
                      this.settings!.autoSyncFrequency.intervalMinutes = value;
                    })
                    .layoutWeight(1)

                    Text(`${this.settings.autoSyncFrequency.intervalMinutes}分钟`)
                      .fontSize(AppText.FONT_SIZE_SMALL)
                      .fontColor(AppColors.PRIMARY)
                      .fontWeight(FontWeight.Bold)
                      .margin({ left: 12 })
                  }
                  .width('100%')
                  .padding({ left: 12, right: 12 })
                  .alignItems(VerticalAlign.Center)
                }
                .width('90%')
                .padding(AppDimensions.PADDING_MEDIUM)
                .backgroundColor(Color.White)
                .borderRadius(AppDimensions.BORDER_RADIUS)
                .shadow({ radius: 2, color: Color.Gray, offsetX: 0, offsetY: 1 })
              }

              // 应用启动时同步
              Column() {
                Row() {
                  Column({ space: 4 }) {
                    Text('应用启动时同步')
                      .fontSize(AppText.FONT_SIZE_BODY)
                      .fontWeight(FontWeight.Bold)
                    Text('应用启动时自动同步一次')
                      .fontSize(12)
                      .fontColor(AppColors.GRAY)
                  }
                  .layoutWeight(1)

                  Toggle({ type: ToggleType.Switch, isOn: this.settings.syncOnAppStart })
                    .onChange((isOn: boolean) => {
                      this.settings!.syncOnAppStart = isOn;
                    })
                }
                .width('100%')
                .padding(AppDimensions.PADDING_MEDIUM)
                .alignItems(VerticalAlign.Center)
              }
              .width('90%')
              .backgroundColor(Color.White)
              .borderRadius(AppDimensions.BORDER_RADIUS)
              .shadow({ radius: 2, color: Color.Gray, offsetX: 0, offsetY: 1 })

              // 冲突解决策略
              Column({ space: 8 }) {
                Text('冲突解决策略')
                  .fontSize(AppText.FONT_SIZE_BODY)
                  .fontWeight(FontWeight.Bold)
                  .padding({ left: 8 })

                Column() {
                  Text('当本地数据和鸿蒙数据冲突时，选择保留哪份数据')
                    .fontSize(12)
                    .fontColor(AppColors.GRAY)
                    .padding(12)
                }
                .width('100%')
                .backgroundColor(AppColors.BACKGROUND)
                .borderRadius(8)

                ForEach(
                  this.conflictResolutionOptions,
                  (option: ConflictResolutionOption) => {
                    Row() {
                      Radio({ value: option.value, group: 'conflict' })
                        .checked(this.settings!.conflictResolution === option.value)
                        .onChange((isChecked: boolean) => {
                          if (isChecked) {
                            this.settings!.conflictResolution = option.value;
                          }
                        })

                      Text(option.label)
                        .fontSize(AppText.FONT_SIZE_BODY)
                        .fontColor(Color.Black)
                        .layoutWeight(1)
                        .margin({ left: 8 })
                    }
                    .width('100%')
                    .padding(12)
                    .alignItems(VerticalAlign.Center)
                  }
                )
              }
              .width('90%')
              .padding(AppDimensions.PADDING_MEDIUM)
              .backgroundColor(Color.White)
              .borderRadius(AppDimensions.BORDER_RADIUS)
              .shadow({ radius: 2, color: Color.Gray, offsetX: 0, offsetY: 1 })

              // 高级选项
              Column({ space: 8 }) {
                Text('高级选项')
                  .fontSize(AppText.FONT_SIZE_BODY)
                  .fontWeight(FontWeight.Bold)
                  .padding({ left: 8 })

                Row() {
                  Column({ space: 4 }) {
                    Text('最大重试次数')
                      .fontSize(AppText.FONT_SIZE_SMALL)
                      .fontColor(AppColors.GRAY)
                  }
                  .layoutWeight(1)

                  Row({ space: 8 }) {
                    Button('-')
                      .width(36)
                      .height(36)
                      .fontSize(16)
                      .fontColor(AppColors.PRIMARY)
                      .backgroundColor(AppColors.BACKGROUND)
                      .border({ width: 1, color: AppColors.PRIMARY, radius: 6 })
                      .onClick(() => {
                        if (this.settings && this.settings.maxSyncRetries > 0) {
                          this.settings.maxSyncRetries--;
                        }
                      })

                    Text(`${this.settings.maxSyncRetries}`)
                      .fontSize(16)
                      .fontColor(Color.Black)
                      .width(40)
                      .textAlign(TextAlign.Center)

                    Button('+')
                      .width(36)
                      .height(36)
                      .fontSize(16)
                      .fontColor(AppColors.PRIMARY)
                      .backgroundColor(AppColors.BACKGROUND)
                      .border({ width: 1, color: AppColors.PRIMARY, radius: 6 })
                      .onClick(() => {
                        if (this.settings && this.settings.maxSyncRetries < 10) {
                          this.settings.maxSyncRetries++;
                        }
                      })
                  }
                }
                .width('100%')
                .padding(12)
                .alignItems(VerticalAlign.Center)
                .justifyContent(FlexAlign.SpaceBetween)

                Divider()

                Row() {
                  Column({ space: 4 }) {
                    Text('请求超时时间')
                      .fontSize(AppText.FONT_SIZE_SMALL)
                      .fontColor(AppColors.GRAY)
                  }
                  .layoutWeight(1)

                  Text(`${this.settings.requestTimeout / 1000}秒`)
                    .fontSize(14)
                    .fontColor(Color.Black)
                }
                .width('100%')
                .padding(12)
                .alignItems(VerticalAlign.Center)
                .justifyContent(FlexAlign.SpaceBetween)
              }
              .width('90%')
              .padding(AppDimensions.PADDING_MEDIUM)
              .backgroundColor(Color.White)
              .borderRadius(AppDimensions.BORDER_RADIUS)
              .shadow({ radius: 2, color: Color.Gray, offsetX: 0, offsetY: 1 })
            }
          }
        }
        .width('100%')
        .alignItems(HorizontalAlign.Center)
        .padding({ top: 16, bottom: 20 })
      }
      .layoutWeight(1)

      // 底部按钮
      Row({ space: 12 }) {
        Button('取消')
          .layoutWeight(1)
          .height(44)
          .fontSize(AppText.FONT_SIZE_BODY)
          .fontColor(AppColors.PRIMARY)
          .backgroundColor(Color.White)
          .border({ width: 1, color: AppColors.PRIMARY, radius: 8 })
          .onClick(() => {
            try {
              router.back();
            } catch (e) {
              hilog.error(DOMAIN, TAG, `Failed to navigate back, cause: ${e}`);
            }
          })

        Button('保存')
          .layoutWeight(1)
          .height(44)
          .fontSize(AppText.FONT_SIZE_BODY)
          .fontColor(Color.White)
          .backgroundColor(AppColors.PRIMARY)
          .onClick(() => {
            this.saveSettings();
          })
      }
      .width('90%')
      .padding({ left: 16, right: 16, bottom: 16 })
    }
    .width('100%')
    .height('100%')
    .backgroundColor(AppColors.BACKGROUND)
  }
}
