// 定义体重记录的数据模型
export class WeightRecord {
  id: number;
  weight: number;
  date: number; // 使用时间戳存储日期

  constructor(weight: number, date: number, id?: number) {
    this.id = id;
    this.weight = weight;
    this.date = date;
  }
}