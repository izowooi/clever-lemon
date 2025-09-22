import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/poem_settings.dart';
import '../providers/poem_settings_provider.dart';

class PoemSettingsScreen extends ConsumerWidget {
  const PoemSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(poemSettingsProvider);
    final configAsync = ref.watch(poemSettingsConfigProvider);
    final notifier = ref.read(poemSettingsProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('시 설정'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          TextButton(
            onPressed: () => notifier.resetToDefaults(),
            child: const Text('기본값 복원'),
          ),
        ],
      ),
      body: configAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text('설정을 불러오는데 실패했습니다\n$error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.refresh(poemSettingsConfigProvider),
                child: const Text('다시 시도'),
              ),
            ],
          ),
        ),
        data: (config) => SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSettingCard(
                context,
                title: '시 스타일',
                subtitle: '시의 분위기와 톤을 결정합니다',
                child: _buildStyleDropdown(
                  context,
                  value: settings.style,
                  items: config.styles,
                  onChanged: notifier.updateStyle,
                ),
              ),
              const SizedBox(height: 16),
              _buildSettingCard(
                context,
                title: '작가 스타일',
                subtitle: '참고할 시인의 문체를 선택합니다',
                child: _buildAuthorStyleDropdown(
                  context,
                  value: settings.authorStyle,
                  items: config.authorStyles,
                  onChanged: notifier.updateAuthorStyle,
                ),
              ),
              const SizedBox(height: 16),
              _buildSettingCard(
                context,
                title: '시 길이',
                subtitle: '생성될 시의 행 수를 설정합니다',
                child: _buildLengthSelector(
                  context,
                  value: settings.length,
                  items: config.lengths,
                  onChanged: notifier.updateLength,
                ),
              ),
              const SizedBox(height: 24),
              _buildCurrentSettingsCard(context, settings),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSettingCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required Widget child,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }

  Widget _buildStyleDropdown(
    BuildContext context, {
    required String value,
    required List<String> items,
    required Function(String) onChanged,
  }) {
    return DropdownButtonFormField<String>(
      initialValue: items.contains(value) ? value : null,
      decoration: const InputDecoration(
        border: OutlineInputBorder(),
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      items: items.map((style) {
        return DropdownMenuItem(
          value: style,
          child: Text(style),
        );
      }).toList(),
      onChanged: (newValue) {
        if (newValue != null) {
          onChanged(newValue);
        }
      },
    );
  }

  Widget _buildAuthorStyleDropdown(
    BuildContext context, {
    required String value,
    required List<String> items,
    required Function(String) onChanged,
  }) {
    return DropdownButtonFormField<String>(
      initialValue: items.contains(value) ? value : null,
      decoration: const InputDecoration(
        border: OutlineInputBorder(),
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      items: items.map((author) {
        return DropdownMenuItem(
          value: author,
          child: Text(author),
        );
      }).toList(),
      onChanged: (newValue) {
        if (newValue != null) {
          onChanged(newValue);
        }
      },
    );
  }

  Widget _buildLengthSelector(
    BuildContext context, {
    required int value,
    required List<int> items,
    required Function(int) onChanged,
  }) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: items.map((length) {
        final isSelected = length == value;
        return FilterChip(
          label: Text(_getLengthDisplayText(length)),
          selected: isSelected,
          onSelected: (selected) {
            if (selected) {
              onChanged(length);
            }
          },
          selectedColor: Theme.of(context).colorScheme.primaryContainer,
          checkmarkColor: Theme.of(context).colorScheme.onPrimaryContainer,
        );
      }).toList(),
    );
  }

  Widget _buildCurrentSettingsCard(BuildContext context, PoemSettings settings) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '현재 설정',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildSettingChip(context, '스타일', settings.style),
                _buildSettingChip(context, '작가', settings.authorStyle),
                _buildSettingChip(context, '길이', _getLengthDisplayText(settings.length)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingChip(BuildContext context, String label, String value) {
    return Chip(
      label: Text('$label: $value'),
      backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      labelStyle: TextStyle(
        color: Theme.of(context).colorScheme.onPrimaryContainer,
        fontSize: 12,
      ),
    );
  }

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