import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/poetry_creation_provider.dart';
import '../providers/poem_settings_provider.dart';
import '../widgets/selection_card.dart';
import '../widgets/poetry_template_card.dart';
import '../models/word.dart';

class SequentialCreationScreen extends ConsumerWidget {
  const SequentialCreationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(poetryCreationProvider);
    final notifier = ref.read(poetryCreationProvider.notifier);

    return _buildMainContent(context, state, notifier);
  }

  Widget _buildProgressIndicator(BuildContext context, PoetryCreationState state) {
    final int currentWordStep = 4 + state.selectedWords.length; // 4, 5, 6단계

    return _buildProgressIndicatorForSettings(context, currentWordStep, 6, state);
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
      case CreationStep.styleSelection:
        return _buildStyleSelectionStep(context, state, notifier);
      case CreationStep.authorStyleSelection:
        return _buildAuthorStyleSelectionStep(context, state, notifier);
      case CreationStep.lengthSelection:
        return _buildLengthSelectionStep(context, state, notifier);
      case CreationStep.wordSelection:
        return _buildWordSelectionStep(context, state, notifier);
      case CreationStep.templateSelection:
        return _buildTemplateSelectionStep(context, state, notifier);
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

          // 뒤로가기 버튼
          if (notifier.canGoBack())
            _buildBackButton(context, notifier),

          // 에러 메시지 표시
          if (state.errorMessage != null)
            _buildErrorMessage(context, state, notifier),

          // 단어 선택 카드
          Expanded(
            child: SelectionCard<Word>(
              items: state.currentWords,
              onItemSelected: notifier.selectWordSequentially,
              getDisplayText: (word) => word.text,
              getSubText: (word) => word.category,
              isLoading: state.isLoading,
              title: title,
              onRefresh: state.currentWords.isEmpty ? null : notifier.loadRandomWords,
              isGenerating: state.selectedWords.length == 3 && state.isLoading,
              generatingText: 'AI가 시를 창작하고 있습니다...',
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

    // 시가 생성되고 저장된 후 완료 화면 표시
    if (state.generatedTemplates.isNotEmpty) {
      return _buildCompletedView(context, state, notifier);
    }

    return const Center(
      child: Text('시를 생성하는 중입니다...'),
    );
  }

  Widget _buildCompletedView(BuildContext context, PoetryCreationState state, PoetryCreationNotifier notifier) {
    return Column(
      children: [
        // 뒤로가기 버튼
        if (notifier.canGoBack())
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: _buildBackButton(context, notifier),
          ),

        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: state.generatedTemplates.length + 1, // 시 4개 + 축하 카드 1개
            itemBuilder: (context, index) {
              // 마지막 인덱스는 축하 카드
              if (index == state.generatedTemplates.length) {
                return _buildCongratulationsCard(context, state, notifier);
              }

              // 시 템플릿 카드들
              final template = state.generatedTemplates[index];
              return PoetryTemplateCard(
                template: template,
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCongratulationsCard(BuildContext context, PoetryCreationState state, PoetryCreationNotifier notifier) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
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
              '${state.generatedTemplates.length}개의 시가 성공적으로 저장되었습니다',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              '위에서 방금 생성된 시들을 확인해보세요!\n작품 목록에서도 언제든 다시 볼 수 있습니다.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
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

  /// 시 스타일 선택 단계 - 단어 선택과 동일한 UI 사용
  Widget _buildStyleSelectionStep(BuildContext context, PoetryCreationState state, PoetryCreationNotifier notifier) {
    return Consumer(
      builder: (context, ref, child) {
        final configAsync = ref.watch(poemSettingsConfigProvider);

        return configAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => _buildErrorWidget(context, error.toString()),
          data: (config) => Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                _buildProgressIndicatorForSettings(context, 1, 6, state),
                const SizedBox(height: 16),

                // 뒤로가기 버튼
                if (notifier.canGoBack())
                  _buildBackButton(context, notifier),

                Expanded(
                  child: SelectionCard<String>(
                    items: config.styles,
                    onItemSelected: notifier.selectStyle,
                    getDisplayText: (style) => style,
                    title: '시 스타일을 선택하세요',
                    isLoading: false,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// 작가 스타일 선택 단계
  Widget _buildAuthorStyleSelectionStep(BuildContext context, PoetryCreationState state, PoetryCreationNotifier notifier) {
    return Consumer(
      builder: (context, ref, child) {
        final configAsync = ref.watch(poemSettingsConfigProvider);

        return configAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => _buildErrorWidget(context, error.toString()),
          data: (config) => Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                _buildProgressIndicatorForSettings(context, 2, 6, state),
                const SizedBox(height: 16),

                // 뒤로가기 버튼
                if (notifier.canGoBack())
                  _buildBackButton(context, notifier),

                Expanded(
                  child: SelectionCard<String>(
                    items: config.authorStyles,
                    onItemSelected: notifier.selectAuthorStyle,
                    getDisplayText: (style) => style,
                    title: '작가 스타일을 선택하세요',
                    isLoading: false,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// 시 길이 선택 단계
  Widget _buildLengthSelectionStep(BuildContext context, PoetryCreationState state, PoetryCreationNotifier notifier) {
    return Consumer(
      builder: (context, ref, child) {
        final configAsync = ref.watch(poemSettingsConfigProvider);

        return configAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => _buildErrorWidget(context, error.toString()),
          data: (config) => Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                _buildProgressIndicatorForSettings(context, 3, 6, state),
                const SizedBox(height: 16),

                // 뒤로가기 버튼
                if (notifier.canGoBack())
                  _buildBackButton(context, notifier),

                Expanded(
                  child: SelectionCard<int>(
                    items: config.lengths,
                    onItemSelected: notifier.selectLength,
                    getDisplayText: (length) => _getLengthDisplayText(length),
                    title: '시 길이를 선택하세요',
                    isLoading: false,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// 설정 선택용 진행률 표시기 (선택된 설정들을 단어처럼 표시)
  Widget _buildProgressIndicatorForSettings(BuildContext context, int currentStep, int totalSteps, PoetryCreationState state) {
    final selectedItems = <String>[];

    if (state.selectedStyle != null) {
      selectedItems.add(state.selectedStyle!);
    }
    if (state.selectedAuthorStyle != null) {
      selectedItems.add(state.selectedAuthorStyle!);
    }
    if (state.selectedLength != null) {
      selectedItems.add(_getLengthDisplayText(state.selectedLength!));
    }

    // 단어들도 추가
    selectedItems.addAll(state.selectedWords.map((word) => word.text));

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
                      value: currentStep / totalSteps,
                      minHeight: 36,
                      backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                  Text(
                    _getStepTitle(currentStep),
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
            if (selectedItems.isNotEmpty) ...[
              const SizedBox(height: 8),
              SizedBox(
                height: 36,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: selectedItems.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 6),
                  itemBuilder: (context, index) {
                    final item = selectedItems[index];
                    return Chip(
                      label: Text(item),
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


  /// 에러 위젯
  Widget _buildErrorWidget(BuildContext context, String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 48, color: Colors.red),
          const SizedBox(height: 16),
          Text('설정을 불러오는데 실패했습니다\n$error'),
        ],
      ),
    );
  }

  /// 단계별 제목 반환
  String _getStepTitle(int step) {
    switch (step) {
      case 1:
        return '시 스타일 선택 (1/6)';
      case 2:
        return '작가 스타일 선택 (2/6)';
      case 3:
        return '시 길이 선택 (3/6)';
      case 4:
        return '첫 번째 단어 선택 (4/6)';
      case 5:
        return '두 번째 단어 선택 (5/6)';
      case 6:
        return '세 번째 단어 선택 (6/6)';
      default:
        return '진행 중';
    }
  }

  /// 뒤로가기 버튼
  Widget _buildBackButton(BuildContext context, PoetryCreationNotifier notifier) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      child: OutlinedButton.icon(
        onPressed: notifier.goToPreviousStep,
        icon: const Icon(Icons.arrow_back),
        label: const Text(
          '이전 단계로',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          side: BorderSide(
            color: Theme.of(context).colorScheme.outline,
            width: 1.5,
          ),
        ),
      ),
    );
  }

  /// 길이 표시 텍스트 변환
  String _getLengthDisplayText(int length) {
    switch (length) {
      case 4:
        return '아주 짧게';
      case 8:
        return '짧게';
      case 12:
        return '보통';
      case 16:
        return '길게';
      case 20:
        return '아주 길게';
      default:
        return '$length행';
    }
  }

}
