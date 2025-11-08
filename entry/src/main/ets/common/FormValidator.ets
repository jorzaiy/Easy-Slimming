/**
 * 表单验证工具类
 * 统一管理表单验证逻辑
 */
import { BusinessConstants } from './Constants';

export interface ValidationResult {
  isValid: boolean;
  errorMessage: string;
}

export class FormValidator {
  /**
   * 验证体重输入
   * @param weightInput 体重输入字符串
   * @returns 验证结果
   */
  static validateWeight(weightInput: string): ValidationResult {
    if (!weightInput || weightInput.trim() === '') {
      return { isValid: false, errorMessage: '' };
    }
    
    const weight = parseFloat(weightInput);
    if (isNaN(weight)) {
      return { isValid: false, errorMessage: '请输入有效的数字' };
    }
    
    if (weight < BusinessConstants.MIN_WEIGHT || weight > BusinessConstants.MAX_WEIGHT) {
      return {
        isValid: false,
        errorMessage: `体重应在 ${BusinessConstants.MIN_WEIGHT}-${BusinessConstants.MAX_WEIGHT} kg 范围内`
      };
    }
    
    return { isValid: true, errorMessage: '' };
  }

  /**
   * 验证日期有效性
   * @param selectedDate 选择的日期
   * @returns 是否有效
   */
  static validateDate(selectedDate: Date): boolean {
    return selectedDate.getTime() <= new Date().getTime();
  }

  /**
   * 验证目标体重
   * @param weightInput 目标体重输入字符串
   * @returns 验证结果
   */
  static validateTargetWeight(weightInput: string): ValidationResult {
    if (!weightInput || weightInput.trim() === '') {
      return { isValid: false, errorMessage: '请输入目标体重' };
    }
    
    const weight = parseFloat(weightInput);
    if (isNaN(weight)) {
      return { isValid: false, errorMessage: '请输入有效的数字' };
    }
    
    if (weight <= 0 || weight > BusinessConstants.MAX_WEIGHT) {
      return {
        isValid: false,
        errorMessage: `目标体重应在 1-${BusinessConstants.MAX_WEIGHT} kg 范围内`
      };
    }
    
    return { isValid: true, errorMessage: '' };
  }

  /**
   * 验证表单整体有效性
   * @param weightInput 体重输入
   * @param selectedDate 选择日期
   * @returns 是否有效
   */
  static validateForm(weightInput: string, selectedDate: Date): boolean {
    const weightValidation = this.validateWeight(weightInput);
    return weightValidation.isValid && this.validateDate(selectedDate);
  }
}