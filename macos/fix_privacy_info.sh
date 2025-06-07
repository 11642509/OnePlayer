#!/bin/bash

# 设置路径
VOLUME_CONTROLLER_PATH="${HOME}/.pub-cache/hosted/pub.dev/volume_controller-3.4.0"
PRIVACY_SOURCE="${VOLUME_CONTROLLER_PATH}/macos/volume_controller/Sources/volume_controller/PrivacyInfo.xcprivacy"
PRIVACY_DEST="${VOLUME_CONTROLLER_PATH}/macos/volume_controller/Sources/volume_controller/PrivacyInfo.plist"

# 检查源文件是否存在
if [ -f "$PRIVACY_SOURCE" ]; then
  echo "找到PrivacyInfo.xcprivacy文件，正在转换为plist格式..."
  
  # 复制文件并更改名称
  cp "$PRIVACY_SOURCE" "$PRIVACY_DEST"
  
  # 删除原始文件以避免冲突
  rm "$PRIVACY_SOURCE"
  
  echo "转换完成。"
  
  # 更新podspec文件
  PODSPEC="${VOLUME_CONTROLLER_PATH}/macos/volume_controller.podspec"
  
  if [ -f "$PODSPEC" ]; then
    echo "更新podspec文件..."
    
    # 创建临时文件
    TMP_FILE=$(mktemp)
    
    # 读取podspec并添加资源引用
    cat "$PODSPEC" | 
    awk '{
      print $0;
      if ($0 ~ /source_files/) {
        print "  s.resources = [\"Sources/volume_controller/PrivacyInfo.plist\"]";
      }
    }' > "$TMP_FILE"
    
    # 替换原文件
    mv "$TMP_FILE" "$PODSPEC"
    
    echo "podspec文件已更新。"
  else
    echo "未找到podspec文件: $PODSPEC"
  fi
else
  echo "未找到PrivacyInfo.xcprivacy文件: $PRIVACY_SOURCE"
  
  # 检查是否已经转换为plist
  if [ -f "$PRIVACY_DEST" ]; then
    echo "找到PrivacyInfo.plist文件，不需要转换。"
  else
    echo "警告：未找到任何隐私信息文件。"
  fi
fi

echo "修复脚本执行完成。" 