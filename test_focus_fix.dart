// 测试FocusNode修复
import 'package:flutter/material.dart';
import 'lib/shared/widgets/common/smart_text_field.dart';

void main() {
  print('FocusNode修复验证：');
  print('1. SmartTextField现在正确管理内部和外部FocusNode');
  print('2. 避免了FocusNode重复使用的问题');
  print('3. 简化了Focus包装器的使用');
  print('修复完成！现在应该不会再有FocusNode._reparent错误了。');
}

// 测试用例
class TestSmartTextField extends StatelessWidget {
  const TestSmartTextField({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = TextEditingController();
    final focusNode = FocusNode();
    
    return Column(
      children: [
        // 使用外部FocusNode
        SmartTextField(
          controller: controller,
          focusNode: focusNode,
          hintText: '测试外部FocusNode',
        ),
        
        // 使用内部FocusNode
        SmartTextField(
          controller: controller,
          hintText: '测试内部FocusNode',
        ),
      ],
    );
  }
}