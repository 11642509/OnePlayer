import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../../shared/controllers/window_controller.dart';
import '../controllers/search_controller.dart' as search_ctrl;

/// 搜索页面遥控器导航处理器
class SearchRemoteNavigationHandler {
  final search_ctrl.SearchController controller;
  
  SearchRemoteNavigationHandler(this.controller);
  
  /// 处理键盘事件
  KeyEventResult handleKeyEvent(KeyEvent event) {
    if (event is! KeyDownEvent) {
      return KeyEventResult.ignored;
    }
    
    switch (event.logicalKey) {
      case LogicalKeyboardKey.arrowUp:
        return _handleArrowUp();
      case LogicalKeyboardKey.arrowDown:
        return _handleArrowDown();
      case LogicalKeyboardKey.arrowLeft:
        return _handleArrowLeft();
      case LogicalKeyboardKey.arrowRight:
        return _handleArrowRight();
      case LogicalKeyboardKey.select:
      case LogicalKeyboardKey.enter:
        return _handleConfirm();
      case LogicalKeyboardKey.escape:
      case LogicalKeyboardKey.goBack:
        return _handleBack();
      default:
        return KeyEventResult.ignored;
    }
  }
  
  /// 处理上键
  KeyEventResult _handleArrowUp() {
    // 如果搜索框有焦点，不处理
    if (controller.searchFocusNode.hasFocus) {
      return KeyEventResult.ignored;
    }
    
    // 如果在源列表中
    if (controller.focusedSourceIndexValue >= 0) {
      controller.moveFocusUp();
      return KeyEventResult.handled;
    }
    
    // 如果在结果网格中，向上移动
    if (controller.focusedResultIndexValue >= 0) {
      _moveResultFocusUp();
      return KeyEventResult.handled;
    }
    
    return KeyEventResult.ignored;
  }
  
  /// 处理下键
  KeyEventResult _handleArrowDown() {
    // 如果搜索框有焦点，由SmartTextField处理
    if (controller.searchFocusNode.hasFocus) {
      return KeyEventResult.ignored;
    }
    
    // 如果在源列表中
    if (controller.focusedSourceIndexValue >= 0) {
      controller.moveFocusDown();
      return KeyEventResult.handled;
    }
    
    // 如果在结果网格中，向下移动
    if (controller.focusedResultIndexValue >= 0) {
      _moveResultFocusDown();
      return KeyEventResult.handled;
    }
    
    // 如果没有焦点，默认聚焦到第一个源
    if (controller.availableSources.isNotEmpty) {
      controller.navigateFromSearchToSources();
      return KeyEventResult.handled;
    }
    
    return KeyEventResult.ignored;
  }
  
  /// 处理左键
  KeyEventResult _handleArrowLeft() {
    // 如果清除按钮有焦点，跳转到搜索框
    if (controller.getClearButtonFocusNode.hasFocus) {
      controller.navigateToSearchBox();
      return KeyEventResult.handled;
    }
    
    // 如果搜索框有焦点，让文本框处理
    if (controller.searchFocusNode.hasFocus) {
      return KeyEventResult.ignored;
    }
    
    // 如果在结果网格中，向左移动
    if (controller.focusedResultIndexValue >= 0) {
      controller.moveFocusLeft();
      return KeyEventResult.handled;
    }
    
    // 如果在源列表中且有结果，跳转到结果区域
    if (controller.focusedSourceIndexValue >= 0 && controller.hasResults) {
      controller.navigateFromSourcesToResults();
      return KeyEventResult.handled;
    }
    
    return KeyEventResult.ignored;
  }
  
  /// 处理右键
  KeyEventResult _handleArrowRight() {
    // 如果返回按钮有焦点，跳转到搜索框
    if (controller.getBackButtonFocusNode.hasFocus) {
      controller.navigateToSearchBox();
      return KeyEventResult.handled;
    }
    
    // 如果搜索框有焦点，让文本框处理
    if (controller.searchFocusNode.hasFocus) {
      return KeyEventResult.ignored;
    }
    
    // 如果在结果网格中，向右移动或跳转到源列表
    if (controller.focusedResultIndexValue >= 0) {
      controller.moveFocusRight();
      return KeyEventResult.handled;
    }
    
    // 如果在源列表中且有结果，跳转到结果区域
    if (controller.focusedSourceIndexValue >= 0 && controller.hasResults) {
      controller.navigateFromSourcesToResults();
      return KeyEventResult.handled;
    }
    
    return KeyEventResult.ignored;
  }
  
