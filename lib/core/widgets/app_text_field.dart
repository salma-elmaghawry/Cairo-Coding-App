import 'package:cairo_coding_app/core/helpers/spacing.dart';
import 'package:cairo_coding_app/core/utils/app_text_styles.dart';
import 'package:flutter/material.dart';

class AppTextField extends StatelessWidget {
  const AppTextField({
    super.key,
    required this.label,
    this.controller,
    this.hint,
    this.prefixIcon,
    this.suffix,
    this.keyboardType,
    this.textInputAction,
    this.obscureText = false,
    this.validator,
    this.maxLines = 1,
    this.monospace = false,
    this.autofillHints,
    this.onSubmitted,
    this.readOnly = false,
    this.onTap,
  });

  final String label;
  final TextEditingController? controller;
  final String? hint;
  final IconData? prefixIcon;
  final Widget? suffix;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final bool obscureText;
  final FormFieldValidator<String>? validator;
  final int maxLines;
  final bool monospace;
  final Iterable<String>? autofillHints;
  final ValueChanged<String>? onSubmitted;
  final bool readOnly;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(label, style: AppTextStyles.font14Bold),
        verticalSpace(8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          obscureText: obscureText,
          validator: validator,
          maxLines: maxLines,
          autofillHints: autofillHints,
          onFieldSubmitted: onSubmitted,
          readOnly: readOnly,
          onTap: onTap,
          style: monospace ? AppTextStyles.monoFont14Medium : AppTextStyles.font16Normal,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: prefixIcon == null ? null : Icon(prefixIcon, size: 20),
            suffixIcon: suffix,
          ),
        ),
      ],
    );
  }
}
