import hilog from '@ohos.hilog';
import router from '@ohos.router';
import promptAction from '@ohos.promptAction';
import { AppColors, AppDimensions, AppText, BusinessConstants, LogConstants } from '../common/Constants';
import { getAppDao } from '../common/Global';
import { WeightRecord } from '../model/WeightRecord';
import { NumericKeypad } from '../components/NumericKeypad';
import { getAppTargetWeightService } from '../common/Global';

interface KeypadCallbacks {
  onValueChange?: (value: string) => void;
  onConfirm?: (value: string) => void;
  onCancel?: () => void;
}

const DOMAIN = LogConstants.DOMAIN;
const TAG = LogConstants.TAG_PREFIX + 'Index';

@Entry
@Component
struct Index {
  @State latestRecord: WeightRecord | null = null;
  @State weightInput: string = '';
  @State error: string = '';
  @State isSaving: boolean = false;
  @State currentTargetWeight: number = 70.0;
  @Provide callbacks: KeypadCallbacks = {};

  async aboutToAppear() {
    await this.loadLatestRecord();
    await this.loadCurrentTargetWeight();
    this.setupKeypadCallbacks();
  }

  onPageShow() {
    this.loadLatestRecord();
  }

  private setupKeypadCallbacks() {
    this.callbacks = {
      onValueChange: (value: string) => {
        this.weightInput = value;
        this.error = '';
      },
      onConfirm: async (value: string) => {
        await this.handleConfirmWeight(value);
      },
      onCancel: () => {
        this.weightInput = '';
        this.error = '';
      }
    };
  }

  private async handleConfirmWeight(weightStr: string) {
    this.error = '';
    if (this.isSaving) {
      return;
    }

    const weight = parseFloat(weightStr);
    if (isNaN(weight) || weight < BusinessConstants.MIN_WEIGHT || weight > BusinessConstants.MAX_WEIGHT) {
      this.error = `体重应在 ${BusinessConstants.MIN_WEIGHT}-${BusinessConstants.MAX_WEIGHT} kg 范围内`;
      return;
    }

    this.isSaving = true;
    try {
      const dao = getAppDao();
      if (!dao) {
        throw new Error('Global DAO not initialized');
      }

      const newRecord = new WeightRecord(weight, Date.now());
      const recordId = await dao.insert(newRecord);

      if (recordId > 0) {
        hilog.info(DOMAIN, TAG, `Successfully inserted weight record with id: ${recordId}`);
        promptAction.showToast({
          message: '体重记录保存成功',
          duration: 2000
        });

        await this.loadLatestRecord();
        this.weightInput = '';
        this.error = '';
      } else {
        throw new Error('Failed to insert weight record');
      }
    } catch (e) {
      hilog.error(DOMAIN, TAG, `Failed to save weight record, cause: ${e}`);
      this.error = '保存失败，请重试';
      promptAction.showToast({
        message: '保存失败，请重试',
        duration: 2000
      });
    } finally {
      this.isSaving = false;
    }
  }

  formatDate(timestamp: number): string {
    const date = new Date(timestamp);
    const year = date.getFullYear();
    const month = (date.getMonth() + 1).toString().padStart(2, '0');
    const day = date.getDate().toString().padStart(2, '0');
    const hour = date.getHours().toString().padStart(2, '0');
    const minute = date.getMinutes().toString().padStart(2, '0');
    return `${year}/${month}/${day} ${hour}:${minute}`;
  }

  private calculateDifferenceFromTarget(): number | null {
    if (!this.latestRecord) {
      return null;
    }
    return this.latestRecord.weight - this.currentTargetWeight;
  }

  private getDifferenceColor(): string {
    const diff = this.calculateDifferenceFromTarget();
    if (diff === null) {
      return AppColors.GRAY;
    }
    if (diff > 0) {
      return AppColors.ORANGE; // 超重
    } else if (diff < 0) {
      return AppColors.GREEN; // 未达目标
    } else {
      return AppColors.SUCCESS; // 达到目标
    }
  }

  private getDifferenceText(): string {
    const diff = this.calculateDifferenceFromTarget();
    if (diff === null) {
      return '';
    }
    const sign = diff > 0 ? '+' : '';
    return `${sign}${diff.toFixed(1)} kg`;
  }

  async loadLatestRecord() {
    try {
      const dao = getAppDao();
      if (!dao) {
        throw new Error('Global DAO not initialized');
      }
      const records = await dao.queryAll();
      if (records.length > 0) {
        this.latestRecord = records[0];
        hilog.info(DOMAIN, TAG, 'Loaded latest record.');
      } else {
        this.latestRecord = null;
      }
    } catch (e) {
      hilog.error(DOMAIN, TAG, `Failed to load latest record, cause: ${e}`);
    }
  }

  private async loadCurrentTargetWeight() {
    try {
      const service = getAppTargetWeightService();
      if (service) {
        const targetRecord = await service.getCurrentTarget();
        if (targetRecord) {
          this.currentTargetWeight = targetRecord.targetWeight;
        }
      }
    } catch (e) {
      hilog.error(DOMAIN, TAG, `Failed to load target weight, cause: ${e}`);
    }
  }

  private navigateToEditRecord() {
    if (!this.latestRecord) {
      return;
    }
    try {
      router.pushUrl({
        url: 'pages/WeightEditForm',
        params: { record: this.latestRecord }
      });
    } catch (error) {
      hilog.error(DOMAIN, TAG, `Failed to navigate to WeightEditForm, cause: ${error}`);
    }
  }

