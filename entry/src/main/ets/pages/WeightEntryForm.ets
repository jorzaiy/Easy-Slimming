import hilog from '@ohos.hilog';
import relationalStore from '@ohos.data.relationalStore';
import { WeightRecord } from '../model/WeightRecord';
import { Remark, RemarkType } from '../model/Remark';
import { NavigationHelper } from '../common/NavigationHelper';
import { FormValidator } from '../common/FormValidator';
import { AppColors, AppDimensions, AppText, BusinessConstants, LogConstants } from '../common/Constants';
import promptAction from '@ohos.promptAction';
import { getAppDao } from '../common/Global';
import { RemarkEntry } from '../components/RemarkEntry';

const DOMAIN = LogConstants.DOMAIN;
const TAG = LogConstants.TAG_PREFIX + 'EntryForm';

@Entry
@Component
struct WeightEntryForm {
  @State selectedDate: Date = new Date();
  @State weightInput: string = '';
  @State notesInput: string = '';
  @State remarks: Remark[] = [];
  @State isSubmitting: boolean = false;

  isWeightValid(): boolean {
    return FormValidator.validateWeight(this.weightInput).isValid;
  }

  isDateValid(): boolean {
    return FormValidator.validateDate(this.selectedDate);
  }

  isFormValid(): boolean {
    return FormValidator.validateForm(this.weightInput, this.selectedDate);
  }

  formatDateOnly(timestamp: number): string {
    const date = new Date(timestamp);
    const year = date.getFullYear();
    const month = (date.getMonth() + 1).toString().padStart(2, '0');
    const day = date.getDate().toString().padStart(2, '0');
    return `${year}/${month}/${day}`;
  }

  getWeightErrorMessage(): string {
    return FormValidator.validateWeight(this.weightInput).errorMessage;
  }

  async handleSubmit() {
    if (!this.isFormValid() || this.isSubmitting) {
      return;
    }

    this.isSubmitting = true;

    let dao = getAppDao();
    let rdbStore: relationalStore.RdbStore | null = null;

    try {
      const weight = parseFloat(this.weightInput);
      const timestamp = this.selectedDate.getTime();
      const notes = this.notesInput.trim() || undefined;

      const newRecord = new WeightRecord(weight, timestamp, undefined, notes);
      if (!dao) {
        throw new Error('Global DAO not initialized');
      }

      const store = dao.getRdbStore();
      rdbStore = store;
      await store.executeSql('BEGIN TRANSACTION');

      const recordId = await dao.insert(newRecord);

      if (recordId > 0) {
        hilog.info(DOMAIN, TAG, `Successfully saved weight record with id: ${recordId}`);
        
        // 保存备注
        let savedRemarks = 0;
        for (const remark of this.remarks) {
          remark.recordId = recordId;
          const remarkId = await dao.addRemark(recordId, remark.type, remark.content);
          if (remarkId > 0) {
            savedRemarks++;
          }
        }
        
        await store.executeSql('COMMIT');
        hilog.info(DOMAIN, TAG, `Successfully saved ${savedRemarks} remarks for record: ${recordId}`);
        
        promptAction.showToast({
          message: '体重记录保存成功',
          duration: 2000
        });

        this.weightInput = '';
        this.notesInput = '';
        this.remarks = [];
        this.selectedDate = new Date();

        await NavigationHelper.navigateBackWithFeedback();
      } else {
        await store.executeSql('ROLLBACK');
        throw new Error('Failed to insert record');
      }
    } catch (e) {
      if (rdbStore) {
        try {
          await rdbStore.executeSql('ROLLBACK');
        } catch (rollbackError) {
          hilog.error(DOMAIN, TAG, `Failed to rollback transaction: ${rollbackError}`);
        }
      }
      hilog.error(DOMAIN, TAG, `Failed to save weight record, cause: ${e}`);
      promptAction.showToast({
        message: '保存失败，请重试',
        duration: 2000
      });
    } finally {
      this.isSubmitting = false;
    }
  }

