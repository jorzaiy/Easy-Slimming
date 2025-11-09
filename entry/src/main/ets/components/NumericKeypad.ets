import hilog from '@ohos.hilog';
import promptAction from '@ohos.promptAction';
import { AppColors, AppDimensions, AppText, BusinessConstants, LogConstants } from '../common/Constants';

const DOMAIN = LogConstants.DOMAIN;
const TAG = LogConstants.TAG_PREFIX + 'NumericKeypad';

export interface NumericKeypadCallbacks {
  onValueChange?: (value: string) => void;
  onConfirm?: (value: string) => void;
  onCancel?: () => void;
}

interface NumericKeypadParams {
  callbacks?: NumericKeypadCallbacks;
}

@Component
export struct NumericKeypad {
  @State displayValue: string = '';
  @State errorMessage: string = '';
  @Consume callbacks: NumericKeypadCallbacks;

  private handleButtonClick(key: string) {
    this.errorMessage = '';

    if (key === 'delete') {
      if (this.displayValue.length > 0) {
        this.displayValue = this.displayValue.slice(0, -1);
      }
    } else if (key === '.') {
      if (!this.displayValue.includes('.')) {
        if (this.displayValue === '') {
          this.displayValue = '0.';
        } else {
          this.displayValue += '.';
        }
      }
    } else {
      if (this.displayValue === '0' && key !== '0') {
        this.displayValue = key;
      } else if (this.displayValue !== '0') {
        this.displayValue += key;
      } else if (key === '0') {
        if (this.displayValue.length === 1) {
          this.displayValue = '0';
        }
      }
    }

    if (this.callbacks && this.callbacks.onValueChange) {
      this.callbacks.onValueChange(this.displayValue);
    }
  }

  private handleConfirm() {
    if (this.displayValue === '') {
      this.errorMessage = '请输入体重';
      return;
    }

    const weight = parseFloat(this.displayValue);
    if (isNaN(weight)) {
      this.errorMessage = '请输入有效的数字';
      return;
    }

    if (weight <= 0 || weight > BusinessConstants.MAX_WEIGHT) {
      this.errorMessage = `体重应在 0-${BusinessConstants.MAX_WEIGHT} kg 范围内`;
      return;
    }

    if (this.callbacks && this.callbacks.onConfirm) {
      this.callbacks.onConfirm(this.displayValue);
    }
  }

  private handleCancel() {
    this.displayValue = '';
    this.errorMessage = '';
    if (this.callbacks && this.callbacks.onCancel) {
      this.callbacks.onCancel();
    }
  }

