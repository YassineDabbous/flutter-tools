import 'package:flutter/material.dart';

class TextInput extends StatelessWidget {
  final TextStyle? textStyle;
  final FocusNode? focusNode;
  final String? initialValue;
  final String name;
  final String? hint;
  final String? errorText;
  final TextEditingController? controller;
  final Widget? leading;
  final Widget? trailing;
  final bool expands;
  // final bool enabled;
  final bool obscure;
  final EdgeInsets? padding;
  final TextInputType? keyboardType;
  final void Function(String)? onSubmitted;
  final void Function(String)? onChanged;
  final void Function()? onTap;
  final String? Function(String?)? validator;
  final bool readOnly;
  final InputDecorationTheme? decoration;
  const TextInput({
    super.key,
    this.initialValue,
    this.hint,
    this.errorText,
    this.controller,
    this.leading,
    this.trailing,
    this.padding,
    this.keyboardType,
    this.onChanged,
    this.onSubmitted,
    this.onTap,
    this.validator,
    this.focusNode,
    this.textStyle,
    this.decoration,
    this.obscure = false,
    this.expands = false,
    this.readOnly = false,
    // this.enabled = true,
    this.name = 'value',
  }) : assert(controller == null || onChanged == null);

  @override
  Widget build(BuildContext context) {
    InputDecoration inputDecoration = InputDecoration(
      border: const OutlineInputBorder(), // InputBorder.none
      // // isDense: true,
      // // contentPadding: EdgeInsets.symmetric(vertical: 15, horizontal: 10),
      // focusedBorder: OutlineInputBorder(
      //   borderRadius: BorderRadius.circular(10.0),
      //   borderSide: BorderSide(color: Theme.of(context).colorScheme.secondary, width: 1.0),
      // ),
      labelStyle: TextStyle(color: Theme.of(context).hintColor),
      hintText: hint,
      labelText: hint,
      prefixIcon: leading,
      suffixIcon: trailing,
      errorText: errorText,
    );
    if (decoration != null) {
      inputDecoration = inputDecoration.applyDefaults(decoration!);
    }
    return Container(
      padding: padding,
      child: TextFormField(
        // strutStyle: StrutStyle(),
        focusNode: focusNode,
        key: initialValue == null ? null : Key(initialValue!),
        onTap: onTap,
        readOnly: readOnly,
        validator: validator,
        keyboardType: keyboardType,
        initialValue: controller == null ? initialValue : null,
        style:
            textStyle, // TextStyle(color: Theme.of(context).colorScheme.secondary),
        controller: controller,
        onChanged: onChanged,
        onFieldSubmitted: onSubmitted,
        //minLines: null,
        maxLines: expands ? null : 1,
        expands: expands,
        obscureText: obscure,
        textAlignVertical: TextAlignVertical.top,
        decoration: inputDecoration,
        // validator: (value) {
        //   if ((value ?? '').isEmpty) {
        //     return 'Please enter a correct $name';
        //   }
        //   return null;
        // },
      ),
    );
  }
}
