import 'package:flutter/material.dart';

/// 재사용 가능한 선택 카드 위젯
/// 단어 선택, 설정 선택 등에서 공통으로 사용
class SelectionCard<T> extends StatelessWidget {
  final List<T> items;
  final Function(T) onItemSelected;
  final bool isLoading;
  final String title;
  final VoidCallback? onRefresh;
  final bool isGenerating;
  final String loadingText;
  final String generatingText;
  final String Function(T) getDisplayText;
  final String? Function(T)? getSubText;

  const SelectionCard({
    super.key,
    required this.items,
    required this.onItemSelected,
    required this.getDisplayText,
    this.isLoading = false,
    this.title = '선택하세요',
    this.onRefresh,
    this.isGenerating = false,
    this.loadingText = '불러오는 중...',
    this.generatingText = '생성하는 중...',
    this.getSubText,
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
                    isGenerating ? generatingText : title,
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
                if (onRefresh != null && !isGenerating)
                  IconButton.filledTonal(
                    onPressed: onRefresh,
                    icon: const Icon(Icons.refresh),
                    tooltip: '다시 불러오기',
                  ),
              ],
            ),
            const SizedBox(height: 20),
            Expanded(
              child: isGenerating
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const CircularProgressIndicator(),
                          const SizedBox(height: 16),
                          Text(generatingText),
                        ],
                      ),
                    )
                  : isLoading
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const CircularProgressIndicator(),
                              const SizedBox(height: 16),
                              Text(loadingText),
                            ],
                          ),
                        )
                      : SingleChildScrollView(
                          child: Wrap(
                            spacing: 12,
                            runSpacing: 12,
                            alignment: WrapAlignment.center,
                            children: items
                                .map(
                                  (item) => _SelectionChip<T>(
                                    item: item,
                                    getDisplayText: getDisplayText,
                                    getSubText: getSubText,
                                    onTap: () => onItemSelected(item),
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

class _SelectionChip<T> extends StatefulWidget {
  final T item;
  final String Function(T) getDisplayText;
  final String? Function(T)? getSubText;
  final VoidCallback onTap;

  const _SelectionChip({
    required this.item,
    required this.getDisplayText,
    required this.onTap,
    this.getSubText,
  });

  @override
  State<_SelectionChip<T>> createState() => _SelectionChipState<T>();
}

class _SelectionChipState<T> extends State<_SelectionChip<T>>
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
    final subText = widget.getSubText?.call(widget.item);

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
                Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.7),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.getDisplayText(widget.item),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
                textAlign: TextAlign.center,
              ),
              if (subText != null) ...[
                const SizedBox(height: 2),
                Text(
                  subText,
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context)
                        .colorScheme
                        .onPrimaryContainer
                        .withValues(alpha: 0.7),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}