import hilog from '@ohos.hilog';
import { getWeightRecordDao } from '../data/WeightRecordDao';
import { WeightRecord } from '../model/WeightRecord';
import router from '@ohos.router';

const DOMAIN = 0x0000;
const TAG = 'WeightApp_Index';

@Entry
@Component
struct Index {
  @State currentWeight: string = '';
  @State latestRecord: WeightRecord | null = null;

  async aboutToAppear() {
    await this.loadLatestRecord();
  }

  async loadLatestRecord() {
    try {
      const dao = await getWeightRecordDao(getContext(this));
      const records = await dao.queryAll();
      if (records.length > 0) {
        this.latestRecord = records[0]; // 默认按日期降序，第一个就是最新的
        hilog.info(DOMAIN, TAG, 'Loaded latest record.');
      }
    } catch (e) {
      hilog.error(DOMAIN, TAG, `Failed to load latest record, cause: ${e}`);
    }
  }

  build() {
    Column() {
      Text('体重记录器')
        .fontSize(38)
        .fontWeight(FontWeight.Bold)
        .margin({ top: 40, bottom: 60 })

      TextInput({ placeholder: '请输入当前体重 (kg)' })
        .type(InputType.Number)
        .width('80%')
        .height(50)
        .fontSize(20)
        .onChange((value: string) => {
          this.currentWeight = value;
        })

      Button('保存')
        .type(ButtonType.Capsule)
        .width('80%')
        .height(50)
        .fontSize(22)
        .fontWeight(FontWeight.Bold)
        .margin({ top: 30 })
        .onClick(async () => {
          if (this.currentWeight) {
            try {
              const weight = parseFloat(this.currentWeight);
              if (isNaN(weight) || weight <= 0) {
                hilog.warn(DOMAIN, TAG, 'Invalid weight input.');
                return;
              }
              const newRecord = new WeightRecord(weight, new Date().getTime());
              const dao = await getWeightRecordDao(getContext(this));
              await dao.insert(newRecord);
              hilog.info(DOMAIN, TAG, 'New weight record saved.');
              this.currentWeight = ''; // 清空输入框
              await this.loadLatestRecord(); // 重新加载并显示最新记录
            } catch (e) {
              hilog.error(DOMAIN, TAG, `Failed to save weight, cause: ${e}`);
            }
          }
        })

      Button('查看历史')
        .type(ButtonType.Normal)
        .width('80%')
        .height(50)
        .fontSize(22)
        .fontWeight(FontWeight.Bold)
        .margin({ top: 20 })
        .backgroundColor(Color.White)
        .fontColor(Color.Black)
        .border({ width: 1, color: Color.Gray, radius: 25 })
        .onClick(() => {
          router.pushUrl({ url: 'pages/History' });
        })

      if (this.latestRecord) {
        Text(`最近体重: ${this.latestRecord.weight.toFixed(1)} kg`)
          .fontSize(24)
          .margin({ top: 80 })
          .fontColor(Color.Gray)
        Text(`记录于: ${new Date(this.latestRecord.date).toLocaleString()}`)
          .fontSize(16)
          .margin({ top: 10 })
          .fontColor(Color.Gray)
      } else {
        Text('暂无记录')
          .fontSize(24)
          .margin({ top: 80 })
          .fontColor(Color.Gray)
      }
    }
    .width('100%')
    .height('100%')
    .padding({ left: 20, right: 20 })
  }
}