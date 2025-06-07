#!/bin/bash

# 设置变量
WORKSPACE_PATH="./macos/Runner.xcworkspace"
PROJECT_PATH="./macos/Runner.xcodeproj"
XCODE_BUILD_PATH="./build/macos"
DERIVED_DATA_PATH="$HOME/Library/Developer/Xcode/DerivedData"

# 显示当前状态
echo "===== 开始修复构建重复任务问题 ====="
echo "工作区路径: $WORKSPACE_PATH"
echo "项目路径: $PROJECT_PATH"
echo "构建路径: $XCODE_BUILD_PATH"

# 步骤1: 清理之前的构建
echo "步骤1: 清理之前的构建..."
rm -rf "$XCODE_BUILD_PATH"
echo "已删除构建目录: $XCODE_BUILD_PATH"

# 步骤2: 清理Xcode派生数据
echo "步骤2: 清理Xcode派生数据..."
find "$DERIVED_DATA_PATH" -name "*Runner*" -type d -exec rm -rf {} \; 2>/dev/null || true
echo "已清理Runner相关的派生数据"

# 步骤3: 修改项目设置以使用单一架构
echo "步骤3: 修改项目设置..."

# 使用PlistBuddy修改xcodeproj文件
# 注意：这需要在项目中创建临时的架构设置文件

# 创建临时文件
cat > ./macos/arch_settings.xcconfig <<EOF
// 强制使用arm64架构
ARCHS = arm64
ONLY_ACTIVE_ARCH = YES

// 禁用重复构建任务
SWIFT_ACTIVE_COMPILATION_CONDITIONS = \$(inherited)
GCC_PREPROCESSOR_DEFINITIONS = \$(inherited)
EOF

echo "已创建架构配置文件: ./macos/arch_settings.xcconfig"

# 步骤4: 更新Runner.xcconfig以包含新设置
echo "步骤4: 更新Runner配置..."
RUNNER_CONFIG="./macos/Flutter/ephemeral/Flutter-Generated.xcconfig"

if [ -f "$RUNNER_CONFIG" ]; then
  echo "// 包含架构设置" >> "$RUNNER_CONFIG"
  echo "#include \"../arch_settings.xcconfig\"" >> "$RUNNER_CONFIG"
  echo "已更新Flutter配置文件"
else
  echo "警告: 未找到Flutter配置文件: $RUNNER_CONFIG"
fi

# 步骤5: 运行pod install以应用更改
echo "步骤5: 重新安装Pod..."
cd macos && pod install && cd ..
echo "Pod已重新安装"

echo "===== 修复完成 ====="
echo "请尝试重新构建项目，如果仍有问题，可能需要手动设置Xcode项目配置。" 