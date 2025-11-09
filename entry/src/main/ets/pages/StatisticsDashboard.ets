/**
 * 统计仪表板页面
 * 展示体重统计的各种指标和分析
 */
import hilog from '@ohos.hilog';
import router from '@ohos.router';
import { WeightStatistics } from '../model/WeightStatistics';
import { StatisticsService, RangeStatistics } from '../data/StatisticsService';
import { AppColors, AppDimensions, AppText, LogConstants } from '../common/Constants';
import { HeightSettingDialog } from '../common/HeightSettingDialog';
import { TimeRangeSelector, TimeRange } from '../common/TimeRangeSelector';
import promptAction from '@ohos.promptAction';
import { common } from '@kit.AbilityKit';

const DOMAIN = LogConstants.DOMAIN;
const TAG = LogConstants.TAG_PREFIX + 'StatisticsDashboard';

@Entry
@Component
struct StatisticsDashboard {
  @State statistics: WeightStatistics | null = null;
  @State isLoading: boolean = true;
  @State isRefreshing: boolean = false;
  @State userHeight: number = 170;
  @State showHeightDialog: boolean = false;
  @State selectedTimeRange: TimeRange = 'all';
  @State rangeStats: RangeStatistics | null = null;
  private scroller: Scroller = new Scroller();

  async aboutToAppear(): Promise<void> {
    await this.loadStatistics();
    await this.loadUserHeight();
    await this.loadRangeStatistics();
  }

  onPageShow(): void {
    this.loadStatistics();
    this.loadRangeStatistics();
  }

  async loadStatistics(): Promise<void> {
    try {
      const context = this.getUIContext() as common.Context | null;
      if (context) {
        this.statistics = await StatisticsService.getStatistics(context);
      }
    } catch (e) {
      hilog.error(DOMAIN, TAG, `Failed to load statistics: ${e}`);
      promptAction.showToast({
        message: '加载统计数据失败',
        duration: 2000
      });
    } finally {
      this.isLoading = false;
    }
  }

  async loadUserHeight(): Promise<void> {
    try {
      const context = this.getUIContext() as common.Context | null;
      if (context) {
        this.userHeight = await StatisticsService.getUserHeight(context);
      }
    } catch (e) {
      hilog.error(DOMAIN, TAG, `Failed to load user height: ${e}`);
    }
  }

  onHeightChange(height: number): void {
    this.userHeight = height;
    // 重新计算统计数据（因为身高变化会影响BMI）
    this.loadStatistics();
  }

  async loadRangeStatistics(): Promise<void> {
    try {
      const context = this.getUIContext() as common.Context | null;
      if (context) {
        this.rangeStats = await StatisticsService.getTimeRangeStatistics(context, this.selectedTimeRange);
      }
    } catch (e) {
      hilog.error(DOMAIN, TAG, `Failed to load range statistics: ${e}`);
    }
  }

  onTimeRangeChange(range: TimeRange): void {
    this.selectedTimeRange = range;
    this.loadRangeStatistics();
  }

  async onRefresh(): Promise<void> {
    this.isRefreshing = true;
    try {
      const context = this.getUIContext() as common.Context | null;
      if (context) {
        this.statistics = await StatisticsService.refreshStatistics(context);
        await this.loadRangeStatistics();
      }
      promptAction.showToast({
        message: '数据已更新',
        duration: 1000
      });
    } catch (e) {
      hilog.error(DOMAIN, TAG, `Failed to refresh statistics: ${e}`);
      promptAction.showToast({
        message: '刷新失败',
        duration: 2000
      });
    } finally {
      this.isRefreshing = false;
    }
  }

