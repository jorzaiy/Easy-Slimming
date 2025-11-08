import hilog from '@ohos.hilog';
import router from '@ohos.router';
import { WeightRecord } from '../model/WeightRecord';
import { Remark, RemarkType } from '../model/Remark';
import { NavigationHelper } from '../common/NavigationHelper';
import { ErrorHandler } from '../common/ErrorHandler';
import { AppColors, AppDimensions, AppText, LogConstants } from '../common/Constants';
import promptAction from '@ohos.promptAction';
import { getAppDao } from '../common/Global';
import { RemarkSummary } from '../components/RemarkDisplay';
import { RemarkFilter } from '../components/RemarkFilter';
import { getTargetWeightService, TargetWeightRecord } from '../data/TargetWeightService';
import { common } from '@kit.AbilityKit';

const DOMAIN = LogConstants.DOMAIN;
const TAG = LogConstants.TAG_PREFIX + 'History';

@Entry
@Component
struct HistoryPage {
  @State records: WeightRecord[] = [];
  @State filteredRecords: WeightRecord[] = [];
  @State remarksMap: Map<number, Remark[]> = new Map();
  @State showDeleteDialog: boolean = false;
  @State recordToDelete: WeightRecord | null = null;
  @State selectedRemarkType: RemarkType | 'all' = 'all';
  @State currentTarget: TargetWeightRecord | null = null;

  async aboutToAppear() {
    await this.loadHistory();
    await this.loadTargetWeight();
  }

  onPageShow() {
    this.loadHistory();
    this.loadTargetWeight();
  }

  async loadTargetWeight() {
    try {
      const context = this.getUIContext();
      if (!context) {
        return;
      }
      const service = await getTargetWeightService(context as unknown as common.Context);
      if (service) {
        this.currentTarget = await service.getCurrentTarget();
      }
    } catch (e) {
      hilog.error(DOMAIN, TAG, `Failed to load target weight: ${e}`);
    }
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

  formatDateOnly(timestamp: number): string {
    const date = new Date(timestamp);
    const year = date.getFullYear();
    const month = (date.getMonth() + 1).toString().padStart(2, '0');
    const day = date.getDate().toString().padStart(2, '0');
    return `${year}/${month}/${day}`;
  }

  async loadHistory() {
    try {
      const dao = getAppDao();
      if (!dao) {
        throw new Error('Global DAO not initialized');
      }
      this.records = await dao.queryAll();
      
      // 加载每条记录的备注
      this.remarksMap.clear();
      for (const record of this.records) {
        const remarks = await dao.queryRemarksByRecordId(record.id);
        this.remarksMap.set(record.id, remarks);
      }
      
      this.applyFilter();
      hilog.info(DOMAIN, TAG, `Loaded ${this.records.length} history records with remarks.`);
    } catch (e) {
      hilog.error(DOMAIN, TAG, `Failed to load history, cause: ${e}`);
    }
  }

  applyFilter() {
    if (this.selectedRemarkType === 'all') {
      this.filteredRecords = this.records;
    } else {
      this.filteredRecords = this.records.filter(record => {
        const remarks = this.remarksMap.get(record.id) || [];
        return remarks.some(remark => remark.type === this.selectedRemarkType);
      });
    }
    hilog.info(DOMAIN, TAG, `Applied filter: ${this.selectedRemarkType}, showing ${this.filteredRecords.length} records.`);
  }

  showRecordDetail(record: WeightRecord) {
    try {
      router.pushUrl({
        url: 'pages/RecordDetail',
        params: { record: record }
      });
    } catch (error) {
      hilog.error(DOMAIN, TAG, `Failed to navigate to RecordDetail, cause: ${error}`);
    }
  }

  editRecord(record: WeightRecord) {
    try {
      router.pushUrl({
        url: 'pages/WeightEditForm',
        params: { record: record }
      });
    } catch (error) {
      hilog.error(DOMAIN, TAG, `Failed to navigate to WeightEditForm, cause: ${error}`);
    }
  }

  confirmDelete(record: WeightRecord) {
    this.recordToDelete = record;
    this.showDeleteDialog = true;
  }

  async deleteRecord() {
    if (!this.recordToDelete) return;

    try {
      const dao = getAppDao();
      if (!dao) {
        throw new Error('Global DAO not initialized');
      }
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
            try {
              router.back();
            } catch (error) {
              hilog.error(DOMAIN, TAG, `Failed to navigate back, cause: ${error}`);
            }
          })
        Text('历史记录')
          .fontSize(24)
          .fontWeight(FontWeight.Bold)
          .layoutWeight(1)
          .textAlign(TextAlign.Center)
          .margin({ right: 24 }) // to balance the back button
        
        Image($r('app.media.ic_back'))
          .width(24)
          .height(24)
          .fillColor(Color.Blue)
          .onClick(() => {
            try {
              router.pushUrl({ url: 'pages/WeightChart' });
            } catch (error) {
              hilog.error(DOMAIN, TAG, `Failed to navigate to WeightChart, cause: ${error}`);
            }
          })
      }
      .width('100%')
      .padding(15)
      .backgroundColor(Color.White)
      .shadow({ radius: 3, color: Color.Gray, offsetX: 0, offsetY: 2 })

