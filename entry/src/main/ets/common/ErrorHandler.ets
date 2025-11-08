/**
 * 错误处理工具类
 * 统一管理错误处理和用户反馈
 */
import promptAction from '@ohos.promptAction';
import hilog from '@ohos.hilog';
import { LogConstants, BusinessConstants } from './Constants';

export class ErrorHandler {
  private static readonly DOMAIN = LogConstants.DOMAIN;
  private static readonly TAG = LogConstants.TAG_PREFIX + 'ErrorHandler';

  /**
   * 处理数据库操作错误
   * @param error 错误对象
   * @param operation 操作名称
   * @param userMessage 用户显示的消息
   */
  static handleDatabaseError(error: any, operation: string, userMessage?: string): void {
    const errorMessage = error?.message || error || 'Unknown error';
    hilog.error(this.DOMAIN, this.TAG, `Database operation '${operation}' failed: ${errorMessage}`);
    
    const message = userMessage || '数据库操作失败，请重试';
    this.showToast(message);
  }

  /**
   * 处理导航错误
   * @param error 错误对象
   * @param targetPage 目标页面
   */
  static handleNavigationError(error: any, targetPage: string): void {
    const errorMessage = error?.message || error || 'Unknown error';
    hilog.error(this.DOMAIN, this.TAG, `Navigation to '${targetPage}' failed: ${errorMessage}`);
    this.showToast('页面跳转失败，请重试');
  }

  /**
   * 处理表单验证错误
   * @param validationErrors 验证错误列表
   */
  static handleValidationError(validationErrors: string[]): void {
    const message = validationErrors.length > 0 ? validationErrors[0] : '输入数据无效';
    hilog.warn(this.DOMAIN, this.TAG, `Validation failed: ${validationErrors.join(', ')}`);
    this.showToast(message);
  }

  /**
   * 处理通用错误
   * @param error 错误对象
   * @param context 错误上下文
   * @param userMessage 用户显示的消息
   */
  static handleGenericError(error: any, context: string, userMessage?: string): void {
    const errorMessage = error?.message || error || 'Unknown error';
    hilog.error(this.DOMAIN, this.TAG, `Error in '${context}': ${errorMessage}`);
    
    const message = userMessage || '操作失败，请重试';
    this.showToast(message);
  }

  /**
   * 显示成功消息
   * @param message 成功消息
   */
  static showSuccess(message: string): void {
    hilog.info(this.DOMAIN, this.TAG, `Success: ${message}`);
    this.showToast(message);
  }

  /**
   * 显示警告消息
   * @param message 警告消息
   */
  static showWarning(message: string): void {
    hilog.warn(this.DOMAIN, this.TAG, `Warning: ${message}`);
    this.showToast(message);
  }

  /**
   * 显示Toast消息
   * @param message 消息内容
   * @param duration 显示时长，默认使用常量值
   */
  private static showToast(message: string, duration: number = BusinessConstants.TOAST_DURATION): void {
    try {
      promptAction.showToast({
        message: message,
        duration: duration
      });
    } catch (error) {
      hilog.error(this.DOMAIN, this.TAG, `Failed to show toast: ${error}`);
    }
  }

  /**
   * 创建标准化的错误对象
   * @param message 错误消息
   * @param code 错误代码
   * @param context 错误上下文
   * @returns 标准化错误对象
   */
  static createError(message: string, code?: string, context?: string): Error {
    const fullMessage = context ? `[${context}] ${message}` : message;
    const error = new Error(fullMessage);
    if (code) {
      (error as any).code = code;
    }
    return error;
  }

  /**
   * 检查是否为网络相关错误
   * @param error 错误对象
   * @returns 是否为网络错误
   */
  static isNetworkError(error: any): boolean {
    const errorMessage = error?.message?.toLowerCase() || '';
    return errorMessage.includes('network') || 
           errorMessage.includes('connection') || 
           errorMessage.includes('timeout');
  }

  /**
   * 检查是否为权限相关错误
   * @param error 错误对象
   * @returns 是否为权限错误
   */
  static isPermissionError(error: any): boolean {
    const errorMessage = error?.message?.toLowerCase() || '';
    return errorMessage.includes('permission') || 
           errorMessage.includes('access denied') ||
           errorMessage.includes('unauthorized');
  }
}