import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/app_theme.dart';

/// 统一的文本输入框
class AppInput extends StatefulWidget {
  final TextEditingController? controller;
  final String? label;
  final String? hint;
  final String? helperText;
  final String? errorText;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final bool obscureText;
  final TextInputType? keyboardType;
  final int? maxLines;
  final int? maxLength;
  final bool showCounter;
  final bool enabled;
  final bool readOnly;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onTap;
  final FormFieldValidator<String>? validator;
  final List<TextInputFormatter>? inputFormatters;
  final FocusNode? focusNode;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;

  const AppInput({
    super.key,
    this.controller,
    this.label,
    this.hint,
    this.helperText,
    this.errorText,
    this.prefixIcon,
    this.suffixIcon,
    this.obscureText = false,
    this.keyboardType,
    this.maxLines = 1,
    this.maxLength,
    this.showCounter = false,
    this.enabled = true,
    this.readOnly = false,
    this.onChanged,
    this.onTap,
    this.validator,
    this.inputFormatters,
    this.focusNode,
    this.textInputAction,
    this.onSubmitted,
  });

  @override
  State<AppInput> createState() => _AppInputState();
}

class _AppInputState extends State<AppInput> {
  late TextEditingController _controller;
  bool _showClearButton = false;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController();
    _controller.addListener(_updateClearButton);
  }

  @override
  void dispose() {
    _controller.removeListener(_updateClearButton);
    if (widget.controller == null) {
      _controller.dispose();
    }
    super.dispose();
  }

  void _updateClearButton() {
    setState(() {
      _showClearButton = _controller.text.isNotEmpty;
    });
  }

  void _clearText() {
    _controller.clear();
    widget.onChanged?.call('');
  }

  @override
  Widget build(BuildContext context) {
    Widget? suffix = widget.suffixIcon;

    // 如果没有自定义 suffix 且文本不为空，显示清除按钮
    if (suffix == null && _showClearButton && widget.enabled && !widget.readOnly) {
      suffix = IconButton(
        icon: const Icon(Icons.clear, size: 20),
        onPressed: _clearText,
        color: AppTheme.textSecondary,
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(),
      );
    }

    return TextFormField(
      controller: _controller,
      focusNode: widget.focusNode,
      decoration: InputDecoration(
        labelText: widget.label,
        hintText: widget.hint,
        helperText: widget.helperText,
        errorText: widget.errorText,
        prefixIcon: widget.prefixIcon != null ? Icon(widget.prefixIcon) : null,
        suffixIcon: suffix != null
            ? Padding(
                padding: const EdgeInsets.only(right: 12),
                child: suffix,
              )
            : null,
        counterText: widget.showCounter ? null : '',
        filled: true,
        fillColor: widget.enabled ? AppTheme.surface : AppTheme.background,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppTheme.spacingMD,
          vertical: AppTheme.spacingMD,
        ),
        border: OutlineInputBorder(
          borderRadius: AppTheme.borderRadiusStandard,
          borderSide: const BorderSide(color: AppTheme.divider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppTheme.borderRadiusStandard,
          borderSide: const BorderSide(color: AppTheme.divider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppTheme.borderRadiusStandard,
          borderSide: const BorderSide(color: AppTheme.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: AppTheme.borderRadiusStandard,
          borderSide: const BorderSide(color: AppTheme.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: AppTheme.borderRadiusStandard,
          borderSide: const BorderSide(color: AppTheme.error, width: 2),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: AppTheme.borderRadiusStandard,
          borderSide: BorderSide(color: AppTheme.divider.withOpacity(0.5)),
        ),
      ),
      obscureText: widget.obscureText,
      keyboardType: widget.keyboardType,
      maxLines: widget.obscureText ? 1 : widget.maxLines,
      maxLength: widget.maxLength,
      enabled: widget.enabled,
      readOnly: widget.readOnly,
      onChanged: widget.onChanged,
      onTap: widget.onTap,
      validator: widget.validator,
      inputFormatters: widget.inputFormatters,
      textInputAction: widget.textInputAction,
      onFieldSubmitted: widget.onSubmitted,
      style: AppTheme.body1,
    );
  }
}

/// 密码输入框（带显示/隐藏切换）
class PasswordInput extends StatefulWidget {
  final TextEditingController? controller;
  final String? label;
  final String? hint;
  final String? errorText;
  final ValueChanged<String>? onChanged;
  final FormFieldValidator<String>? validator;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;

  const PasswordInput({
    super.key,
    this.controller,
    this.label,
    this.hint,
    this.errorText,
    this.onChanged,
    this.validator,
    this.textInputAction,
    this.onSubmitted,
  });

  @override
  State<PasswordInput> createState() => _PasswordInputState();
}

class _PasswordInputState extends State<PasswordInput> {
  bool _obscureText = true;

  void _toggleVisibility() {
    setState(() {
      _obscureText = !_obscureText;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AppInput(
      controller: widget.controller,
      label: widget.label ?? '密码',
      hint: widget.hint ?? '请输入密码',
      errorText: widget.errorText,
      prefixIcon: Icons.lock_outline,
      suffixIcon: IconButton(
        icon: Icon(
          _obscureText ? Icons.visibility_outlined : Icons.visibility_off_outlined,
          size: 20,
        ),
        onPressed: _toggleVisibility,
        color: AppTheme.textSecondary,
      ),
      obscureText: _obscureText,
      onChanged: widget.onChanged,
      validator: widget.validator,
      textInputAction: widget.textInputAction,
      onSubmitted: widget.onSubmitted,
    );
  }
}

/// 搜索输入框
class SearchInput extends StatelessWidget {
  final TextEditingController? controller;
  final String? hint;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onSearch;
  final bool autoFocus;

  const SearchInput({
    super.key,
    this.controller,
    this.hint,
    this.onChanged,
    this.onSearch,
    this.autoFocus = false,
  });

  @override
  Widget build(BuildContext context) {
    return AppInput(
      controller: controller,
      hint: hint ?? '搜索...',
      prefixIcon: Icons.search,
      keyboardType: TextInputType.text,
      textInputAction: TextInputAction.search,
      onChanged: onChanged,
      onSubmitted: onSearch != null ? (_) => onSearch!() : null,
    );
  }
}

/// 多行文本输入框
class TextAreaInput extends StatelessWidget {
  final TextEditingController? controller;
  final String? label;
  final String? hint;
  final String? errorText;
  final int minLines;
  final int maxLines;
  final int? maxLength;
  final bool showCounter;
  final ValueChanged<String>? onChanged;
  final FormFieldValidator<String>? validator;

  const TextAreaInput({
    super.key,
    this.controller,
    this.label,
    this.hint,
    this.errorText,
    this.minLines = 3,
    this.maxLines = 6,
    this.maxLength,
    this.showCounter = true,
    this.onChanged,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return AppInput(
      controller: controller,
      label: label,
      hint: hint,
      errorText: errorText,
      maxLines: maxLines,
      maxLength: maxLength,
      showCounter: showCounter,
      onChanged: onChanged,
      validator: validator,
      keyboardType: TextInputType.multiline,
      textInputAction: TextInputAction.newline,
    );
  }
}

/// 数字输入框
class NumberInput extends StatelessWidget {
  final TextEditingController? controller;
  final String? label;
  final String? hint;
  final String? errorText;
  final String? helperText;
  final IconData? prefixIcon;
  final String? suffix;
  final double? min;
  final double? max;
  final int decimals;
  final ValueChanged<String>? onChanged;
  final FormFieldValidator<String>? validator;

  const NumberInput({
    super.key,
    this.controller,
    this.label,
    this.hint,
    this.errorText,
    this.helperText,
    this.prefixIcon,
    this.suffix,
    this.min,
    this.max,
    this.decimals = 0,
    this.onChanged,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return AppInput(
      controller: controller,
      label: label,
      hint: hint,
      errorText: errorText,
      helperText: helperText,
      prefixIcon: prefixIcon,
      suffixIcon: suffix != null
          ? Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Center(
                widthFactor: 1,
                child: Text(
                  suffix!,
                  style: AppTheme.body2.copyWith(color: AppTheme.textSecondary),
                ),
              ),
            )
          : null,
      keyboardType: TextInputType.numberWithOptions(decimal: decimals > 0),
      inputFormatters: [
        FilteringTextInputFormatter.allow(
          decimals > 0 ? RegExp(r'^\d*\.?\d*') : RegExp(r'^\d*'),
        ),
      ],
      onChanged: onChanged,
      validator: validator ??
          (value) {
            if (value == null || value.isEmpty) return null;
            final number = double.tryParse(value);
            if (number == null) return '请输入有效的数字';
            if (min != null && number < min!) return '最小值为 $min';
            if (max != null && number > max!) return '最大值为 $max';
            return null;
          },
    );
  }
}

/// 下拉选择输入框
class DropdownInput<T> extends StatelessWidget {
  final T? value;
  final String? label;
  final String? hint;
  final String? errorText;
  final IconData? prefixIcon;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?>? onChanged;
  final FormFieldValidator<T>? validator;

  const DropdownInput({
    super.key,
    this.value,
    this.label,
    this.hint,
    this.errorText,
    this.prefixIcon,
    required this.items,
    this.onChanged,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<T>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        errorText: errorText,
        prefixIcon: prefixIcon != null ? Icon(prefixIcon) : null,
        filled: true,
        fillColor: AppTheme.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppTheme.spacingMD,
          vertical: AppTheme.spacingMD,
        ),
        border: OutlineInputBorder(
          borderRadius: AppTheme.borderRadiusStandard,
          borderSide: const BorderSide(color: AppTheme.divider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppTheme.borderRadiusStandard,
          borderSide: const BorderSide(color: AppTheme.divider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppTheme.borderRadiusStandard,
          borderSide: const BorderSide(color: AppTheme.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: AppTheme.borderRadiusStandard,
          borderSide: const BorderSide(color: AppTheme.error),
        ),
      ),
      items: items,
      onChanged: onChanged,
      validator: validator,
      style: AppTheme.body1,
      dropdownColor: AppTheme.surface,
    );
  }
}
