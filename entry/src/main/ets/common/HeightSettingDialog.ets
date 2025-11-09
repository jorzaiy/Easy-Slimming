/**
 * 身高设置对话框组件
 */
import { StatisticsService } from '../data/StatisticsService';
import { AppColors, AppDimensions, AppText } from './Constants';
import { common } from '@kit.AbilityKit';
import { getComponentContext } from './ContextUtils';
import promptAction from '@ohos.promptAction';

@Component
export struct HeightSettingDialog {
  @Prop isVisible: boolean;
  @Prop currentHeight: number;
  @Prop onHeightChange: (height: number) => void;
  @Prop onDismiss: () => void;

  @State inputHeight: string = '';
  @State isSaving: boolean = false;

  aboutToAppear() {
    this.inputHeight = this.currentHeight.toString();
  }

  async saveHeight() {
    const height: number = parseFloat(this.inputHeight);
    
    if (isNaN(height) || height < 100 || height > 250) {
      promptAction.showToast({
        message: '请输入有效的身高（100-250cm）',
        duration: 2000
      });
      return;
    }

    const abilityContext = getComponentContext(this);
    if (!abilityContext) {
      promptAction.showToast({
        message: '保存失败，请重试',
        duration: 2000
      });
      return;
    }

    this.isSaving = true;
    try {
      await StatisticsService.saveUserHeight(abilityContext, height);
      this.onHeightChange(height);
      this.onDismiss();
      promptAction.showToast({
        message: `身高已更新为 ${height}cm`,
        duration: 2000
      });
    } catch (e) {
      promptAction.showToast({
        message: '保存失败',
        duration: 2000
      });
    } finally {
      this.isSaving = false;
    }
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
          Text('设置身高')
            .fontSize(AppText.FONT_SIZE_TITLE)
            .fontWeight(FontWeight.Bold)
            .width('100%')
            .textAlign(TextAlign.Center)

          // 输入区域
          Column({ space: AppDimensions.MARGIN_SMALL }) {
            Text('请输入您的身高（厘米）')
              .fontSize(AppText.FONT_SIZE_BODY)
              .fontColor(AppColors.GRAY)

            Row({ space: 10 }) {
              TextInput({ placeholder: '身高' })
                .width('60%')
                .height(50)
                .fontSize(AppText.FONT_SIZE_BODY)
                .backgroundColor(AppColors.WHITE)
                .borderRadius(AppDimensions.BORDER_RADIUS_SMALL)
                .border({ width: 1, color: AppColors.BORDER_GRAY })
                .type(InputType.Number)
                .textAlign(TextAlign.Center)
                .onChange((value: string) => {
                  this.inputHeight = value;
                })

              Text('cm')
                .fontSize(AppText.FONT_SIZE_BODY)
                .fontColor(AppColors.GRAY)
                .margin({ left: 10 })
            }
            .width('100%')
            .justifyContent(FlexAlign.Center)
          }
          .width('100%')

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
              .enabled(!this.isSaving)
              .onClick(() => {
                this.saveHeight();
              })
          }
          .width('100%')
        }
        .width('80%')
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
