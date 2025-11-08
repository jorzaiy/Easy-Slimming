/**
 * 导航工具类
 * 统一管理页面导航逻辑
 */
import router from '@ohos.router';
import { BusinessConstants } from './Constants';
import hilog from '@ohos.hilog';
import { LogConstants } from './Constants';

export class NavigationHelper {
  private static readonly DOMAIN = LogConstants.DOMAIN;
  private static readonly TAG = LogConstants.TAG_PREFIX + 'Navigation';

  /**
    * 安全导航到指定页面
    * @param url 目标页面URL
    * @param params 传递的参数
    * @param delay 延迟时间（毫秒），默认为0
    */
  static async navigateToPage(url: string, params?: object, delay: number = 0): Promise<void> {
    try {
      if (delay > 0) {
        await new Promise(resolve => setTimeout(resolve, delay));
      }

      const navigationParams = params ? { url, params } : { url };
      await router.pushUrl(navigationParams);

      hilog.info(NavigationHelper.DOMAIN, NavigationHelper.TAG, `Successfully navigated to: ${url}`);
    } catch (error) {
      hilog.error(NavigationHelper.DOMAIN, NavigationHelper.TAG, `Failed to navigate to ${url}, cause: ${error}`);
      throw new Error(`Failed to navigate to ${url}: ${error}`);
    }
  }

  /**
    * 安全返回上一页
    * @param delay 延迟时间（毫秒），默认为0
    */
  static async navigateBack(delay: number = 0): Promise<void> {
    try {
      if (delay > 0) {
        await new Promise(resolve => setTimeout(resolve, delay));
      }

      await router.back();
      hilog.info(NavigationHelper.DOMAIN, NavigationHelper.TAG, 'Successfully navigated back');
    } catch (error) {
      hilog.error(NavigationHelper.DOMAIN, NavigationHelper.TAG, `Failed to navigate back, cause: ${error}`);
      throw new Error(`Failed to navigate back: ${error}`);
    }
  }

  /**
    * 带用户反馈的安全返回
    * @param delay 延迟时间（毫秒）
    */
  static async navigateBackWithFeedback(delay: number = BusinessConstants.NAVIGATION_DELAY): Promise<void> {
    try {
      await NavigationHelper.navigateBack(delay);
    } catch (error) {
      hilog.error(NavigationHelper.DOMAIN, NavigationHelper.TAG, `Navigation back failed, ignoring error: ${error}`);
      // 即使导航失败也不抛出异常，避免阻塞用户操作
    }
  }

  /**
    * 获取路由参数
    * @returns 路由参数对象
    */
  static getRouteParams(): object | undefined {
    try {
      const params = router.getParams();
      return params !== null ? params : undefined;
    } catch (error) {
      hilog.error(NavigationHelper.DOMAIN, NavigationHelper.TAG, `Failed to get route params, cause: ${error}`);
      return undefined;
    }
  }

  /**
    * 清除导航历史
    */
  static async clear(): Promise<void> {
    try {
      await router.clear();
      hilog.info(NavigationHelper.DOMAIN, NavigationHelper.TAG, 'Navigation history cleared');
    } catch (error) {
      hilog.error(NavigationHelper.DOMAIN, NavigationHelper.TAG, `Failed to clear navigation, cause: ${error}`);
      throw new Error(`Failed to clear navigation: ${error}`);
    }
  }
}