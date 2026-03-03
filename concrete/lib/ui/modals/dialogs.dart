import 'package:flutter/material.dart';
import 'package:concrete/concrete.dart';

Future<T?> selectAndPop<T extends Object?>(BuildContext context, Widget screen) async {
  return await Navigator.push<T>(context, PageRouteBuilder(pageBuilder: (context, animation, secondaryAnimation) => screen));
}

class DialogMenuAction {
  Icon? icon;
  String title;
  Function() action;
  // Function(BuildContext)? actionCtx;
  DialogMenuAction({
    this.icon,
    required this.title,
    required this.action,
    // this.actionCtx,
  });
}

Future dialogMenu({required BuildContext context, required List<DialogMenuAction> items, String? title}) {
  return showDialog(
    context: context,
    builder: (BuildContext ctx) {
      // return alert dialog object
      return AlertDialog(
        title: title == null ? null : Text(title),
        content: SizedBox(
          height: items.length * 60.0,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: items
                .map(
                  (e) => ListTile(
                    title: Text(e.title),
                    leading: e.icon,
                    onTap: () {
                      Navigator.pop(ctx); // shoould be before action
                      e.action.call();
                    },
                  ),
                )
                .toList(),
          ),
        ),
      );
    },
  );
}

Future dialogConfirmation({required BuildContext context, String? title, String? content, required Function() onConfirm}) async {
  return await showDialog(
    context: context,
    builder: (ctx) {
      return SizedBox(
        height: 100,
        child: AlertDialog(
          title: title == null ? Text('are you sure'.i18n()) : Text(title),
          content: content == null ? null : Text(content),
          actions: [
            TextButton(
              child: Text('yes'.i18n()),
              onPressed: () {
                Navigator.pop(ctx);
                onConfirm();
              },
            ),
            ElevatedButton(
              child: Text('no'.i18n()),
              onPressed: () {
                Navigator.pop(ctx);
              },
            ),
          ],
        ),
      );
    },
  );
}

Future dialogButtons({required BuildContext context, Widget? title, Widget? content, required List<Widget> actions}) async {
  return await showDialog(
    context: context,
    builder: (ctx) {
      return SizedBox(
        height: 100,
        child: AlertDialog(
          title: title ,
          content: content ,
          actions: [
            ...actions,
            // ElevatedButton(
            //   child: Text('no'.i18n()),
            //   onPressed: () {
            //     Navigator.pop(ctx);
            //   },
            // ),
          ],
        ),
      );
    },
  );
}

Future dialogValue({required BuildContext context, String? title, String? hint, required Function(String) onSubmit}) {
  TextEditingController tc = TextEditingController();
  return showDialog(
    context: context,
    builder: (ctx) {
      return AlertDialog(
        title: title == null ? null : Text(title),
        content: SizedBox(
          height: 120,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              TextInput(controller: tc, hint: hint, leading: const Icon(Icons.key)),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () {
                  onSubmit(tc.text);
                  Navigator.pop(ctx);
                },
                child: Text('confirm'.i18n()),
              ),
            ],
          ),
        ),
      );
    },
  );
}

Future dialogInfoSuccess({required BuildContext context, String? title}) {
  return dialogInfo(
    context: context,
    height: 200,
    title: title ?? 'done with success'.i18n(),
    content: const Icon(Icons.done_all, size: 100, color: Colors.green),
  );
}

Future dialogInfo({required BuildContext context, required Widget content, String? title, double height = 100}) {
  return showDialog(
    context: context,
    builder: (ctx) {
      return Center(
        child: SizedBox(
          height: height,
          width: height,
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  content,
                  const SizedBox(height: Sz.lg),
                  if (title != null) Text(title),
                  // SizedBox(height: 16),
                  // TextButton(
                  //   child: Text('ok'.i18n()),
                  //   onPressed: () => Navigator.pop(ctx),
                  // ),
                ],
              ),
            ),
          ),
        ),
      );
    },
  );
}

Future dialogView({required BuildContext context, required Widget view, double? maxWidth, double? maxHeight}) {
  return showDialog(
    context: context,
    builder: (ctx) {
      return Center(
        child: SizedBox(height: maxHeight, width: maxWidth, child: view),
      );
    },
  );
}

Future dialogExpandedView({required BuildContext context, required Widget view, double? margin, double? maxWidth, double? maxHeight}) {
  return showDialog(
    context: context,
    builder: (ctx) {
      return LayoutBuilder(
        builder: (context, constraints) {
          return Center(
            child: SizedBox(
              height: maxHeight ?? constraints.maxHeight - (margin ?? (constraints.maxHeight / 8)),
              width: maxWidth ?? constraints.maxWidth - (margin ?? (constraints.maxWidth / 8)),
              child: view,
            ),
          );
        },
      );
    },
  );
}
