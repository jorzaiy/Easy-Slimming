import hilog from '@ohos.hilog';
import router from '@ohos.router';
import { WeightRecord } from '../model/WeightRecord';
import { NavigationHelper } from '../common/NavigationHelper';
import { AppColors, AppDimensions, AppText, LogConstants } from '../common/Constants';
import promptAction from '@ohos.promptAction';

// 路由参数接口
interface RecordDetailParams {
  record: WeightRecord;
}

const DOMAIN = LogConstants.DOMAIN;
const TAG = LogConstants.TAG_PREFIX + 'RecordDetail';

@Entry
@Component
struct RecordDetailPage {
  @State record: WeightRecord | null = null;

  aboutToAppear() {
    try {
      const params = router.getParams();
      hilog.info(DOMAIN, TAG, `Router params type: ${typeof params}, value: ${params}`);

      if (params && typeof params === 'object' && params && (params as RecordDetailParams).record) {
        const recordParams = params as RecordDetailParams;
        this.record = recordParams.record;
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
    NavigationHelper.navigateBackWithFeedback(1000);
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

  build() {
    Column() {
      // Header
      Row() {
        Image($r('app.media.ic_back'))
          .width(AppDimensions.ICON_SIZE)
          .height(AppDimensions.ICON_SIZE)
          .onClick(() => {
            NavigationHelper.navigateBack();
          })
        Text('记录详情')
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
              .fontColor(Color.Blue)
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
              .backgroundColor(Color.Blue)
              .margin({ bottom: 15 })
              .onClick(() => {
                try {
                  router.pushUrl({
                    url: 'pages/WeightEditForm',
                    params: { record: this.record }
                  });
                } catch (error) {
                  hilog.error(DOMAIN, TAG, `Failed to navigate to WeightEditForm, cause: ${error}`);
                }
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