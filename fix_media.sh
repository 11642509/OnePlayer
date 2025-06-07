#!/bin/bash

# 显示开始消息
echo "===== 开始全面修复媒体框架问题 ====="

# 步骤1: 清理项目
echo "步骤1: 清理项目..."
flutter clean
rm -rf build/
rm -rf macos/Pods
rm -rf macos/Flutter/ephemeral
rm -rf macos/.symlinks
rm -rf ~/.pub-cache/hosted/pub.dev/media_kit_libs_macos_video-1.1.4

# 步骤2: 重新添加依赖
echo "步骤2: 重新安装媒体库..."
flutter pub remove media_kit media_kit_video media_kit_libs_macos_video || true
flutter pub add media_kit media_kit_video media_kit_libs_macos_video

# 步骤3: 更新Flutter依赖
echo "步骤3: 更新Flutter依赖..."
flutter pub get

# 步骤4: 修复生成的插件注册文件
echo "步骤4: 修复插件注册文件..."
cat > macos/Flutter/GeneratedPluginRegistrant.swift << 'EOF'
//
//  Generated file. Do not edit.
//

import FlutterMacOS
import Foundation

// 有条件导入媒体库
#if canImport(media_kit_libs_macos_video)
import media_kit_libs_macos_video
#endif
import media_kit_video
import package_info_plus
import path_provider_foundation
import video_player_avfoundation
import volume_controller
import wakelock_plus

func RegisterGeneratedPlugins(registry: FlutterPluginRegistry) {
  #if canImport(media_kit_libs_macos_video)
  MediaKitLibsMacosVideoPlugin.register(with: registry.registrar(forPlugin: "MediaKitLibsMacosVideoPlugin"))
  #endif
  MediaKitVideoPlugin.register(with: registry.registrar(forPlugin: "MediaKitVideoPlugin"))
  FPPPackageInfoPlusPlugin.register(with: registry.registrar(forPlugin: "FPPPackageInfoPlusPlugin"))
  PathProviderPlugin.register(with: registry.registrar(forPlugin: "PathProviderPlugin"))
  FVPVideoPlayerPlugin.register(with: registry.registrar(forPlugin: "FVPVideoPlayerPlugin"))
  VolumeControllerPlugin.register(with: registry.registrar(forPlugin: "VolumeControllerPlugin"))
  WakelockPlusMacosPlugin.register(with: registry.registrar(forPlugin: "WakelockPlusMacosPlugin"))
}
EOF

# 步骤5: 创建架构配置文件
echo "步骤5: 创建架构配置文件..."
cat > macos/arm64_only.xcconfig << 'EOF'
// 强制使用arm64架构
ARCHS = arm64
ONLY_ACTIVE_ARCH = YES
EXCLUDED_ARCHS = x86_64 i386
VALID_ARCHS = arm64

// 架构相关设置
SWIFT_ACTIVE_COMPILATION_CONDITIONS = $(inherited) ARM64_ONLY
GCC_PREPROCESSOR_DEFINITIONS = $(inherited) ARM64_ONLY=1
EOF

# 步骤6: 修改Podfile文件
echo "步骤6: 修改Podfile文件..."
cat > macos/Podfile << 'EOF'
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
  
  post_install do |installer|
    installer.pods_project.targets.each do |target|
      flutter_additional_macos_build_settings(target)
      
      # 为所有目标添加架构设置
      target.build_configurations.each do |config|
        # 强制arm64架构
        config.build_settings['ARCHS'] = 'arm64'
        config.build_settings['ONLY_ACTIVE_ARCH'] = 'YES'
        config.build_settings['EXCLUDED_ARCHS'] = 'x86_64 i386'
        config.build_settings['VALID_ARCHS'] = 'arm64'
        
        # Swift编译条件
        config.build_settings['SWIFT_ACTIVE_COMPILATION_CONDITIONS'] = '$(inherited) ARM64_ONLY'
        
        # 链接设置
        config.build_settings['OTHER_LDFLAGS'] = '$(inherited)'
        
        # 启用BitCode
        config.build_settings['ENABLE_BITCODE'] = 'NO'
        
        # 指定Swift版本
        config.build_settings['SWIFT_VERSION'] = '5.0'
      end
      
      # 处理volume_controller插件
      if target.name == 'volume_controller'
        target.build_configurations.each do |config|
          config.build_settings['EXCLUDED_SOURCE_FILE_NAMES'] = ['**/PrivacyInfo.xcprivacy']
          config.build_settings['INFOPLIST_KEY_NSPrivacyAccessedAPITypes'] = '$(inherited)'
        end
      end
      
      # 特别处理media_kit插件
      if target.name.include?('media_kit')
        target.build_configurations.each do |config|
          config.build_settings['ARCHS'] = 'arm64'
          config.build_settings['BUILD_LIBRARY_FOR_DISTRIBUTION'] = 'YES'
        end
      end
    end
  end
end
EOF

# 步骤7: 安装Pod依赖
echo "步骤7: 安装Pod依赖..."
cd macos && pod install && cd ..

# 步骤8: 尝试构建项目
echo "步骤8: 尝试构建项目..."
flutter build macos --debug

echo "===== 修复完成 ====="
echo "如果构建成功，应用程序应该可以正常运行了。" 