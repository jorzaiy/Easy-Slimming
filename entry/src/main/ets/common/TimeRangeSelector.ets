/**
 * 时间范围选择器组件
 */
import { AppColors, AppDimensions, AppText } from './Constants';

export type TimeRange = 'all' | 'month' | 'week' | '7days' | '30days';

export interface TimeRangeOption {
  value: TimeRange;
  label: string;
}

@Component
export struct TimeRangeSelector {
  @Prop selectedRange: TimeRange;
  @Prop onRangeChange: (range: TimeRange) => void;

  private ranges: TimeRangeOption[] = [
    { value: 'all', label: '全部' },
    { value: 'month', label: '本月' },
    { value: 'week', label: '本周' },
    { value: '7days', label: '7天' },
    { value: '30days', label: '30天' }
  ];

  build() {
    Row({ space: AppDimensions.MARGIN_SMALL }) {
      ForEach(this.ranges.slice(), (range: TimeRangeOption, index?: number) => {
        Button(range.label)
          .type(ButtonType.Normal)
          .height(32)
          .fontSize(12)
          .padding({ left: 12, right: 12 })
          .backgroundColor(this.selectedRange === range.value ? AppColors.PRIMARY : AppColors.WHITE)
          .fontColor(this.selectedRange === range.value ? AppColors.WHITE : AppColors.GRAY)
          .border({
            width: 1,
            color: this.selectedRange === range.value ? AppColors.PRIMARY : AppColors.BORDER_GRAY,
            radius: 16
          })
          .onClick(() => {
            this.onRangeChange(range.value);
          })
      })
    }
    .width('100%')
    .justifyContent(FlexAlign.SpaceAround)
    .padding(AppDimensions.PADDING_SMALL)
    .backgroundColor(AppColors.WHITE)
    .borderRadius(AppDimensions.BORDER_RADIUS)
  }
}
