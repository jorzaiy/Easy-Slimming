/**
 * 目标体重设置对话框组件
 */
import { getTargetWeightService, TargetWeightRecord } from '../data/TargetWeightService';
import { AppColors, AppDimensions, AppText } from './Constants';
import { common } from '@kit.AbilityKit';
import { resolveAbilityContext } from './ContextUtils';
import promptAction from '@ohos.promptAction';
import hilog from '@ohos.hilog';
import { LogConstants } from './Constants';

const DOMAIN = LogConstants.DOMAIN;
const TAG = LogConstants.TAG_PREFIX + 'TargetWeightDialog';

@Component
export struct TargetWeightSettingDialog {
  @Prop isVisible: boolean;
  @Prop currentTarget: TargetWeightRecord | null;
  @Prop onTargetChange: (target: TargetWeightRecord) => void;
  @Prop onDismiss: () => void;

  @State inputWeight: string = '';
  @State selectedTargetDate: Date = new Date();
  @State hasTargetDate: boolean = false;
  @State notes: string = '';
  @State isSaving: boolean = false;
  private scroller: Scroller = new Scroller();

  // 预设目标值
  private readonly presets: readonly number[] = [60, 65, 70, 75, 80];

  aboutToAppear() {
    if (this.currentTarget) {
      this.inputWeight = this.currentTarget.targetWeight.toString();
      if (this.currentTarget.targetDate) {
        this.hasTargetDate = true;
        this.selectedTargetDate = new Date(this.currentTarget.targetDate);
      }
      this.notes = this.currentTarget.notes || '';
    }
  }

  private validateWeight(weight: string): boolean {
    const w = parseFloat(weight);
    return !isNaN(w) && w > 0 && w < 200;
  }

  private getWeightError(): string {
    if (!this.inputWeight) {
      return '请输入目标体重';
    }
    if (!this.validateWeight(this.inputWeight)) {
      return '目标体重应在 0-200 kg 之间';
    }
    return '';
  }

  private async saveTarget() {
    const error = this.getWeightError();
    if (error) {
      promptAction.showToast({
        message: error,
        duration: 2000
      });
      return;
    }

    const uiContext = this.getUIContext();
    if (!uiContext) {
      promptAction.showToast({
        message: '保存失败，请重试',
        duration: 2000
      });
      return;
    }

    const abilityContext = resolveAbilityContext(uiContext);
    if (!abilityContext) {
      promptAction.showToast({
        message: '保存失败，请重试',
        duration: 2000
      });
      return;
    }

    this.isSaving = true;
    try {
      const service = await getTargetWeightService(abilityContext);
      if (!service) {
        throw new Error('Service not initialized');
      }

      const weight = parseFloat(this.inputWeight);
      const targetDate = this.hasTargetDate ? this.selectedTargetDate.getTime() : undefined;

      const success = await service.setTargetWeight(weight, targetDate, this.notes);
      if (success) {
        const target = await service.getCurrentTarget();
        if (target) {
          this.onTargetChange(target);
          this.onDismiss();
          promptAction.showToast({
            message: `目标已设置为 ${weight.toFixed(1)} kg`,
            duration: 2000
          });
          hilog.info(DOMAIN, TAG, `Target weight set to ${weight}`);
        }
      } else {
        throw new Error('Failed to save target weight');
      }
    } catch (e) {
      hilog.error(DOMAIN, TAG, `Failed to save target: ${e}`);
      promptAction.showToast({
        message: '保存失败，请重试',
        duration: 2000
      });
    } finally {
      this.isSaving = false;
    }
  }

  private selectPreset(weight: number) {
    this.inputWeight = weight.toString();
  }

