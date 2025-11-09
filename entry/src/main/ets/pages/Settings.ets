/**
 * 设置中心页面
 * 集中管理所有应用设置和快捷操作
 */

import hilog from '@ohos.hilog';
import router from '@ohos.router';
import { WeightRecord } from '../model/WeightRecord';
import { AppColors, AppDimensions, AppText, LogConstants } from '../common/Constants';
import promptAction from '@ohos.promptAction';
import { getTargetWeightService, TargetWeightRecord } from '../data/TargetWeightService';
import { TargetWeightSettingDialog } from '../common/TargetWeightSettingDialog';
import { getComponentContext } from '../common/ContextUtils';
import { NavigationHelper } from '../common/NavigationHelper';

const DOMAIN = LogConstants.DOMAIN;
const TAG = LogConstants.TAG_PREFIX + 'Settings';

@Entry
@Component
struct Settings {
  @State currentTarget: TargetWeightRecord | null = null;
  @State showTargetDialog: boolean = false;

  @Watch('onTargetLinkChanged')
  @Provide currentTargetLink: TargetWeightRecord | null = null;

  onTargetLinkChanged() {
    this.currentTarget = this.currentTargetLink;
    if (this.currentTargetLink) {
      WeightRecord.setTargetWeight(this.currentTargetLink.targetWeight);
    }
  }

  async aboutToAppear() {
    await this.loadTargetWeight();
  }

