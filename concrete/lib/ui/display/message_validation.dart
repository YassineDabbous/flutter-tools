import 'package:concrete/concrete.dart';
import 'package:flutter/material.dart';

class ValidationMessage extends StatelessWidget {
  final Map bag;
  const ValidationMessage({super.key, required this.bag});

  @override
  Widget build(BuildContext context) {
    final lista = bag.entries.map((e) {
      var v = e.value;
      if (v is Iterable) {
        return v.join(', ');
      }
      return e.value.toString();
    }).toList();
    return Container(
      padding: Edges.xs,
      decoration: BoxDecoration(
        //color: Colors.limeAccent,
        // border: Border.all(),
        borderRadius: Corner.xs,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ...lista.map(
            (e) => Container(
              padding: Edges.xs,
              // color: Colors.deepOrangeAccent,
              child: Text(
                e,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
