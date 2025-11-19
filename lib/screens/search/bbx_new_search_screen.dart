import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../widgets/bbx_chip.dart';
import '../../widgets/bbx_empty_state.dart';
import '../../widgets/bbx_button.dart';
import '../../utils/responsive.dart';

/// BBX 搜索页面（独立）
class BBXNewSearchScreen extends StatefulWidget {
  const BBXNewSearchScreen({super.key});

  @override
  State<BBXNewSearchScreen> createState() => _BBXNewSearchScreenState();
}

class _BBXNewSearchScreenState extends State<BBXNewSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocus = FocusNode();
  bool _showResults = false;
  List<String> _searchHistory = ['PET塑料瓶', '废铁', '纸箱'];
  final List<String> _hotSearches = [
    '塑料瓶',
    '废铁',
    '纸箱',
    '电子废料',
    '玻璃瓶',
    '废纸',
  ];

  @override
  void initState() {
    super.initState();
    // 自动聚焦
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _searchFocus.requestFocus();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  void _onSearch() {
    if (_searchController.text.isNotEmpty) {
      setState(() {
        _showResults = true;
        if (!_searchHistory.contains(_searchController.text)) {
          _searchHistory.insert(0, _searchController.text);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // 顶部搜索栏
            _buildSearchBar(),

            // 内容区域
            Expanded(
              child: _showResults
                  ? _buildSearchResults()
                  : _buildSearchSuggestions(),
            ),
          ],
        ),
      ),
    );
  }

  /// 搜索栏
  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacing16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(
            color: AppTheme.neutral300,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          BBXIconButton(
            icon: Icons.arrow_back_rounded,
            onPressed: () => Navigator.pop(context),
            size: 40,
          ),
          const SizedBox(width: AppTheme.spacing8),
          Expanded(
            child: TextField(
              controller: _searchController,
              focusNode: _searchFocus,
              onSubmitted: (_) => _onSearch(),
              decoration: InputDecoration(
                hintText: '搜索废料类型、商品...',
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                isDense: true,
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded),
                        onPressed: () {
                          setState(() {
                            _searchController.clear();
                            _showResults = false;
                          });
                        },
                      )
                    : null,
              ),
            ),
          ),
          BBXIconButton(
            icon: Icons.tune_rounded,
            onPressed: () {
              // 打开筛选抽屉
            },
            size: 40,
          ),
        ],
      ),
    );
  }

  /// 搜索建议（未输入时）
  Widget _buildSearchSuggestions() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.spacing16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 热门搜索
          const Text('热门搜索', style: AppTheme.heading4),
          const SizedBox(height: AppTheme.spacing12),
          Wrap(
            spacing: AppTheme.spacing8,
            runSpacing: AppTheme.spacing8,
            children: _hotSearches.map((search) {
              return GestureDetector(
                onTap: () {
                  _searchController.text = search;
                  _onSearch();
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.spacing16,
                    vertical: AppTheme.spacing8,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.neutral100,
                    borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                  ),
                  child: Text(
                    search,
                    style: AppTheme.body2,
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: AppTheme.spacing24),

          // 搜索历史
          if (_searchHistory.isNotEmpty) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('搜索历史', style: AppTheme.heading4),
                BBXTextButton(
                  text: '清除',
                  onPressed: () {
                    setState(() {
                      _searchHistory.clear();
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spacing12),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _searchHistory.length,
              itemBuilder: (context, index) {
                final search = _searchHistory[index];
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(
                    Icons.history_rounded,
                    color: AppTheme.neutral500,
                  ),
                  title: Text(search, style: AppTheme.body1),
                  trailing: IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () {
                      setState(() {
                        _searchHistory.removeAt(index);
                      });
                    },
                  ),
                  onTap: () {
                    _searchController.text = search;
                    _onSearch();
                  },
                );
              },
            ),
          ],
        ],
      ),
    );
  }

  /// 搜索结果
  Widget _buildSearchResults() {
    return Column(
      children: [
        // 结果统计和排序
        Container(
          padding: const EdgeInsets.all(AppTheme.spacing16),
          child: Row(
            children: [
              const Text('找到 0 个结果', style: AppTheme.body2),
              const Spacer(),
              DropdownButton<String>(
                value: '最新发布',
                underline: const SizedBox(),
                items: ['最新发布', '价格从低到高', '价格从高到低']
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (value) {},
              ),
            ],
          ),
        ),

        // 搜索结果列表
        Expanded(
          child: BBXEmptyState.noResults(
            title: '无搜索结果',
            description: '试试其他关键词',
            action: ElevatedButton(
              onPressed: () {
                setState(() {
                  _showResults = false;
                  _searchController.clear();
                });
              },
              child: const Text('清除筛选'),
            ),
          ),
        ),
      ],
    );
  }
}
