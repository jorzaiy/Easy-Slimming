/**
 * 统计数据服务
 * 负责获取、计算和缓存统计数据
 */
import { WeightRecord } from '../model/WeightRecord';
import { WeightStatistics, StatisticsCalculator } from '../model/WeightStatistics';
import { getWeightRecordDao } from './WeightRecordDao';
import { common } from '@kit.AbilityKit';
import hilog from '@ohos.hilog';
import { LogConstants } from '../common/Constants';
import preferences from '@ohos.data.preferences';

const DOMAIN = LogConstants.DOMAIN;
const TAG = LogConstants.TAG_PREFIX + 'StatisticsService';

export class StatisticsService {
  private static readonly CACHE_KEY = 'weight_statistics_cache';
  private static readonly CACHE_DURATION = 5 * 60 * 1000; // 5分钟缓存
  private static readonly HEIGHT_KEY = 'user_height';

  /**
   * 获取统计数据（带缓存）
   */
  static async getStatistics(context: common.Context): Promise<WeightStatistics | null> {
    try {
      // 先尝试从缓存获取
      const cached = await this.getCachedStatistics(context);
      if (cached && !this.isCacheExpired(cached.lastUpdated)) {
        hilog.info(DOMAIN, TAG, 'Using cached statistics');
        return cached;
      }

      // 缓存过期或不存在，重新计算
      hilog.info(DOMAIN, TAG, 'Calculating fresh statistics');
      const dao = await getWeightRecordDao(context);
      if (!dao) {
        throw new Error('Failed to get WeightRecordDao');
      }

      const records = await dao.queryAll();
      const height = await this.getUserHeight(context);
      
      const statistics = StatisticsCalculator.calculateStatistics(records, height);
      
      // 缓存结果
      if (statistics) {
        await this.cacheStatistics(context, statistics);
      }

      return statistics;
    } catch (e) {
      hilog.error(DOMAIN, TAG, `Failed to get statistics: ${e}`);
      return null;
    }
  }

  /**
   * 强制刷新统计数据
   */
  static async refreshStatistics(context: common.Context): Promise<WeightStatistics | null> {
    try {
      // 清除缓存
      await this.clearCache(context);
      
      // 重新计算
      return await this.getStatistics(context);
    } catch (e) {
      hilog.error(DOMAIN, TAG, `Failed to refresh statistics: ${e}`);
      return null;
    }
  }

  /**
   * 缓存统计数据
   */
  private static async cacheStatistics(context: common.Context, statistics: WeightStatistics): Promise<void> {
    try {
      const dataStore = await preferences.getPreferences(context, 'weight_app_stats');
      await dataStore.put(this.CACHE_KEY, JSON.stringify(statistics));
      await dataStore.flush();
      hilog.info(DOMAIN, TAG, 'Statistics cached successfully');
    } catch (e) {
      hilog.error(DOMAIN, TAG, `Failed to cache statistics: ${e}`);
    }
  }

  /**
   * 获取缓存的统计数据
   */
  private static async getCachedStatistics(context: common.Context): Promise<WeightStatistics | null> {
    try {
      const dataStore = await preferences.getPreferences(context, 'weight_app_stats');
      const cachedData = await dataStore.get(this.CACHE_KEY, '') as string;
      
      if (!cachedData) {
        return null;
      }

      const data = JSON.parse(cachedData);
      return new WeightStatistics(
        data.currentWeight,
        data.targetWeight,
        data.weightLoss,
        data.averageWeight,
        data.bmi,
        data.maxWeight,
        data.minWeight,
        data.totalRecords,
        data.trend7Days,
        data.trend30Days,
        data.progressPercentage,
        data.lastUpdated
      );
    } catch (e) {
      hilog.error(DOMAIN, TAG, `Failed to get cached statistics: ${e}`);
      return null;
    }
  }

  /**
   * 检查缓存是否过期
   */
  private static isCacheExpired(lastUpdated: number): boolean {
    return Date.now() - lastUpdated > this.CACHE_DURATION;
  }

