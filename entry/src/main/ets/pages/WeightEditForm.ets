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
import { RemarkDisplay } from '../components/RemarkDisplay';
import { RemarkEditDialog } from '../components/RemarkEditDialog';

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
  @State isAddingRemark: boolean = false;
  @State isEditingRemark: boolean = false;
  @State remarksLoading: boolean = false;
  @State notesError: string = '';

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
    return this.isWeightValid() && this.isDateValid() && this.validateNotes();
  }

  formatDateOnly(timestamp: number): string {
    const date = new Date(timestamp);
    const year = date.getFullYear();
    const month = (date.getMonth() + 1).toString().padStart(2, '0');
    const day = date.getDate().toString().padStart(2, '0');
    return `${year}/${month}/${day}`;
  }

  async loadRemarks() {
    if (!this.isEditMode || this.recordId <= 0) {
      return;
    }

    this.remarksLoading = true;
    try {
      const dao = getAppDao();
      if (!dao) {
        throw new Error('Global DAO not initialized');
      }
      this.remarks = await dao.queryRemarksByRecordId(this.recordId);
      hilog.info(DOMAIN, TAG, `Loaded ${this.remarks.length} remarks for record ${this.recordId}`);
    } catch (e) {
      hilog.error(DOMAIN, TAG, `Failed to load remarks, cause: ${e}`);
      promptAction.showToast({
        message: '加载备注失败，请重试',
        duration: 2000
      });
    } finally {
      this.remarksLoading = false;
    }
  }

  showAddRemarkDialog() {
    this.resetDialogState();
    this.isAddingRemark = true;
    this.isEditingRemark = false;
    this.showEditDialog = true;
    hilog.info(DOMAIN, TAG, 'Opening add remark dialog');
  }

  showEditRemarkDialog(remark: Remark, index: number) {
    this.resetDialogState();
    this.editingRemark = remark;
    this.editingIndex = index;
    this.isAddingRemark = false;
    this.isEditingRemark = true;
    this.showEditDialog = true;
    hilog.info(DOMAIN, TAG, `Opening edit remark dialog for remark ${remark.id}`);
  }

  private resetDialogState() {
    this.editingRemark = null;
    this.editingIndex = -1;
    this.isAddingRemark = false;
    this.isEditingRemark = false;
  }

  async handleSaveRemark(type: RemarkType, content: string) {
    if (!this.isEditMode || this.recordId <= 0) {
      return;
    }

    try {
      const dao = getAppDao();
      if (!dao) {
        throw new Error('Global DAO not initialized');
      }

      let success = false;
      let operation = '';

      if (this.editingRemark && this.editingIndex >= 0) {
        // 更新现有备注
        const rows = await dao.updateRemark(this.editingRemark.id, type, content);
        if (rows > 0) {
          success = true;
          operation = '更新';
          hilog.info(DOMAIN, TAG, `Successfully updated remark ${this.editingRemark.id}`);
        } else {
          throw new Error('No rows affected during update');
        }
      } else {
        // 添加新备注
        const remarkId = await dao.addRemark(this.recordId, type, content);
        if (remarkId > 0) {
          success = true;
          operation = '添加';
          hilog.info(DOMAIN, TAG, `Successfully added new remark with id ${remarkId}`);
        } else {
          throw new Error('Failed to insert new remark');
        }
      }

      if (success) {
        // 重新加载备注以确保状态同步
        await this.loadRemarks();
        promptAction.showToast({
          message: `备注${operation}成功`,
          duration: 2000
        });
      }
    } catch (e) {
      hilog.error(DOMAIN, TAG, `Failed to save remark, cause: ${e}`);
      promptAction.showToast({
        message: '保存失败，请重试',
        duration: 2000
      });
    } finally {
      this.showEditDialog = false;
      this.resetDialogState();
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
        hilog.info(DOMAIN, TAG, `Successfully deleted remark ${remarkId}`);
        // 重新加载备注以确保状态同步
        await this.loadRemarks();
        promptAction.showToast({
          message: '备注删除成功',
          duration: 2000
        });
      } else {
        throw new Error('No rows affected during delete');
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

  validateNotes(): boolean {
    if (this.notesInput.length > BusinessConstants.MAX_NOTES_LENGTH) {
      this.notesError = `备注长度不能超过 ${BusinessConstants.MAX_NOTES_LENGTH} 个字符`;
      return false;
    }
    this.notesError = '';
    return true;
  }

  getNotesCharacterCount(): string {
    const current = this.notesInput.length;
    const max = BusinessConstants.MAX_NOTES_LENGTH;
    const isNearLimit = current > max * 0.8;
    const isOverLimit = current >= max;
    
    if (isOverLimit) {
      return `${current}/${max}`;
    } else if (isNearLimit) {
      return `${current}/${max} (接近限制)`;
    } else {
      return `${current}/${max}`;
    }
  }

  getNotesCharacterCountColor(): string {
    const current = this.notesInput.length;
    const max = BusinessConstants.MAX_NOTES_LENGTH;
    
    if (current >= max) {
      return AppColors.ERROR;
    } else if (current > max * 0.8) {
      return AppColors.WARNING;
    } else {
      return AppColors.GRAY;
    }
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

      // 验证所有字段
      if (!this.validateNotes()) {
        throw new Error('备注验证失败');
      }

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
          .width(AppDimensions.ICON_SIZE)
          .height(AppDimensions.ICON_SIZE)
          .onClick(() => {
            try {
              router.back();
            } catch (error) {
              hilog.error(DOMAIN, TAG, `Failed to navigate back, cause: ${error}`);
            }
          })
        Text('编辑记录')
          .fontSize(AppText.FONT_SIZE_TITLE)
          .fontWeight(FontWeight.Bold)
          .layoutWeight(1)
          .textAlign(TextAlign.Center)
          .margin({ right: AppDimensions.ICON_SIZE })
      }
      .width('100%')
      .padding(AppDimensions.PADDING_MEDIUM)
      .backgroundColor(AppColors.WHITE)
      .shadow({
        radius: 3,
        color: Color.Gray,
        offsetX: 0,
        offsetY: 2
      })

      Column() {
        Column() {
          Row() {
            Text('日期')
              .fontSize(AppText.FONT_SIZE_SMALL)
              .fontWeight(FontWeight.Medium)
            Text('*')
              .fontSize(AppText.FONT_SIZE_SMALL)
              .fontColor(AppColors.ERROR)
              .margin({ left: 4 })
          }
          .margin({ bottom: AppDimensions.MARGIN_SMALL })

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
        .padding(AppDimensions.PADDING_LARGE)
        .backgroundColor(AppColors.WHITE)
        .borderRadius(AppDimensions.BORDER_RADIUS)
        .alignItems(HorizontalAlign.Start)
        .margin({ bottom: AppDimensions.MARGIN_MEDIUM })

        Column() {
          Row() {
            Text('体重 (kg)')
              .fontSize(AppText.FONT_SIZE_SMALL)
              .fontWeight(FontWeight.Medium)
            Text('*')
              .fontSize(AppText.FONT_SIZE_SMALL)
              .fontColor(AppColors.ERROR)
              .margin({ left: 4 })
          }
          .margin({ bottom: AppDimensions.MARGIN_SMALL })

          TextInput({ placeholder: '请输入体重，如：65.5', text: this.weightInput })
            .type(InputType.Number)
            .width('100%')
            .height(AppDimensions.BUTTON_HEIGHT)
            .fontSize(AppText.FONT_SIZE_BODY)
            .placeholderFont({ size: AppText.FONT_SIZE_SMALL })
            .onChange((value: string) => {
              this.weightInput = value;
            })

          if (this.getWeightErrorMessage()) {
            Text(this.getWeightErrorMessage())
              .fontSize(AppText.FONT_SIZE_TINY)
              .fontColor(AppColors.ERROR)
              .margin({ top: 8 })
          } else if (this.weightInput) {
            Text(`范围：${BusinessConstants.MIN_WEIGHT}-${BusinessConstants.MAX_WEIGHT} kg`)
              .fontSize(AppText.FONT_SIZE_TINY)
              .fontColor(AppColors.GRAY)
              .margin({ top: 8 })
          }
        }
        .width('100%')
        .padding(AppDimensions.PADDING_LARGE)
        .backgroundColor(AppColors.WHITE)
        .borderRadius(AppDimensions.BORDER_RADIUS)
        .alignItems(HorizontalAlign.Start)
        .margin({ bottom: AppDimensions.MARGIN_MEDIUM })

        Column() {
          Text('传统备注')
            .fontSize(AppText.FONT_SIZE_SMALL)
            .fontWeight(FontWeight.Medium)
            .margin({ bottom: AppDimensions.MARGIN_SMALL })

          TextArea({ 
            placeholder: '记录一般性备注信息（可选）', 
            text: this.notesInput 
          })
            .width('100%')
            .height(80)
            .fontSize(AppText.FONT_SIZE_SMALL)
            .placeholderFont({ size: AppText.FONT_SIZE_SMALL })
            .maxLength(BusinessConstants.MAX_NOTES_LENGTH)
            .onChange((value: string) => {
              this.notesInput = value;
              // 实时验证备注
              this.validateNotes();
            })

          // 显示字符计数和错误信息
          Column() {
            if (this.notesError) {
              Text(this.notesError)
                .fontSize(AppText.FONT_SIZE_TINY)
                .fontColor(AppColors.ERROR)
                .margin({ top: 4 })
                .width('100%')
                .textAlign(TextAlign.Start)
            }

            Row() {
              Blank()
              Text(this.getNotesCharacterCount())
                .fontSize(AppText.FONT_SIZE_TINY)
                .fontColor(this.getNotesCharacterCountColor())
            }
            .width('100%')
            .margin({ top: 4 })
          }
          .width('100%')
        }
        .width('100%')
        .padding(AppDimensions.PADDING_LARGE)
        .backgroundColor(AppColors.WHITE)
        .borderRadius(AppDimensions.BORDER_RADIUS)
        .alignItems(HorizontalAlign.Start)
        .margin({ bottom: AppDimensions.MARGIN_MEDIUM })

        // 结构化备注部分（仅在编辑模式下显示）
        if (this.isEditMode) {
          Column() {
            Row() {
              Text('详细备注')
                .fontSize(AppText.FONT_SIZE_SMALL)
                .fontWeight(FontWeight.Bold)
                .layoutWeight(1)

              if (this.remarksLoading) {
                Row() {
                  LoadingProgress()
                    .width(16)
                    .height(16)
                    .color(AppColors.PRIMARY)
                  Text('加载中...')
                    .fontSize(AppText.FONT_SIZE_TINY)
                    .fontColor(AppColors.GRAY)
                    .margin({ left: 4 })
                }
              } else {
                Button(this.remarks.length > 0 ? '添加备注' : '添加第一条备注')
                  .type(ButtonType.Capsule)
                  .height(AppDimensions.BUTTON_HEIGHT_SMALL)
                  .fontSize(AppText.FONT_SIZE_SMALL)
                  .backgroundColor(AppColors.PRIMARY)
                  .onClick(() => {
                    this.showAddRemarkDialog();
                  })
              }
            }
            .width('100%')
            .margin({ bottom: AppDimensions.MARGIN_SMALL })
            .justifyContent(FlexAlign.SpaceBetween)
            .alignItems(VerticalAlign.Center)

            if (!this.remarksLoading) {
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
          }
          .width('100%')
          .padding(AppDimensions.PADDING_LARGE)
          .backgroundColor(AppColors.WHITE)
          .borderRadius(AppDimensions.BORDER_RADIUS)
          .margin({ bottom: AppDimensions.MARGIN_MEDIUM })
        }

        Button(this.isSubmitting ? '更新中...' : '保存修改')
          .type(ButtonType.Capsule)
          .width('100%')
          .height(AppDimensions.BUTTON_HEIGHT)
          .fontSize(AppText.FONT_SIZE_BODY)
          .fontWeight(FontWeight.Bold)
          .enabled(!this.isSubmitting && this.isFormValid())
          .backgroundColor(this.isFormValid() && !this.isSubmitting ? AppColors.PRIMARY : AppColors.LIGHT_GRAY)
          .onClick(() => {
            this.handleSubmit();
          })
      }
      .width('100%')
      .padding({ left: AppDimensions.PADDING_LARGE, right: AppDimensions.PADDING_LARGE, top: AppDimensions.PADDING_LARGE })
    }
    .width('100%')
    .height('100%')
    .backgroundColor(AppColors.BACKGROUND)
    .bindContentCover(this.showEditDialog, this.buildEditDialog(), {
      modalTransition: ModalTransition.NONE,
      backgroundColor: Color.Transparent
    })
  }

  @Builder
  buildEditDialog() {
    RemarkEditDialog({
      isVisible: this.showEditDialog,
      remark: this.editingRemark ?? undefined,
      onSave: (type: RemarkType, content: string) => {
        this.handleSaveRemark(type, content);
      },
      onCancel: () => {
        this.showEditDialog = false;
        this.resetDialogState();
        hilog.info(DOMAIN, TAG, 'Remark edit dialog cancelled');
      }
    })
  }
}