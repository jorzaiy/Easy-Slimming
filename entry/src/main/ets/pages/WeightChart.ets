import hilog from '@ohos.hilog';
import router from '@ohos.router';
import { WeightRecord } from '../model/WeightRecord';
import { NavigationHelper } from '../common/NavigationHelper';
import { ErrorHandler } from '../common/ErrorHandler';
import { FormValidator } from '../common/FormValidator';
import { AppColors, AppDimensions, AppText, LogConstants } from '../common/Constants';
import promptAction from '@ohos.promptAction';
import { getAppDao } from '../common/Global';
import { getTargetWeightService, TargetWeightRecord } from '../data/TargetWeightService';
import { TargetWeightSettingDialog } from '../common/TargetWeightSettingDialog';
import { common } from '@kit.AbilityKit';
import { resolveAbilityContext } from '../common/ContextUtils';

const DOMAIN = LogConstants.DOMAIN;
const TAG = LogConstants.TAG_PREFIX + 'Chart';

// 时间范围枚举
enum TimeRange {
  WEEK = 'week',
  MONTH = 'month',
  THREE_MONTHS = 'three_months'
}

// 图表数据点
interface ChartDataPoint {
  date: Date;
  weight: number;
  x: number;
  y: number;
}

// 体重范围接口
interface WeightRange {
  minWeight: number;
  maxWeight: number;
}

// 统计信息接口
interface Statistics {
  currentWeight: number;
  startWeight: number;
  minWeight: number;
  maxWeight: number;
  avgWeight: number;
  totalChange: number;
}

@Entry
@Component
struct WeightChartPage {
  @State records: WeightRecord[] = [];
  @State timeRange: TimeRange = TimeRange.MONTH;
  @State targetWeight: number = WeightRecord.getTargetWeight();
  @State currentTarget: TargetWeightRecord | null = null;
  @State selectedPoint: ChartDataPoint | null = null;
  @State chartWidth: number = 350;
  @State chartHeight: number = 300;
  @State showTargetDialog: boolean = false;
  @State showSettingDialog: boolean = false;
  @State tempTargetWeight: string = '';
  @State statistics: Statistics = {
    currentWeight: 0,
    startWeight: 0,
    minWeight: 0,
    maxWeight: 0,
    avgWeight: 0,
    totalChange: 0
  };
  @State weightRange: WeightRange = {
    minWeight: 0,
    maxWeight: 0
  };
  private chartDataPoints: ChartDataPoint[] = [];
  private chartPadding: number = 40;
  private targetWeightLineY: number = 0;

  async aboutToAppear() {
    await this.loadChartData();
    await this.loadTargetWeight();
  }

  onPageShow() {
    this.loadChartData();
    this.loadTargetWeight();
  }

