import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import '../models/poetry_template.dart';

class PoetryTemplateCard extends StatelessWidget {
  final PoetryTemplate template;
  final VoidCallback? onCopy;

  const PoetryTemplateCard({
    super.key,
    required this.template,
    this.onCopy,
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

  Future<void> _sharePoetry(BuildContext context) async {
    final fullText = '${template.title}\n\n${template.content}';

    try {
      await SharePlus.instance.share(ShareParams(
        text: fullText,
        subject: template.title,
      ));
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('공유에 실패했습니다: $e'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 제목과 액션 버튼들
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // 제목
                Expanded(
                  child: Text(
                    template.title,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
                // 액션 버튼들
                Row(
                  children: [
                    // 복사하기 버튼
                    IconButton(
                      onPressed: () => _copyToClipboard(context),
                      icon: const Icon(Icons.copy),
                      tooltip: '복사하기',
                    ),
                    // 공유하기 버튼
                    IconButton(
                      onPressed: () => _sharePoetry(context),
                      icon: const Icon(Icons.share),
                      tooltip: '공유하기',
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 본문
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
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
    );
  }
}
