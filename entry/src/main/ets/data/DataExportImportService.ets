/**
 * 数据导出导入服务
 * 支持CSV、Excel、JSON格式的数据导出和导入
 */
import relationalStore from '@ohos.data.relationalStore';
import { WeightRecord, ValidationResult } from '../model/WeightRecord';
import { TargetWeightRecord } from './TargetWeightService';
import { WeightRecordDao } from './WeightRecordDao';
import hilog from '@ohos.hilog';
import { LogConstants } from '../common/Constants';
import {
  ExportOptions,
  ExportResult,
  ImportOptions,
  ImportResult,
  ExportDataContent,
  ExportRecordData,
  ExportTargetData,
  ExportStatisticsData
} from '../model/ExportData';

const DOMAIN = LogConstants.DOMAIN;
const TAG = LogConstants.TAG_PREFIX + 'DataExportImportService';

export class DataExportImportService {
  private dao: WeightRecordDao;

  constructor(dao: WeightRecordDao) {
    this.dao = dao;
  }

  /**
   * 导出数据为JSON格式
   */
  async exportToJSON(
    options: ExportOptions,
    targets?: TargetWeightRecord[]
  ): Promise<string> {
    try {
      let records = await this.dao.queryAll();

      // 过滤日期范围
      if (options.startDate || options.endDate) {
        records = records.filter(r => {
          if (options.startDate && r.date < options.startDate) {
            return false;
          }
          if (options.endDate && r.date > options.endDate) {
            return false;
          }
          return true;
        });
      }
      const exportRecords: ExportRecordData[] = records.map(r => ({
        id: r.id,
        weight: r.weight,
        date: r.date,
        formattedDate: r.getFormattedDate(),
        notes: r.notes
      } as ExportRecordData));
      let exportStatistics: ExportStatisticsData | undefined;
      if (options.includeStatistics && records.length > 0) {
        const weights: number[] = records.map(r => r.weight);
        exportStatistics = {
          totalRecords: records.length,
          latestWeight: records[0]?.weight,
          averageWeight: weights.reduce((a, b) => a + b, 0) / weights.length,
          minWeight: Math.min(...weights),
          maxWeight: Math.max(...weights),
          currentTarget: targets && targets.length > 0 ? targets[0].targetWeight : undefined
        } as ExportStatisticsData;
      }
      const exportTargets: ExportTargetData[] | undefined = targets && targets.length > 0
        ? targets.map(t => ({
          id: t.id,
          targetWeight: t.targetWeight,
          setDate: t.setDate,
          formattedDate: new Date(t.setDate).toISOString(),
          targetDate: t.targetDate,
          notes: t.notes
        } as ExportTargetData))
        : undefined;

      const content: ExportDataContent = {
        exportDate: new Date().toISOString(),
        version: '1.0',
        records: exportRecords,
        targets: exportTargets,
        statistics: exportStatistics
      };

      hilog.info(DOMAIN, TAG, `Exported ${records.length} records to JSON`);
      return JSON.stringify(content, null, 2);
    } catch (e) {
      hilog.error(DOMAIN, TAG, `Failed to export to JSON, cause: ${e}`);
      throw new Error(`Failed to export to JSON: ${e}`);
    }
  }

  /**
   * 导出数据为CSV格式
   */
  async exportToCSV(
    options: ExportOptions,
    targets?: TargetWeightRecord[]
  ): Promise<string> {
    try {
      let records = await this.dao.queryAll();

      // 过滤日期范围
      if (options.startDate || options.endDate) {
        records = records.filter(r => {
          if (options.startDate && r.date < options.startDate) {
            return false;
          }
          if (options.endDate && r.date > options.endDate) {
            return false;
          }
          return true;
        });
      }

      let csv: string = '日期,体重(kg),备注\n';

      for (const record of records) {
        const date: string = record.getFormattedDate();
        const weight: string = record.weight.toFixed(1);
        const notes: string = (record.notes || '').replace(/,/g, '，').replace(/\n/g, ' ');
        csv += `${date},${weight},"${notes}"\n`;
      }

      if (options.includeStatistics) {
        csv += '\n统计数据\n';
        csv += `总记录数,${records.length}\n`;
        if (records.length > 0) {
          const weights: number[] = records.map(r => r.weight);
          csv += `最新体重,${records[0].weight.toFixed(1)}\n`;
          csv += `平均体重,${(weights.reduce((a, b) => a + b, 0) / weights.length).toFixed(1)}\n`;
          csv += `最小体重,${Math.min(...weights).toFixed(1)}\n`;
          csv += `最大体重,${Math.max(...weights).toFixed(1)}\n`;
        }
        if (targets && targets.length > 0) {
          csv += `当前目标,${targets[0].targetWeight.toFixed(1)}\n`;
        }
      }

      hilog.info(DOMAIN, TAG, `Exported ${records.length} records to CSV`);
      return csv;
    } catch (e) {
      hilog.error(DOMAIN, TAG, `Failed to export to CSV, cause: ${e}`);
      throw new Error(`Failed to export to CSV: ${e}`);
    }
  }

