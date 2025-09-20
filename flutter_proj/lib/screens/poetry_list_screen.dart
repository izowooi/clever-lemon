import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import '../providers/poetry_list_provider.dart';
import '../models/poetry.dart';

class PoetryListScreen extends ConsumerStatefulWidget {
  const PoetryListScreen({super.key});

  @override
  ConsumerState<PoetryListScreen> createState() => _PoetryListScreenState();
}

class _PoetryListScreenState extends ConsumerState<PoetryListScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final poetryListState = ref.watch(poetryListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('작품 목록'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: '키워드로 검색...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          ref.read(poetryListProvider.notifier).loadPoetries();
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey[100],
              ),
              onChanged: (value) {
                setState(() {});
                if (value.trim().isEmpty) {
                  ref.read(poetryListProvider.notifier).loadPoetries();
                } else {
                  ref.read(poetryListProvider.notifier).searchPoetries(value);
                }
              },
            ),
          ),
        ),
      ),
      body: _buildBody(poetryListState),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          ref.read(poetryListProvider.notifier).loadPoetries();
        },
        child: const Icon(Icons.refresh),
      ),
    );
  }

  Widget _buildBody(PoetryListState state) {
    if (state.isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (state.errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            Text(
              state.errorMessage!,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.red,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                ref.read(poetryListProvider.notifier).clearError();
                ref.read(poetryListProvider.notifier).loadPoetries();
              },
              child: const Text('다시 시도'),
            ),
          ],
        ),
      );
    }

    if (state.poetries.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.library_books,
              size: 80,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Text(
              '아직 작성한 시가 없습니다',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
            SizedBox(height: 8),
            Text(
              '새로운 시를 작성해보세요!',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: state.poetries.length,
      itemBuilder: (context, index) {
        final poetry = state.poetries[index];
        return _buildPoetryCard(poetry);
      },
    );
  }

  Widget _buildPoetryCard(Poetry poetry) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showPoetryDetail(poetry),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      poetry.title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'delete') {
                        _confirmDelete(poetry);
                      } else if (value == 'share') {
                        _sharePoetry(poetry);
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'share',
                        child: Row(
                          children: [
                            Icon(Icons.share),
                            SizedBox(width: 8),
                            Text('공유하기'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, color: Colors.red),
                            SizedBox(width: 8),
                            Text('삭제'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                poetry.content,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[700],
                  height: 1.4,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  if (poetry.keywords.isNotEmpty) ...[
                    Expanded(
                      child: Wrap(
                        spacing: 4,
                        children: poetry.keywords.take(3).map((keyword) {
                          return Chip(
                            label: Text(
                              keyword,
                              style: const TextStyle(fontSize: 12),
                            ),
                            backgroundColor: Colors.blue[50],
                            labelPadding: const EdgeInsets.symmetric(horizontal: 4),
                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                  Text(
                    _formatDate(poetry.createdAt),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showPoetryDetail(Poetry poetry) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400, maxHeight: 600),
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      poetry.title,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Flexible(
                child: SingleChildScrollView(
                  child: Text(
                    poetry.content,
                    style: const TextStyle(
                      fontSize: 16,
                      height: 1.6,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              if (poetry.keywords.isNotEmpty) ...[
                const Text(
                  '키워드',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: poetry.keywords.map((keyword) {
                    return Chip(
                      label: Text(keyword),
                      backgroundColor: Colors.blue[50],
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
              ],
              Text(
                '작성일: ${_formatDate(poetry.createdAt)}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmDelete(Poetry poetry) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('시 삭제'),
        content: Text('\'${poetry.title}\'을(를) 삭제하시겠습니까?\n이 작업은 되돌릴 수 없습니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              ref.read(poetryListProvider.notifier).deletePoetry(poetry.id);
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('삭제'),
          ),
        ],
      ),
    );
  }

  Future<void> _sharePoetry(Poetry poetry) async {
    final fullText = '${poetry.title}\n\n${poetry.content}';

    try {
      await SharePlus.instance.share(ShareParams(
        text: fullText,
        subject: poetry.title,
      ));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('공유에 실패했습니다: $e'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  String _formatDate(DateTime date) {
    return '${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')}';
  }
}
