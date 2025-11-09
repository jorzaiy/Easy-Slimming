import hilog from '@ohos.hilog';
import promptAction from '@ohos.promptAction';
import { AppColors, AppDimensions, AppText, BusinessConstants, LogConstants } from '../common/Constants';

const DOMAIN = LogConstants.DOMAIN;
const TAG = LogConstants.TAG_PREFIX + 'NumericKeypad';

/**
 * Callbacks for NumericKeypad component
 * 
 * Usage:
 * - onValueChange: Called when user enters/modifies a digit. Parent is responsible for range validation.
 * - onDelete: Called when delete (←) button is pressed.
 * - onClear: Called when clear (C) button is pressed to reset all input.
 * - onConfirm: Called when confirm (✓) button is pressed after internal validation.
 * - onCancel: Called when cancel (✗) button is pressed.
 */
export interface NumericKeypadCallbacks {
  onValueChange?: (value: string) => void;
  onDelete?: (value: string) => void;
  onClear?: () => void;
  onConfirm?: (value: string) => void;
  onCancel?: () => void;
}

interface NumericKeypadParams {
  callbacks?: NumericKeypadCallbacks;
}

/**
 * NumericKeypad Component
 * 
 * A reusable numeric input component with a 4×3 keypad layout plus control buttons.
 * 
 * Features:
 * - Digit input (0-9) with leading zero handling
 * - Decimal point support (single decimal point per value)
 * - Delete button (←) to remove last character
 * - Clear button (C) to reset input
 * - Confirm button (✓) with basic validation
 * - Cancel button (✗) to abort input
 * - Error message display with color highlighting
 * - Optional disabled state for all buttons
 * 
 * Behavior:
 * 1. Digit Entry: Automatically replaces leading zeros when new digit entered (except 0.x pattern)
 * 2. Decimal Point: Only one decimal point allowed; auto-prefixes "0." if entered without integer part
 * 3. Delete (←): Removes last character from current value
 * 4. Clear (C): Resets displayValue and errorMessage, triggers onClear callback
 * 5. Cancel (✗): Clears everything and triggers onCancel callback
 * 6. Confirm (✓): Validates value is non-empty and within range, triggers onConfirm callback
 * 
 * Range Validation:
 * - Component performs basic checks (non-empty, valid number, within 0-200kg)
 * - Parent components should implement additional business logic validation
 * - Parent can set showErrorMessage to display custom error states
 * 
 * Props:
 * - callbacks: NumericKeypadCallbacks interface with optional handlers
 * - disabled: boolean to disable all button interactions
 * - showErrorMessage: string to display custom error messages
 */
@Component
export struct NumericKeypad {
  @State displayValue: string = '';
  @State errorMessage: string = '';
  @Consume callbacks: NumericKeypadCallbacks;
  @Prop disabled: boolean = false;
  @Prop showErrorMessage: string = '';

  aboutToAppear() {
    if (this.showErrorMessage) {
      this.errorMessage = this.showErrorMessage;
    }
  }

  private handleButtonClick(key: string) {
    if (this.disabled) {
      return;
    }

    this.errorMessage = '';

    if (key === 'delete') {
      if (this.displayValue.length > 0) {
        this.displayValue = this.displayValue.slice(0, -1);
      }
      if (this.callbacks && this.callbacks.onDelete) {
        this.callbacks.onDelete(this.displayValue);
      }
    } else if (key === 'clear') {
      this.displayValue = '';
      this.errorMessage = '';
      if (this.callbacks && this.callbacks.onClear) {
        this.callbacks.onClear();
      }
    } else if (key === '.') {
      if (!this.displayValue.includes('.')) {
        if (this.displayValue === '') {
          this.displayValue = '0.';
        } else {
          this.displayValue += '.';
        }
      }
      if (this.callbacks && this.callbacks.onValueChange) {
        this.callbacks.onValueChange(this.displayValue);
      }
    } else {
      // Handle digit input
      if (this.displayValue === '0' && key !== '0') {
        this.displayValue = key;
      } else if (this.displayValue !== '0') {
        this.displayValue += key;
      } else if (key === '0') {
        if (this.displayValue.length === 1) {
          this.displayValue = '0';
        }
      }

      if (this.callbacks && this.callbacks.onValueChange) {
        this.callbacks.onValueChange(this.displayValue);
      }
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
              .enabled(!this.disabled)
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
              .enabled(!this.disabled)
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
              .enabled(!this.disabled)
              .onClick(() => this.handleButtonClick(key))
          }, (key: string) => key)
        }
        .width('100%')
        .justifyContent(FlexAlign.SpaceBetween)
        .gap(10)
        .margin({ bottom: 10 })

        // Row 4: 0, ., delete (←)
        Row() {
          Button('0')
            .width('100%')
            .height(60)
            .fontSize(AppText.FONT_SIZE_BODY)
            .fontWeight(FontWeight.Bold)
            .backgroundColor(AppColors.PRIMARY)
            .fontColor(AppColors.WHITE)
            .borderRadius(8)
            .enabled(!this.disabled)
            .onClick(() => this.handleButtonClick('0'))

          Button('.')
            .width('100%')
            .height(60)
            .fontSize(AppText.FONT_SIZE_BODY)
            .fontWeight(FontWeight.Bold)
            .backgroundColor(AppColors.PRIMARY)
            .fontColor(AppColors.WHITE)
            .borderRadius(8)
            .enabled(!this.disabled)
            .onClick(() => this.handleButtonClick('.'))

          Button('← 删除')
            .width('100%')
            .height(60)
            .fontSize(AppText.FONT_SIZE_BODY)
            .fontWeight(FontWeight.Bold)
            .backgroundColor(AppColors.WARNING)
            .fontColor(AppColors.WHITE)
            .borderRadius(8)
            .enabled(!this.disabled)
            .onClick(() => this.handleButtonClick('delete'))
        }
        .width('100%')
        .justifyContent(FlexAlign.SpaceBetween)
        .gap(10)
        .margin({ bottom: 10 })

        // Row 5: confirm ✓, clear C, cancel ✗
        Row() {
          Button('✓ 确认')
            .width('100%')
            .height(60)
            .fontSize(AppText.FONT_SIZE_BODY)
            .fontWeight(FontWeight.Bold)
            .backgroundColor(AppColors.SUCCESS)
            .fontColor(AppColors.WHITE)
            .borderRadius(8)
            .enabled(!this.disabled)
            .onClick(() => this.handleConfirm())

          Button('C 清空')
            .width('100%')
            .height(60)
            .fontSize(AppText.FONT_SIZE_BODY)
            .fontWeight(FontWeight.Bold)
            .backgroundColor(AppColors.SECONDARY)
            .fontColor(AppColors.WHITE)
            .borderRadius(8)
            .enabled(!this.disabled)
            .onClick(() => this.handleButtonClick('clear'))

          Button('✗ 取消')
            .width('100%')
            .height(60)
            .fontSize(AppText.FONT_SIZE_BODY)
            .fontWeight(FontWeight.Bold)
            .backgroundColor(AppColors.ERROR)
            .fontColor(AppColors.WHITE)
            .borderRadius(8)
            .enabled(!this.disabled)
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
