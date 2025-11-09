/**
 * 健康数据同步设置对话框
 * 用于配置与鸿蒙运动健康应用的同步设置
 */

import { SyncSettings, SyncMode } from '../model/SyncSettings';
import { ResolutionOption } from '../model/HealthSyncConflict';
import { AppColors, AppDimensions, AppText } from '../common/Constants';

interface SyncOption<T> {
  label: string;
  value: T;
}

type SyncModeOption = SyncOption<SyncMode>;
type ConflictResolutionOption = SyncOption<ResolutionOption>;

export interface HealthSyncSettingsDialogParams {
  isVisible: boolean;
  settings: SyncSettings | null;
  onSettingsChanged: (settings: SyncSettings) => void;
  onDismiss: () => void;
}

@Component
export struct HealthSyncSettingsDialog {
  @Link isVisible: boolean;
  @State settings: SyncSettings | null = null;
  @State syncModeOptions: SyncModeOption[] = [
    { label: '手动同步', value: SyncMode.MANUAL },
    { label: '自动同步', value: SyncMode.AUTO },
    { label: '后台自动同步', value: SyncMode.AUTO_BACKGROUND }
  ];
  @State conflictResolutionOptions: ConflictResolutionOption[] = [
    { label: '保留本地数据', value: ResolutionOption.USE_LOCAL },
    { label: '使用鸿蒙数据', value: ResolutionOption.USE_HEALTH },
    { label: '合并数据', value: ResolutionOption.MERGE_AVERAGE }
  ];
  onSettingsChanged: (settings: SyncSettings) => void = () => {};
  onDismiss: () => void = () => {};

  aboutToAppear() {
    if (this.settings === null) {
      // Initialize with default or passed settings
    }
  }

