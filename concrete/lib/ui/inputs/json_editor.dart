import 'package:flutter/material.dart';
import 'dart:convert';

// --- SCHEMA CLASSES ---

// Base class for all schema nodes
abstract class JsonSchemaNode {
  final String key;
  final String label;

  JsonSchemaNode({required this.key, required this.label});
}

// Helper class for schema nodes with a default value
class JsonSchemaNodeWithDefault<T> extends JsonSchemaNode {
  final T defaultValue;
  JsonSchemaNodeWithDefault({required super.key, required super.label, required this.defaultValue});
}

// Schema for a simple String value
class StringSchemaNode extends JsonSchemaNodeWithDefault<String> {
  StringSchemaNode({required super.key, required super.label, super.defaultValue = ''});
}

// Schema for an Integer value
class IntSchemaNode extends JsonSchemaNodeWithDefault<int> {
  IntSchemaNode({required super.key, required super.label, super.defaultValue = 0});
}

// Schema for a Double value
class DoubleSchemaNode extends JsonSchemaNodeWithDefault<double> {
  DoubleSchemaNode({required super.key, required super.label, super.defaultValue = 0.0});
}

// Schema for a Boolean value
class BoolSchemaNode extends JsonSchemaNodeWithDefault<bool> {
  BoolSchemaNode({required super.key, required super.label, super.defaultValue = false});
}

// Schema for a nested JSON Object (Map)
class ObjectSchemaNode extends JsonSchemaNode {
  final List<JsonSchemaNode> children;
  ObjectSchemaNode({required super.key, required super.label, required this.children});
}

// Schema for a JSON Array (List) of objects
class ListSchemaNode extends JsonSchemaNode {
  final List<JsonSchemaNode> childObjectSchema;
  ListSchemaNode({required super.key, required super.label, required this.childObjectSchema});
}

// --- NEW SCHEMA NODE and HELPER CLASS ---

/// Represents a single choice in a selection list.
class ChoiceOption<T> {
  final String label;
  final T value;

  const ChoiceOption({required this.label, required this.value});
}

/// Schema for a field that allows selecting multiple values from a predefined list.
/// The resulting JSON value will be a List&lt;T&gt; of the selected values.
class MultiSelectSchemaNode<T> extends JsonSchemaNodeWithDefault<List<T>> {
  final List<ChoiceOption<T>> options;

  MultiSelectSchemaNode({required super.key, required super.label, required this.options, super.defaultValue = const []});
}



/// A typedef for the function that builds a custom field widget.
/// It receives the current value and a callback to notify the editor of changes.
typedef CustomFieldBuilder = Widget Function(
  BuildContext context,
  dynamic currentValue,
  void Function(dynamic newValue) onChanged,
  bool isReadOnly,
);

/// A schema node that allows rendering a completely custom widget.
class CustomSchemaNode<T> extends JsonSchemaNodeWithDefault<T> {
  final CustomFieldBuilder builder;

  CustomSchemaNode({
    required super.key,
    required super.label,
    required super.defaultValue,
    required this.builder,
  });
}

// --- MAIN JSON EDITOR WIDGET ---

class JsonEditor extends StatefulWidget {
  final List<JsonSchemaNode> schema;
  final Map<String, dynamic> initial;
  final bool isReadOnly;
  final void Function(Map<String, dynamic> json) onChanged;

  const JsonEditor({super.key, required this.schema, required this.initial, required this.onChanged, this.isReadOnly = false});

  @override
  State<JsonEditor> createState() => _JsonEditorState();
}

class _JsonEditorState extends State<JsonEditor> {
  late Map<String, dynamic> _editableJson;
  final Map<String, TextEditingController> _controllers = {};

  @override
  void initState() {
    super.initState();
    _initializeState();
  }

