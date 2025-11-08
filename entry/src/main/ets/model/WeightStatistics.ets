/**
 * 体重统计数据模型
 * 包含各种统计指标和计算结果
 */
import { WeightRecord } from './WeightRecord';

export interface TrendData {
  period: string; // '7days' | '30days'
  change: number; // 变化量
  trend: 'up' | 'down' | 'stable'; // 趋势
  percentage: number; // 变化百分比
}

export class WeightStatistics {
  currentWeight: number;
  targetWeight: number;
  weightLoss: number; // 已减重量
  averageWeight: number; // 平均体重
  bmi: number; // BMI值
  maxWeight: number; // 最高体重
  minWeight: number; // 最低体重
  totalRecords: number; // 总记录数
  trend7Days: TrendData; // 7天趋势
  trend30Days: TrendData; // 30天趋势
  progressPercentage: number; // 减重进度百分比
  lastUpdated: number; // 最后更新时间

  constructor(
    currentWeight: number,
    targetWeight: number,
    weightLoss: number,
    averageWeight: number,
    bmi: number,
    maxWeight: number,
    minWeight: number,
    totalRecords: number,
    trend7Days: TrendData,
    trend30Days: TrendData,
    progressPercentage: number,
    lastUpdated: number
  ) {
    this.currentWeight = currentWeight;
    this.targetWeight = targetWeight;
    this.weightLoss = weightLoss;
    this.averageWeight = averageWeight;
    this.bmi = bmi;
    this.maxWeight = maxWeight;
    this.minWeight = minWeight;
    this.totalRecords = totalRecords;
    this.trend7Days = trend7Days;
    this.trend30Days = trend30Days;
    this.progressPercentage = progressPercentage;
    this.lastUpdated = lastUpdated;
  }

  /**
   * 获取BMI状态描述
   */
  getBmiStatus(): string {
    if (this.bmi < 18.5) return '偏瘦';
    if (this.bmi < 24) return '正常';
    if (this.bmi < 28) return '偏胖';
    return '肥胖';
  }

  /**
   * 获取BMI状态颜色
   */
  getBmiStatusColor(): string {
    if (this.bmi < 18.5) return '#FF9800'; // 橙色 - 偏瘦
    if (this.bmi < 24) return '#4CAF50'; // 绿色 - 正常
    if (this.bmi < 28) return '#FF9800'; // 橙色 - 偏胖
    return '#F44336'; // 红色 - 肥胖
  }

  /**
   * 获取减重进度状态
   */
  getProgressStatus(): 'achieved' | 'close' | 'inProgress' {
    if (this.weightLoss >= 0) return 'achieved'; // 已达到或超过目标
    if (Math.abs(this.weightLoss) <= 2) return 'close'; // 接近目标
    return 'inProgress'; // 进行中
  }

  /**
   * 获取进度状态颜色
   */
  getProgressStatusColor(): string {
    const status = this.getProgressStatus();
    switch (status) {
      case 'achieved': return '#4CAF50';
      case 'close': return '#FF9800';
      case 'inProgress': return '#2196F3';
      default: return '#666666';
    }
  }

  /**
   * 格式化趋势文本
   */
  formatTrendText(trend: TrendData): string {
    const direction = trend.trend === 'up' ? '↑' : trend.trend === 'down' ? '↓' : '→';
    const changeText = Math.abs(trend.change).toFixed(1);
    const percentageText = Math.abs(trend.percentage).toFixed(1);
    return `${direction} ${changeText}kg (${percentageText}%)`;
  }

  /**
   * 获取趋势颜色
   */
  getTrendColor(trend: TrendData): string {
    if (trend.trend === 'stable') return '#666666';
    // 对于减重，下降是好的趋势
    return trend.trend === 'down' ? '#4CAF50' : '#F44336';
  }
}

/**
 * 统计计算工具类
 */
export class StatisticsCalculator {
  private static readonly DEFAULT_HEIGHT = 170; // 默认身高(cm)

  /**
   * 从体重记录计算统计数据
   */
  static calculateStatistics(records: WeightRecord[], height?: number): WeightStatistics | null {
    if (!records || records.length === 0) {
      return null;
    }

    const currentWeight = records[0].weight; // 最新体重
    const targetWeight = WeightRecord.getTargetWeight();
    const weightLoss = targetWeight - currentWeight; // 已减重量（正数表示已减重）

    // 计算平均体重
    const totalWeight = records.reduce((sum, record) => sum + record.weight, 0);
    const averageWeight = totalWeight / records.length;

    // 计算BMI
    const userHeight = height || this.DEFAULT_HEIGHT;
    const bmi = currentWeight / Math.pow(userHeight / 100, 2);

    // 找出最高和最低体重
    const weights = records.map(r => r.weight);
    const maxWeight = Math.max(...weights);
    const minWeight = Math.min(...weights);

    // 计算趋势
    const trend7Days = this.calculateTrend(records, 7);
    const trend30Days = this.calculateTrend(records, 30);

    // 计算进度百分比
    const initialWeight = records[records.length - 1].weight; // 最初始体重
    const totalLossNeeded = initialWeight - targetWeight;
    const currentLoss = initialWeight - currentWeight;
    const progressPercentage = totalLossNeeded > 0 ? (currentLoss / totalLossNeeded) * 100 : 0;

    return new WeightStatistics(
      currentWeight,
      targetWeight,
      weightLoss,
      averageWeight,
      bmi,
      maxWeight,
      minWeight,
      records.length,
      trend7Days,
      trend30Days,
      progressPercentage,
      Date.now()
    );
  }

  /**
   * 计算指定天数内的趋势
   */
  private static calculateTrend(records: WeightRecord[], days: number): TrendData {
    const now = Date.now();
    const daysAgo = now - (days * 24 * 60 * 60 * 1000);

    // 筛选指定天数内的记录
    const recentRecords = records.filter(record => record.date >= daysAgo);
    
    if (recentRecords.length < 2) {
      return {
        period: `${days}days`,
        change: 0,
        trend: 'stable',
        percentage: 0
      };
    }

    // 取最早和最晚的记录
    const earliestRecord = recentRecords[recentRecords.length - 1];
    const latestRecord = recentRecords[0];

    const change = latestRecord.weight - earliestRecord.weight;
    const percentage = (change / earliestRecord.weight) * 100;

    let trend: 'up' | 'down' | 'stable';
    if (Math.abs(change) < 0.1) {
      trend = 'stable';
    } else if (change > 0) {
      trend = 'up';
    } else {
      trend = 'down';
    }

    return {
      period: `${days}days`,
      change,
      trend,
      percentage
    };
  }
}
