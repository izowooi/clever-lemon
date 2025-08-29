import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/poetry_template.dart';

class PoetryTemplateCard extends StatelessWidget {
  final PoetryTemplate template;
  final VoidCallback? onCopy;
  final VoidCallback? onEdit;
  final VoidCallback? onSave;

  const PoetryTemplateCard({
    super.key,
    required this.template,
    this.onCopy,
    this.onEdit,
    this.onSave,
  });

  Future<void> _copyToClipboard(BuildContext context) async {
    final fullText = '${template.title}\n\n${template.content}';
    await Clipboard.setData(ClipboardData(text: fullText));
    
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('클립보드에 복사되었습니다'),
          duration: Duration(seconds: 2),
        ),
      );
    }
    
    onCopy?.call();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 시 내용
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 제목
                Text(
                  template.title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 16),
                
                // 본문
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                    ),
                  ),
                  child: Text(
                    template.content,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      height: 1.8,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // 액션 버튼들
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(12),
                bottomRight: Radius.circular(12),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  // 복사하기 버튼
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _copyToClipboard(context),
                      icon: const Icon(Icons.copy),
                      label: const Text('복사하기'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  
                  // 편집하기 버튼
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onEdit,
                      icon: const Icon(Icons.edit),
                      label: const Text('편집하기'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  
                  // 저장하기 버튼
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: onSave,
                      icon: const Icon(Icons.save),
                      label: const Text('저장하기'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