  build() {
    Column() {
      // Display area
      Column() {
        if (this.errorMessage) {
          Text(this.errorMessage)
            .fontSize(AppText.FONT_SIZE_SMALL)
            .fontColor(AppColors.ERROR)
            .textAlign(TextAlign.Center)
            .width('100%')
            .margin({ bottom: AppDimensions.MARGIN_SMALL })
        }

        Text(this.displayValue || '0')
          .fontSize(48)
          .fontWeight(FontWeight.Bold)
          .textAlign(TextAlign.Center)
          .width('100%')
          .padding({ top: 20, bottom: 20 })
          .fontColor(this.errorMessage ? AppColors.ERROR : AppColors.BLUE)
      }
      .width('100%')
      .backgroundColor(AppColors.WHITE)
      .borderRadius(AppDimensions.BORDER_RADIUS)
      .padding(AppDimensions.PADDING_MEDIUM)
      .margin({ bottom: AppDimensions.MARGIN_MEDIUM })

      // Number pad grid
      Column() {
        // Row 1: 1, 2, 3
        Row() {
          ForEach(['1', '2', '3'], (key: string) => {
            Button(key)
              .width('100%')
              .height(60)
              .fontSize(AppText.FONT_SIZE_BODY)
              .fontWeight(FontWeight.Bold)
              .backgroundColor(AppColors.PRIMARY)
              .fontColor(AppColors.WHITE)
              .borderRadius(8)
              .onClick(() => this.handleButtonClick(key))
          }, (key: string) => key)
        }
        .width('100%')
        .justifyContent(FlexAlign.SpaceBetween)
        .gap(10)
        .margin({ bottom: 10 })

        // Row 2: 4, 5, 6
        Row() {
          ForEach(['4', '5', '6'], (key: string) => {
            Button(key)
              .width('100%')
              .height(60)
              .fontSize(AppText.FONT_SIZE_BODY)
              .fontWeight(FontWeight.Bold)
              .backgroundColor(AppColors.PRIMARY)
              .fontColor(AppColors.WHITE)
              .borderRadius(8)
              .onClick(() => this.handleButtonClick(key))
          }, (key: string) => key)
        }
        .width('100%')
        .justifyContent(FlexAlign.SpaceBetween)
        .gap(10)
        .margin({ bottom: 10 })

        // Row 3: 7, 8, 9
        Row() {
          ForEach(['7', '8', '9'], (key: string) => {
            Button(key)
              .width('100%')
              .height(60)
              .fontSize(AppText.FONT_SIZE_BODY)
              .fontWeight(FontWeight.Bold)
              .backgroundColor(AppColors.PRIMARY)
              .fontColor(AppColors.WHITE)
              .borderRadius(8)
              .onClick(() => this.handleButtonClick(key))
          }, (key: string) => key)
        }
        .width('100%')
        .justifyContent(FlexAlign.SpaceBetween)
        .gap(10)
        .margin({ bottom: 10 })

        // Row 4: 0, ., delete
        Row() {
          Button('0')
            .width('100%')
            .height(60)
            .fontSize(AppText.FONT_SIZE_BODY)
            .fontWeight(FontWeight.Bold)
            .backgroundColor(AppColors.PRIMARY)
            .fontColor(AppColors.WHITE)
            .borderRadius(8)
            .onClick(() => this.handleButtonClick('0'))

          Button('.')
            .width('100%')
            .height(60)
            .fontSize(AppText.FONT_SIZE_BODY)
            .fontWeight(FontWeight.Bold)
            .backgroundColor(AppColors.PRIMARY)
            .fontColor(AppColors.WHITE)
            .borderRadius(8)
            .onClick(() => this.handleButtonClick('.'))

          Button('删除')
            .width('100%')
            .height(60)
            .fontSize(AppText.FONT_SIZE_BODY)
            .fontWeight(FontWeight.Bold)
            .backgroundColor(AppColors.WARNING)
            .fontColor(AppColors.WHITE)
            .borderRadius(8)
            .onClick(() => this.handleButtonClick('delete'))
        }
        .width('100%')
        .justifyContent(FlexAlign.SpaceBetween)
        .gap(10)
        .margin({ bottom: 10 })

        // Row 5: confirm ✓, cancel ✗
        Row() {
          Button('✓ 确认')
            .width('100%')
            .height(60)
            .fontSize(AppText.FONT_SIZE_BODY)
            .fontWeight(FontWeight.Bold)
            .backgroundColor(AppColors.SUCCESS)
            .fontColor(AppColors.WHITE)
            .borderRadius(8)
            .onClick(() => this.handleConfirm())

          Button('✗ 清除')
            .width('100%')
            .height(60)
            .fontSize(AppText.FONT_SIZE_BODY)
            .fontWeight(FontWeight.Bold)
            .backgroundColor(AppColors.ERROR)
            .fontColor(AppColors.WHITE)
            .borderRadius(8)
            .onClick(() => this.handleCancel())
        }
        .width('100%')
        .justifyContent(FlexAlign.SpaceBetween)
        .gap(10)
      }
      .width('100%')
      .padding(AppDimensions.PADDING_MEDIUM)
      .backgroundColor(AppColors.WHITE)
      .borderRadius(AppDimensions.BORDER_RADIUS)
    }
    .width('100%')
    .padding(AppDimensions.PADDING_MEDIUM)
  }

  public clear() {
    this.displayValue = '';
    this.errorMessage = '';
  }

  public getValue(): string {
    return this.displayValue;
  }
}
