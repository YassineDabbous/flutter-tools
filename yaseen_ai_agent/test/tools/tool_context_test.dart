import 'package:flutter_test/flutter_test.dart';
import 'package:yaseen_ai_agent/src/tools/_parser.dart';
import 'package:yaseen_ai_agent/src/tools/_tool_runner.dart';
import 'package:yaseen_ai_agent/src/tools/tool_context.dart';
import 'package:yaseen_ai_agent/src/tools/tool_registry.dart';
import 'package:yaseen_ai_agent/src/tools/tool_response.dart';

import '../helpers/fake_dio.dart';

class _ContextSpy extends SpyTool {
  ToolContext? seenContext;

  @override
  Future<ToolResponse> runWithContext(
    Map<String, dynamic> params,
    ToolContext context,
  ) async {
    seenContext = context;
    return super.run(params);
  }
}

void main() {
  group('ToolContext', () {
    test('runWithContext defaults to run()', () async {
      final tool = SpyTool();
      final response = await tool.runWithContext({
        'query': 'q',
      }, const ToolContext());
      expect(response.isRequestSuccessful, isTrue);
      expect(tool.seenParams, {'query': 'q'});
    });

    test('ToolRunner forwards the context', () async {
      final registry = ToolRegistry();
      final spy = _ContextSpy();
      registry.registerTool(spy);
      final runner = ToolRunner();
      final meta = Object();
      final responses = await runner.runTools(
        PromptParserResult(
          outcome: ParseOutcome.tools,
          agentNames: const [],
          toolNames: const ['spy_tool'],
          params: const {
            'spy_tool': {'query': 'ctx'},
          },
        ),
        registry,
        context: ToolContext(metaData: meta),
      );
      expect(responses.single.isRequestSuccessful, isTrue);
      expect(spy.seenContext?.metaData, same(meta));
    });
  });
}