  /// 处理确认键
  KeyEventResult _handleConfirm() {
    // 如果返回按钮有焦点，执行返回操作
    if (controller.getBackButtonFocusNode.hasFocus) {
      Get.back();
      return KeyEventResult.handled;
    }
    
    // 如果清除按钮有焦点，执行清除操作
    if (controller.getClearButtonFocusNode.hasFocus) {
      controller.clearSearch();
      return KeyEventResult.handled;
    }
    
    // 如果搜索框有焦点，执行搜索
    if (controller.searchFocusNode.hasFocus) {
      controller.performSearch(controller.textController.text);
      return KeyEventResult.handled;
    }
    
    // 如果在源列表中，选择源
    if (controller.focusedSourceIndexValue >= 0) {
      controller.confirmSelection();
      return KeyEventResult.handled;
    }
    
    // 如果在结果网格中，选择结果
    if (controller.focusedResultIndexValue >= 0) {
      final result = controller.currentResults[controller.focusedResultIndexValue];
      // 这里需要调用结果选择回调
      // 由于没有直接的回调，我们使用Get.toNamed
      Get.toNamed('/video-detail', arguments: result);
      return KeyEventResult.handled;
    }
    
    return KeyEventResult.ignored;
  }
  
  /// 处理返回键
  KeyEventResult _handleBack() {
    // 如果返回按钮有焦点，执行返回操作
    if (controller.getBackButtonFocusNode.hasFocus) {
      Get.back();
      return KeyEventResult.handled;
    }
    
    // 如果清除按钮有焦点，跳转到搜索框
    if (controller.getClearButtonFocusNode.hasFocus) {
      controller.navigateToSearchBox();
      return KeyEventResult.handled;
    }
    
    // 如果搜索框有焦点，清除焦点
    if (controller.searchFocusNode.hasFocus) {
      controller.searchFocusNode.unfocus();
      return KeyEventResult.handled;
    }
    
    // 如果在结果网格中，返回到源列表
    if (controller.focusedResultIndexValue >= 0) {
      controller.navigateFromResultsToSources();
      return KeyEventResult.handled;
    }
    
    // 如果在源列表中，返回到搜索框
    if (controller.focusedSourceIndexValue >= 0) {
      controller.navigateToSearchBox();
      return KeyEventResult.handled;
    }
    
    // 否则返回上一页
    Get.back();
    return KeyEventResult.handled;
  }
  
  /// 在结果网格中向上移动焦点
  void _moveResultFocusUp() {
    final currentIndex = controller.focusedResultIndexValue;
    final totalResults = controller.currentResults.length;
    
    if (totalResults == 0) return;
    
    // 获取网格列数（横屏4列，竖屏2列）
    final isPortrait = Get.find<WindowController>().isPortrait.value;
    final columns = isPortrait ? 2 : 4;
    
    // 计算上一行的索引
    final newIndex = currentIndex - columns;
    
    if (newIndex >= 0) {
      controller.focusedResultIndex.value = newIndex;
      controller.scrollToFocusedResult();
    } else {
      // 如果到达顶部，跳转到源列表
      controller.focusedResultIndex.value = -1;
      controller.focusedSourceIndex.value = 0;
    }
  }
  
  /// 在结果网格中向下移动焦点
  void _moveResultFocusDown() {
    final currentIndex = controller.focusedResultIndexValue;
    final totalResults = controller.currentResults.length;
    
    if (totalResults == 0) return;
    
    // 获取网格列数（横屏4列，竖屏2列）
    final isPortrait = Get.find<WindowController>().isPortrait.value;
    final columns = isPortrait ? 2 : 4;
    
    // 计算下一行的索引
    final newIndex = currentIndex + columns;
    
    if (newIndex < totalResults) {
      controller.focusedResultIndex.value = newIndex;
      controller.scrollToFocusedResult();
    }
  }
}