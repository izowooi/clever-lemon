import 'package:flutter/material.dart';
import '../models/word.dart';

class WordSelectionCard extends StatelessWidget {
  final List<Word> words;
  final Function(Word) onWordSelected;
  final bool isLoading;
  final String title;
  final VoidCallback? onRefresh;
  final bool isGeneratingPoetry;

  const WordSelectionCard({
    super.key,
    required this.words,
    required this.onWordSelected,
    this.isLoading = false,
    this.title = '단어를 선택하세요',
    this.onRefresh,
    this.isGeneratingPoetry = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    isGeneratingPoetry ? "시를 생성하는 중..." : title,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ) ??
                        TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                  ),
                ),
                if (onRefresh != null && !isGeneratingPoetry)
                  IconButton.filledTonal(
                    onPressed: onRefresh,
                    icon: const Icon(Icons.refresh),
                    tooltip: '다른 단어 보기',
                  ),
              ],
            ),
            const SizedBox(height: 20),
            Expanded(
              child: isGeneratingPoetry
                  ? const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 16),
                          Text('시를 생성하는 중...'),
                        ],
                      ),
                    )
                  : isLoading
                      ? const Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CircularProgressIndicator(),
                              SizedBox(height: 16),
                              Text('단어를 불러오는 중...'),
                            ],
                          ),
                        )
                      : SingleChildScrollView(
                      child: Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        alignment: WrapAlignment.center,
                        children: words
                            .map(
                              (word) => _WordChip(
                                word: word,
                                onTap: () => onWordSelected(word),
                              ),
                            )
                            .toList(),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WordChip extends StatefulWidget {
  final Word word;
  final VoidCallback onTap;

  const _WordChip({
    required this.word,
    required this.onTap,
  });

  @override
  State<_WordChip> createState() => _WordChipState();
}

class _WordChipState extends State<_WordChip>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _animationController.forward(),
      onTapUp: (_) {
        _animationController.reverse();
        widget.onTap();
      },
      onTapCancel: () => _animationController.reverse(),
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Theme.of(context).colorScheme.primaryContainer,
                Theme.of(context).colorScheme.primaryContainer.withOpacity(0.7),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.word.text,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                widget.word.category,
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context)
                      .colorScheme
                      .onPrimaryContainer
                      .withOpacity(0.7),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
