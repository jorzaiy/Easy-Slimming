# 鸿蒙运动健康同步功能 (PR #10)

## 功能概述

本功能实现了与鸿蒙运动健康应用的双向数据同步，允许用户在应用中记录的体重数据与鸿蒙生态进行互联，提供无缝的数据共享和同步体验。

## 核心功能模块

### 1. 数据模型 (Models)

#### HealthSyncRecord.ets
- **SyncDirection**: 同步方向枚举
  - `TO_HEALTH`: 向鸿蒙健康应用同步
  - `FROM_HEALTH`: 从鸿蒙健康应用导入
  - `BIDIRECTIONAL`: 双向同步

- **SyncStatus**: 同步状态枚举
  - `PENDING`: 待同步
  - `SYNCING`: 同步中
  - `SUCCESS`: 成功
  - `FAILED`: 失败
  - `CONFLICT`: 数据冲突
  - `CANCELLED`: 已取消

- **HealthSyncRecord**: 同步记录类
  - 跟踪每次同步的详细信息
  - 记录同步时间、状态、错误信息
  - 关联本地和鸿蒙健康应用中的记录

#### SyncSettings.ets
- **SyncMode**: 同步模式枚举
  - `MANUAL`: 手动同步
  - `AUTO`: 自动同步
  - `AUTO_BACKGROUND`: 后台自动同步

- **SyncSettings**: 同步配置类
  - 管理同步总开关
  - 配置同步模式和频率
  - 设置冲突解决策略
  - 配置重试策略和超时时间

#### HealthSyncConflict.ets
- **ConflictType**: 冲突类型枚举
  - `DUPLICATE`: 重复数据
  - `VERSION_MISMATCH`: 版本不匹配
  - `TIMESTAMP_CONFLICT`: 时间戳冲突
  - `DATA_INCONSISTENCY`: 数据不一致

- **ResolutionOption**: 冲突解决方案
  - `USE_LOCAL`: 使用本地数据
  - `USE_HEALTH`: 使用鸿蒙健康数据
  - `MERGE_AVERAGE`: 合并取平均值
  - `SKIP`: 跳过

- **HealthSyncConflict**: 冲突记录类
  - 记录本地数据和鸿蒙数据的冲突
  - 提供冲突解决方案

### 2. 数据访问层 (DAO)

#### HealthSyncRecordDao.ets
功能：管理同步记录的持久化存储
- `insert()`: 插入新的同步记录
- `update()`: 更新同步记录状态
- `queryAll()`: 查询所有同步记录
- `queryByWeightRecordId()`: 查询特定体重记录的同步历史
- `queryFailedRecords()`: 查询失败的同步记录
- `delete()`: 删除同步记录
- `clear()`: 清空所有同步记录

#### SyncSettingsDao.ets
功能：管理同步配置的持久化存储
- `save()`: 保存或更新设置
- `insert()`: 插入新的设置
- `update()`: 更新设置
- `queryDefault()`: 查询默认设置
- `queryAll()`: 查询所有设置
- `initializeDefaultSettings()`: 初始化默认设置

### 3. 业务逻辑层 (Service)

#### HealthSyncService.ets
核心同步服务，提供以下功能：

##### 初始化
```typescript
async initialize(): Promise<boolean>
```
初始化服务，加载同步设置。

##### 同步操作
```typescript
async syncToHealth(weightRecordIds?: number[]): Promise<SyncResult>
```
向鸿蒙健康应用同步体重数据。

```typescript
async syncFromHealth(): Promise<SyncResult>
```
从鸿蒙健康应用导入体重数据。

```typescript
async bidirectionalSync(): Promise<SyncResult>
```
执行双向同步。

##### 冲突处理
```typescript
async resolveConflict(conflictId: number, option: ResolutionOption): Promise<boolean>
```
解决数据冲突。

```typescript
getConflicts(): Map<number, HealthSyncConflict>
```
获取所有冲突。

##### 状态管理
```typescript
getSyncSettings(): SyncSettings | null
getSyncProgress(): SyncProgress
getIsSyncing(): boolean
```

### 4. 用户界面

#### HealthSync.ets (页面)
- 显示同步状态（已同步/未同步/同步中/失败）
- 显示最后同步时间
- 提供"同步到鸿蒙"按钮
- 显示同步进度条
- 显示同步历史记录列表

#### HealthSyncSettings.ets (页面)
- 启用/关闭同步功能
- 选择同步模式
- 配置同步频率
- 设置应用启动时是否同步
- 选择冲突解决策略
- 配置高级选项（重试次数、超时时间）

#### HealthSyncSettingsDialog.ets (组件)
- 设置对话框组件
- 弹窗式配置界面

### 5. 数据库架构