  private navigateToPage(url: string) {
    try {
      router.pushUrl({ url });
    } catch (error) {
      hilog.error(DOMAIN, TAG, `Failed to navigate to ${url}, cause: ${error}`);
    }
  }

  build() {
    Column() {
      // 第一栏 - 上次记录展示
      Column() {
        Text('最近记录')
          .fontSize(AppText.FONT_SIZE_SUBTITLE)
          .fontWeight(FontWeight.Bold)
          .margin({ bottom: AppDimensions.MARGIN_MEDIUM })

        if (this.latestRecord) {
          Column() {
            Text(this.latestRecord.weight.toFixed(1))
              .fontSize(48)
              .fontWeight(FontWeight.Bold)
              .fontColor(AppColors.PRIMARY)

            Text('kg')
              .fontSize(AppText.FONT_SIZE_BODY)
              .fontColor(AppColors.GRAY)
              .margin({ top: 5 })

            Divider()
              .margin({ top: AppDimensions.MARGIN_MEDIUM, bottom: AppDimensions.MARGIN_MEDIUM })

            Text(this.formatDate(this.latestRecord.date))
              .fontSize(AppText.FONT_SIZE_SMALL)
              .fontColor(AppColors.GRAY)
              .margin({ bottom: AppDimensions.MARGIN_MEDIUM })

            if (this.getDifferenceText()) {
              Column() {
                Text('差值')
                  .fontSize(AppText.FONT_SIZE_SMALL)
                  .fontColor(AppColors.GRAY)

                Text(this.getDifferenceText())
                  .fontSize(AppText.FONT_SIZE_SUBTITLE)
                  .fontWeight(FontWeight.Bold)
                  .fontColor(this.getDifferenceColor())
                  .margin({ top: 5 })
              }
              .alignItems(HorizontalAlign.Center)
              .margin({ top: AppDimensions.MARGIN_MEDIUM })
            }
          }
          .width('100%')
          .padding(AppDimensions.PADDING_LARGE)
          .backgroundColor(AppColors.WHITE)
          .borderRadius(AppDimensions.BORDER_RADIUS)
          .alignItems(HorizontalAlign.Center)
          .onClick(() => this.navigateToEditRecord())
        } else {
          Column() {
            Text('暂无记录')
              .fontSize(AppText.FONT_SIZE_BODY)
              .fontColor(AppColors.GRAY)
              .textAlign(TextAlign.Center)
          }
          .width('100%')
          .height(180)
          .padding(AppDimensions.PADDING_LARGE)
          .backgroundColor(AppColors.WHITE)
          .borderRadius(AppDimensions.BORDER_RADIUS)
          .justifyContent(FlexAlign.Center)
          .alignItems(HorizontalAlign.Center)
        }
      }
      .width('100%')
      .height(200)
      .padding(AppDimensions.PADDING_SMALL)

      // 第二栏 - 功能按钮栏（水平排列）
      Row() {
        Button('趋势图表')
          .layoutWeight(1)
          .height(AppDimensions.BUTTON_HEIGHT)
          .fontSize(AppText.FONT_SIZE_SMALL)
          .fontWeight(FontWeight.Bold)
          .backgroundColor(AppColors.BLUE)
          .fontColor(AppColors.WHITE)
          .borderRadius(AppDimensions.BORDER_RADIUS_SMALL)
          .onClick(() => this.navigateToPage('pages/WeightChart'))
          .margin({ right: AppDimensions.MARGIN_SMALL })

        Button('统计仪表板')
          .layoutWeight(1)
          .height(AppDimensions.BUTTON_HEIGHT)
          .fontSize(AppText.FONT_SIZE_SMALL)
          .fontWeight(FontWeight.Bold)
          .backgroundColor(AppColors.GREEN)
          .fontColor(AppColors.WHITE)
          .borderRadius(AppDimensions.BORDER_RADIUS_SMALL)
          .onClick(() => this.navigateToPage('pages/StatisticsDashboard'))
          .margin({ right: AppDimensions.MARGIN_SMALL })

        Button('设置')
          .layoutWeight(1)
          .height(AppDimensions.BUTTON_HEIGHT)
          .fontSize(AppText.FONT_SIZE_SMALL)
          .fontWeight(FontWeight.Bold)
          .backgroundColor(AppColors.SECONDARY)
          .fontColor(AppColors.WHITE)
          .borderRadius(AppDimensions.BORDER_RADIUS_SMALL)
          .onClick(() => this.navigateToPage('pages/Settings'))
      }
      .width('100%')
      .height(80)
      .padding(AppDimensions.PADDING_SMALL)
      .justifyContent(FlexAlign.SpaceBetween)

      // 第三栏 - 数字键盘输入（占用剩余空间）
      Column() {
        Text('体重输入')
          .fontSize(AppText.FONT_SIZE_SUBTITLE)
          .fontWeight(FontWeight.Bold)
          .margin({ bottom: AppDimensions.MARGIN_MEDIUM })

        NumericKeypad({})
      }
      .width('100%')
      .layoutWeight(1)
      .padding(AppDimensions.PADDING_SMALL)
    }
    .width('100%')
    .height('100%')
    .backgroundColor(AppColors.BACKGROUND)
  }
}