/**
 * 数据管理页面
 * 提供数据导出和导入功能
 */
import router from '@ohos.router';
import hilog from '@ohos.hilog';
import { AppColors, AppDimensions, AppText, LogConstants } from '../common/Constants';
import promptAction from '@ohos.promptAction';
import { getAppDao } from '../common/Global';
import { getTargetWeightService } from '../data/TargetWeightService';
import { getDataExportImportService, DataExportImportService } from '../data/DataExportImportService';
import { common } from '@kit.AbilityKit';
import fs from '@ohos.file.fs';
import picker from '@ohos.file.picker';
import relationalStore from '@ohos.data.relationalStore';

const DOMAIN = LogConstants.DOMAIN;
const TAG = LogConstants.TAG_PREFIX + 'DataManagement';

interface ConflictResolution {
  type: 'override' | 'merge' | 'skip';
}

@Entry
@Component
struct DataManagement {
  @State showExportDialog: boolean = false;
  @State showImportDialog: boolean = false;
  @State exportFormat: 'json' | 'csv' | 'excel' = 'json';
  @State includeStatistics: boolean = true;
  @State conflictResolution: 'override' | 'merge' | 'skip' = 'skip';
  @State isProcessing: boolean = false;
  @State progressMessage: string = '';

  async aboutToAppear() {
  }

  async onExport() {
    if (this.isProcessing) {
      return;
    }

    this.isProcessing = true;
    this.progressMessage = '正在导出数据...';

    try {
      const dao = getAppDao();
      if (!dao) {
        throw new Error('DAO not initialized');
      }

      const service = await getDataExportImportService(dao);

      if (!service) {
        throw new Error('Export service not initialized');
      }

      const context = this.getUIContext();
      const targetService = context ? await getTargetWeightService(context as unknown as common.Context) : null;
      const targets = targetService ? await targetService.getAllTargets() : undefined;

      const options = {
        format: this.exportFormat as 'csv' | 'excel' | 'json',
        includeStatistics: this.includeStatistics,
        timestamp: Date.now()
      };

      let content = '';
      let fileName = '';
      let mimeType = '';

      switch (this.exportFormat) {
        case 'json':
          content = await service.exportToJSON(options, targets);
          fileName = `weight_export_${Date.now()}.json`;
          mimeType = 'application/json';
          break;
        case 'csv':
          content = await service.exportToCSV(options, targets);
          fileName = `weight_export_${Date.now()}.csv`;
          mimeType = 'text/csv';
          break;
        case 'excel':
          content = await service.exportToExcel(options, targets);
          fileName = `weight_export_${Date.now()}.xlsx`;
          mimeType = 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
          break;
      }

      await this.saveExportFile(fileName, content);
      
      this.showExportDialog = false;
      promptAction.showToast({
        message: `导出成功: ${fileName}`,
        duration: 2000
      });
      hilog.info(DOMAIN, TAG, `Export successful: ${fileName}`);
    } catch (e) {
      hilog.error(DOMAIN, TAG, `Export failed: ${e}`);
      promptAction.showToast({
        message: `导出失败: ${e}`,
        duration: 2000
      });
    } finally {
      this.isProcessing = false;
      this.progressMessage = '';
    }
  }

  async onImport() {
    try {
      const documentPicker = new picker.DocumentViewPicker();
      const result = await documentPicker.select();

      if (result && result.length > 0) {
        const filePath = result[0];
        await this.importFromFile(filePath);
      }
    } catch (e) {
      hilog.error(DOMAIN, TAG, `Import failed: ${e}`);
      promptAction.showToast({
        message: '导入被取消或出错',
        duration: 2000
      });
    }
  }

