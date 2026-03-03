import 'package:concrete/concrete.dart';
import 'package:flutter/material.dart';

class Message extends StatelessWidget {
  final String message;
  final Color color;
  final bool expand;
  const Message({super.key, required this.message, this.color = Colors.lightBlue, this.expand = true});
  const Message.error({super.key, required this.message, this.color = Colors.deepOrange, this.expand = true});
  const Message.success({super.key, required this.message, this.color = Colors.lightGreen, this.expand = true});

  @override
  Widget build(BuildContext context) {
    return expand
        ? Row(
            children: [
              Expanded(
                child: Container(
                  padding: Edges.xs,
                  color: color,
                  child: Text(
                    message,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ],
          )
        : Container(
            padding: Edges.md,
            color: color,
            child: Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white),
            ),
          );
  }
}

class ErrorMessage extends StatelessWidget {
  final String message;
  const ErrorMessage({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: Edges.md,
      color: Colors.deepOrangeAccent,
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: const TextStyle(color: Colors.white),
      ),
    );
  }
}

class SuccessMessage extends StatelessWidget {
  final String message;
  const SuccessMessage({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: Edges.md,
      color: Colors.green,
      child: Center(
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.white),
        ),
      ),
    );
  }
}
