import hilog from '@ohos.hilog';
import router from '@ohos.router';
import { getWeightRecordDao } from '../data/WeightRecordDao';
import { WeightRecord } from '../model/WeightRecord';
import { NavigationHelper } from '../common/NavigationHelper';
import { FormValidator } from '../common/FormValidator';
import { AppColors, AppDimensions, AppText, BusinessConstants, LogConstants } from '../common/Constants';
import promptAction from '@ohos.promptAction';

const DOMAIN = LogConstants.DOMAIN;
const TAG = LogConstants.TAG_PREFIX + 'EditForm';

@Entry
@Component
struct WeightEditForm {
  @State selectedDate: Date = new Date();
  @State weightInput: string = '';
  @State notesInput: string = '';
  @State isSubmitting: boolean = false;
  @State recordId: number = -1;
  @State isEditMode: boolean = false;

  aboutToAppear() {
    try {
      const params = router.getParams();
      hilog.info(DOMAIN, TAG, `Router params type: ${typeof params}, value: ${params}`);
      
      if (params && typeof params === 'object' && 'record' in params) {
        const recordParams = params as { record: WeightRecord };
        const record = recordParams.record;
        if (record && record.id) {
          this.recordId = record.id;
          this.selectedDate = new Date(record.date);
          this.weightInput = record.weight.toString();
          this.notesInput = record.notes || '';
          this.isEditMode = true;
          hilog.info(DOMAIN, TAG, `Loaded record for editing, id: ${this.recordId}`);
        } else {
          hilog.error(DOMAIN, TAG, 'Invalid record object received');
          this.handleNavigationError();
        }
      } else {
        hilog.error(DOMAIN, TAG, 'No record parameter found for editing');
        this.handleNavigationError();
      }
    } catch (e) {
      hilog.error(DOMAIN, TAG, `Failed to load record for editing, cause: ${e}`);
      this.handleNavigationError();
    }
  }

  handleNavigationError() {
    promptAction.showToast({
      message: '记录信息加载失败',
      duration: 2000
    });
    NavigationHelper.navigateBackWithFeedback(1000);
  }

  isWeightValid(): boolean {
    if (!this.weightInput || this.weightInput.trim() === '') {
      return false;
    }
    const weight = parseFloat(this.weightInput);
    if (isNaN(weight)) {
      return false;
    }
    return weight >= BusinessConstants.MIN_WEIGHT && weight <= BusinessConstants.MAX_WEIGHT;
  }

  isDateValid(): boolean {
    return this.selectedDate.getTime() <= new Date().getTime();
  }

  isFormValid(): boolean {
    return this.isWeightValid() && this.isDateValid();
  }

  getWeightErrorMessage(): string {
    if (!this.weightInput || this.weightInput.trim() === '') {
      return '';
    }
    const weight = parseFloat(this.weightInput);
    if (isNaN(weight)) {
      return '请输入有效的数字';
    }
    if (weight < BusinessConstants.MIN_WEIGHT || weight > BusinessConstants.MAX_WEIGHT) {
      return `体重应在 ${BusinessConstants.MIN_WEIGHT}-${BusinessConstants.MAX_WEIGHT} kg 范围内`;
    }
    return '';
  }