  async importFromFile(filePath: string) {
    if (this.isProcessing) {
      return;
    }

    this.isProcessing = true;
    this.progressMessage = '正在导入数据...';

    try {
      const dao = getAppDao();
      if (!dao) {
        throw new Error('DAO not initialized');
      }

      const service = await getDataExportImportService(dao);
      
      // 读取文件
      const content = fs.readTextSync(filePath);

      let importResult;

      if (filePath.endsWith('.json')) {
        importResult = await service.importFromJSON(content, {
          conflictResolution: this.conflictResolution as 'override' | 'merge' | 'skip'
        });
      } else if (filePath.endsWith('.csv') || filePath.endsWith('.xlsx')) {
        importResult = await service.importFromCSV(content, {
          conflictResolution: this.conflictResolution as 'override' | 'merge' | 'skip'
        });
      } else {
        throw new Error('Unsupported file format');
      }

      this.showImportDialog = false;

      if (importResult.success) {
        promptAction.showToast({
          message: `导入成功: 导入${importResult.importedCount}条记录`,
          duration: 2000
        });
        hilog.info(
          DOMAIN,
          TAG,
          `Import successful: ${importResult.importedCount} imported, ${importResult.skippedCount} skipped`
        );
      } else {
        const errorMsg = importResult.errors.length > 0 ? importResult.errors[0] : '导入失败';
        promptAction.showToast({
          message: `导入完成但有错误: ${errorMsg}`,
          duration: 3000
        });
      }
    } catch (e) {
      hilog.error(DOMAIN, TAG, `Import from file failed: ${e}`);
      promptAction.showToast({
        message: `导入失败: ${e}`,
        duration: 2000
      });
    } finally {
      this.isProcessing = false;
      this.progressMessage = '';
    }
  }

  private async saveExportFile(fileName: string, content: string): Promise<void> {
    try {
      const filePath = `/data/storage/el2/base/files/${fileName}`;
      const file = fs.openSync(filePath, fs.OpenMode.CREATE | fs.OpenMode.WRITE);
      try {
        fs.writeSync(file.fd, content);
      } finally {
        fs.closeSync(file);
      }
      hilog.info(DOMAIN, TAG, `File saved: ${filePath}`);
    } catch (e) {
      hilog.error(DOMAIN, TAG, `Failed to save file: ${e}`);
      throw new Error(`Failed to save export file: ${e}`);
    }
  }

