import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/generic_creation_provider.dart';
import '../providers/generic_settings_provider.dart';
import '../widgets/selection_card.dart';
import '../widgets/poetry_template_card.dart';
import '../models/word.dart';

class GenericCreationScreen extends ConsumerWidget {
  final CreationType creationType;

  const GenericCreationScreen({
    super.key,
    required this.creationType,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // creationType에 따라 적절한 provider 선택
    final provider = creationType == CreationType.poetry
        ? poetryCreationProvider
        : dailyVerseCreationProvider;

    final state = ref.watch(provider);
    final notifier = ref.read(provider.notifier);
    final uiTextsAsync = ref.watch(getUITextsProvider(creationType));

    return uiTextsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(child: Text('UI 텍스트 로딩 실패: $error')),
      data: (uiTexts) => _buildMainContent(context, state, notifier, uiTexts),
    );
  }

  Widget _buildProgressIndicator(BuildContext context, GenericCreationState state, GenericUITexts uiTexts) {
    final int currentWordStep = 4 + state.selectedWords.length; // 4, 5, 6단계
    return _buildProgressIndicatorForSettings(context, currentWordStep, 6, state, uiTexts);
  }

  Widget _buildErrorMessage(BuildContext context, GenericCreationState state, GenericCreationNotifier notifier) {
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

  Widget _buildMainContent(BuildContext context, GenericCreationState state, GenericCreationNotifier notifier, GenericUITexts uiTexts) {
    switch (state.currentStep) {
      case CreationStep.styleSelection:
        return _buildStyleSelectionStep(context, state, notifier, uiTexts);
      case CreationStep.authorStyleSelection:
        return _buildAuthorStyleSelectionStep(context, state, notifier, uiTexts);
      case CreationStep.lengthSelection:
        return _buildLengthSelectionStep(context, state, notifier, uiTexts);
      case CreationStep.wordSelection:
        return _buildWordSelectionStep(context, state, notifier, uiTexts);
      case CreationStep.templateSelection:
        return _buildTemplateSelectionStep(context, state, notifier, uiTexts);
    }
  }

  Widget _buildWordSelectionStep(BuildContext context, GenericCreationState state, GenericCreationNotifier notifier, GenericUITexts uiTexts) {
    String title;
    if (state.selectedWords.isEmpty) {
      title = uiTexts.selectWord1;
    } else if (state.selectedWords.length == 1) {
      title = uiTexts.selectWord2;
    } else {
      title = uiTexts.selectWord3;
    }

    final isGeneratingResult = state.selectedWords.length == 3 && state.isLoading;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // 진행 상태 표시
          _buildProgressIndicator(context, state, uiTexts),
          const SizedBox(height: 16),

          // 뒤로가기 버튼 (마지막 단어 생성 중이 아닐 때만 표시)
          if (notifier.canGoBack() && !isGeneratingResult)
            _buildBackButton(context, notifier, uiTexts),

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
              isGenerating: isGeneratingResult,
              generatingText: uiTexts.aiGenerating,
              loadingText: uiTexts.loading,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTemplateSelectionStep(BuildContext context, GenericCreationState state, GenericCreationNotifier notifier, GenericUITexts uiTexts) {
    if (state.isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              uiTexts.aiGenerating,
              style: const TextStyle(fontSize: 16),
            ),
          ],
        ),
      );
    }

    // 결과물이 생성되고 저장된 후 완료 화면 표시
    if (state.generatedTemplates.isNotEmpty) {
      return _buildCompletedView(context, state, notifier, uiTexts);
    }

    return Center(
      child: Text(uiTexts.aiGenerating),
    );
  }

  Widget _buildCompletedView(BuildContext context, GenericCreationState state, GenericCreationNotifier notifier, GenericUITexts uiTexts) {
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: state.generatedTemplates.length + 2, // 축하 카드(처음) + 결과물들 + 축하 카드(끝)
            itemBuilder: (context, index) {
              // 첫 번째 인덱스는 축하 카드
              if (index == 0) {
                return _buildCongratulationsCard(context, state, notifier, uiTexts);
              }

              // 마지막 인덱스는 축하 카드
              if (index == state.generatedTemplates.length + 1) {
                return _buildCongratulationsCard(context, state, notifier, uiTexts);
              }

              // 결과물 템플릿 카드들
              final template = state.generatedTemplates[index - 1];
              return PoetryTemplateCard(
                template: template,
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCongratulationsCard(BuildContext context, GenericCreationState state, GenericCreationNotifier notifier, GenericUITexts uiTexts) {
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
              uiTexts.congratulations,
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              '${state.generatedTemplates.length}${uiTexts.successMessage}',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              uiTexts.successDetail,
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
                label: Text(
                  uiTexts.newCreation,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
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

  /// 스타일 선택 단계
  Widget _buildStyleSelectionStep(BuildContext context, GenericCreationState state, GenericCreationNotifier notifier, GenericUITexts uiTexts) {
    return Consumer(
      builder: (context, ref, child) {
        final configAsync = ref.watch(getSettingsConfigProvider(creationType));

        return configAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => _buildErrorWidget(context, error.toString()),
          data: (config) => Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                _buildProgressIndicatorForSettings(context, 1, 6, state, uiTexts),
                const SizedBox(height: 16),

                Expanded(
                  child: SelectionCard<String>(
                    items: config.styles,
                    onItemSelected: notifier.selectStyle,
                    getDisplayText: (style) => style,
                    title: uiTexts.selectStyle,
                    isLoading: false,
                    loadingText: uiTexts.loading,
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
  Widget _buildAuthorStyleSelectionStep(BuildContext context, GenericCreationState state, GenericCreationNotifier notifier, GenericUITexts uiTexts) {
    return Consumer(
      builder: (context, ref, child) {
        final configAsync = ref.watch(getSettingsConfigProvider(creationType));

        return configAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => _buildErrorWidget(context, error.toString()),
          data: (config) => Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                _buildProgressIndicatorForSettings(context, 2, 6, state, uiTexts),
                const SizedBox(height: 16),

                // 뒤로가기 버튼
                if (notifier.canGoBack())
                  _buildBackButton(context, notifier, uiTexts),

                Expanded(
                  child: SelectionCard<String>(
                    items: config.authorStyles,
                    onItemSelected: notifier.selectAuthorStyle,
                    getDisplayText: (style) => style,
                    title: uiTexts.selectAuthorStyle,
                    isLoading: false,
                    loadingText: uiTexts.loading,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// 길이 선택 단계
  Widget _buildLengthSelectionStep(BuildContext context, GenericCreationState state, GenericCreationNotifier notifier, GenericUITexts uiTexts) {
    return Consumer(
      builder: (context, ref, child) {
        final configAsync = ref.watch(getSettingsConfigProvider(creationType));

        return configAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => _buildErrorWidget(context, error.toString()),
          data: (config) => Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                _buildProgressIndicatorForSettings(context, 3, 6, state, uiTexts),
                const SizedBox(height: 16),

                // 뒤로가기 버튼
                if (notifier.canGoBack())
                  _buildBackButton(context, notifier, uiTexts),

                Expanded(
                  child: SelectionCard<int>(
                    items: config.lengths,
                    onItemSelected: notifier.selectLength,
                    getDisplayText: (length) => _getLengthDisplayText(length),
                    title: uiTexts.selectLength,
                    isLoading: false,
                    loadingText: uiTexts.loading,
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
  Widget _buildProgressIndicatorForSettings(BuildContext context, int currentStep, int totalSteps, GenericCreationState state, GenericUITexts uiTexts) {
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
                    _getStepTitle(currentStep, uiTexts),
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

  /// 뒤로가기 버튼
  Widget _buildBackButton(BuildContext context, GenericCreationNotifier notifier, GenericUITexts uiTexts) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      child: OutlinedButton.icon(
        onPressed: notifier.goToPreviousStep,
        icon: const Icon(Icons.arrow_back),
        label: Text(
          uiTexts.backButton,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
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
  String _getStepTitle(int step, GenericUITexts uiTexts) {
    switch (step) {
      case 1:
        return uiTexts.stepTitle1;
      case 2:
        return uiTexts.stepTitle2;
      case 3:
        return uiTexts.stepTitle3;
      case 4:
        return uiTexts.stepTitle4;
      case 5:
        return uiTexts.stepTitle5;
      case 6:
        return uiTexts.stepTitle6;
      default:
        return '진행 중';
    }
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