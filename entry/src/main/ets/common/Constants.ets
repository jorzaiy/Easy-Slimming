/**
 * 应用程序常量定义
 * 统一管理颜色、尺寸、文本等常量
 */

// 颜色常量
export class AppColors {
  static readonly PRIMARY = '#007DFF';
  static readonly SECONDARY = '#6C757D';
  static readonly WHITE = '#FFFFFF';
  static readonly BACKGROUND = '#F1F3F5';
  static readonly GRAY = '#666666';
  static readonly LIGHT_GRAY = '#CCCCCC';
  static readonly BORDER_GRAY = '#E5E5E5';
  static readonly ERROR = '#FF0000';
  static readonly SUCCESS = '#4CAF50';
  static readonly WARNING = '#FF9800';
  static readonly BLUE = '#2196F3';
  static readonly GREEN = '#4CAF50';
  static readonly ORANGE = '#FF9800';
  static readonly RED = '#F44336';
}

// 尺寸常量
export class AppDimensions {
  static readonly BUTTON_HEIGHT = 50;
  static readonly BUTTON_HEIGHT_SMALL = 40;
  static readonly BORDER_RADIUS = 12;
  static readonly BORDER_RADIUS_SMALL = 10;
  static readonly PADDING_LARGE = 20;
  static readonly PADDING_MEDIUM = 15;
  static readonly PADDING_SMALL = 10;
  static readonly MARGIN_LARGE = 30;
  static readonly MARGIN_MEDIUM = 20;
  static readonly MARGIN_SMALL = 10;
  static readonly ICON_SIZE = 24;
  static readonly ICON_SIZE_SMALL = 22;
}

// 文本常量
export class AppText {
  static readonly FONT_SIZE_LARGE = 38;
  static readonly FONT_SIZE_TITLE = 24;
  static readonly FONT_SIZE_SUBTITLE = 20;
  static readonly FONT_SIZE_BODY = 18;
  static readonly FONT_SIZE_SMALL = 16;
  static readonly FONT_SIZE_TINY = 14;
}

// 业务常量
export class BusinessConstants {
  static readonly MIN_WEIGHT = 30;
  static readonly MAX_WEIGHT = 200;
  static readonly MAX_NOTES_LENGTH = 200;
  static readonly MAX_REMARK_CONTENT_LENGTH = 200;
  static readonly DEFAULT_TARGET_WEIGHT = 70.0;
  static readonly TOAST_DURATION = 2000;
  static readonly NAVIGATION_DELAY = 500;
}

// 日志常量
export class LogConstants {
  static readonly DOMAIN = 0x0000;
  static readonly TAG_PREFIX = 'WeightApp_';
}