  @override
  void didUpdateWidget(covariant JsonEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initial != oldWidget.initial || widget.schema != oldWidget.schema) {
      _disposeControllers();
      _initializeState();
    }
  }

  void _initializeState() {
    _editableJson = json.decode(json.encode(widget.initial));
    _populateMissingWithDefaults(widget.schema, _editableJson);
    _createControllers(widget.schema, _editableJson);
  }

  void _populateMissingWithDefaults(List<JsonSchemaNode> schema, Map<String, dynamic> jsonMap) {
    for (final node in schema) {
      if (!jsonMap.containsKey(node.key)) {
        if (node is JsonSchemaNodeWithDefault) jsonMap[node.key] = node.defaultValue;
        if (node is ObjectSchemaNode) {
          jsonMap[node.key] = <String, dynamic>{};
          _populateMissingWithDefaults(node.children, jsonMap[node.key] as Map<String, dynamic>);
        }
        if (node is ListSchemaNode) jsonMap[node.key] = [];
      } else if (node is ObjectSchemaNode && jsonMap[node.key] is Map) {
        _populateMissingWithDefaults(node.children, (jsonMap[node.key] as Map).cast<String, dynamic>());
      }
    }
  }

  void _createControllers(List<JsonSchemaNode> schema, Map<String, dynamic> jsonMap) {
    for (final node in schema) {
      if (node is StringSchemaNode || node is IntSchemaNode || node is DoubleSchemaNode) {
        final value = jsonMap[node.key];
        _controllers[node.key] = TextEditingController(text: value.toString());
      }
    }
  }

  @override
  void dispose() {
    _disposeControllers();
    super.dispose();
  }

  void _disposeControllers() {
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    _controllers.clear();
  }

  void _notifyParent() {
    if (!widget.isReadOnly) {
      widget.onChanged(_editableJson);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: widget.schema.length,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final schemaNode = widget.schema[index];
        final value = _editableJson[schemaNode.key];
        return _buildEditorForRow(schemaNode, value);
      },
    );
  }

  Widget _buildEditorForRow(JsonSchemaNode schemaNode, dynamic value) {
    final key = schemaNode.key;
    final title = Text(schemaNode.label, style: const TextStyle(fontWeight: FontWeight.bold));

    if (schemaNode is BoolSchemaNode) {
      return ListTile(
        title: title,
        trailing: Switch(
          value: value,
          onChanged: widget.isReadOnly
              ? null
              : (newValue) {
                  setState(() {
                    _editableJson[key] = newValue;
                  });
                  _notifyParent();
                },
        ),
      );
    } else if (schemaNode is IntSchemaNode || schemaNode is DoubleSchemaNode) {
      return ListTile(
        title: title,
        subtitle: TextField(
          readOnly: widget.isReadOnly,
          controller: _controllers[key],
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(border: InputBorder.none),
          onChanged: (newValue) {
            num? parsedValue = (schemaNode is IntSchemaNode) ? int.tryParse(newValue) : double.tryParse(newValue);
            if (parsedValue != null) {
              _editableJson[key] = parsedValue;
              _notifyParent();
            }
          },
        ),
      );
    } else if (schemaNode is StringSchemaNode) {
      return ListTile(
        title: title,
        subtitle: TextField(
          readOnly: widget.isReadOnly,
          controller: _controllers[key],
          decoration: const InputDecoration(border: InputBorder.none),
          onChanged: (newValue) {
            _editableJson[key] = newValue;
            _notifyParent();
          },
        ),
      );
    } else if (schemaNode is ObjectSchemaNode) {
      return ListTile(
        title: title,
        subtitle: const Text('{...}'),
        trailing: widget.isReadOnly ? null : const Icon(Icons.arrow_forward_ios),
        onTap: widget.isReadOnly
            ? null
            : () async {
                final result = await Navigator.of(context).push<Map<String, dynamic>>(
                  MaterialPageRoute(
                    builder: (_) => _JsonNestedObjectEditorPage(
                      title: schemaNode.label,
                      schema: schemaNode.children,
                      isReadOnly: widget.isReadOnly,
                      initial: (value as Map).cast<String, dynamic>(),
                    ),
                  ),
                );
                if (result != null) {
                  setState(() {
                    _editableJson[key] = result;
                  });
                  _notifyParent();
                }
              },
      );
    } else if (schemaNode is ListSchemaNode) {
      return ListTile(
        title: title,
        subtitle: Text('[${(value as List).length} items]'),
        trailing: widget.isReadOnly ? null : const Icon(Icons.arrow_forward_ios),
        onTap: widget.isReadOnly
            ? null
            : () async {
                final result = await Navigator.of(context).push<List<dynamic>>(
                  MaterialPageRoute(
                    builder: (_) => _JsonListEditorPage(
                      title: schemaNode.label,
                      objectSchema: schemaNode.childObjectSchema,
                      isReadOnly: widget.isReadOnly,
                      initialList: List<dynamic>.from(value),
                    ),
                  ),
                );
                if (result != null) {
                  setState(() {
                    _editableJson[key] = result;
                  });
                  _notifyParent();
                }
              },
      );
    } else if (schemaNode is MultiSelectSchemaNode) {
      final selectedValues = List.from(value);
      // Create a readable summary of selected items
      final optionsMap = {for (var opt in schemaNode.options) opt.value: opt.label};
      final summary = selectedValues.map((v) => optionsMap[v] ?? 'Unknown').join(', ');
      // final summary = selectedValues
      //     .map(
      //       (v) => schemaNode.options
      //           .firstWhere(
      //             (opt) => opt.value == v,
      //             orElse: () => ChoiceOption(label: 'Unknown', value: v),
      //           )
      //           .label,
      //     )
      //     .join(', ');

      return ListTile(
        title: title,
        subtitle: Text(summary.isEmpty ? 'None selected' : summary, maxLines: 2, overflow: TextOverflow.ellipsis),
        trailing: widget.isReadOnly ? null : const Icon(Icons.arrow_forward_ios),
        onTap: widget.isReadOnly
            ? null
            : () async {
                final result = await Navigator.of(context).push<List<dynamic>>(
                  MaterialPageRoute(
                    builder: (_) => _MultiSelectPage(title: schemaNode.label, options: schemaNode.options, initialSelection: selectedValues.toSet()),
                  ),
                );
                if (result != null) {
                  setState(() {
                    _editableJson[key] = result;
                  });
                  _notifyParent();
                }
              },
      );
    }
    else if (schemaNode is CustomSchemaNode) {
      return schemaNode.builder(
        context,
        value,
        (newValue) {
          setState(() {
            _editableJson[key] = newValue;
          });
          _notifyParent();
        },
        widget.isReadOnly,
      );
    }
    return ListTile(title: title, subtitle: Text(value?.toString() ?? 'null'));
  }
}

