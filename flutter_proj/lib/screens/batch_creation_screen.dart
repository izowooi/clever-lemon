import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/poetry_creation_provider.dart';
import '../widgets/poetry_template_selection_widget.dart';
import '../widgets/poetry_editor_widget.dart';
import '../models/word.dart';

class BatchCreationScreen extends StatefulWidget {
  const BatchCreationScreen({super.key});

  @override
  State<BatchCreationScreen> createState() => _BatchCreationScreenState();
}

class _BatchCreationScreenState extends State<BatchCreationScreen> {
  final List<List<Word>> _wordGroups = [[], [], []]; // 3개 그룹
  final List<Word?> _selectedWords = [null, null, null]; // 선택된 단어들
  bool _isInitialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      _loadWordGroups();
      _isInitialized = true;
    }
  }

  Future<void> _loadWordGroups() async {
    final provider = Provider.of<PoetryCreationProvider>(context, listen: false);
    
    // 각 그룹에 대해 무작위 단어들을 로드
    for (int i = 0; i < 3; i++) {
      await provider.loadRandomWords();
      _wordGroups[i] = List.from(provider.currentWords);
    }
    
    if (mounted) {
      setState(() {});
    }
  }

  void _onWordSelected(int groupIndex, Word word) {
    setState(() {
      _selectedWords[groupIndex] = word;
    });
  }

  bool get _allWordsSelected => _selectedWords.every((word) => word != null);

  void _submitWords() {
    if (_allWordsSelected) {
      final provider = Provider.of<PoetryCreationProvider>(context, listen: false);
      provider.selectWords(_selectedWords.whereType<Word>().toList());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<PoetryCreationProvider>(
      builder: (context, provider, child) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // 에러 메시지 표시
              if (provider.errorMessage != null)
                _buildErrorMessage(context, provider),
              
              // 메인 컨텐츠
              Expanded(
                child: _buildMainContent(context, provider),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildErrorMessage(BuildContext context, PoetryCreationProvider provider) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            Icons.error,
            color: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              provider.errorMessage!,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onErrorContainer,
              ),
            ),
          ),
          IconButton(
            onPressed: provider.clearError,
            icon: const Icon(Icons.close),
            iconSize: 20,
          ),
        ],
      ),
    );
  }

  Widget _buildMainContent(BuildContext context, PoetryCreationProvider provider) {
    switch (provider.currentStep) {
      case CreationStep.wordSelection:
        return _buildBatchWordSelectionStep(context, provider);
      case CreationStep.templateSelection:
        return _buildTemplateSelectionStep(context, provider);
      case CreationStep.editing:
        return _buildEditingStep(context, provider);
      case CreationStep.completed:
        return _buildCompletedStep(context, provider);
    }
  }

  Widget _buildBatchWordSelectionStep(BuildContext context, PoetryCreationProvider provider) {
    if (_wordGroups.any((group) => group.isEmpty)) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    return Column(
      children: [
        Text(
          '각 그룹에서 하나씩 선택하고 제출하세요',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        
        // 선택된 단어 미리보기
        if (_selectedWords.any((word) => word != null))
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  Text(
                    '선택된 단어:',
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    children: _selectedWords
                        .where((word) => word != null)
                        .map<Widget>((word) => Chip(
                              label: Text(word!.text),
                              backgroundColor: Theme.of(context)
                                  .colorScheme
                                  .primaryContainer,
                            ))
                        .toList(),
                  ),
                ],
              ),
            ),
          ),
        
        const SizedBox(height: 16),
        
        // 단어 그룹들
        Expanded(
          child: ListView.builder(
            itemCount: 3,
            itemBuilder: (context, groupIndex) {
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '그룹 ${groupIndex + 1}',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Column(
                        children: _wordGroups[groupIndex].map<Widget>((word) {
                          return RadioListTile<Word>(
                            title: Text(word.text),
                            subtitle: Text('카테고리: ${word.category}'),
                            value: word,
                            groupValue: _selectedWords[groupIndex],
                            onChanged: (value) => _onWordSelected(groupIndex, value!),
                            dense: true,
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        
        const SizedBox(height: 16),
        
        // 제출 버튼
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _allWordsSelected && !provider.isLoading ? _submitWords : null,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: provider.isLoading
                ? const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      SizedBox(width: 8),
                      Text('처리 중...'),
                    ],
                  )
                : const Text(
                    '제출',
                    style: TextStyle(fontSize: 18),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildTemplateSelectionStep(BuildContext context, PoetryCreationProvider provider) {
    return PoetryTemplateSelectionWidget(
      templates: provider.generatedTemplates,
      onTemplateSelected: provider.selectTemplate,
      isLoading: provider.isLoading,
    );
  }

  Widget _buildEditingStep(BuildContext context, PoetryCreationProvider provider) {
    if (provider.editingPoetry == null) {
      return const Center(child: Text('편집할 시가 없습니다.'));
    }

    return PoetryEditorWidget(
      poetry: provider.editingPoetry!,
      onPoetryChanged: provider.updatePoetryContent,
      onSave: provider.savePoetry,
      isLoading: provider.isLoading,
    );
  }

  Widget _buildCompletedStep(BuildContext context, PoetryCreationProvider provider) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.check_circle,
            size: 80,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 16),
          Text(
            '시가 성공적으로 저장되었습니다!',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                // 상태 초기화
                setState(() {
                  _selectedWords.fillRange(0, 3, null);
                  _isInitialized = false;
                });
                provider.startNewCreation();
                _loadWordGroups();
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text(
                '새로운 시 창작하기',
                style: TextStyle(fontSize: 18),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
