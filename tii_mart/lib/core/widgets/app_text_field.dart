import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// ช่องกรอกข้อมูลที่ใช้ซ้ำทั้งแอพ (ถ้า obscure = true จะมีปุ่มตาแสดง/ซ่อนรหัสผ่าน)
class AppTextField extends StatefulWidget {
  const AppTextField({
    super.key,
    required this.controller,
    required this.label,
    this.validator,
    this.keyboardType,
    this.obscure = false,
    this.enabled = true,
    this.maxLines = 1,
    this.inputFormatters,
    this.textInputAction = TextInputAction.next,
    this.onSubmitted,
    this.autofillHints,
  });

  final TextEditingController controller;
  final String label;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final bool obscure;
  final bool enabled;
  final int maxLines;
  final List<TextInputFormatter>? inputFormatters;
  final TextInputAction textInputAction;
  final void Function(String)? onSubmitted;
  final Iterable<String>? autofillHints;

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  late bool _hidden = widget.obscure;

  @override
  Widget build(BuildContext context) {
    final multiline = !widget.obscure && widget.maxLines > 1;
    return TextFormField(
      controller: widget.controller,
      enabled: widget.enabled,
      obscureText: _hidden,
      maxLines: widget.obscure ? 1 : widget.maxLines,
      keyboardType: multiline ? TextInputType.multiline : widget.keyboardType,
      inputFormatters: widget.inputFormatters,
      textInputAction: multiline ? TextInputAction.newline : widget.textInputAction,
      validator: widget.validator,
      onFieldSubmitted: widget.onSubmitted,
      autofillHints: widget.autofillHints,
      decoration: InputDecoration(
        labelText: widget.label,
        alignLabelWithHint: multiline,
        filled: true,
        fillColor: Theme.of(context).cardColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        suffixIcon: widget.obscure
            ? IconButton(
                icon: Icon(
                  _hidden
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                ),
                onPressed: () => setState(() => _hidden = !_hidden),
              )
            : null,
      ),
    );
  }
}