// --- HELPER & NESTED PAGES ---
Map<String, dynamic> _createObjectFromSchema(List<JsonSchemaNode> schema) {
  final newObject = <String, dynamic>{};
  for (final node in schema) {
    if (node is JsonSchemaNodeWithDefault) {
      newObject[node.key] = node.defaultValue;
    } else if (node is ObjectSchemaNode) {
      newObject[node.key] = _createObjectFromSchema(node.children);
    } else if (node is ListSchemaNode) {
      newObject[node.key] = [];
    }
  }
  return newObject;
}

// Nested Object Editor Page (now accepts schema)
class _JsonNestedObjectEditorPage extends StatefulWidget {
  final String title;
  final List<JsonSchemaNode> schema;
  final Map<String, dynamic> initial;
  final bool isReadOnly;

  const _JsonNestedObjectEditorPage({required this.title, required this.schema, required this.initial, this.isReadOnly = false});

  @override
  State<_JsonNestedObjectEditorPage> createState() => __JsonNestedObjectEditorPageState();
}

class __JsonNestedObjectEditorPageState extends State<_JsonNestedObjectEditorPage> {
  late Map<String, dynamic> _editedJson;

  @override
  void initState() {
    super.initState();
    _editedJson = widget.initial;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        Navigator.of(context).pop(_editedJson);
      },
      child: Scaffold(
        appBar: AppBar(title: Text(widget.isReadOnly ? 'Viewing "${widget.title}"' : 'Editing "${widget.title}"')),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: JsonEditor(
            schema: widget.schema,
            initial: _editedJson,
            isReadOnly: widget.isReadOnly,
            onChanged: (newJson) {
              _editedJson = newJson;
            },
          ),
        ),
      ),
    );
  }
}

// Nested List Editor Page (now stateful with "Add" and "Delete")
class _JsonListEditorPage extends StatefulWidget {
  final String title;
  final List<JsonSchemaNode> objectSchema;
  final List<dynamic> initialList;
  final bool isReadOnly;

  const _JsonListEditorPage({required this.title, required this.objectSchema, required this.initialList, this.isReadOnly = false});

  @override
  State<_JsonListEditorPage> createState() => _JsonListEditorPageState();
}

class _JsonListEditorPageState extends State<_JsonListEditorPage> {
  late List<dynamic> _editedList;

  @override
  void initState() {
    super.initState();
    _editedList = widget.initialList;
  }

  void _addNewItem() {
    setState(() {
      _editedList.add(_createObjectFromSchema(widget.objectSchema));
    });
  }

