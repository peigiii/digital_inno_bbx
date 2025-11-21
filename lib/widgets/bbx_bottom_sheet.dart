import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class BBXBottomSheet extends StatelessWidget {
  final String? title;
  final Widget child;
  final double? height;
  final bool showHandle;
  final bool showCloseButton;
  final VoidCallback? onClose;

  const BBXBottomSheet({
    super.key,
    this.title,
    required this.child,
    this.height,
    this.showHandle = true,
    this.showCloseButton = true,
    this.onClose,
  });

  static Future<T?> show<T>({
    required BuildContext context,
    String? title,
    required Widget child,
    double? height,
    bool showHandle = true,
    bool showCloseButton = true,
    bool isDismissible = true,
    bool enableDrag = true,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      isDismissible: isDismissible,
      enableDrag: enableDrag,
      backgroundColor: Colors.transparent,
      builder: (context) => BBXBottomSheet(
        title: title,
        height: height,
        showHandle: showHandle,
        showCloseButton: showCloseButton,
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final maxHeight = MediaQuery.of(context).size.height * 0.9;

    return Container(
      constraints: BoxConstraints(
        maxHeight: height ?? maxHeight,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(AppTheme.radiusXLarge),
          topRight: Radius.circular(AppTheme.radiusXLarge),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
                    if (showHandle)
            Container(
              margin: const EdgeInsets.only(top: AppTheme.spacing12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.neutral400,
                borderRadius: BorderRadius.circular(AppTheme.radiusFull),
              ),
            ),

                    if (title != null)
            Container(
              padding: const EdgeInsets.all(AppTheme.spacing16),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      title!,
                      style: AppTheme.heading2,
                    ),
                  ),
                  if (showCloseButton)
                    IconButton(
                      onPressed: onClose ?? () => Navigator.pop(context),
                      icon: const Icon(Icons.close_rounded),
                      color: AppTheme.neutral600,
                    ),
                ],
              ),
            ),

                    Flexible(
            child: child,
          ),
        ],
      ),
    );
  }
}

class BBXFilterBottomSheet extends StatelessWidget {
  final List<Widget> filters;
  final VoidCallback onReset;
  final VoidCallback onApply;

  const BBXFilterBottomSheet({
    super.key,
    required this.filters,
    required this.onReset,
    required this.onApply,
  });

  static Future<Map<String, dynamic>?> show({
    required BuildContext context,
    required List<Widget> filters,
    required VoidCallback onReset,
  }) async {
    return BBXBottomSheet.show<Map<String, dynamic>>(
      context: context,
      title: '筛选条?,
      height: MediaQuery.of(context).size.height * 0.8,
      child: BBXFilterBottomSheet(
        filters: filters,
        onReset: onReset,
        onApply: () {
          Navigator.pop(context, {});
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
                Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppTheme.spacing16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: filters,
            ),
          ),
        ),

                Container(
          padding: const EdgeInsets.all(AppTheme.spacing16),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(
              top: BorderSide(
                color: AppTheme.neutral300,
                width: 1,
              ),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onReset,
                  child: const Text('重置'),
                ),
              ),
              const SizedBox(width: AppTheme.spacing12),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: onApply,
                  child: const Text('应用筛?),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
