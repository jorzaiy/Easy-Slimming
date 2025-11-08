import hilog from '@ohos.hilog';
import router from '@ohos.router';
import { getWeightRecordDao } from '../data/WeightRecordDao';
import { WeightRecord } from '../model/WeightRecord';
import { NavigationHelper } from '../common/NavigationHelper';
import { AppColors, AppDimensions, AppText, LogConstants } from '../common/Constants';
import promptAction from '@ohos.promptAction';

const DOMAIN = LogConstants.DOMAIN;
const TAG = LogConstants.TAG_PREFIX + 'Index';

@Entry
@Component
struct Index {
  @State latestRecord: WeightRecord | null = null;

  async aboutToAppear() {
    await this.loadLatestRecord();
  }

  onPageShow() {
    this.loadLatestRecord();
  }

  async loadLatestRecord() {
    try {
      const dao = await getWeightRecordDao(this.getUIContext().getApplicationContext());
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
      Text('轻松减重')
        .fontSize(38)
        .fontWeight(FontWeight.Bold)
        .margin({ top: 40, bottom: 60 })

      Button('记录体重')
        .type(ButtonType.Capsule)
        .width('80%')
        .height(50)
        .fontSize(22)
        .fontWeight(FontWeight.Bold)
        .onClick(() => {
          try {
            router.pushUrl({ url: 'pages/WeightEntryForm' });
          } catch (error) {
            hilog.error(DOMAIN, TAG, `Failed to navigate to WeightEntryForm, cause: ${error}`);
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
          try {
            router.pushUrl({ url: 'pages/History' });
          } catch (error) {
            hilog.error(DOMAIN, TAG, `Failed to navigate to History, cause: ${error}`);
          }
        })

      Button('趋势图表')
        .type(ButtonType.Capsule)
        .width('80%')
        .height(50)
        .fontSize(22)
        .fontWeight(FontWeight.Bold)
        .margin({ top: 20 })
        .backgroundColor(Color.Blue)
        .onClick(() => {
          try {
            router.pushUrl({ url: 'pages/WeightChart' });
          } catch (error) {
            hilog.error(DOMAIN, TAG, `Failed to navigate to WeightChart, cause: ${error}`);
          }
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