  /**
   * 清除缓存
   */
  private static async clearCache(context: common.Context): Promise<void> {
    try {
      const dataStore = await preferences.getPreferences(context, 'weight_app_stats');
      await dataStore.delete(this.CACHE_KEY);
      await dataStore.flush();
      hilog.info(DOMAIN, TAG, 'Cache cleared successfully');
    } catch (e) {
      hilog.error(DOMAIN, TAG, `Failed to clear cache: ${e}`);
    }
  }

  /**
   * 保存用户身高
   */
  static async saveUserHeight(context: common.Context, height: number): Promise<void> {
    try {
      const dataStore = await preferences.getPreferences(context, 'weight_app_settings');
      await dataStore.put(this.HEIGHT_KEY, height);
      await dataStore.flush();
      hilog.info(DOMAIN, TAG, `User height saved: ${height}cm`);
      
      // 清除统计缓存，因为身高变化会影响BMI
      await this.clearCache(context);
    } catch (e) {
      hilog.error(DOMAIN, TAG, `Failed to save user height: ${e}`);
    }
  }

  /**
   * 获取用户身高
   */
  static async getUserHeight(context: common.Context): Promise<number> {
    try {
      const dataStore = await preferences.getPreferences(context, 'weight_app_settings');
      const height = await dataStore.get(this.HEIGHT_KEY, 170) as number; // 默认170cm
      hilog.info(DOMAIN, TAG, `User height retrieved: ${height}cm`);
      return height;
    } catch (e) {
      hilog.error(DOMAIN, TAG, `Failed to get user height: ${e}`);
      return 170; // 默认身高
    }
  }

  /**
   * 获取指定时间范围的统计概览
   */
  static async getRangeStatistics(
    context: common.Context, 
    startDate: number, 
    endDate: number
  ): Promise<{
    count: number;
    average: number;
    min: number;
    max: number;
    change: number;
  } | null> {
    try {
      const dao = await getWeightRecordDao(context);
      if (!dao) {
        throw new Error('Failed to get WeightRecordDao');
      }

      const records = await dao.queryByDateRange(startDate, endDate);
      
      if (records.length === 0) {
        return null;
      }

      const weights = records.map(r => r.weight);
      const average = weights.reduce((sum, w) => sum + w, 0) / weights.length;
      const min = Math.min(...weights);
      const max = Math.max(...weights);
      const change = records.length > 1 ? records[records.length - 1].weight - records[0].weight : 0;

      return {
        count: records.length,
        average: Math.round(average * 10) / 10,
        min: Math.round(min * 10) / 10,
        max: Math.round(max * 10) / 10,
        change: Math.round(change * 10) / 10
      };
    } catch (e) {
      hilog.error(DOMAIN, TAG, `Failed to get range statistics: ${e}`);
      return null;
    }
  }

  /**
   * 根据时间范围类型获取日期范围
   */
  static getDateRange(range: string): { startDate: number; endDate: number } {
    const now = Date.now();
    const today = new Date(now);
    today.setHours(0, 0, 0, 0);
    const endDate = today.getTime() + 24 * 60 * 60 * 1000 - 1; // 今天结束

    let startDate: number;

    switch (range) {
      case '7days':
        startDate = now - 7 * 24 * 60 * 60 * 1000;
        break;
      case '30days':
        startDate = now - 30 * 24 * 60 * 60 * 1000;
        break;
      case 'week':
        const dayOfWeek = today.getDay();
        startDate = today.getTime() - dayOfWeek * 24 * 60 * 60 * 1000;
        break;
      case 'month':
        const firstDayOfMonth = new Date(today.getFullYear(), today.getMonth(), 1);
        startDate = firstDayOfMonth.getTime();
        break;
      case 'all':
      default:
        startDate = 0; // 从最早开始
        break;
    }

    return { startDate, endDate };
  }

  /**
   * 获取时间范围统计（基于范围类型）
   */
  static async getTimeRangeStatistics(
    context: common.Context,
    range: string
  ): Promise<{
    count: number;
    average: number;
    min: number;
    max: number;
    change: number;
  } | null> {
    const { startDate, endDate } = this.getDateRange(range);
    return await this.getRangeStatistics(context, startDate, endDate);
  }
}