  build() {
    if (this.isVisible) {
      Stack() {
        // 遮罩层
        Column()
          .width('100%')
          .height('100%')
          .backgroundColor('rgba(0, 0, 0, 0.5)')
          .onClick(() => {
            this.onDismiss();
          })

        // 对话框内容
        Column({ space: AppDimensions.MARGIN_MEDIUM }) {
          // 标题
          Text('设置目标体重')
            .fontSize(AppText.FONT_SIZE_TITLE)
            .fontWeight(FontWeight.Bold)
            .width('100%')
            .textAlign(TextAlign.Center)

          // 内容区
          Scroll(this.scroller) {
           Column({ space: AppDimensions.MARGIN_MEDIUM }) {
              // 预设目标值
              Column({ space: AppDimensions.MARGIN_SMALL }) {
                Text('快速选择')
                  .fontSize(AppText.FONT_SIZE_SMALL)
                  .fontColor(AppColors.GRAY)
                  .fontWeight(FontWeight.Medium)

                Grid() {
                   ForEach(this.presets, (preset: number) => {
                     GridItem() {
                       Text(preset.toString())
                         .width('100%')
                         .height(45)
                         .fontSize(AppText.FONT_SIZE_BODY)
                         .textAlign(TextAlign.Center)
                         .borderRadius(8)
                         .backgroundColor(
                           this.inputWeight === preset.toString()
                             ? AppColors.PRIMARY
                             : AppColors.BACKGROUND
                         )
                         .fontColor(
                           this.inputWeight === preset.toString()
                             ? AppColors.WHITE
                             : AppColors.GRAY
                         )
                         .onClick(() => {
                           this.selectPreset(preset);
                         })
                     }
                   })
                 }
                 .columnsTemplate('1fr 1fr 1fr 1fr 1fr')
                 .width('100%')
                 .columnsGap(8)
              }
              .width('100%')

              // 目标体重输入
              Column({ space: AppDimensions.MARGIN_SMALL }) {
                Text('目标体重（kg）')
                  .fontSize(AppText.FONT_SIZE_SMALL)
                  .fontColor(AppColors.GRAY)
                  .fontWeight(FontWeight.Medium)

                TextInput({ placeholder: '请输入目标体重', text: this.inputWeight })
                   .width('100%')
                   .height(50)
                   .fontSize(AppText.FONT_SIZE_BODY)
                   .backgroundColor(AppColors.WHITE)
                   .borderRadius(AppDimensions.BORDER_RADIUS_SMALL)
                   .border({ width: 1, color: AppColors.BORDER_GRAY })
                   .type(InputType.Number)
                   .onChange((value: string) => {
                     this.inputWeight = value;
                   })

                if (this.getWeightError()) {
                  Text(this.getWeightError())
                    .fontSize(AppText.FONT_SIZE_TINY)
                    .fontColor(AppColors.ERROR)
                }
              }
              .width('100%')

              // 目标日期
              Column({ space: AppDimensions.MARGIN_SMALL }) {
                Row() {
                  Checkbox({ name: 'targetDate', group: 'targetDateGroup' })
                    .width(24)
                    .height(24)
                    .select(this.hasTargetDate)
                    .onChange((value: boolean) => {
                      this.hasTargetDate = value;
                    })

                  Text('设置目标完成日期（可选）')
                    .fontSize(AppText.FONT_SIZE_SMALL)
                    .fontColor(AppColors.GRAY)
                    .margin({ left: 10 })
                    .layoutWeight(1)
                }
                .width('100%')

                if (this.hasTargetDate) {
                  DatePicker({
                    start: new Date(),
                    end: new Date(new Date().getFullYear() + 5, 11, 31),
                    selected: this.selectedTargetDate
                  })
                    .lunar(false)
                    .onChange((value: DatePickerResult) => {
                      if (
                        value &&
                        value.year !== undefined &&
                        value.month !== undefined &&
                        value.day !== undefined
                      ) {
                        this.selectedTargetDate = new Date(value.year, value.month, value.day);
                      }
                    })
                }
              }
              .width('100%')

              // 备注
              Column({ space: AppDimensions.MARGIN_SMALL }) {
                Text('备注（可选）')
                  .fontSize(AppText.FONT_SIZE_SMALL)
                  .fontColor(AppColors.GRAY)
                  .fontWeight(FontWeight.Medium)

                TextArea({ placeholder: '输入相关备注信息', text: this.notes })
                   .width('100%')
                   .height(80)
                   .fontSize(AppText.FONT_SIZE_SMALL)
                   .backgroundColor(AppColors.WHITE)
                   .borderRadius(AppDimensions.BORDER_RADIUS_SMALL)
                   .border({ width: 1, color: AppColors.BORDER_GRAY })
                   .onChange((value: string) => {
                     this.notes = value;
                   })

                Text(`${this.notes.length}/200`)
                  .fontSize(AppText.FONT_SIZE_TINY)
                  .fontColor(AppColors.GRAY)
                  .width('100%')
                  .textAlign(TextAlign.End)
              }
              .width('100%')
            }
          }
          .width('100%')
          .layoutWeight(1)

          // 按钮区域
          Row({ space: AppDimensions.MARGIN_MEDIUM }) {
            Button('取消')
              .type(ButtonType.Normal)
              .layoutWeight(1)
              .height(45)
              .fontSize(AppText.FONT_SIZE_BODY)
              .backgroundColor(AppColors.WHITE)
              .fontColor(AppColors.GRAY)
              .border({ width: 1, color: AppColors.BORDER_GRAY, radius: AppDimensions.BORDER_RADIUS_SMALL })
              .onClick(() => {
                this.onDismiss();
              })

            Button(this.isSaving ? '保存中...' : '保存')
              .type(ButtonType.Capsule)
              .layoutWeight(1)
              .height(45)
              .fontSize(AppText.FONT_SIZE_BODY)
              .backgroundColor(AppColors.PRIMARY)
              .enabled(!this.isSaving && !this.getWeightError())
              .onClick(() => {
                this.saveTarget();
              })
          }
          .width('100%')
        }
        .width('85%')
        .height('90%')
        .backgroundColor(AppColors.WHITE)
        .borderRadius(AppDimensions.BORDER_RADIUS)
        .padding(AppDimensions.PADDING_LARGE)
        .shadow({
          radius: 16,
          color: '#40000000',
          offsetX: 0,
          offsetY: 4
        })
      }
      .width('100%')
      .height('100%')
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)
    }
  }
}
