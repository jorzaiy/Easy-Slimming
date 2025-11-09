# 🎯 轻松减重 (Easy-Slimming)

> 💪 ArkTS + HarmonyOS 的专业体重管理应用

[![HarmonyOS](https://img.shields.io/badge/HarmonyOS-6.0.0+-blueviolet.svg)](https://www.harmonyos.com)
[![ArkTS](https://img.shields.io/badge/ArkTS-Strict%20Mode-green.svg)](https://developer.huawei.com/consumer/cn/devservice/doc/harmonyos-guides)
[![License](https://img.shields.io/badge/License-Apache--2.0-blue.svg)](LICENSE)

## 📋 项目简介

**轻松减重** 是一款基于 HarmonyOS Stage Model 和 ArkTS 开发的专业体重管理应用。它提供了完整的体重记录、数据分析、趋势可视化和健康生态同步功能，帮助用户科学地管理体重和健康状态。

### 🎯 项目目标

- ✨ 提供直观的体重记录和管理界面
- 📊 实现数据可视化分析和趋势预测
- 🎯 支持个性化目标体重设置和跟踪
- 📈 提供全面的统计分析仪表板
- 🔗 与 HarmonyOS 运动健康生态深度集成
- 🏗️ 展示 ArkTS 严格模式的规范实践

---

## 🌟 主要功能

### 📊 体重记录与管理
- ✅ 快速便捷的体重录入表单
- ✅ 体重数据的增删改查操作
- ✅ 历史记录浏览和详细查看
- ✅ 按日期快速搜索和筛选

### 📈 体重趋势图表
- ✅ 自定义绘制的交互式图表
- ✅ 多时间范围查看（周/月/3个月）
- ✅ 实时的目标线可视化
- ✅ 触屏交互查看具体数据
- ✅ 智能自动缩放和坐标转换

### 🎯 目标体重管理
- ✅ 灵活的目标体重设置
- ✅ 目标历史记录管理
- ✅ 预设快捷值（60/65/70/75/80kg）
- ✅ 目标截止日期跟踪
- ✅ 实时进度百分比显示

### 📋 备注功能增强
- ✅ 多类型备注支持（饮食、运动、生理期）
- ✅ 与体重记录关联
- ✅ 灵活的备注管理

### 📊 统计仪表板
- ✅ 当前体重与目标对比
- ✅ 平均体重计算
- ✅ BMI 计算与健康分析
- ✅ 体重增减趋势分析
- ✅ 个性化身高设置
- ✅ 自定义时间范围筛选（全部/周/月/7天/30天）

### 💾 数据导入导出
- ✅ 完整的数据备份功能
- ✅ 支持多种数据格式
- ✅ 灵活的数据恢复机制

### 🔗 鸿蒙运动健康同步
- ✅ 与 HarmonyOS 运动健康应用双向同步
- ✅ 多种同步模式（手动、自动、后台）
- ✅ 智能冲突检测和解决
- ✅ 同步历史和状态追踪
- ✅ 灵活的冲突解决策略

---

## 🛠️ 技术栈

### 前端技术
| 技术 | 版本 | 说明 |
|------|------|------|
| **ArkTS** | Strict Mode | 类型安全的 TypeScript 超集 |
| **HarmonyOS** | 6.0.0 (API 20) | Stage Model 应用框架 |
| **ArkUI** | 最新 | 声明式 UI 框架 |
| **构建系统** | Hvigor | HarmonyOS 专用构建工具 |

### 后端技术
| 技术 | 用途 |
|------|------|
| **SQLite** | 关系型数据库持久化 |
| **RDB Store** | HarmonyOS 数据库接口 |
| **DAO 模式** | 数据访问抽象层 |
| **事务管理** | ACID 事务支持 |

### 开发工具
- 📱 **IDE**: DevEco Studio（推荐）
- 🔨 **构建**: Hvigor
- 🧪 **测试**: Hypium（HarmonyOS 测试框架）
- 📦 **版本管理**: Git

---

## 📂 项目结构

```
entry/src/main/ets/
├── entryability/           # 应用入口和生命周期管理
│   └── EntryAbility.ets    # 主能力实现，初始化所有服务
│
├── pages/                   # UI 页面层
│   ├── Index.ets           # 首页面板
│   ├── History.ets         # 历史记录页面
│   ├── WeightEntryForm.ets # 体重录入表单
│   ├── WeightEditForm.ets  # 体重编辑表单
│   ├── WeightChart.ets     # 趋势图表页面
│   ├── StatisticsDashboard.ets # 统计仪表板
│   ├── TargetWeightManagement.ets # 目标管理页面
│   ├── HealthSync.ets      # 健康同步页面
│   ├── HealthSyncSettings.ets # 同步设置页面
│   ├── DataManagement.ets  # 数据导入导出
│   └── RecordDetail.ets    # 记录详情

├── data/                    # 数据访问层 (DAO)
│   ├── RdbHelper.ets       # 数据库统一管理
│   ├── WeightRecordDao.ets # 体重记录 DAO
│   ├── TargetWeightService.ets # 目标体重服务
│   ├── StatisticsService.ets # 统计分析服务
│   ├── HealthSyncService.ets # 健康同步服务
│   ├── HealthSyncRecordDao.ets # 同步记录 DAO
│   ├── SyncSettingsDao.ets # 同步设置 DAO
│   └── (其他 DAO 实现)

├── model/                   # 数据模型层
│   ├── WeightRecord.ets    # 体重记录模型
│   ├── TargetWeightRecord.ets # 目标体重模型
│   ├── WeightStatistics.ets # 统计数据模型
│   ├── HealthSyncRecord.ets # 同步记录模型
│   ├── SyncSettings.ets    # 同步设置模型
│   ├── HealthSyncConflict.ets # 冲突处理模型
│   └── (其他数据模型)

├── components/             # 可复用 UI 组件
│   ├── WeightChart.ets    # 图表组件
│   ├── TimeRangeSelector.ets # 时间范围选择器
│   ├── HealthSyncSettingsDialog.ets # 同步设置对话框
│   ├── HeightSettingDialog.ets # 身高设置对话框
│   └── (其他组件)

├── common/                  # 公共工具和常量
│   ├── Constants.ets       # 应用常量
│   ├── Global.ets          # 全局状态管理
│   ├── TargetWeightSettingDialog.ets # 目标体重设置对话框
│   └── (其他工具类)

└── entrybackupability/     # 数据备份扩展能力
    └── EntryBackupAbility.ets # 备份实现

AppScope/
├── app.json5               # 应用级配置和权限
└── resources/              # 应用资源

配置文件/
├── module.json5            # 模块配置
├── main_pages.json         # 页面路由配置
├── build-profile.json5     # 构建配置
└── hvigorfile.ts           # Hvigor 构建脚本
```

---

## 🚀 快速开始

### 首次运行说明

1. **应用启动**
   - 应用首次启动会自动初始化数据库
   - 所有表（weight_records, target_weight, health_sync_record 等）会自动创建

2. **主界面（Index 页面）**
   - 显示最新体重记录
   - 显示当前目标体重
   - 提供快速操作按钮：
     - 📝 新增记录
     - 📋 查看历史
     - 📈 趋势图表
     - 📊 统计仪表板
     - 🎯 目标管理
     - 🔗 鸿蒙同步

3. **权限授予**
   - 首次使用健康同步功能时会请求权限
   - 需要授予 `HEALTH_DATA_READ` 和 `HEALTH_DATA_WRITE` 权限

---

## 📖 功能使用说明

### 体重记录

#### 新增体重记录
1. 在首页点击"新增记录"按钮
2. 输入当前体重（单位：kg）
3. 可选：添加备注（饮食、运动、生理期等）
4. 点击"保存"完成记录

#### 查看历史记录
1. 在首页点击"历史记录"按钮
2. 所有体重记录按时间倒序显示
3. 点击记录可查看详情或编辑
4. 向左滑动可删除记录

#### 编辑记录
1. 在历史记录中选择要编辑的记录
2. 修改体重值或备注
3. 点击"更新"保存更改

### 趋势图表

#### 查看趋势
1. 在首页点击"趋势图表"按钮
2. 自动显示过去一周的体重趋势
3. 蓝线表示体重数据，红色虚线表示目标体重

#### 时间范围选择
- 支持查看：**周**（7天）、**月**（30天）、**3个月**（90天）
- 在图表上方选择时间范围

#### 交互操作
- 🖱️ 触摸数据点查看具体信息（日期、体重、偏差）
- 📌 长按图表图例编辑目标体重

### 目标体重管理

#### 设置目标体重
1. 在首页点击目标体重区域
2. 选择预设值或自定义输入（60-200kg）
3. 可选：设置目标截止日期
4. 添加备注说明目标
5. 点击"确定"保存

#### 查看目标历史
1. 在首页点击"目标管理"按钮
2. 查看所有曾设置过的目标
3. 可以删除历史记录

### 统计仪表板

#### 查看统计数据
1. 在首页点击"统计仪表板"按钮
2. 显示以下指标：
   - **当前体重**: 最新记录的体重
   - **目标体重**: 当前设定的目标
   - **平均体重**: 选定时间范围内的平均值
   - **BMI**: 身体质量指数（需设置身高）
   - **增减趋势**: 对比上一阶段的变化

#### 个性化设置
1. 点击仪表板上的"设置身高"按钮
2. 输入身高（单位：cm）
3. BMI 会自动更新

#### 时间范围筛选
- 支持筛选数据范围：
  - 全部时间
  - 过去一周
  - 过去一月
  - 过去 7 天
  - 过去 30 天

### 数据导入导出

#### 导出数据
1. 点击首页"数据管理"按钮
2. 选择"导出数据"
3. 选择导出格式和时间范围
4. 文件将保存到设备存储

#### 导入数据
1. 点击"数据管理"按钮
2. 选择"导入数据"
3. 选择要导入的文件
4. 确认合并或覆盖操作

### 鸿蒙运动健康同步

#### 快速同步
1. 在首页点击"鸿蒙同步"按钮
2. 点击"立即同步"开始同步过程
3. 查看实时同步进度
4. 完成后显示同步结果

#### 同步设置
1. 进入"鸿蒙同步"页面
2. 点击"设置"按钮
3. 配置选项：
   - **同步模式**: 手动/自动/后台
   - **同步频率**: 每日/每周等
   - **冲突解决**: 保留本地/保留健康/合并/跳过
   - **高级选项**: 重试次数、超时设置等
4. 保存设置

#### 查看同步历史
1. 在同步页面向下滚动
2. 查看过去的同步记录
3. 点击记录查看详细信息和错误日志

---

## 📝 贡献指南

### 如何参与开发

1. **Fork 项目**
   ```bash
   git clone https://github.com/your-username/easy-slimming.git
   ```

2. **创建功能分支**
   ```bash
   git checkout -b feature/your-feature-name
   ```

3. **提交更改**
   ```bash
   git add .
   git commit -m "feat: description of your changes"
   ```

4. **推送到 Fork**
   ```bash
   git push origin feature/your-feature-name
   ```

5. **提交 Pull Request**
   - 在 GitHub 上创建 PR
   - 使用清晰的标题和描述
   - 参考相关的 Issue

### 代码规范

#### ArkTS 编码规范
- ✅ 使用 **ArkTS 严格模式** (Strict Mode)
- ✅ 所有类型都必须显式定义，**禁止使用 `any`**
- ✅ 使用 PascalCase 命名类和接口
- ✅ 使用 camelCase 命名变量和函数
- ✅ 使用 UPPER_SNAKE_CASE 命名常量

#### 文件组织
```
entry/src/main/ets/
├── model/          # 纯数据模型，不涉及逻辑
├── data/           # 数据访问层，DAO 和 Service
├── pages/          # 完整的页面，使用 @Entry @Component
├── components/     # 可复用组件，使用 @Component
└── common/         # 常量、工具类、全局函数
```

### 代码审查标准

我们会检查以下方面：

- ✅ **代码质量**: 类型安全、无 `any`、规范命名
- ✅ **功能完整性**: 实现完整、边界情况处理
- ✅ **性能**: 无明显性能问题、合理使用缓存
- ✅ **测试覆盖**: 关键逻辑有测试用例
- ✅ **文档**: 复杂逻辑有注释、公共 API 有文档
- ✅ **错误处理**: 异常情况正确处理
- ✅ **架构设计**: 符合分层架构、不破坏现有设计

---

## 📄 许可证和其他

### 开源许可证

本项目采用 **Apache License 2.0** 开源许可证。您可以自由使用、修改和分发本项目代码，但需要：

- ✅ 保留原始许可证和版权声明
- ✅ 说明您对代码进行了哪些修改
- ✅ 在修改后的代码中保留 NOTICE 文件
- ✅ 在项目根目录保留 LICENSE 文件

详见 [LICENSE](LICENSE) 文件。

### 联系方式和反馈

- 📧 **提交 Issue**: [GitHub Issues](https://github.com/your-repo/easy-slimming/issues)
- 💬 **讨论**: [GitHub Discussions](https://github.com/your-repo/easy-slimming/discussions)
- 📝 **报告 Bug**: 使用 "bug" 标签提交 Issue
- 💡 **功能建议**: 使用 "enhancement" 标签提交 Issue

### 致谢

感谢以下贡献者和资源：

- **HarmonyOS 开发者社区**: 提供文档和技术支持
- **开发工具**: DevEco Studio、Hvigor 构建系统
- **开源项目**: 参考的最佳实践和设计模式
- **测试社区**: Hypium 测试框架和测试指导

### 相关资源

- 📚 [HarmonyOS 官方文档](https://developer.huawei.com/consumer/cn/devservice)
- 🎓 [ArkTS 语言指南](https://developer.huawei.com/consumer/cn/devservice/doc/harmonyos-guides)
- 🏗️ [Stage Model 应用开发](https://developer.huawei.com/consumer/cn/devservice/doc/harmonyos-guides-stage-model)
- 📦 [HarmonyOS 运动健康 API](https://developer.huawei.com/consumer/cn/devservice/doc/harmonyos-guides)

---

## 🚦 项目状态

### 当前版本: v1.0.0

- ✅ 核心功能完成
- ✅ 所有 10 个 PR 实现完成
- ✅ 编译无错误和警告
- ✅ 代码规范通过检查
- ⚠️ 真实 HarmonyOS Health API 集成（使用模拟实现）

### 已知限制

1. **同步功能**: 当前使用模拟 API，需要实际 HarmonyOS Health API 支持
2. **后台同步**: 未实现真正的后台同步（需要 WorkScheduler）
3. **数据加密**: 数据传输未加密（生产环境需要添加）
4. **权限处理**: 基础权限检查，缺少运行时权限请求

### 未来计划

- [ ] 真实 HarmonyOS Health API 集成
- [ ] 后台同步实现（WorkScheduler）
- [ ] 数据加密和安全传输
- [ ] 运行时权限请求 UI
- [ ] 云端数据同步
- [ ] 更详细的统计分析
- [ ] 社交分享功能
- [ ] 多语言支持
- [ ] 主题定制

---
<div align="center">

## 💖 支持本项目

如果本项目对您有帮助，请给个 ⭐️ Star！

[GitHub](https://github.com/your-repo/easy-slimming) | 
[Issues](https://github.com/your-repo/easy-slimming/issues) | 
[Discussions](https://github.com/your-repo/easy-slimming/discussions)

---

**轻松减重 (Easy-Slimming)** © 2025

Made with ❤️ using ArkTS + HarmonyOS

</div>
