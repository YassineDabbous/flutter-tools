import 'package:flutter/material.dart';
import 'package:core/core.dart';
import 'package:flutter_parsed_text/flutter_parsed_text.dart';

import 'package:url_launcher/url_launcher_string.dart';

class InteractiveText extends StatelessWidget {
  final String message;
  const InteractiveText(this.message, {super.key});

  @override
  Widget build(BuildContext context) {
    return ParsedText(
      text: message,
      style: const TextStyle(color: Colors.black),
      parse: <MatchText>[
        MatchText(
          type: ParsedType.EMAIL,
          style: const TextStyle(color: Colors.red),
          onTap: (url) {
            launchUrlString("mailto:$url");
          },
        ),
        MatchText(
          type: ParsedType.URL,
          style: const TextStyle(color: Colors.blue),
          onTap: (url) {
            launchUrlString(url);
          },
        ),
        MatchText(
          type: ParsedType.PHONE,
          style: const TextStyle(color: Colors.red),
          onTap: (url) {
            launchUrlString("tel:$url");
          },
        ),
        /*MatchText(
          pattern: r"\[(@[^:]+):([^\]]+)\]",
          style: TextStyle(
            color: Colors.green,
          ),
          // you must return a map with two keys
          // [display] - the text you want to show to the user
          // [value] - the value underneath it
          renderText: ({required String str, required String pattern}) {
            Map<String, String> map = Map<String, String>();
            RegExp customRegExp = RegExp(pattern);
            Match? match = customRegExp.firstMatch(str);
            map['display'] = match?.group(1) ?? 'display';
            map['value'] = match?.group(2) ?? 'value';
            return map;
          },
          onTap: (url) {
            logUI.debug('go to $url');
          },
        ),*/
        MatchText(
          type: ParsedType.CUSTOM,
          pattern:
              r"^(?:http|https):\/\/[\w\-_]+(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)",
          style: const TextStyle(color: Colors.lime),
          onTap: (url) => logUI.debug(url),
        ),
        MatchText(
          type: ParsedType.CUSTOM,
          pattern: "(---( )?(`)?spoiler(`)?( )?---)\n\n(.*?)\n( )?(---( )?(`)?spoiler(`)?( )?---)",
          style: const TextStyle(color: Colors.purple, fontSize: 50),
          onTap: (url) {
            launchUrlString("tel:$url");
          },
        ),
        MatchText(
          pattern: r"\[(@[^:]+):([^\]]+)\]",
          style: const TextStyle(color: Colors.green, fontSize: 24),
          renderText: ({required pattern, required str}) {
            RegExp customRegExp = RegExp(r"\[(@[^:]+):([^\]]+)\]");
            Match match = customRegExp.firstMatch(str)!;

            //logUI.debug('test test: ${match[1]}');
            // return Container(
            //   padding: EdgeInsets.all(5.0),
            //   color: Colors.amber,
            //   child: Text(match[1]!),
            // );
            //
            return {'display': match[1]!};
          },
          onTap: (url) {
            showDialog(
              context: context,
              builder: (BuildContext context) {
                //Map<String, String> map = Map<String, String>();
                RegExp customRegExp = RegExp(r"\[(@[^:]+):([^\]]+)\]");
                Match match = customRegExp.firstMatch(url)!;
                // return object of type Dialog
                return AlertDialog(
                  title: const Text("Mentions clicked"),
                  content: Text("${match.group(1)!} clicked."),
                  actions: <Widget>[
                    // usually buttons at the bottom of the dialog
                    TextButton(child: const Text("Close"), onPressed: () {}),
                  ],
                );
              },
            );
          },
          // onLongTap: (url) {
          //   print('long press');
          // },
        ),
        MatchText(
          pattern: r"\B#+([\w]+)\b",
          style: const TextStyle(color: Colors.pink, fontSize: 24),
          onTap: (url) async {
            showDialog(
              context: context,
              builder: (BuildContext context) {
                // return object of type Dialog
                return AlertDialog(
                  title: const Text("Hashtag clicked"),
                  content: Text("$url clicked."),
                  actions: <Widget>[
                    // usually buttons at the bottom of the dialog
                    TextButton(child: const Text("Close"), onPressed: () {}),
                  ],
                );
              },
            );
          },
          // onLongTap: (url) {
          //   print('long press');
          // },
        ),
        MatchText(
          pattern: r"lon",
          style: const TextStyle(color: Colors.pink, fontSize: 24),
          onTap: (url) async {},
        ),
      ],
    );
  }
}
