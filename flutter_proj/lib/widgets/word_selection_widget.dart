import 'package:flutter/material.dart';
import '../models/word.dart';

class WordSelectionWidget extends StatelessWidget {
  final List<Word> words;
  final Function(Word) onWordSelected;
  final bool isLoading;
  final String title;

  const WordSelectionWidget({
    super.key,
    required this.words,
    required this.onWordSelected,
    this.isLoading = false,
    this.title = '단어를 선택하세요',
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            if (isLoading)
              const Center(
                child: CircularProgressIndicator(),
              )
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
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
          ],
        ),
      ),
    );
  }
}

class _WordChip extends StatelessWidget {
  final Word word;
  final VoidCallback onTap;

  const _WordChip({
    required this.word,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      label: Text(
        word.text,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
      backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      onPressed: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    );
  }
}

class BatchWordSelectionWidget extends StatefulWidget {
  final List<List<Word>> wordGroups;
  final Function(List<Word>) onWordsSelected;
  final bool isLoading;

  const BatchWordSelectionWidget({
    super.key,
    required this.wordGroups,
    required this.onWordsSelected,
    this.isLoading = false,
  });

  @override
  State<BatchWordSelectionWidget> createState() => _BatchWordSelectionWidgetState();
}

class _BatchWordSelectionWidgetState extends State<BatchWordSelectionWidget> {
  final List<Word?> selectedWords = [null, null, null];

  void _onWordSelected(int groupIndex, Word word) {
    setState(() {
      selectedWords[groupIndex] = word;
    });
    
    // 모든 단어가 선택되었는지 확인
    if (selectedWords.every((word) => word != null)) {
      widget.onWordsSelected(selectedWords.cast<Word>());
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        Text(
          '각 그룹에서 하나씩 선택하세요',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: ListView.builder(
            itemCount: widget.wordGroups.length,
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
                        children: widget.wordGroups[groupIndex].map((word) {
                          return RadioListTile<Word>(
                            title: Text(word.text),
                            subtitle: Text('카테고리: ${word.category}'),
                            value: word,
                            groupValue: selectedWords[groupIndex],
                            onChanged: (value) => _onWordSelected(groupIndex, value!),
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
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: selectedWords.every((word) => word != null)
                ? () => widget.onWordsSelected(selectedWords.cast<Word>())
                : null,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: const Text(
              '제출',
              style: TextStyle(fontSize: 18),
            ),
          ),
        ),
      ],
    );
  }
}
