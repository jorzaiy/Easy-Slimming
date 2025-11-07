import hilog from '@ohos.hilog';
import { getWeightRecordDao } from '../data/WeightRecordDao';
import { WeightRecord } from '../model/WeightRecord';
import router from '@ohos.router';

const DOMAIN = 0x0000;
const TAG = 'WeightApp_History';

@Entry
@Component
struct HistoryPage {
  @State records: WeightRecord[] = [];

  async aboutToAppear() {
    await this.loadHistory();
  }

  async loadHistory() {
    try {
      const dao = await getWeightRecordDao(getContext(this));
      this.records = await dao.queryAll();
      hilog.info(DOMAIN, TAG, `Loaded ${this.records.length} history records.`);
    } catch (e) {
      hilog.error(DOMAIN, TAG, `Failed to load history, cause: ${e}`);
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
        Text('历史记录')
          .fontSize(24)
          .fontWeight(FontWeight.Bold)
          .layoutWeight(1)
          .textAlign(TextAlign.Center)
          .margin({ right: 24 }) // to balance the back button
      }
      .width('100%')
      .padding(15)
      .backgroundColor(Color.White)
      .shadow({ radius: 3, color: '#000000', opacity: 0.1 })


      if (this.records.length > 0) {
        List({ space: 10 }) {
          ForEach(this.records, (item: WeightRecord) => {
            ListItem() {
              this.RecordItem(item)
            }
          })
        }
        .layoutWeight(1)
        .padding({ top: 10 })
      } else {
        Column() {
          Text('还没有任何记录哦')
            .fontSize(18)
            .fontColor(Color.Gray)
            .margin({ top: '40%' })
        }
        .layoutWeight(1)
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F1F3F5')
  }

  @Builder
  RecordItem(record: WeightRecord) {
    Row() {
      Column() {
        Text(`${record.weight.toFixed(1)} kg`)
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
        Text(new Date(record.date).toLocaleString())
          .fontSize(14)
          .fontColor(Color.Gray)
          .margin({ top: 5 })
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)

      Image($r('app.media.ic_delete'))
        .width(22)
        .height(22)
        .fillColor(Color.Red)
        .onClick(async () => {
          // TODO: Add delete confirmation dialog
          try {
            const dao = await getWeightRecordDao(getContext(this));
            await dao.deleteById(record.id);
            hilog.info(DOMAIN, TAG, `Deleted record with id: ${record.id}`);
            await this.loadHistory(); // Refresh the list
          } catch (e) {
            hilog.error(DOMAIN, TAG, `Failed to delete record, cause: ${e}`);
          }
        })
    }
    .width('100%')
    .padding(15)
    .backgroundColor(Color.White)
    .borderRadius(10)
  }
}