  async handleSubmit() {
    if (!this.isFormValid() || this.isSubmitting) {
      return;
    }

    this.isSubmitting = true;

    try {
      const weight = parseFloat(this.weightInput);
      const timestamp = this.selectedDate.getTime();
      const notes = this.notesInput.trim() || undefined;

      const updatedRecord = new WeightRecord(weight, timestamp, this.recordId, notes);
      const dao = await getWeightRecordDao(this.getContext());
      const rowsAffected = await dao.update(updatedRecord);

      if (rowsAffected > 0) {
        hilog.info(DOMAIN, TAG, `Successfully updated weight record with id: ${this.recordId}`);
        
        promptAction.showToast({
          message: '体重记录更新成功',
          duration: 2000
        });

        await NavigationHelper.navigateBackWithFeedback();
      } else {
        throw new Error('No records were updated');
      }
    } catch (e) {
      hilog.error(DOMAIN, TAG, `Failed to update weight record, cause: ${e}`);
      promptAction.showToast({
        message: '更新失败，请重试',
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
          .width(24)
          .height(24)
          .onClick(() => {
            try {
              router.back();
            } catch (error) {
              hilog.error(DOMAIN, TAG, `Failed to navigate back, cause: ${error}`);
            }
          })
        Text('编辑记录')
          .fontSize(24)
          .fontWeight(FontWeight.Bold)
          .layoutWeight(1)
          .textAlign(TextAlign.Center)
          .margin({ right: 24 })
      }
      .width('100%')
      .padding(15)
      .backgroundColor(Color.White)
      .shadow({ radius: 3, color: Color.Gray, offsetX: 0, offsetY: 2 })

      Column() {
        Column() {
          Row() {
            Text('日期')
              .fontSize(16)
              .fontWeight(FontWeight.Medium)
            Text('*')
              .fontSize(16)
              .fontColor(Color.Red)
              .margin({ left: 4 })
          }
          .margin({ bottom: 10 })

          DatePicker({
            start: new Date('1900-1-1'),
            end: new Date(),
            selected: this.selectedDate
          })
            .lunar(false)
            .onChange((value: DatePickerResult) => {
              this.selectedDate = new Date(value.year, value.month, value.day);
              hilog.info(DOMAIN, TAG, `Selected date: ${this.selectedDate.toLocaleDateString()}`);
            })
        }
        .width('100%')
        .padding(20)
        .backgroundColor(Color.White)
        .borderRadius(12)
        .alignItems(HorizontalAlign.Start)
        .margin({ bottom: 15 })

        Column() {
          Row() {
            Text('体重 (kg)')
              .fontSize(16)
              .fontWeight(FontWeight.Medium)
            Text('*')
              .fontSize(16)
              .fontColor(Color.Red)
              .margin({ left: 4 })
          }
          .margin({ bottom: 10 })

          TextInput({ placeholder: '请输入体重，如：65.5', text: this.weightInput })
            .type(InputType.Number)
            .width('100%')
            .height(50)
            .fontSize(18)
            .placeholderFont({ size: 16 })
            .onChange((value: string) => {
              this.weightInput = value;
            })

          if (this.getWeightErrorMessage()) {
            Text(this.getWeightErrorMessage())
              .fontSize(14)
              .fontColor(Color.Red)
              .margin({ top: 8 })
          } else if (this.weightInput) {
            Text(`范围：${BusinessConstants.MIN_WEIGHT}-${BusinessConstants.MAX_WEIGHT} kg`)
              .fontSize(14)
              .fontColor(Color.Gray)
              .margin({ top: 8 })
          }
        }
        .width('100%')
        .padding(20)
        .backgroundColor(Color.White)
        .borderRadius(12)
        .alignItems(HorizontalAlign.Start)
        .margin({ bottom: 15 })

        Column() {
          Text('备注')
            .fontSize(16)
            .fontWeight(FontWeight.Medium)
            .margin({ bottom: 10 })

          TextArea({ placeholder: '记录饮食、运动等信息（可选）', text: this.notesInput })
            .width('100%')
            .height(120)
            .fontSize(16)
            .placeholderFont({ size: 16 })
            .maxLength(BusinessConstants.MAX_NOTES_LENGTH)
            .onChange((value: string) => {
              this.notesInput = value;
            })

          Text(`${this.notesInput.length}/${BusinessConstants.MAX_NOTES_LENGTH}`)
            .fontSize(14)
            .fontColor(Color.Gray)
            .margin({ top: 8 })
            .width('100%')
            .textAlign(TextAlign.End)
        }
        .width('100%')
        .padding(20)
        .backgroundColor(Color.White)
        .borderRadius(12)
        .alignItems(HorizontalAlign.Start)
        .margin({ bottom: 30 })

        Button(this.isSubmitting ? '更新中...' : '保存修改')
          .type(ButtonType.Capsule)
          .width('100%')
          .height(50)
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .enabled(!this.isSubmitting && this.isFormValid())
          .backgroundColor(this.isFormValid() && !this.isSubmitting ? Color.Blue : Color.Gray)
          .onClick(() => {
            this.handleSubmit();
          })
      }
      .width('100%')
      .padding({ left: 20, right: 20, top: 20 })
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F1F3F5')
  }
}