#### 健康同步记录表 (health_sync_record)
```sql
CREATE TABLE health_sync_record (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  weight_record_id INTEGER NOT NULL,
  sync_direction TEXT NOT NULL,
  status TEXT NOT NULL,
  start_time INTEGER NOT NULL,
  end_time INTEGER,
  error_message TEXT,
  health_app_record_id TEXT,
  data_hash TEXT,
  FOREIGN KEY (weight_record_id) REFERENCES weight_record(id)
)
```

#### 同步设置表 (sync_settings)
```sql
CREATE TABLE sync_settings (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  sync_enabled INTEGER NOT NULL,
  sync_mode TEXT NOT NULL,
  auto_sync_interval_minutes INTEGER NOT NULL,
  auto_sync_enabled INTEGER NOT NULL,
  last_sync_time INTEGER,
  sync_on_app_start INTEGER NOT NULL,
  conflict_resolution TEXT NOT NULL,
  enable_detailed_logs INTEGER NOT NULL,
  max_sync_retries INTEGER NOT NULL,
  request_timeout INTEGER NOT NULL
)
```

#### 冲突记录表 (health_sync_conflict)
```sql
CREATE TABLE health_sync_conflict (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  conflict_type TEXT NOT NULL,
  local_record_id INTEGER NOT NULL,
  health_record_data TEXT NOT NULL,
  created_time INTEGER NOT NULL,
  resolved_time INTEGER,
  resolution_option TEXT,
  description TEXT NOT NULL,
  FOREIGN KEY (local_record_id) REFERENCES weight_record(id)
)
```

## 集成指南

### 1. 权限配置
在 `AppScope/app.json5` 中已添加以下权限：
```json
"permissions": [
  "ohos.permission.HEALTH_DATA_READ",
  "ohos.permission.HEALTH_DATA_WRITE"
]
```

### 2. 页面注册
在 `entry/src/main/resources/base/profile/main_pages.json` 中已注册：
- `pages/HealthSync`: 同步主页面
- `pages/HealthSyncSettings`: 设置页面

### 3. 服务初始化
在 `EntryAbility.ets` 中自动初始化：
- HealthSyncRecordDao
- SyncSettingsDao
- HealthSyncService

### 4. 导航集成
在 `Index.ets` 页面添加了"鸿蒙同步"按钮，导航到 `HealthSync` 页面。

## 使用场景

### 场景1: 首次启用同步
1. 用户点击"鸿蒙同步"按钮
2. 进入HealthSync页面，点击"同步设置"
3. 启用同步功能，选择同步模式
4. 点击"同步到鸿蒙"按钮进行首次同步

### 场景2: 自动同步
1. 用户在设置中启用"自动同步"模式
2. 应用定期自动同步数据
3. 用户在HealthSync页面可看到同步历史

### 场景3: 处理冲突
1. 检测到数据冲突时，显示冲突提示
2. 用户选择冲突解决方案
3. 系统根据选择更新数据

## 错误处理

### 网络错误
- 自动重试（可配置次数）
- 显示错误信息给用户
- 记录详细错误日志

### 权限拒绝
- 检测权限状态
- 提示用户授予权限
- 降级处理（不执行同步）

### 数据格式错误
- 验证数据完整性
- 转换数据格式
- 记录转换失败的记录

## 性能优化

### 1. 后台同步
- 不阻塞UI线程
- 使用异步操作
- 提供进度反馈

### 2. 数据库查询
- 使用事务保证数据一致性
- 按需查询数据
- 缓存频繁访问的设置

### 3. 哈希冲突检测
- 快速数据对比
- 智能重复检测
- 支持增量同步

## 测试用例

### 单元测试
- HealthSyncService 初始化测试
- 同步状态转换测试
- 冲突检测和解决测试
- 数据验证测试

### 集成测试
- 与WeightRecordDao的集成
- 与TargetWeightService的集成
- 数据库事务测试
- 权限请求和处理测试

### 功能测试
- 首次同步功能
- 增量同步功能
- 自动同步功能
- 冲突处理功能
- 错误恢复功能

## 已知限制

1. **API模拟**: 当前实现使用模拟的鸿蒙健康API
   - 需要与真实HarmonyOS Health API进行集成
   - 实际的数据同步需要调用真实的系统API

2. **权限处理**: 权限请求在运行时处理
   - 需要在页面中添加权限检查和请求逻辑

3. **后台同步**: 目前不支持真正的后台同步
   - 需要使用WorkScheduler API实现后台任务

## 未来改进

1. **实时同步**: 使用WebSocket实现实时数据同步
2. **数据压缩**: 对大数据量进行压缩传输
3. **离线支持**: 离线模式下缓存同步操作，网络恢复后自动同步
4. **同步统计**: 提供同步统计和分析功能
5. **用户偏好**: 记住用户的冲突解决偏好

## 代码规范

- 使用TypeScript进行类型检查
- 遵循HarmonyOS ArkTS编码规范
- 错误信息使用中文
- 日志输出使用hilog
- 数据库操作使用事务确保原子性

## 许可证

该功能作为应用的一部分，遵循项目的许可证要求。
