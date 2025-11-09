import { RemarkType, Remark } from '../model/Remark';
import { AppColors, AppDimensions, AppText } from '../common/Constants';

@Component
export struct RemarkFilter {
  @State selectedType: RemarkType | 'all' = 'all';
  @State showFilterDialog: boolean = false;
  onFilterChange: (type: RemarkType | 'all') => void = () => {};

  private getFilterDisplayName(): string {
    if (this.selectedType === 'all') {
      return '全部备注';
    }
    switch (this.selectedType) {
      case RemarkType.DIET:
        return '饮食 🍽️';
      case RemarkType.EXERCISE:
        return '运动 🏃';
      case RemarkType.MENSTRUAL:
        return '生理期 🩸';
      case RemarkType.OTHER:
        return '其他 📝';
      default:
        return '全部备注';
    }
  }

  private getFilterColor(): string {
    if (this.selectedType === 'all') {
      return AppColors.GRAY;
    }
    switch (this.selectedType) {
      case RemarkType.DIET:
        return '#4CAF50';
      case RemarkType.EXERCISE:
        return '#2196F3';
      case RemarkType.MENSTRUAL:
        return '#E91E63';
      case RemarkType.OTHER:
        return '#757575';
      default:
        return AppColors.GRAY;
    }
  }

  build() {
    Row() {
      Button(this.getFilterDisplayName())
        .type(ButtonType.Capsule)
        .height(AppDimensions.BUTTON_HEIGHT_SMALL)
        .fontSize(AppText.FONT_SIZE_SMALL)
        .backgroundColor(this.getFilterColor())
        .onClick(() => {
          this.showFilterDialog = true;
        })

      if (this.selectedType !== 'all') {
        Button('清除')
          .type(ButtonType.Capsule)
          .height(AppDimensions.BUTTON_HEIGHT_SMALL)
          .fontSize(AppText.FONT_SIZE_TINY)
          .backgroundColor(AppColors.LIGHT_GRAY)
          .margin({ left: AppDimensions.MARGIN_SMALL })
          .onClick(() => {
            this.selectedType = 'all';
            this.onFilterChange('all');
          })
      }
    }
    .bindMenu(this.showFilterDialog ? this.buildFilterMenu() : undefined)
  }

  @Builder
  buildFilterMenu() {
    Column() {
      // 全部选项
      Row() {
        Text('全部')
          .fontSize(AppText.FONT_SIZE_SMALL)
          .layoutWeight(1)
      }
      .width(120)
      .padding(AppDimensions.PADDING_SMALL)
      .backgroundColor(this.selectedType === 'all' ? AppColors.PRIMARY + '20' : AppColors.WHITE)
      .borderRadius(4)
      .onClick(() => {
        this.selectedType = 'all';
        this.showFilterDialog = false;
        this.onFilterChange('all');
      })

      // 分隔线
      Divider()
        .width('80%')
        .height(1)
        .color(AppColors.BORDER_GRAY)
        .margin({ top: 4, bottom: 4 })

      // 备注类型选项
      ForEach(Remark.getAllTypes().slice(), (typeInfo: RemarkTypeInfo) => {
        Row() {
          Text(typeInfo.icon)
            .fontSize(16)
            .margin({ right: 8 })
          
          Text(typeInfo.displayName)
            .fontSize(AppText.FONT_SIZE_SMALL)
            .layoutWeight(1)
        }
        .width(120)
        .padding(AppDimensions.PADDING_SMALL)
        .backgroundColor(this.selectedType === typeInfo.type ? AppColors.PRIMARY + '20' : AppColors.WHITE)
        .borderRadius(4)
        .onClick(() => {
          this.selectedType = typeInfo.type;
          this.showFilterDialog = false;
          this.onFilterChange(typeInfo.type);
        })
      })
    }
    .backgroundColor(AppColors.WHITE)
    .borderRadius(AppDimensions.BORDER_RADIUS_SMALL)
    .shadow({ radius: 4, color: Color.Gray, offsetX: 0, offsetY: 2 })
  }
}