# 目标体重管理功能 (PR #8)

## 功能概述

本功能为应用提供了完整的目标体重管理系统，支持用户设定、跟踪和管理体重目标。

## 核心功能

### 1. 目标体重数据管理

#### 数据存储（TargetWeightService）
- **位置**: `/entry/src/main/ets/data/TargetWeightService.ets`
- **功能**:
  - 在本地数据库中存储目标体重记录
  - 支持目标体重的修改历史记录
  - 自动持久化到 SQLite 数据库
  - 提供缓存机制

#### 数据模型
```typescript
interface TargetWeightRecord {
  id: number;                    // 记录ID
  targetWeight: number;          // 目标体重值（kg）
  setDate: number;               // 设置日期（时间戳）
  targetDate?: number;           // 目标完成日期（可选）
  notes?: string;                // 备注信息（可选）
}
```

#### 数据库表
```sql
CREATE TABLE target_weight (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  targetWeight REAL NOT NULL,
  setDate INTEGER NOT NULL,
  targetDate INTEGER,
  notes TEXT
)
```

### 2. 目标设置界面

#### 目标设置对话框（TargetWeightSettingDialog）
- **位置**: `/entry/src/main/ets/common/TargetWeightSettingDialog.ets`
- **功能**:
  - 快速选择预设目标值（60, 65, 70, 75, 80 kg）
  - 手动输入目标体重
  - 设置目标完成日期（可选）
  - 添加备注信息
  - 实时验证输入数据
  - 支持编辑现有目标

#### 用户交互
- 浮动对话框形式，半透明遮罩背景
- 预设快速按钮，点击即可选择
- 数字输入验证（0-200 kg）
- 日期选择器用于目标日期
- 保存和取消按钮

### 3. 全页面目标管理

#### 目标体重管理页面（TargetWeightManagement）
- **位置**: `/entry/src/main/ets/pages/TargetWeightManagement.ets`
- **功能**:
  - 查看当前目标体重
  - 查看目标设置历史记录
  - 编辑当前目标
  - 删除历史目标记录
  - 设置新目标

#### 页面布局
- 顶部栏：标题 + 返回按钮
- 当前目标卡片：显示当前目标及编辑按钮
- 历史目标列表：显示之前设置的目标
- 底部按钮：设置新目标

### 4. 与其他功能的集成

#### 主页集成（Index.ets）
- 显示当前目标体重卡片
- 显示与目标的差值（颜色编码：超重为橙色，未达标为绿色）
- 目标设置快捷按钮
- 快速导航到目标管理页面

#### 历史记录集成（History.ets）
- 在每条体重记录旁显示与目标的差值
- 差值为正显示为橙色（超重），为负显示为绿色（未达标）
- 支持快速比较当前体重与目标

#### 体重趋势图表集成（WeightChart.ets）
- 图表中显示目标线（红色虚线）
- 点击图例可编辑目标体重
- 选中数据点时显示与目标的差距
- 支持实时更新目标线显示

#### 统计仪表板集成（StatisticsDashboard.ets）
- 显示目标与当前体重的对比
- 计算进度百分比
- 展示目标达成情况

### 5. 全局管理器

#### 目标体重管理器（TargetWeightManager）
- **位置**: `/entry/src/main/ets/common/TargetWeightManager.ets`
- **功能**:
  - 应用启动时初始化目标体重
  - 同步内存和数据库中的目标值
  - 提供观察者模式供页面订阅更新
  - 自动更新 WeightRecord 中的静态目标体重值

### 6. 数据流

```
用户在对话框设置目标
        ↓
TargetWeightService 存储到数据库
        ↓
TargetWeightManager 更新内存状态
        ↓
WeightRecord.setTargetWeight() 同步静态值
        ↓
所有订阅页面收到更新通知
        ↓
各页面重新渲染并显示新的目标值
```

## 路由配置

目标管理页面已添加到路由配置中：
- 文件：`/entry/src/main/resources/base/profile/main_pages.json`
- 路由：`pages/TargetWeightManagement`

## 使用示例

### 在主页设置目标
```typescript
// 用户点击"设置目标体重"按钮
this.showTargetDialog = true;

// TargetWeightSettingDialog 显示并处理用户输入
// 用户输入目标体重并点击保存
async onTargetChange(target: TargetWeightRecord) {
  this.currentTarget = target;
  WeightRecord.setTargetWeight(target.targetWeight);
}
```

### 在历史记录中查看差值
```typescript
// 在 RecordItem 中显示差值
if (this.currentTarget) {
  const difference = record.weight - this.currentTarget.targetWeight;
  // 显示差值，正数为红色，负数为绿色
}
```

### 在图表中编辑目标
```typescript
// 点击图例中的目标线
.onClick(() => this.showTargetWeightDialog())

// 对话框保存后自动更新图表
onTargetChange(target: TargetWeightRecord) {
  this.targetWeight = target.targetWeight;
  this.loadChartData(); // 重新加载图表
}
```

## 验收标准

✅ **目标体重能正确保存和读取**
- 数据存储到本地 SQLite 数据库
- 应用重启后仍能正确读取

✅ **与其他页面集成正常工作**
- 主页显示目标和差值
- 历史记录显示每条记录的差值
- 图表显示目标线
- 统计仪表板显示目标对比

✅ **目标变化在整个应用中实时更新**
- 通过观察者模式通知所有订阅页面
- 多个页面同时打开时保持同步

✅ **UI 美观易用**
- 对话框采用半透明遮罩设计
- 预设快速选择按钮提升用户体验
- 颜色编码直观展示进度情况

✅ **代码遵循项目规范**
- 遵循现有命名约定
- 使用统一的常量定义
- 错误处理完善
- 日志记录充分

## 文件清单

新增文件：
1. `/entry/src/main/ets/data/TargetWeightService.ets` - 目标体重服务
2. `/entry/src/main/ets/common/TargetWeightSettingDialog.ets` - 设置对话框
3. `/entry/src/main/ets/common/TargetWeightManager.ets` - 全局管理器
4. `/entry/src/main/ets/pages/TargetWeightManagement.ets` - 管理页面

修改文件：
1. `/entry/src/main/ets/pages/Index.ets` - 集成目标显示和设置
2. `/entry/src/main/ets/pages/History.ets` - 显示差值
3. `/entry/src/main/ets/pages/WeightChart.ets` - 支持目标编辑
4. `/entry/src/main/resources/base/profile/main_pages.json` - 路由配置

## 技术细节

### 数据库操作
- 使用关系数据库 API (relationalStore)
- 支持事务处理
- 自动关闭 ResultSet 防止内存泄漏

### 状态管理
- React-like 状态管理（@State 装饰器）
- 观察者模式实现跨页面通信
- 缓存机制减少数据库查询

### UI 组件
- Stack 用于对话框遮罩效果
- Column/Row 实现灵活布局
- ForEach 渲染列表
- 条件渲染显示/隐藏元素

### 类型安全
- 完整的 TypeScript 类型定义
- 接口定义明确数据结构
- 类型检查在编译时进行

## 扩展建议

1. **通知功能**：当体重接近目标时发送通知
2. **多阶段目标**：支持多个阶段性目标
3. **目标历史分析**：统计目标达成率
4. **导出导入**：支持备份和恢复目标数据
5. **提醒功能**：定期提醒更新体重
