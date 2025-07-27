import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../shared/controllers/window_controller.dart';
import '../../../shared/widgets/common/glass_container.dart';
import '../../../core/remote_control/focusable_glow.dart';
import '../../../core/remote_control/universal_focus.dart';
import '../services/cms_site_service.dart';

/// CMS站点管理组件
class CmsSiteManager extends StatefulWidget {
  const CmsSiteManager({super.key});

  @override
  State<CmsSiteManager> createState() => _CmsSiteManagerState();
}

class _CmsSiteManagerState extends State<CmsSiteManager> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _urlController = TextEditingController();
  final FocusNode _nameFocusNode = FocusNode();
  final FocusNode _urlFocusNode = FocusNode();

  @override
  void dispose() {
    _nameController.dispose();
    _urlController.dispose();
    _nameFocusNode.dispose();
    _urlFocusNode.dispose();
    super.dispose();
  }

  void _showAddSiteDialog() {
    _nameController.clear();
    _urlController.clear();

    showDialog(
      context: context,
      builder: (context) => _buildAddSiteDialog(),
    );
  }

  Widget _buildAddSiteDialog() {
    return Obx(() {
      final windowController = Get.find<WindowController>();
      final isPortrait = windowController.isPortrait.value;

      return AlertDialog(
        backgroundColor: Colors.transparent,
        content: GlassContainer(
          width: isPortrait ? 300 : 400,
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '添加CMS站点',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isPortrait ? Colors.grey[800] : Colors.white,
                ),
              ),
              const SizedBox(height: 20),
              
              // 站点名称输入
              UniversalFocus(
                focusNode: _nameFocusNode,
                onTap: () => _nameFocusNode.requestFocus(),
                child: TextField(
                  controller: _nameController,
                  focusNode: _nameFocusNode,
                  decoration: InputDecoration(
                    labelText: '站点名称',
                    hintText: '例如：非凡资源',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    filled: true,
                    fillColor: isPortrait 
                        ? Colors.white.withValues(alpha: 0.7)
                        : Colors.white.withValues(alpha: 0.1),
                  ),
                  style: TextStyle(
                    color: isPortrait ? Colors.grey[800] : Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              // 站点URL输入
              UniversalFocus(
                focusNode: _urlFocusNode,
                onTap: () => _urlFocusNode.requestFocus(),
                child: TextField(
                  controller: _urlController,
                  focusNode: _urlFocusNode,
                  decoration: InputDecoration(
                    labelText: '站点URL',
                    hintText: 'https://example.com/api.php/provide/vod',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    filled: true,
                    fillColor: isPortrait 
                        ? Colors.white.withValues(alpha: 0.7)
                        : Colors.white.withValues(alpha: 0.1),
                  ),
                  style: TextStyle(
                    color: isPortrait ? Colors.grey[800] : Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              
              // 按钮行
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // 取消按钮
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.grey.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '取消',
                        style: TextStyle(
                          color: isPortrait ? Colors.grey[800] : Colors.white,
                        ),
                      ),
                    ),
                  ),
                  
                  // 确认按钮
                  TextButton(
                    onPressed: _addSite,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF7BB0),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        '添加',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    });
  }

  void _addSite() async {
    final name = _nameController.text.trim();
    final url = _urlController.text.trim();

    if (name.isEmpty || url.isEmpty) {
      Get.snackbar('错误', '请填写完整的站点信息');
      return;
    }

    final success = await CmsSiteService.instance.addCmsSite(name, url);
    if (mounted) {
      if (success) {
        Navigator.of(context).pop();
        Get.snackbar('成功', '站点添加成功');
      } else {
        Get.snackbar('错误', '站点添加失败，可能URL已存在');
      }
    }
  }

  void _confirmDeleteSite(CmsSite site) {
    showDialog(
      context: context,
      builder: (context) => _buildDeleteConfirmDialog(site),
    );
  }

  Widget _buildDeleteConfirmDialog(CmsSite site) {
    return Obx(() {
      final windowController = Get.find<WindowController>();
      final isPortrait = windowController.isPortrait.value;

      return AlertDialog(
        backgroundColor: Colors.transparent,
        content: GlassContainer(
          width: isPortrait ? 280 : 350,
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '确认删除',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isPortrait ? Colors.grey[800] : Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                '确定要删除站点"${site.name}"吗？',
                style: TextStyle(
                  fontSize: 14,
                  color: isPortrait ? Colors.grey[600] : Colors.grey[300],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.grey.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '取消',
                        style: TextStyle(
                          color: isPortrait ? Colors.grey[800] : Colors.white,
                        ),
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () async {
                      final navigator = Navigator.of(context);
                      await CmsSiteService.instance.removeCmsSite(site.id);
                      navigator.pop();
                      Get.snackbar('成功', '站点删除成功');
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.8),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        '删除',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final windowController = Get.find<WindowController>();
      final isPortrait = windowController.isPortrait.value;
      final cmsSites = CmsSiteService.instance.cmsSites;
      final selectedSiteId = CmsSiteService.instance.selectedSiteId;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 标题和添加按钮
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'CMS采集站点',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isPortrait ? Colors.grey[800] : Colors.white,
                ),
              ),
              FocusableGlow(
                onTap: _showAddSiteDialog,
                borderRadius: BorderRadius.circular(6),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF7BB0),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    '+ 添加',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          // CMS站点列表
          if (cmsSites.isEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isPortrait 
                    ? Colors.grey[200]?.withValues(alpha: 0.5)
                    : Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isPortrait ? Colors.grey[300]! : Colors.white.withValues(alpha: 0.1),
                ),
              ),
              child: Text(
                '暂无CMS站点，点击"+ 添加"按钮添加站点',
                style: TextStyle(
                  color: isPortrait ? Colors.grey[600] : Colors.grey[400],
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
            )
          else
            ...cmsSites.map((site) => _buildSiteItem(site, selectedSiteId, isPortrait)),
        ],
      );
    });
  }

  Widget _buildSiteItem(CmsSite site, String selectedSiteId, bool isPortrait) {
    final isSelected = site.id == selectedSiteId;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: FocusableGlow(
        onTap: () => CmsSiteService.instance.selectCmsSite(site.id),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isSelected
                ? (isPortrait 
                    ? const Color(0xFFFF7BB0).withValues(alpha: 0.1)
                    : const Color(0xFFFF7BB0).withValues(alpha: 0.2))
                : (isPortrait 
                    ? Colors.white.withValues(alpha: 0.7)
                    : Colors.white.withValues(alpha: 0.05)),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected
                  ? const Color(0xFFFF7BB0)
                  : (isPortrait ? Colors.grey[300]! : Colors.white.withValues(alpha: 0.1)),
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              // 选择状态指示器
              Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected ? const Color(0xFFFF7BB0) : Colors.grey[400]!,
                    width: 2,
                  ),
                  color: isSelected ? const Color(0xFFFF7BB0) : Colors.transparent,
                ),
                child: isSelected
                    ? const Icon(Icons.check, size: 10, color: Colors.white)
                    : null,
              ),
              const SizedBox(width: 12),
              
              // 站点信息
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      site.name,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isPortrait ? Colors.grey[800] : Colors.white,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      site.url,
                      style: TextStyle(
                        fontSize: 12,
                        color: isPortrait ? Colors.grey[600] : Colors.grey[400],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              
              // 删除按钮
              FocusableGlow(
                onTap: () => _confirmDeleteSite(site),
                borderRadius: BorderRadius.circular(4),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  child: Icon(
                    Icons.delete_outline,
                    size: 16,
                    color: Colors.red.withValues(alpha: 0.7),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}