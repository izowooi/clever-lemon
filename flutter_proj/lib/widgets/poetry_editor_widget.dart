import 'package:flutter/material.dart';
import '../models/poetry.dart';

class PoetryEditorWidget extends StatefulWidget {
  final Poetry poetry;
  final Function(String title, String content) onPoetryChanged;
  final VoidCallback onSave;
  final bool isLoading;

  const PoetryEditorWidget({
    super.key,
    required this.poetry,
    required this.onPoetryChanged,
    required this.onSave,
    this.isLoading = false,
  });

  @override
  State<PoetryEditorWidget> createState() => _PoetryEditorWidgetState();
}

class _PoetryEditorWidgetState extends State<PoetryEditorWidget> {
  late TextEditingController _titleController;
  late TextEditingController _contentController;
  
  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.poetry.title);
    _contentController = TextEditingController(text: widget.poetry.content);
    
    // 텍스트 변경 리스너 추가
    _titleController.addListener(_onTextChanged);
    _contentController.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    widget.onPoetryChanged(_titleController.text, _contentController.text);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          '시를 편집하세요',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        
        // 키워드 표시
        if (widget.poetry.keywords.isNotEmpty) ...[
          Text(
            '사용된 키워드:',
            style: Theme.of(context).textTheme.labelLarge,
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            children: widget.poetry.keywords
                .map(
                  (keyword) => Chip(
                    label: Text(keyword),
                    backgroundColor: Theme.of(context)
                        .colorScheme
                        .primaryContainer
                        .withOpacity(0.7),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 16),
        ],
        
        // 제목 입력
        TextField(
          controller: _titleController,
          decoration: const InputDecoration(
            labelText: '시 제목',
            border: OutlineInputBorder(),
            hintText: '시의 제목을 입력하세요',
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
            decoration: const InputDecoration(
              labelText: '시 내용',
              alignLabelWithHint: true,
              border: OutlineInputBorder(),
              hintText: '시의 내용을 입력하세요',
            ),
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              height: 1.8,
            ),
          ),
        ),
        
        const SizedBox(height: 16),
        
        // 저장 버튼
        SizedBox(
          width: double.infinity,
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
              style: const TextStyle(fontSize: 18),
            ),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
      ],
    );
  }
}
