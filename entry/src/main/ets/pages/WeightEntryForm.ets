import hilog from '@ohos.hilog';
import { getWeightRecordDao } from '../data/WeightRecordDao';
import { WeightRecord } from '../model/WeightRecord';
import router from '@ohos.router';
import promptAction from '@ohos.promptAction';

const DOMAIN = 0x0000;
const TAG = 'WeightApp_EntryForm';

const MIN_WEIGHT = 30;
const MAX_WEIGHT = 200;

@Entry
@Component
struct WeightEntryForm {
  @State selectedDate: Date = new Date();
  @State weightInput: string = '';
  @State notesInput: string = '';
  @State isSubmitting: boolean = false;

  isWeightValid(): boolean {
    if (!this.weightInput || this.weightInput.trim() === '') {
      return false;
    }
    const weight = parseFloat(this.weightInput);
    if (isNaN(weight)) {
      return false;
    }
    return weight >= MIN_WEIGHT && weight <= MAX_WEIGHT;
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
    if (weight < MIN_WEIGHT || weight > MAX_WEIGHT) {
      return `体重应在 ${MIN_WEIGHT}-${MAX_WEIGHT} kg 范围内`;
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

      const newRecord = new WeightRecord(weight, timestamp, undefined, notes);
      const dao = await getWeightRecordDao(getContext(this));
      const recordId = await dao.insert(newRecord);

      if (recordId > 0) {
        hilog.info(DOMAIN, TAG, `Successfully saved weight record with id: ${recordId}`);
        
        promptAction.showToast({
          message: '体重记录保存成功',
          duration: 2000
        });

        this.weightInput = '';
        this.notesInput = '';
        this.selectedDate = new Date();

        setTimeout(() => {
          router.back();
        }, 500);
      } else {
        throw new Error('Failed to insert record');
      }
    } catch (e) {
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
          .width(24)
          .height(24)
          .onClick(() => {
            router.back();
          })
        Text('记录体重')
          .fontSize(24)
          .fontWeight(FontWeight.Bold)
          .layoutWeight(1)
          .textAlign(TextAlign.Center)
          .margin({ right: 24 })
      }
      .width('100%')
      .padding(15)
      .backgroundColor(Color.White)
      .shadow({ radius: 3, color: '#000000', opacity: 0.1 })

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

          TextInput({ placeholder: '请输入体重，如：65.5' })
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
            Text(`范围：${MIN_WEIGHT}-${MAX_WEIGHT} kg`)
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

          TextArea({ placeholder: '记录饮食、运动等信息（可选）' })
            .width('100%')
            .height(120)
            .fontSize(16)
            .placeholderFont({ size: 16 })
            .maxLength(200)
            .onChange((value: string) => {
              this.notesInput = value;
            })

          Text(`${this.notesInput.length}/200`)
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

        Button(this.isSubmitting ? '保存中...' : '保存记录')
          .type(ButtonType.Capsule)
          .width('100%')
          .height(50)
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .enabled(!this.isSubmitting && this.isFormValid())
          .backgroundColor(this.isFormValid() && !this.isSubmitting ? '#007DFF' : '#CCCCCC')
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