  /**
   * 导出数据为Excel格式（实际为CSV，Excel兼容）
   */
  async exportToExcel(
    options: ExportOptions,
    targets?: TargetWeightRecord[]
  ): Promise<string> {
    return this.exportToCSV(options, targets);
  }

  /**
   * 从JSON导入数据
   */
  async importFromJSON(
    jsonContent: string,
    options: ImportOptions
  ): Promise<ImportResult> {
    const result: ImportResult = {
      success: false,
      importedCount: 0,
      skippedCount: 0,
      failedCount: 0,
      errors: [],
      timestamp: Date.now()
    };
    const rdbStore = this.dao.getRdbStore();

    try {
      const data: ExportDataContent = JSON.parse(jsonContent);

      if (!data.records || !Array.isArray(data.records)) {
        result.errors.push('Invalid JSON format: missing records array');
        return result;
      }

      await rdbStore.executeSql('BEGIN TRANSACTION');

      for (const recordData of data.records) {
        try {
          const record: WeightRecord = new WeightRecord(
            recordData.weight,
            recordData.date,
            undefined,
            recordData.notes
          );

          const validation: ValidationResult = record.validate();
          if (!validation.isValid) {
            result.skippedCount++;
            result.errors.push(
              `Record ${recordData.id}: ${validation.errors.join(', ')}`
            );
            continue;
          }

          // 检查是否存在
          const existing: WeightRecord | null = await this.dao.queryById(recordData.id);
          if (existing) {
            if (options.conflictResolution === 'override') {
              await this.dao.update(record);
              result.importedCount++;
            } else if (options.conflictResolution === 'skip') {
              result.skippedCount++;
            } else {
              // merge
              result.skippedCount++;
            }
          } else {
            const insertId: number = await this.dao.insert(record);
            if (insertId > 0) {
              result.importedCount++;
            } else {
              result.failedCount++;
              result.errors.push(`Failed to import record ${recordData.id}`);
            }
          }
        } catch (e) {
          result.failedCount++;
          result.errors.push(`Error importing record: ${e}`);
        }
      }

      await rdbStore.executeSql('COMMIT');
      result.success = result.failedCount === 0;

      hilog.info(
        DOMAIN,
        TAG,
        `Imported ${result.importedCount} records, skipped ${result.skippedCount}, failed ${result.failedCount}`
      );
    } catch (e) {
      try {
        await rdbStore.executeSql('ROLLBACK');
      } catch (rollbackError) {
        hilog.error(DOMAIN, TAG, `Failed to rollback transaction: ${rollbackError}`);
      }

      result.errors.push(`Import failed: ${e}`);
      hilog.error(DOMAIN, TAG, `Failed to import from JSON, cause: ${e}`);
    }

    return result;
  }

