import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/poetry_creation_provider.dart';
import '../widgets/word_selection_widget.dart';
import '../widgets/poetry_template_selection_widget.dart';
import '../widgets/poetry_editor_widget.dart';

class SequentialCreationScreen extends StatelessWidget {
  const SequentialCreationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<PoetryCreationProvider>(
      builder: (context, provider, child) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // 진행 상태 표시
              _buildProgressIndicator(context, provider),
              const SizedBox(height: 16),
              
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

  Widget _buildProgressIndicator(BuildContext context, PoetryCreationProvider provider) {
    int currentStep = 0;
    String stepText = '';
    
    switch (provider.currentStep) {
      case CreationStep.wordSelection:
        currentStep = provider.selectedWords.length;
        stepText = '단어 선택 (${provider.selectedWords.length}/3)';
        break;
      case CreationStep.templateSelection:
        currentStep = 3;
        stepText = '시 템플릿 선택';
        break;
      case CreationStep.editing:
        currentStep = 4;
        stepText = '시 편집';
        break;
      case CreationStep.completed:
        currentStep = 5;
        stepText = '완료';
        break;
    }
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              stepText,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: currentStep / 5,
              backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
              valueColor: AlwaysStoppedAnimation<Color>(
                Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 8),
            if (provider.selectedWords.isNotEmpty) ...[
              const Text('선택된 단어:'),
              const SizedBox(height: 4),
              Wrap(
                spacing: 6,
                children: provider.selectedWords
                    .map(
                      (word) => Chip(
                        label: Text(word.text),
                        backgroundColor: Theme.of(context)
                            .colorScheme
                            .primaryContainer,
                      ),
                    )
                    .toList(),
              ),
            ],
          ],
        ),
      ),
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
        return _buildWordSelectionStep(context, provider);
      case CreationStep.templateSelection:
        return _buildTemplateSelectionStep(context, provider);
      case CreationStep.editing:
        return _buildEditingStep(context, provider);
      case CreationStep.completed:
        return _buildCompletedStep(context, provider);
    }
  }

  Widget _buildWordSelectionStep(BuildContext context, PoetryCreationProvider provider) {
    String title;
    if (provider.selectedWords.isEmpty) {
      title = '첫 번째 단어를 선택하세요';
    } else if (provider.selectedWords.length == 1) {
      title = '두 번째 단어를 선택하세요';
    } else {
      title = '세 번째 단어를 선택하세요';
    }

    return Column(
      children: [
        Expanded(
          child: WordSelectionWidget(
            words: provider.currentWords,
            onWordSelected: provider.selectWordSequentially,
            isLoading: provider.isLoading,
            title: title,
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: provider.currentWords.isEmpty ? null : provider.loadRandomWords,
            child: const Text('다른 단어 보기'),
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
              onPressed: provider.startNewCreation,
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
