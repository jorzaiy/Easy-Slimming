import { Remark, RemarkType } from '../model/Remark';
import { AppColors, AppDimensions, AppText, BusinessConstants } from '../common/Constants';

@Component
export struct RemarkEntry {
  @State remarks: Remark[] = [];
  @State newRemarkType: RemarkType = RemarkType.OTHER;
  @State newRemarkContent: string = '';
  @State showTypeSelector: boolean = false;

  onRemarksChange: (remarks: Remark[]) => void = () => {};

  private addRemark() {
    if (!this.newRemarkContent.trim()) {
      return;
    }

    const newRemark = new Remark(
      0, // recordId will be set when saving to database
      this.newRemarkType,
      this.newRemarkContent.trim()
    );

    this.remarks.push(newRemark);
    this.newRemarkContent = '';
    this.newRemarkType = RemarkType.OTHER;
    this.onRemarksChange(this.remarks);
  }

  private removeRemark(index: number) {
    this.remarks.splice(index, 1);
    this.onRemarksChange(this.remarks);
  }

  private updateRemark(index: number, remark: Remark) {
    this.remarks[index] = remark;
    this.onRemarksChange(this.remarks);
  }

  build() {
    Column() {
      // 类型选择器
      Row() {
        Text('备注类型')
          .fontSize(AppText.FONT_SIZE_SMALL)
          .fontWeight(FontWeight.Medium)
          .margin({ right: AppDimensions.MARGIN_SMALL })

        Button(this.getTypeDisplayName(this.newRemarkType))
          .type(ButtonType.Capsule)
          .height(AppDimensions.BUTTON_HEIGHT_SMALL)
          .fontSize(AppText.FONT_SIZE_SMALL)
          .backgroundColor(this.getTypeColor(this.newRemarkType))
          .onClick(() => {
            this.showTypeSelector = true;
          })
      }
      .width('100%')
      .margin({ bottom: AppDimensions.MARGIN_SMALL })

      // 备注输入区域
      Row() {
        TextInput({ placeholder: '请输入备注内容...' })
          .width('70%')
          .height(AppDimensions.BUTTON_HEIGHT_SMALL)
          .fontSize(AppText.FONT_SIZE_SMALL)
          .onChange((value: string) => {
            this.newRemarkContent = value;
          })

        Button('添加')
          .type(ButtonType.Capsule)
          .width('25%')
          .height(AppDimensions.BUTTON_HEIGHT_SMALL)
          .fontSize(AppText.FONT_SIZE_SMALL)
          .backgroundColor(AppColors.PRIMARY)
          .enabled(this.newRemarkContent.trim().length > 0)
          .onClick(() => {
            this.addRemark();
          })
      }
      .width('100%')
      .margin({ bottom: AppDimensions.MARGIN_MEDIUM })

      // 已添加的备注列表
      if (this.remarks.length > 0) {
        Column() {
          Text('已添加的备注')
            .fontSize(AppText.FONT_SIZE_SMALL)
            .fontWeight(FontWeight.Medium)
            .margin({ bottom: AppDimensions.MARGIN_SMALL })
            .width('100%')
            .textAlign(TextAlign.Start)

          ForEach(this.remarks, (remark: Remark, index?: number) => {
            Row() {
              // 备注类型图标和标签
              Row() {
                Text(remark.getTypeIcon())
                  .fontSize(16)
                  .margin({ right: 4 })
                
                Text(remark.getTypeDisplayName())
                  .fontSize(AppText.FONT_SIZE_TINY)
                  .fontColor(remark.getTypeColor())
                  .backgroundColor(remark.getTypeColor() + '20')
                  .padding({ left: 6, right: 6, top: 2, bottom: 2 })
                  .borderRadius(4)
              }
              .margin({ right: AppDimensions.MARGIN_SMALL })

              // 备注内容
              Text(remark.content)
                .fontSize(AppText.FONT_SIZE_SMALL)
                .maxLines(2)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
                .layoutWeight(1)

              // 删除按钮
              Button('删除')
                .type(ButtonType.Circle)
                .width(24)
                .height(24)
                .fontSize(12)
                .backgroundColor(AppColors.ERROR)
                .onClick(() => {
                  if (index !== undefined) {
                    this.removeRemark(index);
                  }
                })
            }
            .width('100%')
            .padding(AppDimensions.PADDING_SMALL)
            .backgroundColor(AppColors.WHITE)
            .borderRadius(AppDimensions.BORDER_RADIUS_SMALL)
            .margin({ bottom: AppDimensions.MARGIN_SMALL })
            .alignItems(VerticalAlign.Center)
          })
        }
        .width('100%')
      }
    }
    .width('100%')
    .bindMenu(this.showTypeSelector ? this.buildTypeSelector() : undefined)
  }

  @Builder
  buildTypeSelector() {
    Column() {
      ForEach(Remark.getAllTypes(), (typeInfo) => {
        Row() {
          Text(typeInfo.icon)
            .fontSize(18)
            .margin({ right: 8 })
          
          Text(typeInfo.displayName)
            .fontSize(AppText.FONT_SIZE_SMALL)
            .layoutWeight(1)
        }
        .width(120)
        .padding(AppDimensions.PADDING_SMALL)
        .onClick(() => {
          this.newRemarkType = typeInfo.type;
          this.showTypeSelector = false;
        })
      })
    }
    .backgroundColor(AppColors.WHITE)
    .borderRadius(AppDimensions.BORDER_RADIUS_SMALL)
    .shadow({ radius: 4, color: Color.Gray, offsetX: 0, offsetY: 2 })
  }

  private getTypeDisplayName(type: RemarkType): string {
    switch (type) {
      case RemarkType.DIET:
        return '饮食 🍽️';
      case RemarkType.EXERCISE:
        return '运动 🏃';
      case RemarkType.MENSTRUAL:
        return '生理期 🩸';
      case RemarkType.OTHER:
        return '其他 📝';
      default:
        return '其他 📝';
    }
  }

  private getTypeColor(type: RemarkType): string {
    switch (type) {
      case RemarkType.DIET:
        return '#4CAF50';
      case RemarkType.EXERCISE:
        return '#2196F3';
      case RemarkType.MENSTRUAL:
        return '#E91E63';
      case RemarkType.OTHER:
        return '#757575';
      default:
        return '#757575';
    }
  }
}