  onPageShow() {
    this.loadTargetWeight();
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

  build() {
    Stack() {
      Column() {
        // 顶部栏
        Row() {
          Image($r('app.media.ic_back'))
            .width(AppDimensions.ICON_SIZE)
            .height(AppDimensions.ICON_SIZE)
            .onClick(() => {
              NavigationHelper.navigateBack();
            })
          Text('设置')
            .fontSize(AppText.FONT_SIZE_TITLE)
            .fontWeight(FontWeight.Bold)
            .layoutWeight(1)
            .textAlign(TextAlign.Center)
            .margin({ right: AppDimensions.ICON_SIZE })
        }
        .width('100%')
        .padding(AppDimensions.PADDING_MEDIUM)
        .backgroundColor(AppColors.WHITE)
        .shadow({
          radius: 3,
          color: Color.Gray,
          offsetX: 0,
          offsetY: 2
        })

        Scroll() {
          Column({ space: AppDimensions.MARGIN_LARGE }) {
            // 目标体重设置卡片
            Column({ space: AppDimensions.MARGIN_SMALL }) {
              Text('目标管理')
                .fontSize(AppText.FONT_SIZE_SUBTITLE)
                .fontWeight(FontWeight.Bold)
                .width('100%')

              if (this.currentTarget) {
                Column({ space: AppDimensions.MARGIN_SMALL }) {
                  Row() {
                    Column() {
                      Text('当前目标体重')
                        .fontSize(AppText.FONT_SIZE_SMALL)
                        .fontColor(AppColors.GRAY)
                      Text(`${this.currentTarget.targetWeight.toFixed(1)} kg`)
                        .fontSize(AppText.FONT_SIZE_SUBTITLE)
                        .fontWeight(FontWeight.Bold)
                        .fontColor(AppColors.PRIMARY)
                    }
                    .layoutWeight(1)
                    .alignItems(HorizontalAlign.Start)

                    Button('修改')
                      .type(ButtonType.Normal)
                      .height(36)
                      .fontSize(AppText.FONT_SIZE_SMALL)
                      .backgroundColor(AppColors.PRIMARY)
                      .fontColor(AppColors.WHITE)
                      .border({ width: 1, color: AppColors.PRIMARY, radius: 8 })
                      .onClick(() => {
                        this.showTargetDialog = true;
                      })
                  }
                  .width('100%')
                  .justifyContent(FlexAlign.SpaceBetween)
                  .alignItems(VerticalAlign.Center)
                }
                .width('100%')
                .padding(AppDimensions.PADDING_LARGE)
                .backgroundColor(AppColors.BACKGROUND)
                .borderRadius(AppDimensions.BORDER_RADIUS)
              } else {
                Button('设置目标体重')
                  .type(ButtonType.Normal)
                  .width('100%')
                  .height(50)
                  .fontSize(AppText.FONT_SIZE_BODY)
                  .backgroundColor(AppColors.WHITE)
                  .fontColor(AppColors.PRIMARY)
                  .border({ width: 1, color: AppColors.PRIMARY, radius: AppDimensions.BORDER_RADIUS })
                  .onClick(() => {
                    this.showTargetDialog = true;
                  })
              }

              Button('目标体重管理')
                .type(ButtonType.Normal)
                .width('100%')
                .height(50)
                .fontSize(AppText.FONT_SIZE_BODY)
                .backgroundColor(AppColors.WHITE)
                .fontColor(AppColors.PRIMARY)
                .border({ width: 1, color: AppColors.PRIMARY, radius: AppDimensions.BORDER_RADIUS })
                .onClick(() => {
                  try {
                    router.pushUrl({ url: 'pages/TargetWeightManagement' });
                  } catch (error) {
                    hilog.error(DOMAIN, TAG, `Failed to navigate to TargetWeightManagement, cause: ${error}`);
                  }
                })
            }
            .width('90%')
            .padding(AppDimensions.PADDING_LARGE)
            .backgroundColor(AppColors.WHITE)
            .borderRadius(AppDimensions.BORDER_RADIUS)
            .shadow({
              radius: 3,
              color: Color.Gray,
              offsetX: 0,
              offsetY: 1
            })

            // 数据管理卡片
            Column({ space: AppDimensions.MARGIN_SMALL }) {
              Text('数据管理')
                .fontSize(AppText.FONT_SIZE_SUBTITLE)
                .fontWeight(FontWeight.Bold)
                .width('100%')

              Text('导出和导入体重数据')
                .fontSize(AppText.FONT_SIZE_SMALL)
                .fontColor(AppColors.GRAY)
                .width('100%')

              Button('前往数据管理')
                .type(ButtonType.Normal)
                .width('100%')
                .height(50)
                .fontSize(AppText.FONT_SIZE_BODY)
                .backgroundColor(AppColors.WHITE)
                .fontColor(AppColors.PRIMARY)
                .border({ width: 1, color: AppColors.PRIMARY, radius: AppDimensions.BORDER_RADIUS })
                .onClick(() => {
                  try {
                    router.pushUrl({ url: 'pages/DataManagement' });
                  } catch (error) {
                    hilog.error(DOMAIN, TAG, `Failed to navigate to DataManagement, cause: ${error}`);
                  }
                })
            }
            .width('90%')
            .padding(AppDimensions.PADDING_LARGE)
            .backgroundColor(AppColors.WHITE)
            .borderRadius(AppDimensions.BORDER_RADIUS)
            .shadow({
              radius: 3,
              color: Color.Gray,
              offsetX: 0,
              offsetY: 1
            })

            // 健康同步卡片
            Column({ space: AppDimensions.MARGIN_SMALL }) {
              Text('数据同步')
                .fontSize(AppText.FONT_SIZE_SUBTITLE)
                .fontWeight(FontWeight.Bold)
                .width('100%')

              Text('与鸿蒙运动健康应用同步数据')
                .fontSize(AppText.FONT_SIZE_SMALL)
                .fontColor(AppColors.GRAY)
                .width('100%')

              Button('前往数据同步')
                .type(ButtonType.Normal)
                .width('100%')
                .height(50)
                .fontSize(AppText.FONT_SIZE_BODY)
                .backgroundColor(AppColors.WHITE)
                .fontColor(AppColors.PRIMARY)
                .border({ width: 1, color: AppColors.PRIMARY, radius: AppDimensions.BORDER_RADIUS })
                .onClick(() => {
                  try {
                    router.pushUrl({ url: 'pages/HealthSync' });
                  } catch (error) {
                    hilog.error(DOMAIN, TAG, `Failed to navigate to HealthSync, cause: ${error}`);
                  }
                })
            }
            .width('90%')
            .padding(AppDimensions.PADDING_LARGE)
            .backgroundColor(AppColors.WHITE)
            .borderRadius(AppDimensions.BORDER_RADIUS)
            .shadow({
              radius: 3,
              color: Color.Gray,
              offsetX: 0,
              offsetY: 1
            })
          }
          .width('100%')
          .padding({ top: AppDimensions.PADDING_MEDIUM, bottom: AppDimensions.PADDING_MEDIUM })
          .alignItems(HorizontalAlign.Center)
        }
        .layoutWeight(1)
      }
      .width('100%')
      .height('100%')
      .backgroundColor(AppColors.BACKGROUND)

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
