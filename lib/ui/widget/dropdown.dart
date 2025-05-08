import 'package:flutter/material.dart';

class CustomDropdownButtonFormField<T> extends StatelessWidget {
  final String label;
  final T value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;
  final String? Function(T?)? validator;
  final Icon? icon;
  final bool isRequired;

  const CustomDropdownButtonFormField({
    super.key,
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
    this.validator,
    this.icon,
    this.isRequired = false,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<T>(
      value: value,
      items: items,
      onChanged: onChanged,
      validator: validator,
      decoration: InputDecoration(
        labelText: isRequired ? '$label *' : label,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: value == null || value.toString().isEmpty
                ? Colors.grey
                : Colors.blueAccent,
            width: 2,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 15),
      ),
    );
  }
}
