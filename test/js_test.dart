import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_datascript/src/js.dart';

void main() {
  group('JsRef', () {
    test('update', () {
      final ref = JsRef.gen('databases');
      expect(ref.toJsCode(updater: "2"),
          "state['databases']['${ref.key}'] = 2");
    });

    test('toJsCode()', () {
      final ref = JsRef.gen('database');
      expect(ref.toJsCode(), "state['database']['${ref.key}']");
    });
  });

  group('Context', () {
    test('initialise js global variables as expected', () {
      var ctx = JsContext();
      expect(ctx.isVarDefined('window'), true);
      expect(ctx.isVarDefined('global'), true);
      expect(ctx.isVarDefined('global.state.databases'), true);
      expect(ctx.isVarDefined('global.state.connections'), true);
    });

    test('evaluate()', () {
      var ctx = JsContext();
      expect(ctx.evaluate("true"), true);
      // decode string
      expect(ctx.evaluate("'hello'"), 'hello');
      // decode number
      expect(ctx.evaluate("1"), 1);
      // decode array
      expect(ctx.evaluate("[]"), []);
      // decode map
      expect(ctx.evaluate('[{"a":1}]'), [
        {'a': 1}
      ]);
    });

    test('evaluate()', () async {
      var ctx = JsContext();
      expect(await ctx.evaluateAsync("true"), true);
      // decode string
      expect(await ctx.evaluateAsync("'hello'"), 'hello');
      // decode number
      expect(await ctx.evaluateAsync("1"), 1);
      // decode array
      expect(await ctx.evaluateAsync("[]"), []);
      // decode map
      expect(await ctx.evaluateAsync('[{"a":1}]'), [
        {'a': 1}
      ]);
    });

    test('require()', () {
      var ctx = JsContext();
      var fname = './test/test.js';
      // test variable
      ctx.require(fname, ['vendor']);
      // test function
      expect(ctx.evaluate("fnInJsFile()"), 43);
      ctx.evaluate("vendor = 2");
      expect(ctx.evaluate("fnInJsFile()"), 44);
    });
  });
}
