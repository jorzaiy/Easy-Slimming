/**
 * 备注数据模型
 * 支持饮食、运动、生理期等多种类型的备注
 */
import { BusinessConstants } from '../common/Constants';

export enum RemarkType {
  DIET = 'diet',      // 饮食
  EXERCISE = 'exercise', // 运动
  MENSTRUAL = 'menstrual', // 生理期
  OTHER = 'other'     // 其他
}
export interface ValidationResult {
  isValid: boolean;
  errors: string[];
}

export interface RemarkTypeInfo {
  type: RemarkType;
  displayName: string;
  icon: string;
  color: string;
}

export class Remark {
  id: number;
  recordId: number;  // 关联的体重记录ID
  type: RemarkType;  // 备注类型
  content: string;   // 备注内容
  timestamp: number; // 创建/修改时间戳

  constructor(recordId: number, type: RemarkType, content: string, timestamp?: number, id?: number) {
    if (recordId <= 0) {
      throw new Error(`Invalid recordId: ${recordId}. Must be a positive number.`);
    }
    if (!content || content.trim().length === 0) {
      throw new Error(`Content cannot be empty.`);
    }
    if (content.trim().length > BusinessConstants.MAX_REMARK_CONTENT_LENGTH) {
      throw new Error(`Content too long: ${content.length}. Maximum length is ${BusinessConstants.MAX_REMARK_CONTENT_LENGTH}.`);
    }

    this.id = id ?? -1;
    this.recordId = recordId;
    this.type = type;
    this.content = content.trim();
    this.timestamp = timestamp ?? Date.now();
  }

  /**
   * 获取备注类型的显示名称
   * @returns 备注类型的中文显示名称
   */
  getTypeDisplayName(): string {
    switch (this.type) {
      case RemarkType.DIET:
        return '饮食';
      case RemarkType.EXERCISE:
        return '运动';
      case RemarkType.MENSTRUAL:
        return '生理期';
      case RemarkType.OTHER:
        return '其他';
      default:
        return '未知';
    }
  }

  /**
   * 获取备注类型对应的颜色
   * @returns 颜色代码
   */
  getTypeColor(): string {
    switch (this.type) {
      case RemarkType.DIET:
        return '#4CAF50'; // 绿色
      case RemarkType.EXERCISE:
        return '#2196F3'; // 蓝色
      case RemarkType.MENSTRUAL:
        return '#E91E63'; // 粉色
      case RemarkType.OTHER:
        return '#757575'; // 灰色
      default:
        return '#757575';
    }
  }

  /**
   * 获取备注类型对应的图标
   * @returns 图标名称
   */
  getTypeIcon(): string {
    switch (this.type) {
      case RemarkType.DIET:
        return '🍽️';
      case RemarkType.EXERCISE:
        return '🏃';
      case RemarkType.MENSTRUAL:
        return '🩸';
      case RemarkType.OTHER:
        return '📝';
      default:
        return '📝';
    }
  }

  /**
   * 获取格式化的时间字符串
   * @returns 格式化的时间字符串
   */
  getFormattedTimestamp(): string {
    const date = new Date(this.timestamp);
    const year = date.getFullYear();
    const month = (date.getMonth() + 1).toString().padStart(2, '0');
    const day = date.getDate().toString().padStart(2, '0');
    const hour = date.getHours().toString().padStart(2, '0');
    const minute = date.getMinutes().toString().padStart(2, '0');
    return `${year}/${month}/${day} ${hour}:${minute}`;
  }

  /**
   * 更新备注内容
   * @param newContent 新的备注内容
   * @returns 是否更新成功
   */
  updateContent(newContent: string): boolean {
    if (!newContent || newContent.trim().length === 0) {
      return false;
    }
    if (newContent.trim().length > 200) {
      return false;
    }
    
    this.content = newContent.trim();
    this.timestamp = Date.now();
    return true;
  }

  /**
   * 验证备注数据的完整性
   * @returns 验证结果
   */
  validate(): ValidationResult {
    const errors: string[] = [];

    if (this.recordId <= 0) {
      errors.push(`Invalid recordId: ${this.recordId}. Must be a positive number.`);
    }

    if (!this.content || this.content.length === 0) {
      errors.push('Content cannot be empty.');
    }

    if (this.content.length > 200) {
      errors.push(`Content too long: ${this.content.length}. Maximum length is 200.`);
    }

    if (this.timestamp <= 0) {
      errors.push(`Invalid timestamp: ${this.timestamp}. Must be a positive number.`);
    }

    if (this.timestamp > Date.now()) {
      errors.push('Timestamp cannot be in the future.');
    }

    const result: ValidationResult = {
      isValid: errors.length === 0,
      errors
    };

    return result;
  }
  /**
   * 获取所有可用的备注类型
   * @returns 备注类型数组
   */
  static getAllTypes(): RemarkTypeInfo[] {
    return [
      {
        type: RemarkType.DIET,
        displayName: '饮食',
        icon: '🍽️',
        color: '#4CAF50'
      },
      {
        type: RemarkType.EXERCISE,
        displayName: '运动',
        icon: '🏃',
        color: '#2196F3'
      },
      {
        type: RemarkType.MENSTRUAL,
        displayName: '生理期',
        icon: '🩸',
        color: '#E91E63'
      },
      {
        type: RemarkType.OTHER,
        displayName: '其他',
        icon: '📝',
        color: '#757575'
      }
    ];
  }
}