// 定义体重记录的数据模型
export class WeightRecord {
  id: number;
  weight: number;
  date: number; // 使用时间戳存储日期
  notes?: string; // 可选备注字段
  
  private static targetWeight: number = 70.0; // 默认目标体重

  constructor(weight: number, date: number, id?: number, notes?: string) {
    this.id = id;
    this.weight = weight;
    this.date = date;
    this.notes = notes;
  }

  // 获取目标体重
  static getTargetWeight(): number {
    return WeightRecord.targetWeight;
  }

  // 设置目标体重
  static setTargetWeight(weight: number): void {
    if (weight > 0 && weight < 200) {
      WeightRecord.targetWeight = weight;
    }
  }
}