/**
 * 统计功能测试
 */
import { WeightRecord } from '../main/ets/model/WeightRecord';
import { WeightStatistics, StatisticsCalculator } from '../main/ets/model/WeightStatistics';

describe('StatisticsCalculator', () => {
  it('should calculate statistics correctly', () => {
    // 创建测试数据
    const now = Date.now();
    const dayMs = 24 * 60 * 60 * 1000;
    
    const records: WeightRecord[] = [
      new WeightRecord(75.0, now - 30 * dayMs), // 30天前
      new WeightRecord(74.5, now - 20 * dayMs), // 20天前
      new WeightRecord(73.8, now - 10 * dayMs), // 10天前
      new WeightRecord(73.2, now - 5 * dayMs),  // 5天前
      new WeightRecord(72.5, now)              // 今天
    ];

    // 设置目标体重
    WeightRecord.setTargetWeight(70.0);

    // 计算统计数据
    const stats = StatisticsCalculator.calculateStatistics(records, 170);

    // 验证结果
    expect(stats).not.toBeNull();
    expect(stats!.currentWeight).toBe(72.5);
    expect(stats!.targetWeight).toBe(70.0);
    expect(stats!.weightLoss).toBe(-2.5); // 目标体重 - 当前体重
    expect(stats!.averageWeight).toBeCloseTo(73.8, 1);
    expect(stats!.maxWeight).toBe(75.0);
    expect(stats!.minWeight).toBe(72.5);
    expect(stats!.totalRecords).toBe(5);
  });

  it('should handle empty records', () => {
    const stats = StatisticsCalculator.calculateStatistics([]);
    expect(stats).toBeNull();
  });

  it('should calculate BMI correctly', () => {
    const now = Date.now();
    const records = [new WeightRecord(70.0, now)];
    WeightRecord.setTargetWeight(70.0);

    const stats = StatisticsCalculator.calculateStatistics(records, 170);
    expect(stats!.bmi).toBeCloseTo(24.22, 2); // 70 / (1.7 * 1.7)
  });

  it('should calculate trends correctly', () => {
    const now = Date.now();
    const dayMs = 24 * 60 * 60 * 1000;
    
    const records: WeightRecord[] = [
      new WeightRecord(75.0, now - 30 * dayMs),
      new WeightRecord(74.5, now - 20 * dayMs),
      new WeightRecord(73.8, now - 10 * dayMs),
      new WeightRecord(73.2, now - 5 * dayMs),
      new WeightRecord(72.5, now)
    ];

    WeightRecord.setTargetWeight(70.0);
    const stats = StatisticsCalculator.calculateStatistics(records, 170);

    // 验证趋势计算
    expect(stats!.trend7Days.trend).toBe('down'); // 体重下降
    expect(stats!.trend30Days.trend).toBe('down'); // 体重下降
  });
});
