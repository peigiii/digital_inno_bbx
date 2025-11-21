import 'package:flutter/material.dart';
import '../../models/listing_model.dart';
import '../../services/search_service.dart';
import '../../utils/app_constants.dart';

/// Advanced Search Screen
class BBXAdvancedSearchScreen extends StatefulWidget {
  const BBXAdvancedSearchScreen({super.key});

  @override
  State<BBXAdvancedSearchScreen> createState() => _BBXAdvancedSearchScreenState();
}

class _BBXAdvancedSearchScreenState extends State<BBXAdvancedSearchScreen> {
  final _searchService = SearchService();
  final _keywordController = TextEditingController();

  // Filter Conditions
  final Set<String> _selectedWasteTypes = {};
  RangeValues _priceRange = const RangeValues(0, 1000);
  RangeValues _quantityRange = const RangeValues(0, 100);
  double _minRating = 0;
  bool _verifiedOnly = false;
  String _sortBy = 'date';
  bool _ascending = false;

  // Search Results
  List<ListingModel> _results = [];
  bool _isSearching = false;
  bool _hasSearched = false;

  @override
  void dispose() {
    _keywordController.dispose();
    super.dispose();
  }

  /// Perform Search
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
            content: Text('Search failed: $e'),
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

  /// Reset Filters
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
        title: const Text('Advanced Search'),
        elevation: 0,
        actions: [
          TextButton(
            onPressed: _resetFilters,
            child: const Text(
              'Reset',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter Section
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Keyword Input
                _buildKeywordField(),
                const SizedBox(height: 24),

                // Waste Type
                _buildWasteTypesSection(),
                const SizedBox(height: 24),

                // Price Range
                _buildPriceRangeSection(),
                const SizedBox(height: 24),

                // Quantity Range
                _buildQuantityRangeSection(),
                const SizedBox(height: 24),

                // Min Rating
                _buildMinRatingSection(),
                const SizedBox(height: 24),

                // Verification Filter
                _buildVerifiedOnlySection(),
                const SizedBox(height: 24),

                // Sort By
                _buildSortBySection(),
                const SizedBox(height: 24),

                // Ascending
                _buildAscendingSection(),
                const SizedBox(height: 80),
              ],
            ),
          ),

          // Search Button (Fixed at bottom)
          _buildSearchButton(),
        ],
      ),
    );
  }

  /// Keyword Input Field
  Widget _buildKeywordField() {
    return TextField(
      controller: _keywordController,
      decoration: InputDecoration(
        prefixIcon: const Icon(Icons.search),
        hintText: 'Enter keyword...',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  /// Waste Types Section
  Widget _buildWasteTypesSection() {
    final wasteTypes = WasteTypeConstants.allTypes;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Waste Type',
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

  /// Price Range Section
  Widget _buildPriceRangeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Price Range',
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

  /// Quantity Range Section
  Widget _buildQuantityRangeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quantity Range',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        Text(
          '${_quantityRange.start.toStringAsFixed(0)} - ${_quantityRange.end.toStringAsFixed(0)} tons',
          style: TextStyle(color: Colors.grey.shade700),
        ),
        RangeSlider(
          values: _quantityRange,
          min: 0,
          max: 100,
          divisions: 20,
          labels: RangeLabels(
            '${_quantityRange.start.toStringAsFixed(0)}',
            '${_quantityRange.end.toStringAsFixed(0)}',
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

  /// Min Rating Section
  Widget _buildMinRatingSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Min Rating',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        Text(
          '${_minRating.toStringAsFixed(1)} stars and up',
          style: TextStyle(color: Colors.grey.shade700),
        ),
        Slider(
          value: _minRating,
          min: 0,
          max: 5,
          divisions: 10,
          label: '${_minRating.toStringAsFixed(1)}',
          onChanged: (value) {
            setState(() {
              _minRating = value;
            });
          },
        ),
      ],
    );
  }

  /// Verified Only Section
  Widget _buildVerifiedOnlySection() {
    return SwitchListTile(
      title: const Text('Verified Sellers Only'),
      value: _verifiedOnly,
      onChanged: (value) {
        setState(() {
          _verifiedOnly = value;
        });
      },
      contentPadding: EdgeInsets.zero,
    );
  }

  /// Sort By Section
  Widget _buildSortBySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Sort By',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          children: [
            ChoiceChip(
              label: const Text('Latest'),
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
              label: const Text('Price'),
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
              label: const Text('Quantity'),
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

  /// Ascending Order Section
  Widget _buildAscendingSection() {
    return SwitchListTile(
      title: const Text('Ascending Order'),
      subtitle: Text(_ascending ? 'Low to High' : 'High to Low'),
      value: _ascending,
      onChanged: (value) {
        setState(() {
          _ascending = value;
        });
      },
      contentPadding: EdgeInsets.zero,
    );
  }

  /// Search Button
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
                      _hasSearched ? 'Show Results (${_results.length})' : 'Search',
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