  void _deleteItem(int index) {
    setState(() {
      _editedList.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        Navigator.of(context).pop(_editedList);
      },
      child: Scaffold(
        appBar: AppBar(title: Text(widget.isReadOnly ? 'Viewing List "${widget.title}"' : 'Editing List "${widget.title}"')),
        body: ListView.builder(
          itemCount: _editedList.length,
          itemBuilder: (context, index) {
            final item = _editedList[index];
            return ListTile(
              title: Text('Item ${index + 1}'),
              subtitle: const Text('{...}'),
              trailing: widget.isReadOnly
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _deleteItem(index),
                    ),
              onTap: // widget.isReadOnly ? null :
              () async {
                final result = await Navigator.of(context).push<Map<String, dynamic>>(
                  MaterialPageRoute(
                    builder: (_) => _JsonNestedObjectEditorPage(
                      isReadOnly: widget.isReadOnly,
                      title: 'Item ${index + 1}',
                      schema: widget.objectSchema,
                      initial: (item as Map).cast<String, dynamic>(),
                    ),
                  ),
                );
                if (result != null) {
                  setState(() {
                    _editedList[index] = result;
                  });
                }
              },
            );
          },
        ),
        floatingActionButton: widget.isReadOnly ? null : FloatingActionButton(onPressed: _addNewItem, child: const Icon(Icons.add)),
      ),
    );
  }
}

// --- Multi-Select Page ---
class _MultiSelectPage extends StatefulWidget {
  final String title;
  final List<ChoiceOption> options;
  final Set<dynamic> initialSelection;

  const _MultiSelectPage({required this.title, required this.options, required this.initialSelection});

  @override
  State<_MultiSelectPage> createState() => _MultiSelectPageState();
}

class _MultiSelectPageState extends State<_MultiSelectPage> {
  late Set<dynamic> _selectedValues;

  @override
  void initState() {
    super.initState();
    _selectedValues = widget.initialSelection;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        Navigator.of(context).pop(_selectedValues.toList());
      },
      child: Scaffold(
        appBar: AppBar(title: Text('Select ${widget.title}')),
        body: ListView.builder(
          itemCount: widget.options.length,
          itemBuilder: (context, index) {
            final option = widget.options[index];
            final isSelected = _selectedValues.contains(option.value);

            return CheckboxListTile(
              title: Text(option.label),
              value: isSelected,
              onChanged: (bool? selected) {
                setState(() {
                  if (selected == true) {
                    _selectedValues.add(option.value);
                  } else {
                    _selectedValues.remove(option.value);
                  }
                });
              },
            );
          },
        ),
      ),
    );
  }
}



class AsyncChoicesField extends StatefulWidget {
  final dynamic currentValue;
  final void Function(dynamic) onChanged;
  final bool isReadOnly;
  final Future<List<ChoiceOption<String>>> Function() fetcher;

  const AsyncChoicesField({
    super.key,
    required this.currentValue,
    required this.onChanged,
    required this.isReadOnly,
    required this.fetcher,
  });

  @override
  State<AsyncChoicesField> createState() => _AsyncChoicesFieldState();
}

class _AsyncChoicesFieldState extends State<AsyncChoicesField> {
  Future<List<ChoiceOption<String>>>? _fetchFuture;

  @override
  void initState() {
    super.initState();
    _fetchFuture = widget.fetcher();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<ChoiceOption<String>>>(
      future: _fetchFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const ListTile(
            title: Text('Categories'), // Placeholder label
            subtitle: LinearProgressIndicator(),
          );
        }

        if (snapshot.hasError) {
          return ListTile(
            title: const Text('Categories'),
            subtitle: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.red)),
          );
        }

        final options = snapshot.data ?? [];
        final selectedValues = List<String>.from(widget.currentValue ?? []);
        final optionsMap = {for (var opt in options) opt.value: opt.label};
        final summary = selectedValues.map((v) => optionsMap[v] ?? v).join(', ');

        return ListTile(
          title: const Text('Categories (from API)'),
          subtitle: Text(summary.isEmpty ? 'None selected' : summary, maxLines: 2),
          trailing: widget.isReadOnly ? null : const Icon(Icons.arrow_forward_ios),
          onTap: widget.isReadOnly ? null : () async {
            final result = await Navigator.of(context).push<List<dynamic>>(
              MaterialPageRoute(
                builder: (_) => _MultiSelectPage(
                  title: 'Categories',
                  options: options,
                  initialSelection: selectedValues.toSet(),
                ),
              ),
            );
            if (result != null) {
              widget.onChanged(result);
            }
          },
        );
      },
    );
  }
}

// --- EXAMPLE USAGE ---

// NEW: Dummy service to simulate fetching data
class ApiService {
  static Future<List<ChoiceOption<String>>> fetchCategories() async {
    await Future.delayed(const Duration(seconds: 2)); // Simulate network delay
    // In a real app, this would be an HTTP request.
    return [
      const ChoiceOption(label: 'Electronics', value: 'cat_elec'),
      const ChoiceOption(label: 'Books', value: 'cat_book'),
      const ChoiceOption(label: 'Home & Garden', value: 'cat_home'),
      const ChoiceOption(label: 'Apparel', value: 'cat_apparel'),
    ];
  }
}

