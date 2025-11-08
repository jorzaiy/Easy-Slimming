import hilog from '@ohos.hilog';
import { getWeightRecordDao } from '../data/WeightRecordDao';
import { WeightRecord } from '../model/WeightRecord';
import router from '@ohos.router';
import promptAction from '@ohos.promptAction';

const DOMAIN = 0x0000;
const TAG = 'WeightApp_History';

@Entry
@Component
struct HistoryPage {
  @State records: WeightRecord[] = [];
  @State showDeleteDialog: boolean = false;
  @State recordToDelete: WeightRecord | null = null;

  async aboutToAppear() {
    await this.loadHistory();
  }

  onPageShow() {
    this.loadHistory();
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

  showRecordDetail(record: WeightRecord) {
    router.pushUrl({
      url: 'pages/RecordDetail',
      params: { record: record }
    });
  }

  editRecord(record: WeightRecord) {
    router.pushUrl({
      url: 'pages/WeightEditForm',
      params: { record: record }
    });
  }

  confirmDelete(record: WeightRecord) {
    this.recordToDelete = record;
    this.showDeleteDialog = true;
  }

  async deleteRecord() {
    if (!this.recordToDelete) return;

    try {
      const dao = await getWeightRecordDao(getContext(this));
      const rowsAffected = await dao.deleteById(this.recordToDelete.id);
      
      if (rowsAffected > 0) {
        hilog.info(DOMAIN, TAG, `Deleted record with id: ${this.recordToDelete.id}`);
        promptAction.showToast({
          message: '删除成功',
          duration: 2000
        });
        await this.loadHistory(); // Refresh the list
      } else {
        throw new Error('No records were deleted');
      }
    } catch (e) {
      hilog.error(DOMAIN, TAG, `Failed to delete record, cause: ${e}`);
      promptAction.showToast({
        message: '删除失败，请重试',
        duration: 2000
      });
    } finally {
      this.showDeleteDialog = false;
      this.recordToDelete = null;
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
    .bindContentCover(this.showDeleteDialog, this.DeleteConfirmDialog(), {
      modalTransition: ModalTransition.NONE,
      backgroundColor: Color.Transparent
    })
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
        if (record.notes && record.notes.trim()) {
          Text(record.notes)
            .fontSize(14)
            .fontColor('#666666')
            .margin({ top: 8 })
            .maxLines(2)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
        }
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)

      Row() {
        Image($r('app.media.ic_edit'))
          .width(22)
          .height(22)
          .fillColor('#007DFF')
          .margin({ right: 15 })
          .onClick(() => {
            this.editRecord(record);
          })

        Image($r('app.media.ic_delete'))
          .width(22)
          .height(22)
          .fillColor(Color.Red)
          .onClick(() => {
            this.confirmDelete(record);
          })
      }
    }
    .width('100%')
    .padding(15)
    .backgroundColor(Color.White)
    .borderRadius(10)
    .onClick(() => {
      this.showRecordDetail(record);
    })
  }

  @Builder
  DeleteConfirmDialog() {
    Column() {
      Column() {
        Text('确认删除')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .margin({ bottom: 15 })

        if (this.recordToDelete) {
          Text(`确定要删除这条记录吗？`)
            .fontSize(16)
            .fontColor('#333333')
            .margin({ bottom: 10 })
          
          Text(`${this.recordToDelete.weight.toFixed(1)} kg - ${new Date(this.recordToDelete.date).toLocaleDateString()}`)
            .fontSize(14)
            .fontColor('#666666')
            .margin({ bottom: 20 })
        }

        Row() {
          Button('取消')
            .type(ButtonType.Capsule)
            .layoutWeight(1)
            .height(40)
            .fontSize(16)
            .backgroundColor('#F1F3F5')
            .fontColor('#333333')
            .margin({ right: 10 })
            .onClick(() => {
              this.showDeleteDialog = false;
              this.recordToDelete = null;
            })

          Button('删除')
            .type(ButtonType.Capsule)
            .layoutWeight(1)
            .height(40)
            .fontSize(16)
            .backgroundColor(Color.Red)
            .onClick(() => {
              this.deleteRecord();
            })
        }
      }
      .width(300)
      .padding(20)
      .backgroundColor(Color.White)
      .borderRadius(12)
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .backgroundColor('rgba(0, 0, 0, 0.5)')
  }
}