import 'package:flutter_test/flutter_test.dart';
import 'package:oneplayer/features/search/controllers/search_controller.dart';
import 'package:oneplayer/shared/models/search_source.dart';
import 'package:oneplayer/shared/models/search_page_state.dart';
import 'package:get/get.dart';

void main() {
  group('SearchController Tests', () {
    late SearchController searchController;

    setUp(() {
      Get.testMode = true;
      searchController = SearchController();
    });

    tearDown(() {
      Get.reset();
    });

    test('初始化状态正确', () {
      expect(searchController.pageState.status, SearchPageStatus.idle);
      expect(searchController.pageState.keyword, '');
      expect(searchController.availableSources.length, 5); // 默认5个源
    });

    test('搜索源配置正确', () {
      final sources = SearchSource.getDefaultSources();
      expect(sources.length, 5);
      expect(sources[0].id, 'bilibili');
      expect(sources[0].name, 'B站');
      expect(sources[1].id, 'iqiyi');
      expect(sources[1].name, '爱奇艺');
    });

    test('搜索历史功能', () {
      // 测试添加搜索历史
      searchController.quickSearch('测试关键词');
      
      // 验证搜索历史
      expect(searchController.currentKeyword, '测试关键词');
    });

    test('焦点管理功能', () {
      // 测试焦点移动
      searchController.focusedSourceIndex.value = 0;
      searchController.moveFocusDown();
      expect(searchController.focusedSourceIndex.value, 1);
      
      searchController.moveFocusUp();
      expect(searchController.focusedSourceIndex.value, 0);
    });

    test('搜索源选择功能', () {
      final sources = searchController.availableSources;
      if (sources.isNotEmpty) {
        searchController.selectSource(sources[0].id);
        expect(searchController.selectedSourceId, sources[0].id);
      }
    });
  });
}