  async loadTargetWeight() {
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
        this.currentTarget = await service.getCurrentTarget();
        if (this.currentTarget) {
          this.targetWeight = this.currentTarget.targetWeight;
        }
      }
    } catch (e) {
      hilog.error(DOMAIN, TAG, `Failed to load target weight: ${e}`);
    }
  }

  async loadChartData() {
    try {
      const dao = getAppDao();
      if (!dao) {
        throw new Error('Global DAO not initialized');
      }
      const endDate = new Date();
      let startDate = new Date();

      switch (this.timeRange) {
        case TimeRange.WEEK:
          startDate.setDate(endDate.getDate() - 7);
          break;
        case TimeRange.MONTH:
          startDate.setMonth(endDate.getMonth() - 1);
          break;
        case TimeRange.THREE_MONTHS:
          startDate.setMonth(endDate.getMonth() - 3);
          break;
      }

      this.records = await dao.queryByDateRange(startDate.getTime(), endDate.getTime());
      this.targetWeight = WeightRecord.getTargetWeight();
      this.processChartData();
      hilog.info(DOMAIN, TAG, `Loaded ${this.records.length} records for chart.`);
    } catch (e) {
      hilog.error(DOMAIN, TAG, `Failed to load chart data, cause: ${e}`);
      promptAction.showToast({
        message: '加载图表数据失败',
        duration: 2000
      });
    }
  }

  processChartData() {
    if (this.records.length === 0) {
      this.chartDataPoints = [];
      return;
    }

    // 计算体重范围
    const weights = this.records.map(r => r.weight);
    const minWeight = Math.min(...weights, this.targetWeight) - 2;
    const maxWeight = Math.max(...weights, this.targetWeight) + 2;
    const weightRange = maxWeight - minWeight;

    // 更新体重范围状态
    this.weightRange = {
      minWeight: minWeight,
      maxWeight: maxWeight
    };

    // 更新统计信息状态
    this.statistics = this.calculateStatistics();

    // 计算时间范围
    const times = this.records.map(r => r.date);
    const minTime = Math.min(...times);
    const maxTime = Math.max(...times);
    const timeRange = maxTime - minTime || 1;

    // 转换为图表坐标点
    this.chartDataPoints = this.records.map((record): ChartDataPoint => {
      const x = this.chartPadding + ((record.date - minTime) / timeRange) * (this.chartWidth - 2 * this.chartPadding);
      const y = this.chartPadding + ((maxWeight - record.weight) / weightRange) * (this.chartHeight - 2 * this.chartPadding);
      return {
        date: new Date(record.date),
        weight: record.weight,
        x: x,
        y: y
      };
    });

    // 计算目标线的Y坐标
    this.targetWeightLineY = this.chartPadding + ((maxWeight - this.targetWeight) / weightRange) * (this.chartHeight - 2 * this.chartPadding);
  }

  onTimeRangeChange(range: TimeRange) {
    this.timeRange = range;
    this.loadChartData();
  }

  formatDateString(date: Date): string {
    switch (this.timeRange) {
      case TimeRange.WEEK:
        return `${date.getMonth() + 1}/${date.getDate()}`;
      case TimeRange.MONTH:
        return `${date.getMonth() + 1}/${date.getDate()}`;
      case TimeRange.THREE_MONTHS:
        return `${date.getMonth() + 1}/${date.getDate()}`;
      default:
        return `${date.getMonth() + 1}/${date.getDate()}`;
    }
  }

  showTargetWeightDialog() {
    this.showSettingDialog = true;
  }

  onTargetChange(target: TargetWeightRecord) {
    this.currentTarget = target;
    this.targetWeight = target.targetWeight;
    WeightRecord.setTargetWeight(target.targetWeight);
    this.loadChartData();
  }

  build() {
    Stack() {
      Column() {
        // 标题栏
        Row() {
          Image($r('app.media.ic_back'))
            .width(24)
            .height(24)
            .onClick(() => {
              try {
                router.back();
              } catch (error) {
                hilog.error(DOMAIN, TAG, `Failed to navigate back, cause: ${error}`);
              }
            })
          Text('体重趋势')
            .fontSize(24)
            .fontWeight(FontWeight.Bold)
            .layoutWeight(1)
            .textAlign(TextAlign.Center)
            .margin({ right: 24 })
        }
        .width('100%')
        .padding(15)
        .backgroundColor(Color.White)
        .shadow({ radius: 3, color: Color.Gray, offsetX: 0, offsetY: 2 })

      // 时间范围选择器
      Row() {
        Button('一周')
          .type(ButtonType.Capsule)
          .height(36)
          .fontSize(14)
          .backgroundColor(this.timeRange === TimeRange.WEEK ? Color.Blue : '#F1F3F5')
          .fontColor(this.timeRange === TimeRange.WEEK ? Color.White : '#333333')
          .onClick(() => this.onTimeRangeChange(TimeRange.WEEK))

        Button('一月')
          .type(ButtonType.Capsule)
          .height(36)
          .fontSize(14)
          .backgroundColor(this.timeRange === TimeRange.MONTH ? Color.Blue : '#F1F3F5')
          .fontColor(this.timeRange === TimeRange.MONTH ? Color.White : '#333333')
          .margin({ left: 10 })
          .onClick(() => this.onTimeRangeChange(TimeRange.MONTH))

        Button('三月')
          .type(ButtonType.Capsule)
          .height(36)
          .fontSize(14)
          .backgroundColor(this.timeRange === TimeRange.THREE_MONTHS ? Color.Blue : '#F1F3F5')
          .fontColor(this.timeRange === TimeRange.THREE_MONTHS ? Color.White : '#333333')
          .margin({ left: 10 })
          .onClick(() => this.onTimeRangeChange(TimeRange.THREE_MONTHS))
      }
      .width('100%')
      .justifyContent(FlexAlign.Center)
      .padding({ top: 20, bottom: 10 })

      // 图表容器
      Column() {
        if (this.records.length > 0) {
          // 统计信息
          this.StatisticsCard()
          
          // 图例和目标体重设置
          Row() {
            Row() {
              Circle({ width: 8, height: 8 })
                .fill(Color.Blue)
              Text('体重')
                .fontSize(12)
                .fontColor('#333333')
                .margin({ left: 5 })
            }
            .margin({ right: 20 })

            Row() {
              Line()
                .width(20)
                .height(2)
                .stroke(Color.Red)
                .strokeDashArray([5, 5])
              Text(`目标 ${this.targetWeight.toFixed(1)}kg`)
                .fontSize(12)
                .fontColor('#333333')
                .margin({ left: 5 })
            }
            .onClick(() => this.showTargetWeightDialog())

            Blank()

            Text(`${this.records.length} 条记录`)
              .fontSize(12)
              .fontColor('#666666')
          }
          .width('100%')
          .padding({ left: 10, right: 10 })
          .margin({ bottom: 10 })

          // 图表
          Stack() {
            // 背景网格
            this.GridBackground()
            
            // 数据点和连线
            if (this.chartDataPoints.length > 0) {
              // Y轴标签
              this.AxisLabels()
              
              // 目标线
              Line()
                .startPoint([this.chartPadding, this.targetWeightLineY])
                .endPoint([this.chartWidth - this.chartPadding, this.targetWeightLineY])
                .stroke(Color.Red)
                .strokeWidth(2)
                .strokeDashArray([5, 5])

              // 体重曲线
              Path()
                .width(this.chartWidth)
                .height(this.chartHeight)
                .commands(this.generatePathCommands())
                .stroke(Color.Blue)
                .strokeWidth(3)
                .fill(Color.Transparent)

              // 数据点
              ForEach(this.chartDataPoints.slice(), (point: ChartDataPoint, index?: number) => {
                Circle({ width: 10, height: 10 })
                  .fill(Color.Blue)
                  .position({ x: point.x - 5, y: point.y - 5 })
                  .onClick(() => {
                    this.selectedPoint = point;
                  })
              })
            }
          }
          .width(this.chartWidth)
          .height(this.chartHeight)
          .margin({ top: 10 })

          // 选中点信息
          if (this.selectedPoint) {
            Column() {
              Row() {
                Text('选中数据')
                  .fontSize(14)
                  .fontColor('#333333')
                  .fontWeight(FontWeight.Bold)
                Blank()
                Image($r('app.media.ic_back'))
                  .width(16)
                  .height(16)
                  .fillColor('#666666')
                  .onClick(() => {
                    this.selectedPoint = null;
                  })
              }
              .width('100%')
              .margin({ bottom: 10 })

              Text(`日期: ${this.formatDateOnly(this.selectedPoint.date.getTime())}`)
                .fontSize(14)
                .fontColor('#333333')
                .width('100%')

              Text(`体重: ${this.selectedPoint.weight.toFixed(1)} kg`)
                .fontSize(16)
                .fontWeight(FontWeight.Bold)
                .fontColor(Color.Blue)
                .width('100%')
                .margin({ top: 5 })

              Text(`目标: ${this.targetWeight.toFixed(1)} kg`)
                .fontSize(14)
                .fontColor('#666666')
                .width('100%')
                .margin({ top: 5 })

              Text(`差距: ${this.calculateWeightDiff(this.selectedPoint.weight, this.targetWeight)} kg`)
                .fontSize(14)
                .fontColor((this.selectedPoint.weight - this.targetWeight) > 0 ? Color.Red : '#00C853')
                .width('100%')
                .margin({ top: 5 })
            }
            .padding(15)
            .backgroundColor(Color.White)
            .borderRadius(10)
            .margin({ top: 15 })
            .shadow({ radius: 3, color: Color.Gray, offsetX: 0, offsetY: 2 })
          }
        } else {
          Column() {
            Text('暂无数据')
              .fontSize(18)
              .fontColor(Color.Gray)
              .margin({ top: '40%' })
            Text('记录体重后即可查看趋势图表')
              .fontSize(14)
              .fontColor(Color.Gray)
              .margin({ top: 10 })
          }
          .layoutWeight(1)
        }
      }
      .layoutWeight(1)
      .width('100%')
      .padding({ left: 20, right: 20 })
      }
      .layoutWeight(1)
      .width('100%')
      .backgroundColor('#F1F3F5')

      // 目标体重设置对话框
      TargetWeightSettingDialog({
        isVisible: this.showSettingDialog,
        currentTarget: this.currentTarget,
        onTargetChange: (target: TargetWeightRecord) => {
          this.onTargetChange(target);
        },
        onDismiss: () => {
          this.showSettingDialog = false;
        }
      })
    }
    .width('100%')
    .height('100%')
  }

  @Builder
  StatisticsCard() {
    if (this.records.length > 0) {
      Column() {
        Text('统计信息')
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor('#333333')
          .margin({ bottom: 15 })
          .width('100%')
          .textAlign(TextAlign.Center)

        Grid() {
          GridItem() {
            Column() {
              Text(`${this.statistics.currentWeight.toFixed(1)}`)
                .fontSize(20)
                .fontWeight(FontWeight.Bold)
                .fontColor(Color.Blue)
              Text('当前体重')
                .fontSize(12)
                .fontColor('#666666')
                .margin({ top: 5 })
            }
            .width('100%')
            .alignItems(HorizontalAlign.Center)
          }

          GridItem() {
            Column() {
              Text(`${this.statistics.totalChange > 0 ? '+' : ''}${this.statistics.totalChange.toFixed(1)}`)
                .fontSize(20)
                .fontWeight(FontWeight.Bold)
                .fontColor(this.statistics.totalChange > 0 ? Color.Red : '#00C853')
              Text('总体变化')
                .fontSize(12)
                .fontColor('#666666')
                .margin({ top: 5 })
            }
            .width('100%')
            .alignItems(HorizontalAlign.Center)
          }

          GridItem() {
            Column() {
              Text(`${this.statistics.avgWeight.toFixed(1)}`)
                .fontSize(20)
                .fontWeight(FontWeight.Bold)
                .fontColor('#FF9800')
              Text('平均体重')
                .fontSize(12)
                .fontColor('#666666')
                .margin({ top: 5 })
            }
            .width('100%')
            .alignItems(HorizontalAlign.Center)
          }

          GridItem() {
            Column() {
              Text(`${(this.statistics.maxWeight - this.statistics.minWeight).toFixed(1)}`)
                .fontSize(20)
                .fontWeight(FontWeight.Bold)
                .fontColor('#9C27B0')
              Text('体重范围')
                .fontSize(12)
                .fontColor('#666666')
                .margin({ top: 5 })
            }
            .width('100%')
            .alignItems(HorizontalAlign.Center)
          }
        }
        .columnsTemplate('1fr 1fr')
        .rowsGap(15)
        .columnsGap(15)
        .width('100%')
      }
      .width('100%')
      .padding(15)
      .backgroundColor(Color.White)
      .borderRadius(10)
      .margin({ bottom: 15 })
      .shadow({ radius: 3, color: Color.Gray, offsetX: 0, offsetY: 2 })
    }
  }

  @Builder
  AxisLabels() {
    if (this.records.length > 0) {
      Column() {
        ForEach([0, 1, 2, 3, 4, 5].slice(), (index: number, arrayIndex?: number) => {
          Text(`${(this.weightRange.maxWeight - (index * (this.weightRange.maxWeight - this.weightRange.minWeight) / 5)).toFixed(1)}`)
            .fontSize(10)
            .fontColor('#666666')
            .width(30)
            .textAlign(TextAlign.End)
            .margin({ top: index === 0 ? 0 : -15 })
            .position({ x: 5, y: this.chartPadding + index * (this.chartHeight - 2 * this.chartPadding) / 5 - 6 })
        })
      }
      .width(this.chartWidth)
      .height(this.chartHeight)
    }
  }

  @Builder
  GridBackground() {
    Column() {
      ForEach([0, 1, 2, 3, 4, 5].slice(), (index: number, arrayIndex?: number) => {
        Line()
          .startPoint([this.chartPadding, this.chartPadding + index * (this.chartHeight - 2 * this.chartPadding) / 5])
          .endPoint([this.chartWidth - this.chartPadding, this.chartPadding + index * (this.chartHeight - 2 * this.chartPadding) / 5])
          .stroke('#E5E5E5')
          .strokeWidth(1)
      })
      
      ForEach([0, 1, 2, 3, 4, 5].slice(), (index: number, arrayIndex?: number) => {
        Line()
          .startPoint([this.chartPadding + index * (this.chartWidth - 2 * this.chartPadding) / 5, this.chartPadding])
          .endPoint([this.chartPadding + index * (this.chartWidth - 2 * this.chartPadding) / 5, this.chartHeight - this.chartPadding])
          .stroke('#E5E5E5')
          .strokeWidth(1)
      })
    }
    .width(this.chartWidth)
    .height(this.chartHeight)
  }

  @Builder
  TargetWeightDialog() {
    Column() {
      Column() {
        Text('设置目标体重')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .margin({ bottom: 20 })

        TextInput({ placeholder: '请输入目标体重 (kg)' })
          .width('100%')
          .height(40)
          .fontSize(16)
          .backgroundColor('#F1F3F5')
          .margin({ bottom: 20 })
          .type(InputType.Number)
          .onChange((value: string) => {
            this.tempTargetWeight = value;
          })

        Row() {
          Button('取消')
            .type(ButtonType.Capsule)
            .layoutWeight(1)
            .height(40)
            .fontSize(16)
            .backgroundColor('#F1F3F5')
            .fontColor('#333333')
            .margin({ right: 10 })
            .onClick(() => {
              this.showTargetDialog = false;
            })

          Button('确定')
            .type(ButtonType.Capsule)
            .layoutWeight(1)
            .height(40)
            .fontSize(16)
            .backgroundColor('#007DFF')
            .onClick(() => {
              this.updateTargetWeight();
            })
        }
      }
      .width(300)
      .padding(20)
      .backgroundColor(Color.White)
      .borderRadius(12)
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .backgroundColor('rgba(0, 0, 0, 0.5)')
  }

  private calculateWeightDiff(currentWeight: number, targetWeight: number): string {
    const diff = currentWeight - targetWeight;
    return `${diff > 0 ? '+' : ''}${diff.toFixed(1)}`;
  }

  formatDateOnly(timestamp: number): string {
    const date = new Date(timestamp);
    const year = date.getFullYear();
    const month = (date.getMonth() + 1).toString().padStart(2, '0');
    const day = date.getDate().toString().padStart(2, '0');
    return `${year}/${month}/${day}`;
  }

  private calculateWeightRange(): WeightRange {
    const weights = this.records.map(r => r.weight);
    const minWeight = Math.min(...weights, this.targetWeight) - 2;
    const maxWeight = Math.max(...weights, this.targetWeight) + 2;

    return {
      minWeight,
      maxWeight
    };
  }

  private calculateStatistics(): Statistics {
    const weights = this.records.map(r => r.weight);
    const currentWeight = this.records[0].weight;
    const startWeight = this.records[this.records.length - 1].weight;
    const minWeight = Math.min(...weights);
    const maxWeight = Math.max(...weights);
    const avgWeight = weights.reduce((sum, w) => sum + w, 0) / weights.length;
    const totalChange = currentWeight - startWeight;

    return {
      currentWeight,
      startWeight,
      minWeight,
      maxWeight,
      avgWeight,
      totalChange
    };
  }

  private generatePathCommands(): string {
    if (this.chartDataPoints.length === 0) {
      return '';
    }

    let commands = `M ${this.chartDataPoints[0].x} ${this.chartDataPoints[0].y}`;
    
    for (let i = 1; i < this.chartDataPoints.length; i++) {
      commands += ` L ${this.chartDataPoints[i].x} ${this.chartDataPoints[i].y}`;
    }
    
    return commands;
  }
}