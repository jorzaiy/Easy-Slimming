import hilog from '@ohos.hilog';
import router from '@ohos.router';
import { LogConstants } from '../common/Constants';
import { getAppDao } from '../common/Global';
import { WeightRecord } from '../model/WeightRecord';

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

  formatDate(timestamp: number): string {
    const date = new Date(timestamp);
    const year = date.getFullYear();
    const month = (date.getMonth() + 1).toString().padStart(2, '0');
    const day = date.getDate().toString().padStart(2, '0');
    const hour = date.getHours().toString().padStart(2, '0');
    const minute = date.getMinutes().toString().padStart(2, '0');
    return `${year}/${month}/${day} ${hour}:${minute}`;
  }

  async loadLatestRecord() {
    try {
      const dao = getAppDao();
      if (!dao) {
        throw new Error('Global DAO not initialized');
      }
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
    Stack() {
      Column() {
        Column() {
          Text('轻松减重')
            .fontSize(38)
            .fontWeight(FontWeight.Bold)
            .margin({ top: 40, bottom: 30 })

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

          Button('统计仪表板')
            .type(ButtonType.Capsule)
            .width('80%')
            .height(50)
            .fontSize(22)
            .fontWeight(FontWeight.Bold)
            .margin({ top: 20 })
            .backgroundColor(Color.Green)
            .onClick(() => {
              try {
                router.pushUrl({ url: 'pages/StatisticsDashboard' });
              } catch (error) {
                hilog.error(DOMAIN, TAG, `Failed to navigate to StatisticsDashboard, cause: ${error}`);
              }
            })

          Button('目标管理')
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
                router.pushUrl({ url: 'pages/TargetWeightManagement' });
              } catch (error) {
                hilog.error(DOMAIN, TAG, `Failed to navigate to TargetWeightManagement, cause: ${error}`);
              }
            })

          Button('数据管理')
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
                router.pushUrl({ url: 'pages/DataManagement' });
              } catch (error) {
                hilog.error(DOMAIN, TAG, `Failed to navigate to DataManagement, cause: ${error}`);
              }
            })

          Button('鸿蒙同步')
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
                router.pushUrl({ url: 'pages/HealthSync' });
              } catch (error) {
                hilog.error(DOMAIN, TAG, `Failed to navigate to HealthSync, cause: ${error}`);
              }
            })

          Button('设置')
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
                router.pushUrl({ url: 'pages/Settings' });
              } catch (error) {
                hilog.error(DOMAIN, TAG, `Failed to navigate to Settings, cause: ${error}`);
              }
            })
          }

        Divider()
          .margin({ top: 20, bottom: 20 })

        if (this.latestRecord) {
          Text(`最近体重: ${this.latestRecord.weight.toFixed(1)} kg`)
            .fontSize(24)
            .fontColor(Color.Gray)
          Text(`记录于: ${this.formatDate(this.latestRecord.date)}`)
            .fontSize(16)
            .margin({ top: 10 })
            .fontColor(Color.Gray)
        } else {
          Text('暂无记录')
            .fontSize(24)
            .fontColor(Color.Gray)
        }
      }
      .width('100%')
      .padding({ left: 20, right: 20 })
      .alignItems(HorizontalAlign.Center)
    }
    .width('100%')
    .height('100%')
  }
}