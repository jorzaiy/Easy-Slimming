/**
 * 目标体重管理页面
 * 支持查看、编辑和管理多个目标体重记录
 */
import hilog from '@ohos.hilog';
import router from '@ohos.router';
import { getTargetWeightService, TargetWeightRecord } from '../data/TargetWeightService';
import { AppColors, AppDimensions, AppText, LogConstants } from '../common/Constants';
import { NavigationHelper } from '../common/NavigationHelper';
import { TargetWeightSettingDialog } from '../common/TargetWeightSettingDialog';
import promptAction from '@ohos.promptAction';
import { common } from '@kit.AbilityKit';
import { resolveAbilityContext } from '../common/ContextUtils';

const DOMAIN = LogConstants.DOMAIN;
const TAG = LogConstants.TAG_PREFIX + 'TargetManagement';

@Entry
@Component
struct TargetWeightManagement {
  @State targetHistory: TargetWeightRecord[] = [];
  @State currentTarget: TargetWeightRecord | null = null;
  @State showDialog: boolean = false;
  @State isLoading: boolean = true;
  private scroller: Scroller = new Scroller();

  async aboutToAppear() {
    await this.loadTargets();
  }

  onPageShow() {
    this.loadTargets();
  }

  async loadTargets() {
    try {
      const uiContext = this.getUIContext();
      if (!uiContext) {
        return;
      }
      const abilityContext = resolveAbilityContext(uiContext);
      if (!abilityContext) {
        return;
      }
      const service = await getTargetWeightService(abilityContext);
      if (service) {
        this.targetHistory = await service.getTargetWeightHistory(20);
        this.currentTarget = this.targetHistory.length > 0 ? this.targetHistory[0] : null;
        hilog.info(DOMAIN, TAG, `Loaded ${this.targetHistory.length} target records`);
      }
    } catch (e) {
      hilog.error(DOMAIN, TAG, `Failed to load targets: ${e}`);
      promptAction.showToast({
        message: '加载目标数据失败',
        duration: 2000
      });
    } finally {
      this.isLoading = false;
    }
  }

  formatDate(timestamp: number): string {
    const date = new Date(timestamp);
    const year = date.getFullYear();
    const month = (date.getMonth() + 1).toString().padStart(2, '0');
    const day = date.getDate().toString().padStart(2, '0');
    return `${year}/${month}/${day}`;
  }

  formatDateTime(timestamp: number): string {
    const date = new Date(timestamp);
    const year = date.getFullYear();
    const month = (date.getMonth() + 1).toString().padStart(2, '0');
    const day = date.getDate().toString().padStart(2, '0');
    const hour = date.getHours().toString().padStart(2, '0');
    const minute = date.getMinutes().toString().padStart(2, '0');
    return `${year}/${month}/${day} ${hour}:${minute}`;
  }

  async deleteTarget(id: number) {
    try {
      promptAction.showDialog({
        title: '删除目标',
        message: '确定要删除这个目标记录吗？',
        buttons: [
          { text: '取消', color: AppColors.GRAY },
          { text: '删除', color: AppColors.ERROR }
        ]
      }).then(async (data) => {
        if (data.index === 1) {
          const context = this.getUIContext();
          if (!context) {
            return;
          }
          const service = await getTargetWeightService(context as unknown as common.Context);
          if (service) {
            const success = await service.deleteTargetWeight(id);
            if (success) {
              promptAction.showToast({
                message: '目标已删除',
                duration: 2000
              });
              await this.loadTargets();
            }
          }
        }
      });
    } catch (e) {
      hilog.error(DOMAIN, TAG, `Failed to delete target: ${e}`);
      promptAction.showToast({
        message: '删除失败',
        duration: 2000
      });
    }
  }

  onTargetChange(target: TargetWeightRecord) {
    this.currentTarget = target;
    this.loadTargets();
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
          Text('目标体重管理')
            .fontSize(AppText.FONT_SIZE_TITLE)
            .fontWeight(FontWeight.Bold)
            .layoutWeight(1)
            .textAlign(TextAlign.Center)
            .margin({ right: AppDimensions.ICON_SIZE })
        }
        .width('100%')
        .padding(AppDimensions.PADDING_MEDIUM)
        .backgroundColor(AppColors.WHITE)
        .shadow({ radius: 3, color: Color.Gray, offsetX: 0, offsetY: 2 })