  build() {
    if (!this.isVisible) {
      EmptyComponent()
    } else {
      Blank()
        .width('100%')
        .height('100%')
        .backgroundColor('rgba(0, 0, 0, 0.5)')
        .onClick(() => {
          this.onDismiss();
        })
        .then((v: BlankAttribute) => {
          v.gestureMask(GestureMask.Normal);
        })

      Column() {
        Row() {
          Text('同步设置')
            .fontSize(AppText.FONT_SIZE_LARGE)
            .fontWeight(FontWeight.Bold)
            .layoutWeight(1)

          Text('✕')
            .fontSize(24)
            .fontColor(AppColors.GRAY)
            .onClick(() => {
              this.onDismiss();
            })
        }
        .width('100%')
        .padding(AppDimensions.PADDING_MEDIUM)
        .justifyContent(FlexAlign.SpaceBetween)

        Divider()

        Scroll() {
          Column({ space: AppDimensions.MARGIN_MEDIUM }) {
            // 启用同步
            Row() {
              Text('启用同步')
                .fontSize(AppText.FONT_SIZE_BODY)
              Spacer()
              Toggle({ type: ToggleType.Switch, isOn: this.settings?.syncEnabled || false })
                .onChange((isOn: boolean) => {
                  if (this.settings) {
                    this.settings.syncEnabled = isOn;
                    this.onSettingsChanged(this.settings);
                  }
                })
            }
            .width('100%')
            .padding(AppDimensions.PADDING_MEDIUM)

            if (this.settings?.syncEnabled) {
              // 同步模式
              Column({ space: AppDimensions.MARGIN_SMALL }) {
                Text('同步模式')
                  .fontSize(AppText.FONT_SIZE_BODY)
                  .fontColor(AppColors.GRAY)

                Row() {
                  ForEach(this.syncModeOptions, (option: { label: string; value: SyncMode }) => {
                    Column() {
                      Text(option.label)
                        .fontSize(AppText.FONT_SIZE_SMALL)
                        .fontColor(
                          this.settings?.syncMode === option.value
                            ? AppColors.PRIMARY
                            : AppColors.GRAY
                        )
                    }
                    .layoutWeight(1)
                    .padding(8)
                    .backgroundColor(
                      this.settings?.syncMode === option.value
                        ? AppColors.PRIMARY + '20'
                        : Color.White
                    )
                    .borderRadius(8)
                    .border({
                      width: 1,
                      color:
                        this.settings?.syncMode === option.value
                          ? AppColors.PRIMARY
                          : AppColors.GRAY
                    })
                    .onClick(() => {
                      if (this.settings) {
                        this.settings.syncMode = option.value;
                        this.settings.autoSyncFrequency.enabled =
                          option.value !== SyncMode.MANUAL;
                        this.onSettingsChanged(this.settings);
                      }
                    })
                  })
                }
                .width('100%')
                .gap(8)
              }
              .width('100%')
              .padding(AppDimensions.PADDING_MEDIUM)

              // 冲突解决策略
              Column({ space: AppDimensions.MARGIN_SMALL }) {
                Text('冲突解决策略')
                  .fontSize(AppText.FONT_SIZE_BODY)
                  .fontColor(AppColors.GRAY)

                ForEach(this.conflictResolutionOptions, (option: { label: string; value: string }) => {
                  Row() {
                    Radio({ value: option.value, group: 'conflict' })
                      .checked(this.settings?.conflictResolution === option.value)
                      .onChange((isChecked: boolean) => {
                        if (isChecked && this.settings) {
                          this.settings.conflictResolution =
                            option.value as 'LOCAL' | 'HEALTH' | 'MERGE';
                          this.onSettingsChanged(this.settings);
                        }
                      })

                    Text(option.label)
                      .fontSize(AppText.FONT_SIZE_BODY)
                      .layoutWeight(1)
                      .margin({ left: 8 })
                  }
                  .width('100%')
                  .alignItems(VerticalAlign.Center)
                })
              }
              .width('100%')
              .padding(AppDimensions.PADDING_MEDIUM)

              // 应用启动时同步
              Row() {
                Text('应用启动时同步')
                  .fontSize(AppText.FONT_SIZE_BODY)
                Spacer()
                Toggle({ type: ToggleType.Switch, isOn: this.settings?.syncOnAppStart || false })
                  .onChange((isOn: boolean) => {
                    if (this.settings) {
                      this.settings.syncOnAppStart = isOn;
                      this.onSettingsChanged(this.settings);
                    }
                  })
              }
              .width('100%')
              .padding(AppDimensions.PADDING_MEDIUM)

              // 最大重试次数
              Column({ space: AppDimensions.MARGIN_SMALL }) {
                Text('最大重试次数')
                  .fontSize(AppText.FONT_SIZE_BODY)
                  .fontColor(AppColors.GRAY)

                Row() {
                  Button('-')
                    .width(40)
                    .height(40)
                    .onClick(() => {
                      if (this.settings && this.settings.maxSyncRetries > 0) {
                        this.settings.maxSyncRetries--;
                        this.onSettingsChanged(this.settings);
                      }
                    })

                  Text(`${this.settings?.maxSyncRetries || 0}`)
                    .fontSize(AppText.FONT_SIZE_BODY)
                    .layoutWeight(1)
                    .textAlign(TextAlign.Center)

                  Button('+')
                    .width(40)
                    .height(40)
                    .onClick(() => {
                      if (this.settings) {
                        this.settings.maxSyncRetries++;
                        this.onSettingsChanged(this.settings);
                      }
                    })
                }
                .width('100%')
                .gap(8)
                .alignItems(VerticalAlign.Center)
              }
              .width('100%')
              .padding(AppDimensions.PADDING_MEDIUM)
            }
          }
          .width('100%')
        }
        .layoutWeight(1)
        .width('100%')

        Divider()

        Row() {
          Button('取消')
            .layoutWeight(1)
            .height(44)
            .fontSize(AppText.FONT_SIZE_BODY)
            .fontColor(AppColors.PRIMARY)
            .backgroundColor(Color.White)
            .border({ width: 1, color: AppColors.PRIMARY, radius: 8 })
            .onClick(() => {
              this.onDismiss();
            })

          Button('保存')
            .layoutWeight(1)
            .height(44)
            .fontSize(AppText.FONT_SIZE_BODY)
            .fontColor(Color.White)
            .backgroundColor(AppColors.PRIMARY)
            .margin({ left: 12 })
            .onClick(() => {
              if (this.settings) {
                this.onSettingsChanged(this.settings);
              }
              this.onDismiss();
            })
        }
        .width('100%')
        .padding(AppDimensions.PADDING_MEDIUM)
        .gap(12)
      }
      .width('85%')
      .backgroundColor(Color.White)
      .borderRadius(AppDimensions.BORDER_RADIUS)
      .padding(0)
      .modal(this.isVisible)
    }
  }
}

@Component
struct EmptyComponent {
  build() {
    Column() {
    }
  }
}
