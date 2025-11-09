import hilog from '@ohos.hilog';
import router from '@ohos.router';
import { WeightRecord } from '../model/WeightRecord';
import { AppColors, AppDimensions, AppText, LogConstants } from '../common/Constants';
import promptAction from '@ohos.promptAction';
import { getAppDao } from '../common/Global';
import { getTargetWeightService, TargetWeightRecord } from '../data/TargetWeightService';
import { TargetWeightSettingDialog } from '../common/TargetWeightSettingDialog';
import { getComponentContext } from '../common/ContextUtils';

const DOMAIN = LogConstants.DOMAIN;
const TAG = LogConstants.TAG_PREFIX + 'Index';

@Entry
@Component
struct Index {
  @State latestRecord: WeightRecord | null = null;
  @State currentTarget: TargetWeightRecord | null = null;
  @State showTargetDialog: boolean = false;

  // 监听currentTargetLink的变化，同步更新currentTarget
  @Watch('onTargetLinkChanged')
  @Provide currentTargetLink: TargetWeightRecord | null = null;

  onTargetLinkChanged() {
    this.currentTarget = this.currentTargetLink;
    if (this.currentTargetLink) {
      WeightRecord.setTargetWeight(this.currentTargetLink.targetWeight);
    }
  }

  async aboutToAppear() {
    await this.loadLatestRecord();
    await this.loadTargetWeight();
  }

  onPageShow() {
    this.loadLatestRecord();
    this.loadTargetWeight();
  }

  formatDate(timestamp: number): string {
    const date = new Date(timestamp);
    const year = date.getFullYear();
    const month = (date.getMonth() + 1).toString().padStart(2, '0');
    const day = date.getDate().toString().padStart(2, '0');
    const hour = date.getHours().toString().padStart(2, '0');
    const minute = date.getMinutes().toString().padStart(2, '0');
    return `${year}/${month}/${day} ${hour}:${minute}`;
  }

  async loadLatestRecord() {
    try {
      const dao = getAppDao();
      if (!dao) {
        throw new Error('Global DAO not initialized');
      }
      const records = await dao.queryAll();
      if (records.length > 0) {
        this.latestRecord = records[0]; // 默认按日期降序，第一个就是最新的
        hilog.info(DOMAIN, TAG, 'Loaded latest record.');
      }
    } catch (e) {
      hilog.error(DOMAIN, TAG, `Failed to load latest record, cause: ${e}`);
    }
  }

  async loadTargetWeight() {
    try {
      const abilityContext = getComponentContext(this);
      if (!abilityContext) {
        hilog.error(DOMAIN, TAG, 'Failed to get ability context');
        return;
      }
      const service = await getTargetWeightService(abilityContext);
      if (service) {
        const target = await service.getCurrentTarget();
        this.currentTarget = target;
        this.currentTargetLink = target;
        hilog.info(DOMAIN, TAG, 'Loaded target weight.');
      }
    } catch (e) {
      hilog.error(DOMAIN, TAG, `Failed to load target weight, cause: ${e}`);
    }
  }

  calculateDifferenceFromTarget(): number {
    if (!this.latestRecord || !this.currentTarget) {
      return 0;
    }
    return this.latestRecord.weight - this.currentTarget.targetWeight;
  }

  getProgressPercentage(): number {
    if (!this.latestRecord || !this.currentTarget) {
      return 0;
    }
    const startWeight = this.latestRecord.weight;
    const targetWeight = this.currentTarget.targetWeight;
    
    if (startWeight <= targetWeight) {
      return 100;
    }
    
    // 假设初始体重为 100kg（示例，实际需要追踪）
    // 这里简化处理
    return Math.min(100, Math.max(0, ((startWeight - targetWeight) / startWeight) * 100));
  }

