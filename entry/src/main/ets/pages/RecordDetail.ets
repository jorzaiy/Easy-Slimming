import hilog from '@ohos.hilog';
import { WeightRecord } from '../model/WeightRecord';
import router from '@ohos.router';
import promptAction from '@ohos.promptAction';

const DOMAIN = 0x0000;
const TAG = 'WeightApp_RecordDetail';

@Entry
@Component
struct RecordDetailPage {
  @State record: WeightRecord | null = null;

  aboutToAppear() {
    try {
      const params = router.getParams();
      hilog.info(DOMAIN, TAG, `Router params type: ${typeof params}, value: ${params}`);
      
      if (params && typeof params === 'object' && 'record' in params) {
        this.record = (params as any).record;
        if (this.record && this.record.id) {
          hilog.info(DOMAIN, TAG, `Loaded record detail for id: ${this.record.id}`);
        } else {
          hilog.error(DOMAIN, TAG, 'Invalid record object received');
          this.handleNavigationError();
        }
      } else {
        hilog.error(DOMAIN, TAG, 'No record parameter found');
        this.handleNavigationError();
      }
    } catch (e) {
      hilog.error(DOMAIN, TAG, `Failed to load record detail, cause: ${e}`);
      this.handleNavigationError();
    }
  }

  handleNavigationError() {
    promptAction.showToast({
      message: '记录信息加载失败',
      duration: 2000
    });
    setTimeout(() => {
      router.back();
    }, 1000);
  }

  formatDate(timestamp: number): string {
    const date = new Date(timestamp);
    return date.toLocaleString('zh-CN', {
      year: 'numeric',
      month: '2-digit',
      day: '2-digit',
      hour: '2-digit',
      minute: '2-digit'
    });
  }

  build() {
    Column() {
      // Header
      Row() {
        Image($r('app.media.ic_back'))
          .width(24)
          .height(24)
          .onClick(() => {
            router.back();
          })
        Text('记录详情')
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

      if (this.record) {
        Column() {
          // Weight Card
          Column() {
            Text('体重')
              .fontSize(16)
              .fontWeight(FontWeight.Medium)
              .fontColor('#666666')
              .margin({ bottom: 10 })
            
            Text(`${this.record.weight.toFixed(1)} kg`)
              .fontSize(32)
              .fontWeight(FontWeight.Bold)
              .fontColor('#007DFF')
          }
          .width('100%')
          .padding(25)
          .backgroundColor(Color.White)
          .borderRadius(12)
          .alignItems(HorizontalAlign.Center)
          .margin({ top: 20, bottom: 15 })

          // Date Card
          Column() {
            Text('记录时间')
              .fontSize(16)
              .fontWeight(FontWeight.Medium)
              .fontColor('#666666')
              .margin({ bottom: 10 })
            
            Text(this.formatDate(this.record.date))
              .fontSize(18)
              .fontWeight(FontWeight.Medium)
          }
          .width('100%')
          .padding(20)
          .backgroundColor(Color.White)
          .borderRadius(12)
          .alignItems(HorizontalAlign.Start)
          .margin({ bottom: 15 })

          // Notes Card (if exists)
          if (this.record.notes && this.record.notes.trim()) {
            Column() {
              Text('备注')
                .fontSize(16)
                .fontWeight(FontWeight.Medium)
                .fontColor('#666666')
                .margin({ bottom: 10 })
              
              Text(this.record.notes)
                .fontSize(16)
                .lineHeight(24)
                .fontColor('#333333')
            }
            .width('100%')
            .padding(20)
            .backgroundColor(Color.White)
            .borderRadius(12)
            .alignItems(HorizontalAlign.Start)
            .margin({ bottom: 20 })
          }

          // Action Buttons
          Column() {
            Button('编辑记录')
              .type(ButtonType.Capsule)
              .width('100%')
              .height(50)
              .fontSize(18)
              .fontWeight(FontWeight.Bold)
              .backgroundColor('#007DFF')
              .margin({ bottom: 15 })
              .onClick(() => {
                router.pushUrl({
                  url: 'pages/WeightEditForm',
                  params: { record: this.record }
                });
              })
          }
          .width('100%')
          .padding({ left: 20, right: 20 })
        }
        .width('100%')
        .padding({ left: 20, right: 20, top: 20 })
        .layoutWeight(1)
      } else {
        Column() {
          Text('记录信息加载中...')
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
}