        if (this.isLoading) {
          Column()
            .width('100%')
            .layoutWeight(1)
            .justifyContent(FlexAlign.Center)
            .alignItems(HorizontalAlign.Center)

          Text('加载中...')
            .fontSize(AppText.FONT_SIZE_BODY)
            .fontColor(AppColors.GRAY)
        } else if (this.targetHistory.length === 0) {
          Column()
            .width('100%')
            .layoutWeight(1)
            .justifyContent(FlexAlign.Center)
            .alignItems(HorizontalAlign.Center)

          Text('暂无目标记录')
            .fontSize(AppText.FONT_SIZE_BODY)
            .fontColor(AppColors.GRAY)
        } else {
          Scroll(this.scroller) {
            Column({ space: AppDimensions.MARGIN_MEDIUM }) {
              // 当前目标卡片
              if (this.currentTarget) {
                Column({ space: AppDimensions.MARGIN_SMALL }) {
                  Row() {
                    Column() {
                      Text('当前目标')
                        .fontSize(AppText.FONT_SIZE_SMALL)
                        .fontColor(AppColors.GRAY)
                      Text(`${this.currentTarget.targetWeight.toFixed(1)} kg`)
                        .fontSize(AppText.FONT_SIZE_SUBTITLE)
                        .fontWeight(FontWeight.Bold)
                        .fontColor(AppColors.PRIMARY)
                    }
                    .layoutWeight(1)
                    .alignItems(HorizontalAlign.Start)

                    Button('编辑')
                      .type(ButtonType.Normal)
                      .height(36)
                      .fontSize(AppText.FONT_SIZE_SMALL)
                      .backgroundColor(AppColors.PRIMARY)
                      .fontColor(AppColors.WHITE)
                      .border({ width: 1, color: AppColors.PRIMARY, radius: 8 })
                      .onClick(() => {
                        this.showDialog = true;
                      })
                  }
                  .width('100%')
                  .justifyContent(FlexAlign.SpaceBetween)
                  .alignItems(VerticalAlign.Center)

                  if (this.currentTarget.targetDate) {
                    Row() {
                      Text('目标日期')
                        .fontSize(AppText.FONT_SIZE_SMALL)
                        .fontColor(AppColors.GRAY)
                      Text(this.formatDate(this.currentTarget.targetDate))
                        .fontSize(AppText.FONT_SIZE_SMALL)
                        .fontColor(AppColors.GRAY)
                    }
                    .width('100%')
                    .justifyContent(FlexAlign.SpaceBetween)
                  }

                  if (this.currentTarget.notes) {
                    Text(this.currentTarget.notes)
                      .fontSize(AppText.FONT_SIZE_TINY)
                      .fontColor(AppColors.GRAY)
                      .maxLines(2)
                      .textOverflow({ overflow: TextOverflow.Ellipsis })
                  }

                  Text(`设置于: ${this.formatDateTime(this.currentTarget.setDate)}`)
                    .fontSize(AppText.FONT_SIZE_TINY)
                    .fontColor(AppColors.LIGHT_GRAY)
                }
                .width('100%')
                .padding(AppDimensions.PADDING_LARGE)
                .backgroundColor(AppColors.WHITE)
                .borderRadius(AppDimensions.BORDER_RADIUS)
                .shadow({ radius: 3, color: Color.Gray, offsetX: 0, offsetY: 1 })
              }

              // 历史记录标题
              if (this.targetHistory.length > 1) {
                Text('历史目标')
                  .fontSize(AppText.FONT_SIZE_BODY)
                  .fontWeight(FontWeight.Bold)
                  .margin({ top: AppDimensions.MARGIN_LARGE })
              }

              // 历史目标列表
              ForEach(this.targetHistory.slice(), (target: TargetWeightRecord, index: number) => {
                if (index > 0) {
                  Column({ space: AppDimensions.MARGIN_SMALL }) {
                    Row() {
                      Text(`${target.targetWeight.toFixed(1)} kg`)
                        .fontSize(AppText.FONT_SIZE_BODY)
                        .fontWeight(FontWeight.Bold)
                        .fontColor(AppColors.GRAY)

                      Button('删除')
                        .type(ButtonType.Normal)
                        .height(32)
                        .fontSize(AppText.FONT_SIZE_TINY)
                        .backgroundColor(AppColors.WHITE)
                        .fontColor(AppColors.ERROR)
                        .border({ width: 1, color: AppColors.ERROR, radius: 6 })
                        .onClick(() => {
                          this.deleteTarget(target.id);
                        })
                    }
                    .width('100%')
                    .justifyContent(FlexAlign.SpaceBetween)
                    .alignItems(VerticalAlign.Center)

                    if (target.targetDate) {
                      Text(`目标日期: ${this.formatDate(target.targetDate)}`)
                        .fontSize(AppText.FONT_SIZE_TINY)
                        .fontColor(AppColors.GRAY)
                    }

                    Text(`设置于: ${this.formatDateTime(target.setDate)}`)
                      .fontSize(AppText.FONT_SIZE_TINY)
                      .fontColor(AppColors.LIGHT_GRAY)
                  }
                  .width('100%')
                  .padding(AppDimensions.PADDING_LARGE)
                  .backgroundColor(AppColors.WHITE)
                  .borderRadius(AppDimensions.BORDER_RADIUS)
                  .shadow({ radius: 2, color: Color.Gray, offsetX: 0, offsetY: 1 })
                }
              })
            }
            .padding(AppDimensions.PADDING_LARGE)
            .width('100%')
          }
          .layoutWeight(1)
        }

        // 设置新目标按钮
        Button('设置新目标')
          .type(ButtonType.Capsule)
          .width('90%')
          .height(AppDimensions.BUTTON_HEIGHT)
          .fontSize(AppText.FONT_SIZE_BODY)
          .backgroundColor(AppColors.PRIMARY)
          .margin({ bottom: AppDimensions.MARGIN_MEDIUM })
          .onClick(() => {
            this.showDialog = true;
          })
      }
      .width('100%')
      .height('100%')
      .backgroundColor(AppColors.BACKGROUND)

      // 目标体重设置对话框
      TargetWeightSettingDialog({
        isVisible: this.showDialog,
        currentTarget: this.currentTarget,
        onTargetChange: (target: TargetWeightRecord) => {
          this.onTargetChange(target);
        },
        onDismiss: () => {
          this.showDialog = false;
        }
      })
    }
    .width('100%')
    .height('100%')
  }
}
