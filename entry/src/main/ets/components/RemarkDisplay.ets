import { Remark } from '../model/Remark';
import { AppColors, AppDimensions, AppText } from '../common/Constants';

@Component
export struct RemarkDisplay {
  remarks: Remark[] = [];
  onEditRemark: (remark: Remark, index: number) => void = () => {};
  onDeleteRemark: (remarkId: number, index: number) => void = () => {};

  build() {
    Column() {
      if (this.remarks.length > 0) {
        ForEach(this.remarks, (remark: Remark, index?: number) => {
          Column() {
            // 备注头部：类型、时间戳
            Row() {
              Row() {
                Text(remark.getTypeIcon())
                  .fontSize(18)
                  .margin({ right: 6 })
                
                Text(remark.getTypeDisplayName())
                  .fontSize(AppText.FONT_SIZE_SMALL)
                  .fontWeight(FontWeight.Bold)
                  .fontColor(remark.getTypeColor())
              }

              Blank()

              Text(remark.getFormattedTimestamp())
                .fontSize(AppText.FONT_SIZE_TINY)
                .fontColor(AppColors.GRAY)
            }
            .width('100%')
            .margin({ bottom: AppDimensions.MARGIN_SMALL })
            .justifyContent(FlexAlign.SpaceBetween)

            // 备注内容
            Text(remark.content)
              .fontSize(AppText.FONT_SIZE_SMALL)
              .fontColor(AppColors.GRAY)
              .margin({ bottom: AppDimensions.MARGIN_SMALL })
              .width('100%')

            // 操作按钮
            Row() {
              Button('编辑')
                .type(ButtonType.Capsule)
                .height(AppDimensions.BUTTON_HEIGHT_SMALL)
                .fontSize(AppText.FONT_SIZE_TINY)
                .backgroundColor(AppColors.BLUE)
                .onClick(() => {
                  if (index !== undefined) {
                    this.onEditRemark(remark, index);
                  }
                })

              Blank().width(AppDimensions.MARGIN_SMALL)

              Button('删除')
                .type(ButtonType.Capsule)
                .height(AppDimensions.BUTTON_HEIGHT_SMALL)
                .fontSize(AppText.FONT_SIZE_TINY)
                .backgroundColor(AppColors.ERROR)
                .onClick(() => {
                  if (index !== undefined) {
                    this.onDeleteRemark(remark.id, index);
                  }
                })
            }
            .width('100%')
            .justifyContent(FlexAlign.End)
          }
          .width('100%')
          .padding(AppDimensions.PADDING_MEDIUM)
          .backgroundColor(AppColors.WHITE)
          .borderRadius(AppDimensions.BORDER_RADIUS)
          .border({ width: 1, color: remark.getTypeColor() + '40' })
          .margin({ bottom: AppDimensions.MARGIN_SMALL })
        })
      } else {
        // 无备注时的占位显示
        Column() {
          Text('📝')
            .fontSize(32)
            .fontColor(AppColors.LIGHT_GRAY)
            .margin({ bottom: AppDimensions.MARGIN_SMALL })

          Text('暂无备注')
            .fontSize(AppText.FONT_SIZE_SMALL)
            .fontColor(AppColors.GRAY)
        }
        .width('100%')
        .padding(AppDimensions.PADDING_LARGE)
        .backgroundColor(AppColors.WHITE)
        .borderRadius(AppDimensions.BORDER_RADIUS)
        .alignItems(HorizontalAlign.Center)
      }
    }
    .width('100%')
  }
}

// 备注摘要组件（用于列表中显示）
@Component
export struct RemarkSummary {
  remarks: Remark[] = [];
  maxDisplay: number = 3;

  build() {
    if (this.remarks.length > 0) {
      Row() {
        ForEach(this.remarks.slice(0, this.maxDisplay), (remark: Remark) => {
          Row() {
            Text(remark.getTypeIcon())
              .fontSize(14)
              .margin({ right: 2 })
            
            Text(remark.getTypeDisplayName())
              .fontSize(AppText.FONT_SIZE_TINY)
              .fontColor(remark.getTypeColor())
              .backgroundColor(remark.getTypeColor() + '20')
              .padding({ left: 4, right: 4, top: 1, bottom: 1 })
              .borderRadius(3)
          }
          .margin({ right: 4 })
        })

        if (this.remarks.length > this.maxDisplay) {
          Text(`+${this.remarks.length - this.maxDisplay}`)
            .fontSize(AppText.FONT_SIZE_TINY)
            .fontColor(AppColors.GRAY)
            .backgroundColor(AppColors.LIGHT_GRAY)
            .padding({ left: 4, right: 4, top: 1, bottom: 1 })
            .borderRadius(3)
        }
      }
      .margin({ top: 4 })
    }
  }
}