  /**
   * 从CSV导入数据
   */
  async importFromCSV(
    csvContent: string,
    options: ImportOptions
  ): Promise<ImportResult> {
    const result: ImportResult = {
      success: false,
      importedCount: 0,
      skippedCount: 0,
      failedCount: 0,
      errors: [],
      timestamp: Date.now()
    };
    const rdbStore = this.dao.getRdbStore();

    try {
      const lines: string[] = csvContent.split('\n').filter(line => line.trim());
      const headerLine: string = lines[0];

      // 检查标题行
      if (!headerLine.includes('日期') || !headerLine.includes('体重')) {
        result.errors.push('Invalid CSV format: missing required columns');
        return result;
      }

      const headers: string[] = headerLine.split(',');
      const dateIndex: number = headers.findIndex(h => h.includes('日期'));
      const weightIndex: number = headers.findIndex(h => h.includes('体重'));

      if (dateIndex === -1 || weightIndex === -1) {
        result.errors.push('Invalid CSV format: missing date or weight column');
        return result;
      }

      await rdbStore.executeSql('BEGIN TRANSACTION');

      for (let i = 1; i < lines.length; i++) {
        const line: string = lines[i].trim();
        if (!line || line.startsWith('统计') || line.startsWith('总')) {
          continue; // Skip statistics and empty lines
        }

        try {
          const values: string[] = this.parseCSVLine(line);

          if (values.length <= Math.max(dateIndex, weightIndex)) {
            result.skippedCount++;
            continue;
          }

          const dateStr: string = values[dateIndex];
          const weightStr: string = values[weightIndex];

          const weight: number = parseFloat(weightStr);
          if (isNaN(weight)) {
            result.skippedCount++;
            result.errors.push(`Line ${i + 1}: Invalid weight value`);
            continue;
          }

          // 尝试解析日期
          let date: number;
          try {
            const parsedDate: Date = new Date(dateStr);
            if (isNaN(parsedDate.getTime())) {
              result.skippedCount++;
              result.errors.push(`Line ${i + 1}: Invalid date format`);
              continue;
            }
            date = parsedDate.getTime();
          } catch (e) {
            result.skippedCount++;
            result.errors.push(`Line ${i + 1}: Failed to parse date`);
            continue;
          }

          const noteIndex: number = headers.findIndex(h => h.includes('备注'));
          const notes: string = noteIndex >= 0 ? (values[noteIndex] || '') : '';

          try {
            const record: WeightRecord = new WeightRecord(weight, date, undefined, notes);
            const validation: ValidationResult = record.validate();

            if (!validation.isValid) {
              result.skippedCount++;
              result.errors.push(`Line ${i + 1}: ${validation.errors.join(', ')}`);
              continue;
            }

            const insertId: number = await this.dao.insert(record);
            if (insertId > 0) {
              result.importedCount++;
            } else {
              result.failedCount++;
              result.errors.push(`Line ${i + 1}: Failed to insert record`);
            }
          } catch (e) {
            result.failedCount++;
            result.errors.push(`Line ${i + 1}: ${e}`);
          }
        } catch (e) {
          result.failedCount++;
          result.errors.push(`Line ${i + 1}: Error parsing CSV line`);
        }
      }

      await rdbStore.executeSql('COMMIT');
      result.success = result.failedCount === 0;

      hilog.info(
        DOMAIN,
        TAG,
        `Imported ${result.importedCount} records from CSV, skipped ${result.skippedCount}, failed ${result.failedCount}`
      );
    } catch (e) {
      try {
        await rdbStore.executeSql('ROLLBACK');
      } catch (rollbackError) {
        hilog.error(DOMAIN, TAG, `Failed to rollback transaction: ${rollbackError}`);
      }

      result.errors.push(`Import failed: ${e}`);
      hilog.error(DOMAIN, TAG, `Failed to import from CSV, cause: ${e}`);
    }

    return result;
  }

  /**
   * 从Excel导入数据（实际为CSV）
   */
  async importFromExcel(
    csvContent: string,
    options: ImportOptions
  ): Promise<ImportResult> {
    return this.importFromCSV(csvContent, options);
  }

  /**
   * 验证导入数据的有效性
   */
  async validateImportData(jsonContent: string): Promise<ValidationResult> {
    const errors: string[] = [];

    try {
      const data: ExportDataContent = JSON.parse(jsonContent);

      if (!data.records || !Array.isArray(data.records)) {
        errors.push('Invalid format: missing records array');
      } else if (data.records.length === 0) {
        errors.push('No records to import');
      } else {
        for (let i = 0; i < Math.min(5, data.records.length); i++) {
          const recordData: ExportRecordData = data.records[i];

          if (typeof recordData.weight !== 'number') {
            errors.push(`Record ${i}: Invalid weight type`);
          } else if (recordData.weight < 0 || recordData.weight > 200) {
            errors.push(`Record ${i}: Weight out of valid range (0-200 kg)`);
          }

          if (typeof recordData.date !== 'number') {
            errors.push(`Record ${i}: Invalid date type`);
          } else if (recordData.date <= 0) {
            errors.push(`Record ${i}: Invalid date value`);
          }
        }
      }
    } catch (e) {
      errors.push(`Invalid JSON format: ${e}`);
    }

    return {
      isValid: errors.length === 0,
      errors
    };
  }

  /**
   * 解析CSV行
   */
  private parseCSVLine(line: string): string[] {
    const result: string[] = [];
    let current: string = '';
    let inQuotes: boolean = false;

    for (let i = 0; i < line.length; i++) {
      const char: string = line[i];

      if (char === '"') {
        if (inQuotes && line[i + 1] === '"') {
          current += '"';
          i++;
        } else {
          inQuotes = !inQuotes;
        }
      } else if (char === ',' && !inQuotes) {
        result.push(current.trim());
        current = '';
      } else {
        current += char;
      }
    }

    result.push(current.trim());
    return result;
  }

  /**
   * 获取数据库的RdbStore
   */
  getRdbStore(): relationalStore.RdbStore {
    return this.dao.getRdbStore();
  }
}

let dataExportImportService: DataExportImportService | null = null;

export async function getDataExportImportService(dao: WeightRecordDao): Promise<DataExportImportService> {
  if (!dataExportImportService) {
    dataExportImportService = new DataExportImportService(dao);
  }
  return dataExportImportService;
}
