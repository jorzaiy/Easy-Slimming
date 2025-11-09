/**
 * 体重记录数据模型
 * 包含体重数据的基本信息和目标体重管理
 */
export interface ValidationResult {
  isValid: boolean;
  errors: string[];
}

export class WeightRecord {
  id: number;
  weight: number;
  date: number; // 使用时间戳存储日期
  notes?: string; // 可选备注字段

  private static targetWeight: number = 70.0; // 默认目标体重

  constructor(weight: number, date: number, id?: number, notes?: string) {
    if (weight < 0 || weight > 200) {
      throw new Error(`Invalid weight value: ${weight}. Must be between 0 and 200 (inclusive).`);
    }
    if (date <= 0) {
      throw new Error(`Invalid date value: ${date}. Must be a positive timestamp.`);
    }

    this.id = id ?? -1;
    this.weight = weight;
    this.date = date;
    this.notes = notes?.trim() || undefined;
  }

  /**
    * 获取目标体重
    * @returns 目标体重值
    */
  static getTargetWeight(): number {
    return WeightRecord.targetWeight;
  }

  /**
    * 设置目标体重
    * @param weight 目标体重值
    * @throws 当体重值无效时抛出异常
    */
  static setTargetWeight(weight: number): void {
    if (weight > 0 && weight < 200) {
      WeightRecord.targetWeight = weight;
    } else {
      throw new Error(`Invalid target weight: ${weight}. Must be between 0 and 200.`);
    }
  }

  /**
    * 获取与目标体重的差值
    * @returns 与目标体重的差值（正值表示超重，负值表示偏轻）
    */
  getDifferenceFromTarget(): number {
    return this.weight - WeightRecord.targetWeight;
  }

  /**
    * 检查是否达到目标体重
    * @param tolerance 允许的误差范围，默认为0.5kg
    * @returns 是否达到目标
    */
  isAtTarget(tolerance: number = 0.5): boolean {
    return Math.abs(this.getDifferenceFromTarget()) <= tolerance;
  }

  /**
    * 获取格式化的日期字符串
    * @returns 格式化的日期字符串
    */
  getFormattedDate(): string {
    const date = new Date(this.date);
    const year = date.getFullYear();
    const month = (date.getMonth() + 1).toString().padStart(2, '0');
    const day = date.getDate().toString().padStart(2, '0');
    const hour = date.getHours().toString().padStart(2, '0');
    const minute = date.getMinutes().toString().padStart(2, '0');
    return `${year}/${month}/${day} ${hour}:${minute}`;
  }

  /**
    * 验证记录数据的完整性
    * @returns 验证结果
    */
  validate(): ValidationResult {
    const errors: string[] = [];

    if (this.weight < 0 || this.weight > 200) {
      errors.push(`Invalid weight: ${this.weight}. Must be between 0 and 200 (inclusive).`);
    }

    if (this.date <= 0) {
      errors.push(`Invalid date: ${this.date}. Must be a positive timestamp.`);
    }

    if (this.date > Date.now()) {
      errors.push(`Date cannot be in the future.`);
    }

    const result: ValidationResult = {
      isValid: errors.length === 0,
      errors
    };

    return result;
  }
}