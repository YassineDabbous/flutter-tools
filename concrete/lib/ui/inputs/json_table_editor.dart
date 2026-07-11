import 'package:core/core.dart';
import 'package:flutter/material.dart';

// Define the signature for the callback function
typedef OnJsonChanged = void Function(Map<String, dynamic> newJson);

class JsonTableEditor extends StatefulWidget {
  final Map<String, dynamic> initial;
  final List<String> rows;
  final List<String> columns;
  final OnJsonChanged onChange;

  const JsonTableEditor({
    super.key,
    required this.initial,
    required this.rows,
    required this.onChange,
    this.columns = const ['en', 'ar', 'fr'],
  });

  @override
  State<JsonTableEditor> createState() => _JsonTranslationEditorState();
}

class _JsonTranslationEditorState extends State<JsonTableEditor> {
  // Deep copy of the initial data to be mutated by the form fields
  late Map<String, dynamic> _currentTranslations;

  @override
  void initState() {
    super.initState();
    // Initialize the mutable state by cloning the initial data.
    // Ensure all rows exist in the map, even if empty.
    _currentTranslations = _initializeData(widget.initial);
  }

  // Helper to ensure the data structure is correctly initialized for all fields
  Map<String, dynamic> _initializeData(Map<String, dynamic> initial) {
    final Map<String, dynamic> data = Map.from(initial);
    for (var field in widget.rows) {
      if (!data.containsKey(field) || data[field] == null) {
        data[field] = <String, dynamic>{};
      }
      // Ensure all supported locales are represented for the field
      for (var locale in widget.columns) {
        if (!data[field].containsKey(locale) || data[field][locale] == null) {
          data[field][locale] = '';
        }
      }
    }
    return data;
  }

  // --- Core Update Logic ---
  void _updateTranslation(String field, String locale, String newValue) {
    setState(() {
      // 1. Update the local state
      if (_currentTranslations.containsKey(field) &&
          _currentTranslations[field] is Map) {
        _currentTranslations[field][locale] = newValue;
      }
      // 2. Call the external onChange function with the new JSON value
      widget.onChange(_currentTranslations);
    });
  }
  // -------------------------

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.vertical,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          // Define the header row with 'Field' and all supported locales
          columns: [
            const DataColumn(
              label: Text(
                'Field',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            ...widget.columns.map(
              (locale) => DataColumn(
                label: Text(
                  locale.toUpperCase(),
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
          // Generate the rows for each translatable field
          rows: widget.rows.map((field) {
            return DataRow(
              cells: [
                // 1. Field Name Cell
                DataCell(Text(field.i18n())),
                // 2. Translation Input Cells for each locale
                ...widget.columns.map((locale) {
                  // Get the current text value for this field and locale
                  String initialValue =
                      _currentTranslations.containsKey(field) &&
                          _currentTranslations[field].containsKey(locale)
                      ? _currentTranslations[field][locale] ?? ''
                      : '';

                  return DataCell(
                    SizedBox(
                      width:
                          150, // Fixed width for inputs to look good in the table
                      child: TextFormField(
                        initialValue: initialValue,
                        // The key is important to manage state of TextFormFields dynamically
                        key: ValueKey('$field-$locale'),
                        decoration: InputDecoration(
                          hintText: 'Enter $locale value',
                          border: const OutlineInputBorder(),
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 8,
                          ),
                        ),
                        // Trigger the update on every change
                        onChanged: (newValue) =>
                            _updateTranslation(field, locale, newValue),
                      ),
                    ),
                  );
                }),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
}