  build() {
    Column() {
      // 标题栏
      Row() {
        Button('←')
          .type(ButtonType.Circle)
          .width(40)
          .height(40)
          .fontSize(20)
          .backgroundColor(AppColors.WHITE)
          .fontColor(AppColors.GRAY)
          .onClick(() => {
            router.back();
          })

        Text('统计仪表板')
          .fontSize(AppText.FONT_SIZE_TITLE)
          .fontWeight(FontWeight.Bold)
          .margin({ left: 20 })

        Blank()

        if (!this.isRefreshing) {
          Button('刷新')
            .type(ButtonType.Normal)
            .height(36)
            .fontSize(14)
            .backgroundColor(AppColors.PRIMARY)
            .onClick(() => this.onRefresh())
        }
      }
      .width('100%')
      .padding(AppDimensions.PADDING_MEDIUM)
      .backgroundColor(AppColors.WHITE)

      if (this.isLoading) {
        LoadingProgress()
          .width(50)
          .height(50)
          .margin({ top: 100 })
        Text('加载中...')
          .fontSize(AppText.FONT_SIZE_BODY)
          .margin({ top: 20 })
          .fontColor(AppColors.GRAY)
      } else if (this.statistics) {
        Scroll(this.scroller) {
          Column({ space: AppDimensions.MARGIN_MEDIUM }) {
            // 时间范围选择器
            TimeRangeSelector({
              selectedRange: this.selectedTimeRange,
              onRangeChange: (range: TimeRange) => this.onTimeRangeChange(range)
            })

            // 时间范围统计卡片
            if (this.rangeStats) {
              this.buildRangeStatsCard()
            }
            
            // 主要指标卡片
            this.buildMainMetricsCard()
            
            // BMI卡片
            this.buildBMICard()
            
            // 趋势卡片
            this.buildTrendCard()
            
            // 进度卡片
            this.buildProgressCard()
            
            // 历史记录统计卡片
            this.buildHistoryCard()
          }
          .padding(AppDimensions.PADDING_MEDIUM)
        }
        .layoutWeight(1)
      } else {
        Column() {
          Text('暂无数据')
            .fontSize(AppText.FONT_SIZE_TITLE)
            .fontColor(AppColors.GRAY)
            .margin({ top: 100 })
          
          Text('请先记录一些体重数据')
            .fontSize(AppText.FONT_SIZE_BODY)
            .fontColor(AppColors.GRAY)
            .margin({ top: 20 })
          
          Button('去记录')
            .type(ButtonType.Capsule)
            .margin({ top: 40 })
            .backgroundColor(AppColors.PRIMARY)
            .onClick(() => {
              router.pushUrl({ url: 'pages/WeightEntryForm' });
            })
        }
        .width('100%')
        .layoutWeight(1)
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(AppColors.BACKGROUND)
    
    // 身高设置对话框
    HeightSettingDialog({
      isVisible: this.showHeightDialog,
      currentHeight: this.userHeight,
      onHeightChange: (height: number) => this.onHeightChange(height),
      onDismiss: () => { this.showHeightDialog = false }
    })
  }

  @Builder
  buildRangeStatsCard(): void {
    if (!this.rangeStats) {
      return;
    }
    
    Card() {
      Column({ space: AppDimensions.MARGIN_SMALL }) {
        Text(`${this.getTimeRangeLabel(this.selectedTimeRange)}统计`)
          .fontSize(AppText.FONT_SIZE_SUBTITLE)
          .fontWeight(FontWeight.Bold)
          .width('100%')
          .textAlign(TextAlign.Start)

        Row({ space: AppDimensions.MARGIN_MEDIUM }) {
          // 记录数
          Column({ space: 5 }) {
            Text('记录数')
              .fontSize(AppText.FONT_SIZE_SMALL)
              .fontColor(AppColors.GRAY)
            Text(this.rangeStats!.count.toString())
              .fontSize(AppText.FONT_SIZE_TITLE)
              .fontWeight(FontWeight.Bold)
              .fontColor(AppColors.PRIMARY)
          }
          .layoutWeight(1)

          // 平均体重
          Column({ space: 5 }) {
            Text('平均体重')
              .fontSize(AppText.FONT_SIZE_SMALL)
              .fontColor(AppColors.GRAY)
            Text(`${this.rangeStats!.average.toFixed(1)} kg`)
              .fontSize(AppText.FONT_SIZE_TITLE)
              .fontWeight(FontWeight.Bold)
              .fontColor(AppColors.WARNING)
          }
          .layoutWeight(1)

          // 变化量
          Column({ space: 5 }) {
            Text('变化量')
              .fontSize(AppText.FONT_SIZE_SMALL)
              .fontColor(AppColors.GRAY)
            Row({ space: 4 }) {
              Text(this.rangeStats!.change >= 0 ? '↑' : '↓')
                .fontSize(16)
                .fontColor(this.rangeStats!.change >= 0 ? '#F44336' : '#4CAF50')
              Text(`${Math.abs(this.rangeStats!.change).toFixed(1)} kg`)
                .fontSize(AppText.FONT_SIZE_BODY)
                .fontWeight(FontWeight.Bold)
                .fontColor(this.rangeStats!.change >= 0 ? '#F44336' : '#4CAF50')
            }
          }
          .layoutWeight(1)
        }
        .width('100%')

        Divider()
          .margin({ vertical: 5 })

        Row({ space: AppDimensions.MARGIN_MEDIUM }) {
          // 最高体重
          Column({ space: 5 }) {
            Text('最高体重')
              .fontSize(AppText.FONT_SIZE_SMALL)
              .fontColor(AppColors.GRAY)
            Text(`${this.rangeStats!.max.toFixed(1)} kg`)
              .fontSize(AppText.FONT_SIZE_BODY)
              .fontWeight(FontWeight.Bold)
              .fontColor('#F44336')
          }
          .layoutWeight(1)

          // 最低体重
          Column({ space: 5 }) {
            Text('最低体重')
              .fontSize(AppText.FONT_SIZE_SMALL)
              .fontColor(AppColors.GRAY)
            Text(`${this.rangeStats!.min.toFixed(1)} kg`)
              .fontSize(AppText.FONT_SIZE_BODY)
              .fontWeight(FontWeight.Bold)
              .fontColor('#4CAF50')
          }
          .layoutWeight(1)
        }
        .width('100%')
      }
      .padding(AppDimensions.PADDING_MEDIUM)
    }
  }

  getTimeRangeLabel(range: TimeRange): string {
    switch (range) {
      case 'all': return '全部时间';
      case 'month': return '本月';
      case 'week': return '本周';
      case '7days': return '最近7天';
      case '30days': return '最近30天';
      default: return '全部时间';
    }
  }

  @Builder
  buildMainMetricsCard(): void {
    if (!this.statistics) {
      return;
    }
    
    Card() {
      Column({ space: AppDimensions.MARGIN_SMALL }) {
        Text('主要指标')
          .fontSize(AppText.FONT_SIZE_SUBTITLE)
          .fontWeight(FontWeight.Bold)
          .width('100%')
          .textAlign(TextAlign.Start)

        Row({ space: AppDimensions.MARGIN_MEDIUM }) {
          // 当前体重
          Column({ space: 5 }) {
            Text('当前体重')
              .fontSize(AppText.FONT_SIZE_SMALL)
              .fontColor(AppColors.GRAY)
            Text(`${this.statistics!.currentWeight.toFixed(1)} kg`)
              .fontSize(AppText.FONT_SIZE_TITLE)
              .fontWeight(FontWeight.Bold)
              .fontColor(AppColors.PRIMARY)
          }
          .layoutWeight(1)

          // 目标体重
          Column({ space: 5 }) {
            Text('目标体重')
              .fontSize(AppText.FONT_SIZE_SMALL)
              .fontColor(AppColors.GRAY)
            Text(`${this.statistics!.targetWeight.toFixed(1)} kg`)
              .fontSize(AppText.FONT_SIZE_TITLE)
              .fontWeight(FontWeight.Bold)
              .fontColor(AppColors.SUCCESS)
          }
          .layoutWeight(1)

          // 平均体重
          Column({ space: 5 }) {
            Text('平均体重')
              .fontSize(AppText.FONT_SIZE_SMALL)
              .fontColor(AppColors.GRAY)
            Text(`${this.statistics!.averageWeight.toFixed(1)} kg`)
              .fontSize(AppText.FONT_SIZE_TITLE)
              .fontWeight(FontWeight.Bold)
              .fontColor(AppColors.WARNING)
          }
          .layoutWeight(1)
        }
        .width('100%')
      }
      .padding(AppDimensions.PADDING_MEDIUM)
    }
    .onClick(() => {
      if (this.statistics) {
        promptAction.showToast({
          message: `当前: ${this.statistics.currentWeight.toFixed(1)}kg | 目标: ${this.statistics.targetWeight.toFixed(1)}kg | 平均: ${this.statistics.averageWeight.toFixed(1)}kg`,
          duration: 3000
        });
      }
    })
  }

  @Builder
  buildBMICard(): void {
    if (!this.statistics) {
      return;
    }
    
    Card() {
      Column({ space: AppDimensions.MARGIN_SMALL }) {
        Row() {
          Text('BMI 指数')
            .fontSize(AppText.FONT_SIZE_SUBTITLE)
            .fontWeight(FontWeight.Bold)
          
          Blank()
          
          Text(`身高: ${this.userHeight}cm`)
            .fontSize(AppText.FONT_SIZE_SMALL)
            .fontColor(AppColors.PRIMARY)
            .onClick(() => {
              this.showHeightDialog = true;
            })
        }
        .width('100%')

        Row({ space: AppDimensions.MARGIN_MEDIUM }) {
          Column({ space: 10 }) {
            Text(this.statistics!.bmi.toFixed(1))
              .fontSize(48)
              .fontWeight(FontWeight.Bold)
              .fontColor(this.statistics!.getBmiStatusColor())
            
            Text(this.statistics!.getBmiStatus())
              .fontSize(AppText.FONT_SIZE_BODY)
              .fontColor(this.statistics!.getBmiStatusColor())
          }
          .alignItems(HorizontalAlign.Center)

          Blank()

          Column({ space: 5 }) {
            Text('BMI 分类')
              .fontSize(AppText.FONT_SIZE_SMALL)
              .fontColor(AppColors.GRAY)
            
            Text('偏瘦 < 18.5')
              .fontSize(12)
              .fontColor(AppColors.GRAY)
            Text('正常 18.5-24')
              .fontSize(12)
              .fontColor('#4CAF50')
            Text('偏胖 24-28')
              .fontSize(12)
              .fontColor(AppColors.WARNING)
            Text('肥胖 ≥ 28')
              .fontSize(12)
              .fontColor('#F44336')
          }
          .alignItems(HorizontalAlign.End)
        }
        .width('100%')
      }
      .padding(AppDimensions.PADDING_MEDIUM)
    }
  }

  @Builder
  buildTrendCard(): void {
    if (!this.statistics) {
      return;
    }
    
    Card() {
      Column({ space: AppDimensions.MARGIN_SMALL }) {
        Text('变化趋势')
          .fontSize(AppText.FONT_SIZE_SUBTITLE)
          .fontWeight(FontWeight.Bold)
          .width('100%')
          .textAlign(TextAlign.Start)

        Row({ space: AppDimensions.MARGIN_MEDIUM }) {
          // 7天趋势
          Column({ space: 5 }) {
            Text('最近7天')
              .fontSize(AppText.FONT_SIZE_SMALL)
              .fontColor(AppColors.GRAY)
            Text(this.statistics!.formatTrendText(this.statistics!.trend7Days))
              .fontSize(AppText.FONT_SIZE_BODY)
              .fontWeight(FontWeight.Bold)
              .fontColor(this.statistics!.getTrendColor(this.statistics!.trend7Days))
          }
          .layoutWeight(1)

          // 30天趋势
          Column({ space: 5 }) {
            Text('最近30天')
              .fontSize(AppText.FONT_SIZE_SMALL)
              .fontColor(AppColors.GRAY)
            Text(this.statistics!.formatTrendText(this.statistics!.trend30Days))
              .fontSize(AppText.FONT_SIZE_BODY)
              .fontWeight(FontWeight.Bold)
              .fontColor(this.statistics!.getTrendColor(this.statistics!.trend30Days))
          }
          .layoutWeight(1)
        }
        .width('100%')

        Divider()
          .margin({ vertical: 5 })

        Row({ space: AppDimensions.MARGIN_MEDIUM }) {
          // 最高体重
          Column({ space: 5 }) {
            Text('最高体重')
              .fontSize(AppText.FONT_SIZE_SMALL)
              .fontColor(AppColors.GRAY)
            Text(`${this.statistics!.maxWeight.toFixed(1)} kg`)
              .fontSize(AppText.FONT_SIZE_BODY)
              .fontWeight(FontWeight.Bold)
              .fontColor('#F44336')
          }
          .layoutWeight(1)

          // 最低体重
          Column({ space: 5 }) {
            Text('最低体重')
              .fontSize(AppText.FONT_SIZE_SMALL)
              .fontColor(AppColors.GRAY)
            Text(`${this.statistics!.minWeight.toFixed(1)} kg`)
              .fontSize(AppText.FONT_SIZE_BODY)
              .fontWeight(FontWeight.Bold)
              .fontColor('#4CAF50')
          }
          .layoutWeight(1)
        }
        .width('100%')
      }
      .padding(AppDimensions.PADDING_MEDIUM)
    }
  }

  @Builder
  buildProgressCard(): void {
    if (!this.statistics) {
      return;
    }
    
    Card() {
      Column({ space: AppDimensions.MARGIN_SMALL }) {
        Text('减重进度')
          .fontSize(AppText.FONT_SIZE_SUBTITLE)
          .fontWeight(FontWeight.Bold)
          .width('100%')
          .textAlign(TextAlign.Start)

        Column({ space: 10 }) {
          Row() {
            Text(`已减重: ${Math.abs(this.statistics!.weightLoss).toFixed(1)} kg`)
              .fontSize(AppText.FONT_SIZE_BODY)
              .fontColor(this.statistics!.getProgressStatusColor())
            
            Blank()
            
            Text(`${this.statistics!.progressPercentage.toFixed(1)}%`)
              .fontSize(AppText.FONT_SIZE_BODY)
              .fontWeight(FontWeight.Bold)
              .fontColor(this.statistics!.getProgressStatusColor())
          }
          .width('100%')

          Progress({
            value: Math.max(0, Math.min(100, this.statistics!.progressPercentage)),
            total: 100,
            type: ProgressType.Linear
          })
            .width('100%')
            .height(8)
            .color(this.statistics!.getProgressStatusColor())
            .backgroundColor(AppColors.LIGHT_GRAY)
            .borderRadius(4)

          Row() {
            Text('开始')
              .fontSize(12)
              .fontColor(AppColors.GRAY)
            
            Blank()
            
            Text('目标')
              .fontSize(12)
              .fontColor(AppColors.GRAY)
          }
          .width('100%')
        }
        .width('100%')
      }
      .padding(AppDimensions.PADDING_MEDIUM)
    }
  }

  @Builder
  buildHistoryCard(): void {
    if (!this.statistics) {
      return;
    }
    
    Card() {
      Column({ space: AppDimensions.MARGIN_SMALL }) {
        Text('历史记录')
          .fontSize(AppText.FONT_SIZE_SUBTITLE)
          .fontWeight(FontWeight.Bold)
          .width('100%')
          .textAlign(TextAlign.Start)

        Row({ space: AppDimensions.MARGIN_MEDIUM }) {
          Column({ space: 5 }) {
            Text('总记录数')
              .fontSize(AppText.FONT_SIZE_SMALL)
              .fontColor(AppColors.GRAY)
            Text(this.statistics!.totalRecords.toString())
              .fontSize(AppText.FONT_SIZE_TITLE)
              .fontWeight(FontWeight.Bold)
              .fontColor(AppColors.PRIMARY)
          }
          .layoutWeight(1)

          Column({ space: 5 }) {
            Button('查看详情')
              .type(ButtonType.Normal)
              .height(36)
              .fontSize(14)
              .backgroundColor(AppColors.WHITE)
              .fontColor(AppColors.PRIMARY)
              .border({ width: 1, color: AppColors.PRIMARY, radius: 18 })
              .onClick(() => {
                router.pushUrl({ url: 'pages/History' });
              })
          }
          .justifyContent(FlexAlign.End)
          .layoutWeight(1)
        }
        .width('100%')
      }
      .padding(AppDimensions.PADDING_MEDIUM)
    }
  }
}

@Component
struct Card {
  @BuilderParam content: () => void;

  build() {
    Column() {
      this.content();
    }
    .width('100%')
    .backgroundColor(AppColors.WHITE)
    .borderRadius(AppDimensions.BORDER_RADIUS)
    .shadow({
      radius: 8,
      color: '#1F000000',
      offsetX: 0,
      offsetY: 2
    })
  }
}
