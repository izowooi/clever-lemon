import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/daily_quote.dart';

class DailyQuoteEditorCard extends StatefulWidget {
  final DailyQuote dailyQuote;
  final Function(String title, String content) onDailyQuoteChanged;
  final VoidCallback? onSave;
  final bool isLoading;

  const DailyQuoteEditorCard({
    super.key,
    required this.dailyQuote,
    required this.onDailyQuoteChanged,
    this.onSave,
    this.isLoading = false,
  });

  @override
  State<DailyQuoteEditorCard> createState() => _DailyQuoteEditorCardState();
}

class _DailyQuoteEditorCardState extends State<DailyQuoteEditorCard> {
  late TextEditingController _titleController;
  late TextEditingController _contentController;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.dailyQuote.title);
    _contentController = TextEditingController(text: widget.dailyQuote.content);

    // 텍스트 변경 리스너 추가
    _titleController.addListener(_onTextChanged);
    _contentController.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    widget.onDailyQuoteChanged(_titleController.text, _contentController.text);
  }

  Future<void> _copyToClipboard() async {
    final fullText = '${_titleController.text}\n\n${_contentController.text}';
    await Clipboard.setData(ClipboardData(text: fullText));

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('클립보드에 복사되었습니다'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 헤더
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.edit,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  '글귀 편집하기',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),

          // 편집 영역
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 키워드 표시
                  if (widget.dailyQuote.keywords.isNotEmpty) ...[
                    Text(
                      '사용된 키워드:',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      children: widget.dailyQuote.keywords
                          .map(
                            (keyword) => Chip(
                              label: Text(keyword),
                              backgroundColor: Theme.of(context)
                                  .colorScheme
                                  .secondaryContainer
                                  .withOpacity(0.7),
                              labelStyle: const TextStyle(fontSize: 12),
                            ),
                          )
                          .toList(),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // 제목 입력
                  TextField(
                    controller: _titleController,
                    decoration: InputDecoration(
                      labelText: '글귀 제목',
                      hintText: '글귀의 제목을 입력하세요',
                      prefixIcon: const Icon(Icons.title),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 16),

                  // 내용 입력
                  Expanded(
                    child: TextField(
                      controller: _contentController,
                      maxLines: null,
                      expands: true,
                      textAlignVertical: TextAlignVertical.top,
                      decoration: InputDecoration(
                        labelText: '글귀 내용',
                        alignLabelWithHint: true,
                        hintText: '글귀의 내용을 입력하세요...',
                        prefixIcon: const Padding(
                          padding: EdgeInsets.only(bottom: 200),
                          child: Icon(Icons.format_quote),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        height: 1.8,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
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
                      onPressed: widget.isLoading ? null : _copyToClipboard,
                      icon: const Icon(Icons.copy),
                      label: const Text('복사하기'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // 저장하기 버튼
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      onPressed: widget.isLoading ? null : widget.onSave,
                      icon: widget.isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.save),
                      label: Text(
                        widget.isLoading ? '저장 중...' : '저장하기',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
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