      // 备注筛选器
      if (this.records.length > 0) {
        RemarkFilter({
          selectedType: this.selectedRemarkType,
          onFilterChange: (type: RemarkType | 'all') => {
            this.selectedRemarkType = type;
            this.applyFilter();
          }
        })
        .margin({ left: 20, right: 20, top: 10, bottom: 10 })
      }

      if (this.filteredRecords.length > 0) {
        List({ space: 10 }) {
          ForEach(this.filteredRecords, (item: WeightRecord) => {
            ListItem() {
              this.RecordItem(item)
            }
          })
        }
        .layoutWeight(1)
        .padding({ left: 20, right: 20, bottom: 10 })
      } else if (this.records.length > 0) {
        Column() {
          Text('没有符合条件的记录')
            .fontSize(18)
            .fontColor(Color.Gray)
            .margin({ top: '40%' })
          
          if (this.selectedRemarkType !== 'all') {
            Button('清除筛选')
              .type(ButtonType.Capsule)
              .margin({ top: 20 })
              .backgroundColor(AppColors.PRIMARY)
              .onClick(() => {
                this.selectedRemarkType = 'all';
                this.applyFilter();
              })
          }
        }
        .layoutWeight(1)
        .padding({ left: 20, right: 20 })
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
        Row() {
          Text(`${record.weight.toFixed(1)} kg`)
            .fontSize(20)
            .fontWeight(FontWeight.Bold)
          
          if (this.currentTarget) {
            const difference = record.weight - this.currentTarget.targetWeight;
            Text(difference > 0 ? `+${difference.toFixed(1)} kg` : `${difference.toFixed(1)} kg`)
              .fontSize(14)
              .fontColor(difference > 0 ? AppColors.WARNING : AppColors.SUCCESS)
              .margin({ left: 10 })
              .fontWeight(FontWeight.Medium)
          }
        }
        
        Text(this.formatDate(record.date))
          .fontSize(14)
          .fontColor(Color.Gray)
          .margin({ top: 5 })
        
        // 传统备注
        if (record.notes && record.notes.trim()) {
          Text(record.notes)
            .fontSize(14)
            .fontColor('#666666')
            .margin({ top: 8 })
            .maxLines(2)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
        }
        
        // 结构化备注摘要
        const remarks = this.remarksMap.get(record.id) || [];
        if (remarks.length > 0) {
          RemarkSummary({ remarks: remarks })
        }
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)

      Row() {
        Image($r('app.media.ic_edit'))
          .width(22)
          .height(22)
          .fillColor(Color.Blue)
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
          
          Text(`${this.recordToDelete.weight.toFixed(1)} kg - ${this.formatDateOnly(this.recordToDelete.date)}`)
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