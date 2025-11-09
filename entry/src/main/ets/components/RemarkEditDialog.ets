import { Remark, RemarkType, RemarkTypeInfo } from '../model/Remark';
import { AppColors, AppDimensions, AppText, BusinessConstants } from '../common/Constants';

@Component
export struct RemarkEditDialog {
  @Prop isVisible: boolean = false;
  @Prop remark?: Remark;
  @State selectedType: RemarkType = RemarkType.OTHER;
  @State content: string = '';
  @State showTypeSelector: boolean = false;
  onSave: (type: RemarkType, content: string) => void = () => {
  };
  onCancel: () => void = () => {
  };

  aboutToAppear() {
    if (this.remark) {
      this.selectedType = this.remark.type;
      this.content = this.remark.content;
    } else {
      this.selectedType = RemarkType.OTHER;
      this.content = '';
    }
  }

  private handleSave() {
    if (this.content.trim()) {
      this.onSave(this.selectedType, this.content.trim());
    }
  }

  build() {
    if (this.isVisible) {
      Column() {
        // 遮罩层
        Column()
          .width('100%')
          .height('100%')
          .backgroundColor('rgba(0, 0, 0, 0.5)')
          .onClick(() => {
            this.onCancel();
          })

        // 对话框内容
        Column() {
          // 标题
          Text(this.remark ? '编辑备注' : '添加备注')
            .fontSize(AppText.FONT_SIZE_SUBTITLE)
            .fontWeight(FontWeight.Bold)
            .margin({ bottom: AppDimensions.MARGIN_LARGE })

          // 类型选择
          Column() {
            Text('备注类型')
              .fontSize(AppText.FONT_SIZE_SMALL)
              .fontWeight(FontWeight.Medium)
              .margin({ bottom: AppDimensions.MARGIN_SMALL })
              .width('100%')
              .textAlign(TextAlign.Start)

            Button(this.getTypeDisplayName(this.selectedType))
              .type(ButtonType.Capsule)
              .width('100%')
              .height(AppDimensions.BUTTON_HEIGHT)
              .fontSize(AppText.FONT_SIZE_SMALL)
              .backgroundColor(this.getTypeColor(this.selectedType))
              .onClick(() => {
                this.showTypeSelector = true;
              })
          }
          .width('100%')
          .margin({ bottom: AppDimensions.MARGIN_MEDIUM })

          // 内容输入
          Column() {
            Text('备注内容')
              .fontSize(AppText.FONT_SIZE_SMALL)
              .fontWeight(FontWeight.Medium)
              .margin({ bottom: AppDimensions.MARGIN_SMALL })
              .width('100%')
              .textAlign(TextAlign.Start)

            TextArea({
              placeholder: '请输入备注内容...',
              text: this.content
            })
              .width('100%')
              .height(100)
              .fontSize(AppText.FONT_SIZE_SMALL)
              .maxLength(BusinessConstants.MAX_REMARK_CONTENT_LENGTH)
              .onChange((value: string) => {
                this.content = value;
              })

            Text(`${this.content.length}/${BusinessConstants.MAX_REMARK_CONTENT_LENGTH}`)
              .fontSize(AppText.FONT_SIZE_TINY)
              .fontColor(AppColors.GRAY)
              .margin({ top: 4 })
              .width('100%')
              .textAlign(TextAlign.End)
          }
          .width('100%')
          .margin({ bottom: AppDimensions.MARGIN_LARGE })

          // 操作按钮
          Row() {
            Button('取消')
              .type(ButtonType.Capsule)
              .layoutWeight(1)
              .height(AppDimensions.BUTTON_HEIGHT)
              .fontSize(AppText.FONT_SIZE_BODY)
              .backgroundColor(AppColors.LIGHT_GRAY)
              .fontColor(AppColors.GRAY)
              .onClick(() => {
                this.onCancel();
              })

            Blank().width(AppDimensions.MARGIN_MEDIUM)

            Button('保存')
              .type(ButtonType.Capsule)
              .layoutWeight(1)
              .height(AppDimensions.BUTTON_HEIGHT)
              .fontSize(AppText.FONT_SIZE_BODY)
              .backgroundColor(AppColors.PRIMARY)
              .enabled(this.content.trim().length > 0)
              .onClick(() => {
                this.handleSave();
              })
          }
          .width('100%')
        }
        .width('90%')
        .padding(AppDimensions.PADDING_LARGE)
        .backgroundColor(AppColors.WHITE)
        .borderRadius(AppDimensions.BORDER_RADIUS)
        .bindMenu(this.showTypeSelector ? this.buildTypeSelector() : undefined)
      }
      .width('100%')
      .height('100%')
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)
    }
  }

  @Builder
  buildTypeSelector() {
    Column() {
      ForEach(Remark.getAllTypes().slice(), (typeInfo: RemarkTypeInfo) => {
        Row() {
          Text(typeInfo.icon)
            .fontSize(18)
            .margin({ right: 8 })

          Text(typeInfo.displayName)
            .fontSize(AppText.FONT_SIZE_SMALL)
            .layoutWeight(1)
        }
        .width(140)
        .padding(AppDimensions.PADDING_SMALL)
        .backgroundColor(this.selectedType === typeInfo.type ? AppColors.PRIMARY + '20' : AppColors.WHITE)
        .borderRadius(4)
        .onClick(() => {
          this.selectedType = typeInfo.type;
          this.showTypeSelector = false;
        })
      })
    }
    .backgroundColor(AppColors.WHITE)
    .borderRadius(AppDimensions.BORDER_RADIUS_SMALL)
    .shadow({
      radius: 4,
      color: Color.Gray,
      offsetX: 0,
      offsetY: 2
    })
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