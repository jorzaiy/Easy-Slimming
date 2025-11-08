import hilog from '@ohos.hilog';
import router from '@ohos.router';
import { WeightRecord } from '../model/WeightRecord';
import { Remark, RemarkType } from '../model/Remark';
import { NavigationHelper } from '../common/NavigationHelper';
import { FormValidator } from '../common/FormValidator';
import { AppColors, AppDimensions, AppText, BusinessConstants, LogConstants } from '../common/Constants';
import promptAction from '@ohos.promptAction';
import { getAppDao } from '../common/Global';
import { RemarkEntry } from '../components/RemarkEntry';
import { RemarkDisplay, RemarkEditDialog } from '../components/RemarkDisplay';

// 路由参数接口
interface EditFormParams {
  record: WeightRecord;
}

const DOMAIN = LogConstants.DOMAIN;
const TAG = LogConstants.TAG_PREFIX + 'EditForm';

@Entry
@Component
struct WeightEditForm {
  @State selectedDate: Date = new Date();
  @State weightInput: string = '';
  @State notesInput: string = '';
  @State remarks: Remark[] = [];
  @State isSubmitting: boolean = false;
  @State recordId: number = -1;
  @State isEditMode: boolean = false;
  @State showEditDialog: boolean = false;
  @State editingRemark: Remark | null = null;
  @State editingIndex: number = -1;

  async aboutToAppear() {
    try {
      const params = router.getParams();
      hilog.info(DOMAIN, TAG, `Router params type: ${typeof params}, value: ${params}`);

      if (params && typeof params === 'object' && params && (params as EditFormParams).record) {
        const recordParams = params as EditFormParams;
        const record = recordParams.record;
        if (record && record.id) {
          this.recordId = record.id;
          this.selectedDate = new Date(record.date);
          this.weightInput = record.weight.toString();
          this.notesInput = record.notes || '';
          this.isEditMode = true;
          hilog.info(DOMAIN, TAG, `Loaded record for editing, id: ${this.recordId}`);
          
          // 加载现有备注
          await this.loadRemarks();
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

  formatDateOnly(timestamp: number): string {
    const date = new Date(timestamp);
    const year = date.getFullYear();
    const month = (date.getMonth() + 1).toString().padStart(2, '0');
    const day = date.getDate().toString().padStart(2, '0');
    return `${year}/${month}/${day}`;
  }

  async loadRemarks() {
    if (!this.isEditMode || this.recordId <= 0) return;

    try {
      const dao = getAppDao();
      if (!dao) {
        throw new Error('Global DAO not initialized');
      }
      this.remarks = await dao.queryRemarksByRecordId(this.recordId);
      hilog.info(DOMAIN, TAG, `Loaded ${this.remarks.length} remarks for record ${this.recordId}`);
    } catch (e) {
      hilog.error(DOMAIN, TAG, `Failed to load remarks, cause: ${e}`);
    }
  }

  showAddRemarkDialog() {
    this.editingRemark = null;
    this.editingIndex = -1;
    this.showEditDialog = true;
  }

  showEditRemarkDialog(remark: Remark, index: number) {
    this.editingRemark = remark;
    this.editingIndex = index;
    this.showEditDialog = true;
  }

  async handleSaveRemark(type: RemarkType, content: string) {
    if (!this.isEditMode || this.recordId <= 0) return;

    try {
      const dao = getAppDao();
      if (!dao) {
        throw new Error('Global DAO not initialized');
      }

      if (this.editingRemark && this.editingIndex >= 0) {
        // 更新现有备注
        const rows = await dao.updateRemark(this.editingRemark.id, type, content);
        if (rows > 0) {
          await this.loadRemarks();
          promptAction.showToast({
            message: '备注更新成功',
            duration: 2000
          });
        }
      } else {
        // 添加新备注
        const remarkId = await dao.addRemark(this.recordId, type, content);
        if (remarkId > 0) {
          await this.loadRemarks();
          promptAction.showToast({
            message: '备注添加成功',
            duration: 2000
          });
        }
      }
    } catch (e) {
      hilog.error(DOMAIN, TAG, `Failed to save remark, cause: ${e}`);
      promptAction.showToast({
        message: '保存失败，请重试',
        duration: 2000
      });
    } finally {
      this.showEditDialog = false;
      this.editingRemark = null;
      this.editingIndex = -1;
    }
  }

  async handleDeleteRemark(remarkId: number, index: number) {
    try {
      const dao = getAppDao();
      if (!dao) {
        throw new Error('Global DAO not initialized');
      }

      const rows = await dao.deleteRemark(remarkId);
      if (rows > 0) {
        await this.loadRemarks();
        promptAction.showToast({
          message: '备注删除成功',
          duration: 2000
        });
      }
    } catch (e) {
      hilog.error(DOMAIN, TAG, `Failed to delete remark, cause: ${e}`);
      promptAction.showToast({
        message: '删除失败，请重试',
        duration: 2000
      });
    }
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
      const dao = getAppDao();
      if (!dao) {
        throw new Error('Global DAO not initialized');
      }
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
              if (value && value.year !== undefined && value.month !== undefined && value.day !== undefined) {
                this.selectedDate = new Date(value.year, value.month, value.day);
                hilog.info(DOMAIN, TAG, `Selected date: ${this.formatDateOnly(this.selectedDate.getTime())}`);
              }
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
          Text('传统备注')
            .fontSize(16)
            .fontWeight(FontWeight.Medium)
            .margin({ bottom: 10 })

          TextArea({ placeholder: '记录一般性备注信息（可选）', text: this.notesInput })
            .width('100%')
            .height(80)
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
        .margin({ bottom: 15 })

        // 结构化备注部分（仅在编辑模式下显示）
        if (this.isEditMode) {
          Column() {
            Row() {
              Text('详细备注')
                .fontSize(16)
                .fontWeight(FontWeight.Medium)
                .layoutWeight(1)

              Button('添加')
                .type(ButtonType.Capsule)
                .height(32)
                .fontSize(14)
                .backgroundColor(AppColors.PRIMARY)
                .onClick(() => {
                  this.showAddRemarkDialog();
                })
            }
            .width('100%')
            .margin({ bottom: 15 })

            RemarkDisplay({
              remarks: this.remarks,
              onEditRemark: (remark: Remark, index: number) => {
                this.showEditRemarkDialog(remark, index);
              },
              onDeleteRemark: (remarkId: number, index: number) => {
                this.handleDeleteRemark(remarkId, index);
              }
            })
          }
          .width('100%')
          .margin({ bottom: 15 })
        }

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
    .bindContentCover(this.showEditDialog, this.buildEditDialog(), {
      modalTransition: ModalTransition.NONE,
      backgroundColor: Color.Transparent
    })
  }

  @Builder
  buildEditDialog() {
    RemarkEditDialog({
      isVisible: this.showEditDialog,
      remark: this.editingRemark,
      onSave: (type: RemarkType, content: string) => {
        this.handleSaveRemark(type, content);
      },
      onCancel: () => {
        this.showEditDialog = false;
        this.editingRemark = null;
        this.editingIndex = -1;
      }
    })
  }
}