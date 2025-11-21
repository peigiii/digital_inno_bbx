import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../widgets/bbx_chip.dart';
import '../../widgets/bbx_empty_state.dart';
import '../../widgets/bbx_button.dart';
import '../../utils/responsive.dart';

class BBXNewSearchScreen extends StatefulWidget {
  const BBXNewSearchScreen({super.key});

  @override
  State<BBXNewSearchScreen> createState() => _BBXNewSearchScreenState();
}

class _BBXNewSearchScreenState extends State<BBXNewSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocus = FocusNode();
  bool _showResults = false;
  List<String> _searchHistory = ['PET Plastic', 'Scrap Metal', 'Cardboard'];
  final List<String> _hotSearches = [
    'Plastic',
    'Scrap Metal',
    'Cardboard',
    'E-Waste',
    'Glass',
    'Paper',
  ];

  @override
  void initState() {
    super.initState();
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
            _buildSearchBar(),

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
                hintText: 'Search waste types, companies...',
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
              // Filter
            },
            size: 40,
          ),
        ],
      ),
    );
  }

  Widget _buildSearchSuggestions() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.spacing16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Popular Searches', style: AppTheme.heading4),
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

          if (_searchHistory.isNotEmpty) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Search History', style: AppTheme.heading4),
                BBXTextButton(
                  text: 'Clear',
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

  Widget _buildSearchResults() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(AppTheme.spacing16),
          child: Row(
            children: [
              const Text('Found 0 results', style: AppTheme.body2),
              const Spacer(),
              DropdownButton<String>(
                value: 'Newest',
                underline: const SizedBox(),
                items: ['Newest', 'Price: Low to High', 'Price: High to Low']
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (value) {},
              ),
            ],
          ),
        ),

        Expanded(
          child: BBXEmptyState.noSearchResults(
            buttonText: 'Clear Filters',
            onButtonPressed: () {
              setState(() {
                _showResults = false;
                _searchController.clear();
              });
            },
          ),
        ),
      ],
    );
  }
}
