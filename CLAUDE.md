# Claude开发指南

## GetX使用规范

### 响应式状态管理
- **优先使用 `Obx()`** 而不是 `GetBuilder()`，确保状态变化立即反映到UI
- **使用 Rx 变量** (`RxBool`, `RxString`, `RxInt` 等) 实现自动响应式更新
- **避免手动 `update()` 调用**，除非使用 `GetBuilder()` 且确有必要

```dart
// ✅ 推荐写法
class MyController extends GetxController {
  final _isLoading = false.obs;
  bool get isLoading => _isLoading.value;
  set isLoading(bool value) => _isLoading.value = value;
}

// UI中使用
Obx(() => Text(controller.isLoading ? '加载中...' : '已完成'))

// ❌ 避免写法  
class MyController extends GetxController {
  bool isLoading = false;
  
  void setLoading(bool value) {
    isLoading = value;
    update(); // 手动调用update
  }
}
```

### 控制器管理
- **使用 `GetView<T>`** 作为页面基类，自动获取控制器实例
- **在 `InitialBinding` 中注册全局控制器**，确保依赖注入正确
- **页面级控制器使用 `Get.put()`**，全局控制器使用 `Get.put(permanent: true)`

```dart
// ✅ 推荐写法
class SettingsPage extends GetView<SettingsController> {
  @override
  Widget build(BuildContext context) {
    return Obx(() => Scaffold(...));
  }
}

// 在页面路由中
Get.put(SettingsController()); // 自动管理生命周期
```

### 性能优化原则
- **组件细粒度响应**：只对需要更新的部分使用 `Obx()`
- **避免整页面 `Obx()`**：将响应式包装器限制在具体变化的组件上
- **背景效果响应式**：确保性能设置变更立即生效

## 代码架构风格（互联网大公司标准）

### 目录结构
```
lib/
├── app/                    # 应用级配置
│   ├── bindings/          # 依赖注入绑定
│   ├── config/            # 应用配置
│   ├── routes/            # 路由管理
│   └── theme/             # 主题配置
├── core/                   # 核心基础设施
│   ├── error/             # 错误处理
│   ├── network/           # 网络层
│   └── utils/             # 工具类
├── features/               # 功能模块
│   └── feature_name/      # 具体功能
│       ├── controllers/   # 业务逻辑控制器
│       ├── pages/         # 页面UI
│       ├── widgets/       # 私有组件
│       └── models/        # 数据模型（可选）
└── shared/                 # 共享资源
    ├── controllers/       # 全局控制器
    ├── widgets/           # 通用组件
    ├── utils/             # 共享工具
    └── models/            # 共享数据模型
```

### 命名规范
- **文件命名**：`snake_case.dart`
- **类命名**：`PascalCase`
- **变量/方法命名**：`camelCase`
- **常量命名**：`UPPER_SNAKE_CASE`
- **私有变量**：`_variableName`

### 代码质量要求
- **零告警原则**：所有代码必须通过 `flutter analyze` 无告警
- **零报错原则**：编译必须无错误，运行时异常需要妥善处理
- **类型安全**：避免使用 `dynamic`，明确指定类型
- **空安全**：正确使用可空类型和非空断言

### 组件设计原则
- **单一职责**：每个组件只负责一个明确的功能
- **可复用性**：通用组件放在 `shared/widgets/` 下
- **一致性**：UI风格保持统一，使用共享的设计组件
- **性能优先**：避免不必要的重建和复杂计算

### 错误处理
- **异常捕获**：关键操作使用 try-catch
- **用户友好**：错误信息对用户可读
- **日志记录**：开发模式下输出详细日志
- **优雅降级**：网络错误时提供离线功能

### 测试要求
- **单元测试**：核心业务逻辑必须有测试覆盖
- **Widget测试**：关键UI组件需要测试
- **集成测试**：主要用户流程需要端到端测试

### 性能要求
- **响应式更新**：状态变化必须立即反映到UI
- **内存管理**：正确释放资源，避免内存泄漏
- **异步操作**：网络请求和IO操作必须异步处理
- **设备适配**：支持不同性能等级设备的自适应

### 代码审查标准
- **可读性**：代码自解释，复杂逻辑有注释
- **可维护性**：代码结构清晰，易于修改和扩展
- **安全性**：不暴露敏感信息，输入验证完整
- **兼容性**：支持目标平台的所有必要功能

## 字体设计规范

### 字体选择策略（参考B站、腾讯视频、爱奇艺）
- **iOS/macOS**: 使用苹方字体 (`PingFang SC`) - 参考B站iOS版、腾讯视频等主流app
- **Android**: 使用思源黑体 (`Source Han Sans SC`) - 开源免费，主流视频app广泛采用
- **Windows**: 使用微软雅黑UI (`Microsoft YaHei UI`) - 注意商用版权
- **字体回退**: 每个平台都配置完整的字体回退链，确保兼容性

### 字体层级系统
```dart
// 使用AppTypography类统一管理字体
Text('标题', style: AppTypography.headlineLarge)     // 页面主标题
Text('副标题', style: AppTypography.titleMedium)     // 区块标题
Text('正文', style: AppTypography.bodyMedium)        // 一般内容
Text('说明', style: AppTypography.labelSmall)        // 辅助信息
```

### 专用字体样式
- `videoTitle`: 视频卡片标题专用
- `videoDescription`: 视频描述专用  
- `videoMetadata`: 播放量、时长等元数据
- `navigationLabel`: 底部导航标签
- `danmaku`: 弹幕文字样式

### 字体使用原则
- **一致性**: 全应用使用统一字体系统，避免随意指定字体
- **可读性**: 确保各级字体大小差异明显，层级清晰
- **适配性**: 支持不同屏幕尺寸和分辨率的字体缩放
- **性能**: 使用系统字体，避免额外字体文件增加包体积

## 当前项目特性

### 技术栈
- **Flutter 3.x** + **GetX 4.7.2**
- **VLC Player** + **Video Player** 双内核支持
- **性能自适应系统** (0-3级性能模式)
- **毛玻璃UI设计** (统一视觉风格)
- **多平台字体系统** (参考主流视频app)

### 关键组件
- `PerformanceManager`: 性能管理和设备检测
- `GlassContainer`: 统一毛玻璃效果组件
- `CosmicBackground`: 宇宙背景效果系统
- `WindowController`: 横竖屏管理
- `AppTypography`: 统一字体管理系统

### 设备支持
- **智能检测**: 基于屏幕分辨率和像素密度区分手机/TV盒子
- **性能自适应**: 高性能模式显示完整特效，低性能模式优化流畅度
- **响应式设计**: 支持横屏/竖屏动态切换

## 开发流程
1. **需求分析** → 确认功能范围和技术方案
2. **架构设计** → 遵循既定目录结构和设计原则  
3. **编码实现** → 遵循命名规范和代码质量要求
4. **测试验证** → 确保功能正确和性能达标
5. **代码审查** → 检查代码质量和架构一致性
6. **部署发布** → 确保零告警零报错

---
*此文档随项目发展持续更新，所有开发人员必须严格遵循以上规范。*