// // // Define the schema that describes the structure of your JSON form.
// final List<JsonSchemaNode> appSchema = [
//   StringSchemaNode(key: 'name', label: 'Full Name', defaultValue: 'N/A'),
//   IntSchemaNode(key: 'age', label: 'Age'),
//   BoolSchemaNode(key: 'isStudent', label: 'Is a Student?', defaultValue: false),
//   DoubleSchemaNode(key: 'height_meters', label: 'Height (meters)', defaultValue: 1.5),

//   // NEW: Add the multi-select field for weekdays.
//   MultiSelectSchemaNode<int>(
//     key: 'available_days',
//     label: 'Available Weekdays',
//     defaultValue: [1, 2, 3, 4, 5], // Monday to Friday
//     options: [
//       const ChoiceOption(label: 'Monday', value: 1),
//       const ChoiceOption(label: 'Tuesday', value: 2),
//       const ChoiceOption(label: 'Wednesday', value: 3),
//       const ChoiceOption(label: 'Thursday', value: 4),
//       const ChoiceOption(label: 'Friday', value: 5),
//       const ChoiceOption(label: 'Saturday', value: 6),
//       const ChoiceOption(label: 'Sunday', value: 7),
//     ],
//   ),
  
//   CustomSchemaNode<List<String>>(
//     key: 'categories',
//     label: 'Categories (from API)', // This label is a fallback
//     defaultValue: [],
//     builder: (context, currentValue, onChanged, isReadOnly) {
//       return AsyncChoicesField(
//         currentValue: currentValue,
//         onChanged: onChanged,
//         isReadOnly: isReadOnly,
//         fetcher: ApiService.fetchCategories,
//       );
//     },
//   ),


//   ObjectSchemaNode(
//     key: 'address',
//     label: 'Address',
//     children: [
//       StringSchemaNode(key: 'street', label: 'Street Address'),
//       StringSchemaNode(key: 'city', label: 'City'),
//       BoolSchemaNode(key: 'is_verified', label: 'Verified Address'),
//     ],
//   ),
//   ListSchemaNode(
//     key: 'projects',
//     label: 'Projects',
//     childObjectSchema: [
//       StringSchemaNode(key: 'name', label: 'Project Name'),
//       IntSchemaNode(key: 'year', label: 'Year Completed', defaultValue: DateTime.now().year),
//     ],
//   ),
// ];

// //
// //
// //
// //
// //

// void main() {
//   runApp(const MyApp());
// }

// class MyApp extends StatelessWidget {
//   const MyApp({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       title: 'Flutter JSON Editor Demo',
//       theme: ThemeData(primarySwatch: Colors.blue),
//       home: const JsonEditorScreen(),
//     );
//   }
// }

// class JsonEditorScreen extends StatefulWidget {
//   const JsonEditorScreen({super.key});

//   @override
//   State<JsonEditorScreen> createState() => _JsonEditorScreenState();
// }

// class _JsonEditorScreenState extends State<JsonEditorScreen> {
//   Map<String, dynamic> _jsonData = {};

//   bool _isReadOnly = false;

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text('Schema-Driven JSON Editor')),
//       body: SingleChildScrollView(
//         child: Padding(
//           padding: const EdgeInsets.all(16.0),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.stretch,
//             children: [
//               // NEW: Add a switch to toggle read-only mode.
//               SwitchListTile(
//                 title: const Text("Read-Only Mode", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
//                 value: _isReadOnly,
//                 onChanged: (value) {
//                   setState(() {
//                     _isReadOnly = value;
//                   });
//                 },
//               ),
//               const SizedBox(height: 8),
//               Card(
//                 child: JsonEditor(
//                   schema: appSchema,
//                   initial: _jsonData,
//                   // NEW: Pass the state variable to the editor.
//                   isReadOnly: _isReadOnly,
//                   onChanged: (newJson) {
//                     setState(() {
//                       _jsonData = newJson;
//                     });
//                   },
//                 ),
//               ),
//               const SizedBox(height: 24),
//               const Text('Live JSON Output:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
//               Container(
//                 padding: const EdgeInsets.all(12),
//                 color: Colors.grey.shade200,
//                 child: Text(const JsonEncoder.withIndent('  ').convert(_jsonData), style: const TextStyle(fontFamily: 'monospace')),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }
