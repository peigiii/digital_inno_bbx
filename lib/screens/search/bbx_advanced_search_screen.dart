import 'package:flutter/material.dart';
import '../../models/listing_model.dart';
import '../../services/search_service.dart';
import '../../utils/app_constants.dart';

/// 高级搜索页面
class BBXAdvancedSearchScreen extends StatefulWidget {
  const BBXAdvancedSearchScreen({super.key});

  @override
  State<BBXAdvancedSearchScreen> createState() => _BBXAdvancedSearchScreenState();
}

class _BBXAdvancedSearchScreenState extends State<BBXAdvancedSearchScreen> {
  final _searchService = SearchService();
  final _keywordController = TextEditingController();

  // 筛选条�?
  final Set<String> _selectedWasteTypes = {};
  RangeValues _priceRange = const RangeValues(0, 1000);
  RangeValues _quantityRange = const RangeValues(0, 100);
  double _minRating = 0;
  bool _verifiedOnly = false;
  String _sortBy = 'date';
  bool _ascending = false;

  // 搜索结果
  List<ListingModel> _results = [];
  bool _isSearching = false;
  bool _hasSearched = false;

  @override
  void dispose() {
    _keywordController.dispose();
    super.dispose();
  }

  /// 执行搜索
  Future<void> _performSearch() async {
    setState(() {
      _isSearching = true;
    });

    try {
      final results = await _searchService.advancedSearch(
        keyword: _keywordController.text.trim().isEmpty ? null : _keywordController.text.trim(),
        wasteTypes: _selectedWasteTypes.isEmpty ? null : _selectedWasteTypes.toList(),
        minPrice: _priceRange.start > 0 ? _priceRange.start : null,
        maxPrice: _priceRange.end < 1000 ? _priceRange.end : null,
        minQuantity: _quantityRange.start > 0 ? _quantityRange.start : null,
        maxQuantity: _quantityRange.end < 100 ? _quantityRange.end : null,
        minRating: _minRating > 0 ? _minRating : null,
        verifiedOnly: _verifiedOnly,
        sortBy: _sortBy,
        ascending: _ascending,
      );

      setState(() {
        _results = results;
        _hasSearched = true;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('搜索失败�?e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSearching = false;
        });
      }
    }
  }

  /// 重置筛选条�?
  void _resetFilters() {
    setState(() {
      _keywordController.clear();
      _selectedWasteTypes.clear();
      _priceRange = const RangeValues(0, 1000);
      _quantityRange = const RangeValues(0, 100);
      _minRating = 0;
      _verifiedOnly = false;
      _sortBy = 'date';
      _ascending = false;
      _results = [];
      _hasSearched = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('高级搜索'),
        elevation: 0,
        actions: [
          TextButton(
            onPressed: _resetFilters,
            child: const Text(
              '重置',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // 筛选条件区�?
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // 关键词输入框
                _buildKeywordField(),
                const SizedBox(height: 24),

                // 废料类型
                _buildWasteTypesSection(),
                const SizedBox(height: 24),

                // 价格范围
                _buildPriceRangeSection(),
                const SizedBox(height: 24),

                // 数量范围
                _buildQuantityRangeSection(),
                const SizedBox(height: 24),

                // 最低评�?
                _buildMinRatingSection(),
                const SizedBox(height: 24),

                // 认证筛�?
                _buildVerifiedOnlySection(),
                const SizedBox(height: 24),

                // 排序方式
                _buildSortBySection(),
                const SizedBox(height: 24),

                // 升序排列
                _buildAscendingSection(),
                const SizedBox(height: 80),
              ],
            ),
          ),

          // 搜索按钮（固定在底部�?
          _buildSearchButton(),
        ],
      ),
    );
  }

  /// 关键词输入框
  Widget _buildKeywordField() {
    return TextField(
      controller: _keywordController,
      decoration: InputDecoration(
        prefixIcon: const Icon(Icons.search),
        hintText: '输入商品名称或描�?..',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  /// 废料类型选择
  Widget _buildWasteTypesSection() {
    final wasteTypes = WasteTypeConstants.allTypes;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '废料类型',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: wasteTypes.map((type) {
            final isSelected = _selectedWasteTypes.contains(type);
            return FilterChip(
              label: Text(type),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    _selectedWasteTypes.add(type);
                  } else {
                    _selectedWasteTypes.remove(type);
                  }
                });
              },
              selectedColor: Colors.green.shade100,
              checkmarkColor: Colors.green.shade700,
            );
          }).toList(),
        ),
      ],
    );
  }

  /// 价格范围
  Widget _buildPriceRangeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '价格范围',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        Text(
          'RM ${_priceRange.start.toStringAsFixed(0)} - RM ${_priceRange.end.toStringAsFixed(0)}',
          style: TextStyle(color: Colors.grey.shade700),
        ),
        RangeSlider(
          values: _priceRange,
          min: 0,
          max: 1000,
          divisions: 20,
          labels: RangeLabels(
            'RM ${_priceRange.start.toStringAsFixed(0)}',
            'RM ${_priceRange.end.toStringAsFixed(0)}',
          ),
          onChanged: (values) {
            setState(() {
              _priceRange = values;
            });
          },
        ),
      ],
    );
  }

  /// 数量范围
  Widget _buildQuantityRangeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '数量范围',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        Text(
          '${_quantityRange.start.toStringAsFixed(0)} - ${_quantityRange.end.toStringAsFixed(0)} �?,
          style: TextStyle(color: Colors.grey.shade700),
        ),
        RangeSlider(
          values: _quantityRange,
          min: 0,
          max: 100,
          divisions: 20,
          labels: RangeLabels(
            '${_quantityRange.start.toStringAsFixed(0)} �?,
            '${_quantityRange.end.toStringAsFixed(0)} �?,
          ),
          onChanged: (values) {
            setState(() {
              _quantityRange = values;
            });
          },
        ),
      ],
    );
  }

  /// 最低评�?
  Widget _buildMinRatingSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '最低评�?,
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        Text(
          '${_minRating.toStringAsFixed(1)} 星以�?,
          style: TextStyle(color: Colors.grey.shade700),
        ),
        Slider(
          value: _minRating,
          min: 0,
          max: 5,
          divisions: 10,
          label: '${_minRating.toStringAsFixed(1)} �?,
          onChanged: (value) {
            setState(() {
              _minRating = value;
            });
          },
        ),
      ],
    );
  }

  /// 认证筛�?
  Widget _buildVerifiedOnlySection() {
    return SwitchListTile(
      title: const Text('只显示认证卖�?),
      value: _verifiedOnly,
      onChanged: (value) {
        setState(() {
          _verifiedOnly = value;
        });
      },
      contentPadding: EdgeInsets.zero,
    );
  }

  /// 排序方式
  Widget _buildSortBySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '排序方式',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          children: [
            ChoiceChip(
              label: const Text('最�?),
              selected: _sortBy == 'date',
              onSelected: (selected) {
                if (selected) {
                  setState(() {
                    _sortBy = 'date';
                  });
                }
              },
            ),
            ChoiceChip(
              label: const Text('价格'),
              selected: _sortBy == 'price',
              onSelected: (selected) {
                if (selected) {
                  setState(() {
                    _sortBy = 'price';
                  });
                }
              },
            ),
            ChoiceChip(
              label: const Text('数量'),
              selected: _sortBy == 'quantity',
              onSelected: (selected) {
                if (selected) {
                  setState(() {
                    _sortBy = 'quantity';
                  });
                }
              },
            ),
          ],
        ),
      ],
    );
  }

  /// 升序排列
  Widget _buildAscendingSection() {
    return SwitchListTile(
      title: const Text('升序排列'),
      subtitle: Text(_ascending ? '从低到高' : '从高到低'),
      value: _ascending,
      onChanged: (value) {
        setState(() {
          _ascending = value;
        });
      },
      contentPadding: EdgeInsets.zero,
    );
  }

  /// 搜索按钮
  Widget _buildSearchButton() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            offset: const Offset(0, -2),
            blurRadius: 8,
            color: Colors.black.withOpacity(0.1),
          ),
        ],
      ),
      child: SizedBox(
        width: double.infinity,
        height: 50,
        child: ElevatedButton(
          onPressed: _isSearching ? null : _performSearch,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: _isSearching
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.search, color: Colors.white),
                    const SizedBox(width: 8),
                    Text(
                      _hasSearched ? '搜索 (${_results.length} 个结�?' : '搜索',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
