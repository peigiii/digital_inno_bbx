import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class ModernSearchBar extends StatelessWidget {
  final String hintText;
  final VoidCallback? onTap;
  final VoidCallback? onFilter;
  final VoidCallback? onVoiceSearch;
  final bool showVoiceSearch;
  final bool showFilter;

  const ModernSearchBar({
    super.key,
    this.hintText = 'SearchWaste Type、Business?..',
    this.onTap,
    this.onFilter,
    this.onVoiceSearch,
    this.showVoiceSearch = false,
    this.showFilter = true,
  });

  @override
  Widget build(BuildContext context) {
    return Hero(
      tag: 'search_bar',
      child: Material(
        color: Colors.transparent,
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),               boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                const SizedBox(width: AppTheme.spacing20),
                
                                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    gradient: AppTheme.primaryGradient,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.search_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
                
                const SizedBox(width: AppTheme.spacing12),

                                Expanded(
                  child: Text(
                    hintText,
                    style: AppTheme.body1.copyWith(
                      color: AppTheme.neutral500,
                    ),
                  ),
                ),

                                if (showVoiceSearch) ...[
                  IconButton(
                    onPressed: onVoiceSearch,
                    icon: const Icon(
                      Icons.mic_rounded,
                      color: AppTheme.primary500,
                    ),
                  ),
                  const SizedBox(width: AppTheme.spacing4),
                ],

                                if (showFilter) ...[
                  IconButton(
                    onPressed: onFilter,
                    icon: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.primary50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.tune_rounded,
                        color: AppTheme.primary500,
                        size: 20,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppTheme.spacing8),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class EditableSearchBar extends StatefulWidget {
  final String? initialValue;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onClear;
  final VoidCallback? onVoiceSearch;
  final bool showVoiceSearch;
  final bool autofocus;

  const EditableSearchBar({
    super.key,
    this.initialValue,
    this.onChanged,
    this.onSubmitted,
    this.onClear,
    this.onVoiceSearch,
    this.showVoiceSearch = false,
    this.autofocus = true,
  });

  @override
  State<EditableSearchBar> createState() => _EditableSearchBarState();
}

class _EditableSearchBarState extends State<EditableSearchBar> {
  late TextEditingController _controller;
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
    _focusNode = FocusNode();
    if (widget.autofocus) {
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) {
          _focusNode.requestFocus();
        }
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          const SizedBox(width: AppTheme.spacing20),
          
                    Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.search_rounded,
              color: Colors.white,
              size: 22,
            ),
          ),
          
          const SizedBox(width: AppTheme.spacing12),

                    Expanded(
            child: TextField(
              controller: _controller,
              focusNode: _focusNode,
              decoration: InputDecoration(
                hintText: 'SearchWaste Type、Business?..',
                hintStyle: TextStyle(
                  color: AppTheme.neutral500,
                  fontSize: 16,
                ),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
              style: AppTheme.body1,
              textInputAction: TextInputAction.search,
              onChanged: widget.onChanged,
              onSubmitted: widget.onSubmitted,
            ),
          ),

                    if (_controller.text.isNotEmpty)
            IconButton(
              onPressed: () {
                _controller.clear();
                widget.onClear?.call();
                setState(() {});
              },
              icon: const Icon(
                Icons.clear_rounded,
                color: AppTheme.neutral500,
              ),
            ),

                    if (widget.showVoiceSearch)
            IconButton(
              onPressed: widget.onVoiceSearch,
              icon: const Icon(
                Icons.mic_rounded,
                color: AppTheme.primary500,
              ),
            ),

          const SizedBox(width: AppTheme.spacing8),
        ],
      ),
    );
  }
}

class SearchHistoryChip extends StatelessWidget {
  final String text;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  const SearchHistoryChip({
    super.key,
    required this.text,
    this.onTap,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.spacing12,
          vertical: AppTheme.spacing8,
        ),
        decoration: BoxDecoration(
          color: AppTheme.neutral50,
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
          border: Border.all(color: AppTheme.neutral200),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.history_rounded,
              size: 16,
              color: AppTheme.neutral500,
            ),
            const SizedBox(width: 6),
            Text(
              text,
              style: AppTheme.body2.copyWith(
                color: AppTheme.neutral700,
              ),
            ),
            if (onDelete != null) ...[
              const SizedBox(width: 6),
              GestureDetector(
                onTap: onDelete,
                child: const Icon(
                  Icons.close_rounded,
                  size: 16,
                  color: AppTheme.neutral500,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class TrendingSearchChip extends StatelessWidget {
  final String text;
  final VoidCallback? onTap;
  final bool isTrending;

  const TrendingSearchChip({
    super.key,
    required this.text,
    this.onTap,
    this.isTrending = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.spacing12,
          vertical: AppTheme.spacing8,
        ),
        decoration: BoxDecoration(
          gradient: isTrending ? AppTheme.primaryGradient : null,
          color: isTrending ? null : AppTheme.primary50,
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isTrending)
              const Icon(
                Icons.local_fire_department_rounded,
                size: 16,
                color: Colors.white,
              )
            else
              const Icon(
                Icons.trending_up_rounded,
                size: 16,
                color: AppTheme.primary500,
              ),
            const SizedBox(width: 6),
            Text(
              text,
              style: AppTheme.body2.copyWith(
                color: isTrending ? Colors.white : AppTheme.primary700,
                fontWeight: AppTheme.semibold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