  build() {
    Column() {
      Row() {
        Image($r('app.media.ic_back'))
          .width(AppDimensions.ICON_SIZE)
          .height(AppDimensions.ICON_SIZE)
          .onClick(() => {
            NavigationHelper.navigateBack();
          })
        Text('记录体重')
          .fontSize(AppText.FONT_SIZE_TITLE)
          .fontWeight(FontWeight.Bold)
          .layoutWeight(1)
          .textAlign(TextAlign.Center)
          .margin({ right: AppDimensions.ICON_SIZE })
      }
      .width('100%')
      .padding(AppDimensions.PADDING_MEDIUM)
      .backgroundColor(AppColors.WHITE)
      .shadow({ radius: 3, color: Color.Gray, offsetX: 0, offsetY: 2 })

      Column() {
        Column() {
          Row() {
            Text('日期')
              .fontSize(AppText.FONT_SIZE_SMALL)
              .fontWeight(FontWeight.Medium)
            Text('*')
              .fontSize(AppText.FONT_SIZE_SMALL)
              .fontColor(AppColors.ERROR)
              .margin({ left: 4 })
          }
          .margin({ bottom: AppDimensions.MARGIN_SMALL })

          DatePicker({
            start: new Date('1900-1-1'),
            end: new Date(),
            selected: this.selectedDate
          })
            .lunar(false)
            .onChange((value: DatePickerResult) => {
              if (value && value.year !== undefined && value.month !== undefined && value.day !== undefined) {
                this.selectedDate = new Date(value.year, value.month, value.day);
                hilog.info(DOMAIN, TAG, `Selected date: ${this.formatDateOnly(this.selectedDate.getTime())}`);
              }
            })
        }
        .width('100%')
        .padding(AppDimensions.PADDING_LARGE)
        .backgroundColor(AppColors.WHITE)
        .borderRadius(AppDimensions.BORDER_RADIUS)
        .alignItems(HorizontalAlign.Start)
        .margin({ bottom: AppDimensions.MARGIN_MEDIUM })

        Column() {
          Row() {
            Text('体重 (kg)')
              .fontSize(AppText.FONT_SIZE_SMALL)
              .fontWeight(FontWeight.Medium)
            Text('*')
              .fontSize(AppText.FONT_SIZE_SMALL)
              .fontColor(AppColors.ERROR)
              .margin({ left: 4 })
          }
          .margin({ bottom: AppDimensions.MARGIN_SMALL })

          TextInput({ placeholder: '请输入体重，如：65.5' })
            .type(InputType.Number)
            .width('100%')
            .height(AppDimensions.BUTTON_HEIGHT)
            .fontSize(AppText.FONT_SIZE_BODY)
            .placeholderFont({ size: AppText.FONT_SIZE_SMALL })
            .onChange((value: string) => {
              this.weightInput = value;
            })

          if (this.getWeightErrorMessage()) {
            Text(this.getWeightErrorMessage())
              .fontSize(AppText.FONT_SIZE_TINY)
              .fontColor(AppColors.ERROR)
              .margin({ top: 8 })
          } else if (this.weightInput) {
            Text(`范围：${BusinessConstants.MIN_WEIGHT}-${BusinessConstants.MAX_WEIGHT} kg`)
              .fontSize(AppText.FONT_SIZE_TINY)
              .fontColor(AppColors.GRAY)
              .margin({ top: 8 })
          }
        }
        .width('100%')
        .padding(AppDimensions.PADDING_LARGE)
        .backgroundColor(AppColors.WHITE)
        .borderRadius(AppDimensions.BORDER_RADIUS)
        .alignItems(HorizontalAlign.Start)
        .margin({ bottom: AppDimensions.MARGIN_MEDIUM })

        Column() {
          Text('传统备注')
            .fontSize(AppText.FONT_SIZE_SMALL)
            .fontWeight(FontWeight.Medium)
            .margin({ bottom: AppDimensions.MARGIN_SMALL })

          TextArea({ placeholder: '记录一般性备注信息（可选）' })
            .width('100%')
            .height(80)
            .fontSize(AppText.FONT_SIZE_SMALL)
            .placeholderFont({ size: AppText.FONT_SIZE_SMALL })
            .maxLength(BusinessConstants.MAX_NOTES_LENGTH)
            .onChange((value: string) => {
              this.notesInput = value;
            })

          Text(`${this.notesInput.length}/${BusinessConstants.MAX_NOTES_LENGTH}`)
            .fontSize(AppText.FONT_SIZE_TINY)
            .fontColor(AppColors.GRAY)
            .margin({ top: 8 })
            .width('100%')
            .textAlign(TextAlign.End)
        }
        .width('100%')
        .padding(AppDimensions.PADDING_LARGE)
        .backgroundColor(AppColors.WHITE)
        .borderRadius(AppDimensions.BORDER_RADIUS)
        .alignItems(HorizontalAlign.Start)
        .margin({ bottom: AppDimensions.MARGIN_MEDIUM })

        // 结构化备注输入
        Column() {
          Text('详细备注')
            .fontSize(AppText.FONT_SIZE_SMALL)
            .fontWeight(FontWeight.Bold)
            .margin({ bottom: AppDimensions.MARGIN_SMALL })
            .width('100%')
            .textAlign(TextAlign.Start)

          RemarkEntry({
            remarks: this.remarks,
            onRemarksChange: (newRemarks: Remark[]) => {
              this.remarks = newRemarks;
            }
          })
        }
        .width('100%')
        .margin({ bottom: AppDimensions.MARGIN_LARGE })

        Button(this.isSubmitting ? '保存中...' : '保存记录')
          .type(ButtonType.Capsule)
          .width('100%')
          .height(AppDimensions.BUTTON_HEIGHT)
          .fontSize(AppText.FONT_SIZE_BODY)
          .fontWeight(FontWeight.Bold)
          .enabled(!this.isSubmitting && this.isFormValid())
          .backgroundColor(this.isFormValid() && !this.isSubmitting ? AppColors.PRIMARY : AppColors.LIGHT_GRAY)
          .onClick(() => {
            this.handleSubmit();
          })
      }
      .width('100%')
      .padding({ left: AppDimensions.PADDING_LARGE, right: AppDimensions.PADDING_LARGE, top: AppDimensions.PADDING_LARGE })
    }
    .width('100%')
    .height('100%')
    .backgroundColor(AppColors.BACKGROUND)
  }
}
