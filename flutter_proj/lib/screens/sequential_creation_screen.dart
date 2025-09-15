import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/poetry_creation_provider.dart';
import '../widgets/word_selection_card.dart';
import '../widgets/poetry_template_card.dart';
import '../widgets/poetry_editor_card.dart';

class SequentialCreationScreen extends ConsumerWidget {
  const SequentialCreationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(poetryCreationProvider);
    final notifier = ref.read(poetryCreationProvider.notifier);

    return _buildMainContent(context, state, notifier);
  }

  Widget _buildProgressIndicator(BuildContext context, PoetryCreationState state) {
    final int currentStep = state.selectedWords.length;
    final String stepText = '단어 선택 (${state.selectedWords.length}/3)';

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: 36,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: currentStep / 3,
                      minHeight: 36,
                      backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                  Text(
                    stepText,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onPrimaryContainer,
                        ) ??
                        TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onPrimaryContainer,
                        ),
                  ),
                ],
              ),
            ),
            if (state.selectedWords.isNotEmpty) ...[
              const SizedBox(height: 8),
              SizedBox(
                height: 36,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: state.selectedWords.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 6),
                  itemBuilder: (context, index) {
                    final word = state.selectedWords[index];
                    return Chip(
                      label: Text(word.text),
                      backgroundColor:
                          Theme.of(context).colorScheme.secondaryContainer,
                      labelStyle: const TextStyle(fontWeight: FontWeight.w500),
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildErrorMessage(BuildContext context, PoetryCreationState state, PoetryCreationNotifier notifier) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            Icons.error_outline,
            color: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              state.errorMessage!,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onErrorContainer,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          IconButton(
            onPressed: notifier.clearError,
            icon: const Icon(Icons.close),
            iconSize: 20,
          ),
        ],
      ),
    );
  }

  Widget _buildMainContent(BuildContext context, PoetryCreationState state, PoetryCreationNotifier notifier) {
    switch (state.currentStep) {
      case CreationStep.wordSelection:
        return _buildWordSelectionStep(context, state, notifier);
      case CreationStep.templateSelection:
        return _buildTemplateSelectionStep(context, state, notifier);
      case CreationStep.editing:
        return _buildEditingStep(context, state, notifier);
      case CreationStep.completed:
        return _buildCompletedStep(context, state, notifier);
    }
  }

  Widget _buildWordSelectionStep(BuildContext context, PoetryCreationState state, PoetryCreationNotifier notifier) {
    String title;
    if (state.selectedWords.isEmpty) {
      title = '첫 번째 단어를 선택하세요';
    } else if (state.selectedWords.length == 1) {
      title = '두 번째 단어를 선택하세요';
    } else {
      title = '세 번째 단어를 선택하세요';
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // 진행 상태 표시
          _buildProgressIndicator(context, state),
          const SizedBox(height: 16),
          
          // 에러 메시지 표시
          if (state.errorMessage != null)
            _buildErrorMessage(context, state, notifier),
          
          // 단어 선택 카드
          Expanded(
            child: WordSelectionCard(
              words: state.currentWords,
              onWordSelected: notifier.selectWordSequentially,
              isLoading: state.isLoading,
              title: title,
              onRefresh: state.currentWords.isEmpty ? null : notifier.loadRandomWords,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTemplateSelectionStep(BuildContext context, PoetryCreationState state, PoetryCreationNotifier notifier) {
    if (state.isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text(
              'AI가 시를 창작하고 있습니다...',
              style: TextStyle(fontSize: 16),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // 헤더
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          child: Text(
            '마음에 드는 시를 선택하세요',
            style: Theme.of(context).textTheme.headlineLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        
        // 시 목록 (스크롤 가능)
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: state.generatedTemplates.length,
            itemBuilder: (context, index) {
              final template = state.generatedTemplates[index];
              return PoetryTemplateCard(
                template: template,
                onEdit: () => notifier.selectTemplate(template),
                onSave: () async {
                  notifier.selectTemplate(template);
                  // 잠깐 기다린 후 자동 저장
                  await Future.delayed(const Duration(milliseconds: 100));
                  notifier.savePoetry();
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildEditingStep(BuildContext context, PoetryCreationState state, PoetryCreationNotifier notifier) {
    if (state.editingPoetry == null) {
      return const Center(child: Text('편집할 시가 없습니다.'));
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: PoetryEditorCard(
        poetry: state.editingPoetry!,
        onPoetryChanged: notifier.updatePoetryContent,
        onSave: notifier.savePoetry,
        isLoading: state.isLoading,
      ),
    );
  }

  Widget _buildCompletedStep(BuildContext context, PoetryCreationState state, PoetryCreationNotifier notifier) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.check_circle,
                size: 80,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 32),
            Text(
              '축하합니다! 🎉',
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              '시가 성공적으로 저장되었습니다',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: notifier.startNewCreation,
                icon: const Icon(Icons.create),
                label: const Text(
                  '새로운 시 창작하기',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
