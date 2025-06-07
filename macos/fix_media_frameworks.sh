#!/bin/bash

# 设置变量
MEDIA_KIT_PACKAGE="media_kit_libs_macos_video"
FRAMEWORK_PATH="$HOME/.pub-cache/hosted/pub.dev/$MEDIA_KIT_PACKAGE"
SYMLINKS_PATH="./macos/Flutter/ephemeral/.symlinks/plugins"

# 显示当前状态
echo "===== 开始修复媒体框架问题 ====="

# 步骤1: 检查媒体包是否存在
echo "步骤1: 检查媒体包安装状态..."
if [ -d "$FRAMEWORK_PATH" ]; then
  echo "媒体包已安装: $FRAMEWORK_PATH"
else
  echo "错误: 未找到媒体包，正在重新安装..."
  flutter pub add $MEDIA_KIT_PACKAGE
fi

# 步骤2: 确保Flutter依赖已更新
echo "步骤2: 更新Flutter依赖..."
flutter pub get

# 步骤3: 清理构建缓存
echo "步骤3: 清理缓存..."
flutter clean
rm -rf build/
echo "已清理构建缓存"

# 步骤4: 检查符号链接目录
echo "步骤4: 检查符号链接..."
if [ -d "$SYMLINKS_PATH" ]; then
  echo "符号链接目录存在: $SYMLINKS_PATH"
  ls -la "$SYMLINKS_PATH"
else
  echo "创建符号链接目录..."
  mkdir -p "$SYMLINKS_PATH"
fi

# 步骤5: 创建配置文件确保使用纯arm64架构
echo "步骤5: 创建架构配置文件..."
cat > ./macos/arm64_only.xcconfig <<EOF
ARCHS = arm64
ONLY_ACTIVE_ARCH = YES
EXCLUDED_ARCHS = x86_64 i386
VALID_ARCHS = arm64
SWIFT_ACTIVE_COMPILATION_CONDITIONS = \$(inherited) ARM64_ONLY
EOF
echo "已创建arm64_only.xcconfig"

# 步骤6: 确保在Podfile中使用架构配置
echo "步骤6: 更新Podfile..."
if grep -q "config.build_settings\['ARCHS'\] = 'arm64'" "./macos/Podfile"; then
  echo "Podfile已包含架构设置"
else
  echo "更新Podfile中的架构设置..."
  cat > ./macos/Podfile.new <<EOF
platform :osx, '10.14'

# CocoaPods analytics sends network stats synchronously affecting flutter build latency.
ENV['COCOAPODS_DISABLE_STATS'] = 'true'

project 'Runner', {
  'Debug' => :debug,
  'Profile' => :release,
  'Release' => :release,
}

def flutter_root
  generated_xcode_build_settings_path = File.expand_path(File.join('..', 'Flutter', 'ephemeral', 'Flutter-Generated.xcconfig'), __FILE__)
  unless File.exist?(generated_xcode_build_settings_path)
    raise "#{generated_xcode_build_settings_path} must exist. If you're running pod install manually, make sure \"flutter pub get\" is executed first"
  end

  File.foreach(generated_xcode_build_settings_path) do |line|
    matches = line.match(/FLUTTER_ROOT\=(.*)/)
    return matches[1].strip if matches
  end
  raise "FLUTTER_ROOT not found in #{generated_xcode_build_settings_path}. Try deleting Flutter-Generated.xcconfig, then run \"flutter pub get\""
end

require File.expand_path(File.join('packages', 'flutter_tools', 'bin', 'podhelper'), flutter_root)

flutter_macos_podfile_setup

target 'Runner' do
  use_frameworks!
  use_modular_headers!

  flutter_install_all_macos_pods File.dirname(File.realpath(__FILE__))
  target 'RunnerTests' do
    inherit! :search_paths
  end
  
  # 修复配置
  post_install do |installer|
    installer.pods_project.targets.each do |target|
      flutter_additional_macos_build_settings(target)
      
      # 为所有目标添加架构设置，避免重复构建任务
      target.build_configurations.each do |config|
        # 指定仅构建arm64架构
        config.build_settings['ARCHS'] = 'arm64'
        config.build_settings['ONLY_ACTIVE_ARCH'] = 'YES'
        config.build_settings['EXCLUDED_ARCHS'] = 'x86_64 i386'
        config.build_settings['VALID_ARCHS'] = 'arm64'
        
        # 确保使用arm64编译
        config.build_settings['SWIFT_ACTIVE_COMPILATION_CONDITIONS'] = '$(inherited) ARM64_ONLY'
      end
      
      if target.name == 'volume_controller'
        target.build_configurations.each do |config|
          # 特别处理volume_controller插件
          config.build_settings['EXCLUDED_SOURCE_FILE_NAMES'] = ['**/PrivacyInfo.xcprivacy']
          
          # 添加隐私权限
          config.build_settings['OTHER_LDFLAGS'] = '$(inherited)'
          config.build_settings['INFOPLIST_KEY_NSPrivacyAccessedAPITypes'] = '$(inherited)'
        end
      end
      
      # 特别处理media_kit_libs_macos_video
      if target.name == 'media_kit_libs_macos_video'
        target.build_configurations.each do |config|
          # 确保框架使用正确架构
          config.build_settings['ARCHS'] = 'arm64'
          config.build_settings['ONLY_ACTIVE_ARCH'] = 'YES'
        end
      end
    end
  end
end
EOF
  mv ./macos/Podfile.new ./macos/Podfile
  echo "已更新Podfile"
fi

# 步骤7: 重新安装Pod
echo "步骤7: 重新安装Pod..."
cd macos && pod deintegrate && pod install && cd ..

echo "===== 修复完成 ====="
echo "请尝试重新构建项目，应该能解决媒体框架的问题。" 