  build() {
    Stack() {
      Column() {
        // 顶部栏
        Row() {
          Button('返回')
            .type(ButtonType.Normal)
            .height(40)
            .width(80)
            .fontSize(AppText.FONT_SIZE_BODY)
            .onClick(() => {
              router.back();
            })

          Text('数据管理')
            .fontSize(AppText.FONT_SIZE_TITLE)
            .fontWeight(FontWeight.Bold)
            .layoutWeight(1)
            .textAlign(TextAlign.Center)

          Button()
            .width(40)
            .height(40)
            .opacity(0)
        }
        .width('100%')
        .height(56)
        .padding({ left: AppDimensions.PADDING_MEDIUM, right: AppDimensions.PADDING_MEDIUM })
        .alignItems(VerticalAlign.Center)
        .backgroundColor(AppColors.WHITE)
        .shadow({ radius: 2, color: Color.Gray, offsetX: 0, offsetY: 1 })

        Scroller() {
          Column({ space: AppDimensions.MARGIN_LARGE }) {
            // 导出功能卡片
            Column({ space: AppDimensions.MARGIN_MEDIUM }) {
              Text('导出数据')
                .fontSize(AppText.FONT_SIZE_SUBTITLE)
                .fontWeight(FontWeight.Bold)
                .width('100%')

              Text('将应用中的体重记录导出为CSV、Excel或JSON格式')
                .fontSize(AppText.FONT_SIZE_SMALL)
                .fontColor(AppColors.GRAY)
                .width('100%')

              Button('导出数据')
                .type(ButtonType.Capsule)
                .width('100%')
                .height(50)
                .fontSize(AppText.FONT_SIZE_BODY)
                .fontWeight(FontWeight.Bold)
                .enabled(!this.isProcessing)
                .onClick(() => {
                  this.showExportDialog = true;
                })
            }
            .width('90%')
            .padding(AppDimensions.PADDING_LARGE)
            .backgroundColor(AppColors.WHITE)
            .borderRadius(AppDimensions.BORDER_RADIUS)
            .shadow({ radius: 3, color: Color.Gray, offsetX: 0, offsetY: 1 })

            // 导入功能卡片
            Column({ space: AppDimensions.MARGIN_MEDIUM }) {
              Text('导入数据')
                .fontSize(AppText.FONT_SIZE_SUBTITLE)
                .fontWeight(FontWeight.Bold)
                .width('100%')

              Text('从导出的CSV、Excel或JSON文件中导入体重记录')
                .fontSize(AppText.FONT_SIZE_SMALL)
                .fontColor(AppColors.GRAY)
                .width('100%')

              Button('选择文件导入')
                .type(ButtonType.Capsule)
                .width('100%')
                .height(50)
                .fontSize(AppText.FONT_SIZE_BODY)
                .fontWeight(FontWeight.Bold)
                .enabled(!this.isProcessing)
                .onClick(() => {
                  this.onImport();
                })
            }
            .width('90%')
            .padding(AppDimensions.PADDING_LARGE)
            .backgroundColor(AppColors.WHITE)
            .borderRadius(AppDimensions.BORDER_RADIUS)
            .shadow({ radius: 3, color: Color.Gray, offsetX: 0, offsetY: 1 })

            // 帮助信息
            Column({ space: AppDimensions.MARGIN_SMALL }) {
              Text('使用说明')
                .fontSize(AppText.FONT_SIZE_SUBTITLE)
                .fontWeight(FontWeight.Bold)
                .width('100%')

              Text('• 导出：选择格式和范围，导出应用中的数据备份\n• 导入：选择包含数据的文件进行导入\n• 支持格式：JSON、CSV、Excel\n• 导入冲突处理：跳过（默认）、覆盖、合并')
                .fontSize(AppText.FONT_SIZE_SMALL)
                .fontColor(AppColors.GRAY)
                .width('100%')
                .lineHeight(1.6)
            }
            .width('90%')
            .padding(AppDimensions.PADDING_LARGE)
            .backgroundColor(AppColors.BACKGROUND)
            .borderRadius(AppDimensions.BORDER_RADIUS)

            Divider()
              .width('90%')
              .height(1)
              .color(AppColors.BORDER_GRAY)
          }
          .width('100%')
          .padding({ top: AppDimensions.PADDING_MEDIUM, bottom: AppDimensions.PADDING_MEDIUM })
          .alignItems(HorizontalAlign.Center)
        }
        .layoutWeight(1)

        if (this.isProcessing) {
          Row({ space: AppDimensions.MARGIN_SMALL }) {
            LoadingProgress()
              .width(30)
              .height(30)
              .color(AppColors.PRIMARY)

            Text(this.progressMessage)
              .fontSize(AppText.FONT_SIZE_BODY)
              .fontColor(AppColors.GRAY)
          }
          .width('100%')
          .height(60)
          .backgroundColor(AppColors.BACKGROUND)
          .justifyContent(FlexAlign.Center)
          .alignItems(VerticalAlign.Center)
        }
      }
      .width('100%')
      .height('100%')
      .backgroundColor(AppColors.BACKGROUND)

      // 导出对话框
      if (this.showExportDialog) {
        Stack() {
          Column()
            .width('100%')
            .height('100%')
            .backgroundColor('rgba(0, 0, 0, 0.5)')
            .onClick(() => {
              this.showExportDialog = false;
            })

          Column({ space: AppDimensions.MARGIN_MEDIUM }) {
            Text('导出选项')
              .fontSize(AppText.FONT_SIZE_TITLE)
              .fontWeight(FontWeight.Bold)
              .width('100%')
              .textAlign(TextAlign.Center)

            Column({ space: AppDimensions.MARGIN_SMALL }) {
              Text('导出格式')
                .fontSize(AppText.FONT_SIZE_SMALL)
                .fontColor(AppColors.GRAY)

              Row({ space: 10 }) {
                Button('JSON')
                  .type(this.exportFormat === 'json' ? ButtonType.Capsule : ButtonType.Normal)
                  .layoutWeight(1)
                  .height(40)
                  .fontSize(AppText.FONT_SIZE_BODY)
                  .backgroundColor(this.exportFormat === 'json' ? AppColors.PRIMARY : AppColors.WHITE)
                  .fontColor(this.exportFormat === 'json' ? AppColors.WHITE : AppColors.GRAY)
                  .border({ width: 1, color: AppColors.BORDER_GRAY })
                  .onClick(() => {
                    this.exportFormat = 'json';
                  })

                Button('CSV')
                  .type(this.exportFormat === 'csv' ? ButtonType.Capsule : ButtonType.Normal)
                  .layoutWeight(1)
                  .height(40)
                  .fontSize(AppText.FONT_SIZE_BODY)
                  .backgroundColor(this.exportFormat === 'csv' ? AppColors.PRIMARY : AppColors.WHITE)
                  .fontColor(this.exportFormat === 'csv' ? AppColors.WHITE : AppColors.GRAY)
                  .border({ width: 1, color: AppColors.BORDER_GRAY })
                  .onClick(() => {
                    this.exportFormat = 'csv';
                  })

                Button('Excel')
                  .type(this.exportFormat === 'excel' ? ButtonType.Capsule : ButtonType.Normal)
                  .layoutWeight(1)
                  .height(40)
                  .fontSize(AppText.FONT_SIZE_BODY)
                  .backgroundColor(this.exportFormat === 'excel' ? AppColors.PRIMARY : AppColors.WHITE)
                  .fontColor(this.exportFormat === 'excel' ? AppColors.WHITE : AppColors.GRAY)
                  .border({ width: 1, color: AppColors.BORDER_GRAY })
                  .onClick(() => {
                    this.exportFormat = 'excel';
                  })
              }
              .width('100%')
            }
            .width('100%')

            Row() {
              Checkbox({ name: 'statistics', group: 'statisticsGroup' })
                .width(24)
                .height(24)
                .select(this.includeStatistics)
                .onChange((value: boolean) => {
                  this.includeStatistics = value;
                })

              Text('包含统计数据摘要')
                .fontSize(AppText.FONT_SIZE_BODY)
                .fontColor(AppColors.GRAY)
                .margin({ left: 10 })
                .layoutWeight(1)
            }
            .width('100%')

            Row({ space: AppDimensions.MARGIN_MEDIUM }) {
              Button('取消')
                .type(ButtonType.Normal)
                .layoutWeight(1)
                .height(45)
                .fontSize(AppText.FONT_SIZE_BODY)
                .backgroundColor(AppColors.WHITE)
                .fontColor(AppColors.GRAY)
                .border({ width: 1, color: AppColors.BORDER_GRAY, radius: AppDimensions.BORDER_RADIUS_SMALL })
                .onClick(() => {
                  this.showExportDialog = false;
                })

              Button('导出')
                .type(ButtonType.Capsule)
                .layoutWeight(1)
                .height(45)
                .fontSize(AppText.FONT_SIZE_BODY)
                .backgroundColor(AppColors.PRIMARY)
                .enabled(!this.isProcessing)
                .onClick(() => {
                  this.onExport();
                })
            }
            .width('100%')
          }
          .width('85%')
          .height('auto')
          .backgroundColor(AppColors.WHITE)
          .borderRadius(AppDimensions.BORDER_RADIUS)
          .padding(AppDimensions.PADDING_LARGE)
        }
        .width('100%')
        .height('100%')
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
      }
    }
    .width('100%')
    .height('100%')
  }
}