  build() {
    Stack() {
      Column() {
        Column() {
          Text('轻松减重')
            .fontSize(38)
            .fontWeight(FontWeight.Bold)
            .margin({ top: 40, bottom: 30 })

          Button('记录体重')
            .type(ButtonType.Capsule)
            .width('80%')
            .height(50)
            .fontSize(22)
            .fontWeight(FontWeight.Bold)
            .onClick(() => {
              try {
                router.pushUrl({ url: 'pages/WeightEntryForm' });
              } catch (error) {
                hilog.error(DOMAIN, TAG, `Failed to navigate to WeightEntryForm, cause: ${error}`);
              }
            })

          Button('查看历史')
            .type(ButtonType.Normal)
            .width('80%')
            .height(50)
            .fontSize(22)
            .fontWeight(FontWeight.Bold)
            .margin({ top: 20 })
            .backgroundColor(Color.White)
            .fontColor(Color.Black)
            .border({ width: 1, color: Color.Gray, radius: 25 })
            .onClick(() => {
              try {
                router.pushUrl({ url: 'pages/History' });
              } catch (error) {
                hilog.error(DOMAIN, TAG, `Failed to navigate to History, cause: ${error}`);
              }
            })

          Button('趋势图表')
            .type(ButtonType.Capsule)
            .width('80%')
            .height(50)
            .fontSize(22)
            .fontWeight(FontWeight.Bold)
            .margin({ top: 20 })
            .backgroundColor(Color.Blue)
            .onClick(() => {
              try {
                router.pushUrl({ url: 'pages/WeightChart' });
              } catch (error) {
                hilog.error(DOMAIN, TAG, `Failed to navigate to WeightChart, cause: ${error}`);
              }
            })

          Button('统计仪表板')
            .type(ButtonType.Capsule)
            .width('80%')
            .height(50)
            .fontSize(22)
            .fontWeight(FontWeight.Bold)
            .margin({ top: 20 })
            .backgroundColor(Color.Green)
            .onClick(() => {
              try {
                router.pushUrl({ url: 'pages/StatisticsDashboard' });
              } catch (error) {
                hilog.error(DOMAIN, TAG, `Failed to navigate to StatisticsDashboard, cause: ${error}`);
              }
            })

          Button('目标管理')
            .type(ButtonType.Normal)
            .width('80%')
            .height(50)
            .fontSize(22)
            .fontWeight(FontWeight.Bold)
            .margin({ top: 20 })
            .backgroundColor(Color.White)
            .fontColor(Color.Black)
            .border({ width: 1, color: Color.Gray, radius: 25 })
            .onClick(() => {
              try {
                router.pushUrl({ url: 'pages/TargetWeightManagement' });
              } catch (error) {
                hilog.error(DOMAIN, TAG, `Failed to navigate to TargetWeightManagement, cause: ${error}`);
              }
            })

          Button('数据管理')
            .type(ButtonType.Normal)
            .width('80%')
            .height(50)
            .fontSize(22)
            .fontWeight(FontWeight.Bold)
            .margin({ top: 20 })
            .backgroundColor(Color.White)
            .fontColor(Color.Black)
            .border({ width: 1, color: Color.Gray, radius: 25 })
            .onClick(() => {
              try {
                router.pushUrl({ url: 'pages/DataManagement' });
              } catch (error) {
                hilog.error(DOMAIN, TAG, `Failed to navigate to DataManagement, cause: ${error}`);
              }
            })

          Button('鸿蒙同步')
            .type(ButtonType.Normal)
            .width('80%')
            .height(50)
            .fontSize(22)
            .fontWeight(FontWeight.Bold)
            .margin({ top: 20 })
            .backgroundColor(Color.White)
            .fontColor(Color.Black)
            .border({ width: 1, color: Color.Gray, radius: 25 })
            .onClick(() => {
              try {
                router.pushUrl({ url: 'pages/HealthSync' });
              } catch (error) {
                hilog.error(DOMAIN, TAG, `Failed to navigate to HealthSync, cause: ${error}`);
              }
            })
          }

        // 目标体重卡片
        if (this.currentTarget) {
          Column({ space: AppDimensions.MARGIN_SMALL }) {
            Row() {
              Column() {
                Text('目标体重')
                  .fontSize(AppText.FONT_SIZE_SMALL)
                  .fontColor(AppColors.GRAY)
                Text(`${this.currentTarget.targetWeight.toFixed(1)} kg`)
                  .fontSize(AppText.FONT_SIZE_SUBTITLE)
                  .fontWeight(FontWeight.Bold)
                  .fontColor(AppColors.PRIMARY)
              }
              .layoutWeight(1)
              .alignItems(HorizontalAlign.Start)

              Button('设置')
                .type(ButtonType.Normal)
                .height(36)
                .fontSize(AppText.FONT_SIZE_SMALL)
                .backgroundColor(AppColors.WHITE)
                .fontColor(AppColors.PRIMARY)
                .border({ width: 1, color: AppColors.PRIMARY, radius: 8 })
                .onClick(() => {
                  this.showTargetDialog = true;
                })
            }
            .width('100%')
            .justifyContent(FlexAlign.SpaceBetween)
            .alignItems(VerticalAlign.Center)
            .margin({ bottom: AppDimensions.MARGIN_SMALL })

            if (this.latestRecord) {
              Row() {
                Text('差值')
                  .fontSize(AppText.FONT_SIZE_SMALL)
                  .fontColor(AppColors.GRAY)
                Text(
                  this.calculateDifferenceFromTarget() > 0
                    ? `+${this.calculateDifferenceFromTarget().toFixed(1)} kg`
                    : `${this.calculateDifferenceFromTarget().toFixed(1)} kg`
                )
                  .fontSize(AppText.FONT_SIZE_BODY)
                  .fontWeight(FontWeight.Bold)
                  .fontColor(
                    this.calculateDifferenceFromTarget() > 0 ? AppColors.WARNING : AppColors.SUCCESS
                  )
              }
              .width('100%')
              .justifyContent(FlexAlign.SpaceBetween)
            }
          }
          .width('90%')
          .padding(AppDimensions.PADDING_LARGE)
          .backgroundColor(AppColors.WHITE)
          .borderRadius(AppDimensions.BORDER_RADIUS)
          .margin({ top: AppDimensions.MARGIN_MEDIUM, bottom: AppDimensions.MARGIN_MEDIUM })
          .shadow({ radius: 3, color: Color.Gray, offsetX: 0, offsetY: 1 })
        } else {
          Button('设置目标体重')
            .type(ButtonType.Normal)
            .width('90%')
            .height(50)
            .fontSize(AppText.FONT_SIZE_BODY)
            .backgroundColor(AppColors.WHITE)
            .fontColor(AppColors.PRIMARY)
            .border({ width: 1, color: AppColors.PRIMARY, radius: AppDimensions.BORDER_RADIUS })
            .margin({ top: AppDimensions.MARGIN_MEDIUM })
            .onClick(() => {
              this.showTargetDialog = true;
            })
        }

        Divider()
          .margin({ top: 20, bottom: 20 })

        if (this.latestRecord) {
          Text(`最近体重: ${this.latestRecord.weight.toFixed(1)} kg`)
            .fontSize(24)
            .fontColor(Color.Gray)
          Text(`记录于: ${this.formatDate(this.latestRecord.date)}`)
            .fontSize(16)
            .margin({ top: 10 })
            .fontColor(Color.Gray)
        } else {
          Text('暂无记录')
            .fontSize(24)
            .fontColor(Color.Gray)
        }
      }
      .width('100%')
      .padding({ left: 20, right: 20 })
      .alignItems(HorizontalAlign.Center)

      // 目标体重设置对话框
      TargetWeightSettingDialog({
        isVisible: this.showTargetDialog,
        currentTarget: $currentTargetLink,
        dialogVisible: $showTargetDialog
      })
    }
    .width('100%')
    .height('100%')
  }
}