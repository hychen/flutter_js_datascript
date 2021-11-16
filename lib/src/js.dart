import 'dart:convert';
import 'dart:io';
import 'package:flutter_js/flutter_js.dart';
import 'package:uuid/uuid.dart';

const uuid = Uuid();

/// A reference to deal with the updating and retrieving of a Js object
/// inside JsRuntime.
class JsRef {
  /// The name of the space to storage actual value inside Js runtime.
  String ns;

  /// A object key of a mapping.
  String key;

  JsRef(this.ns, this.key);

  factory JsRef.define(JsContext context, String ns, String updater) {
    final ref = JsRef.fromNs(ns);
    ref.update(context, updater);
    return ref;
  }

  factory JsRef.fromKey(ns, key) {
    return JsRef(ns, key);
  }

  factory JsRef.fromNs(ns) {
    return JsRef(ns, uuid.v4());
  }

  fetch(JsContext context) {
    return context.evaluate(toJsCode());
  }

  update(JsContext context, String updaterJs) {
    return context.evaluate(toJsCode(updater: updaterJs));
  }

  updateAsync(runtime, String updaterJs) async {
    return runtime.evaluteAsync(toJsCode(updater: updaterJs));
  }

  String toJsCode({String? updater}) {
    if (updater == null) {
      return "state['$ns']['$key']";
    } else {
      return "state['$ns']['$key'] = $updater";
    }
  }
}

class JsContext {
  late final JavascriptRuntime runtime;

  JsContext() {
    runtime = getJavascriptRuntime(xhr: false);
    // @FIXME: js state variable should be dynamic to avoid collision.
    runtime.evaluate("""
    var window = global = globalThis;
    var state = {
      'databases': {},
      'connections': {}
    };
    """);
  }

  bool isVarDefined(String name) {
    String used = runtime.evaluate("""
    (typeof $name === 'undefined') ? 0 : 1;
    """).stringResult;
    return used == '0' ? false : true;
  }

  evaluate(String code) {
    var result = runtime.evaluate(code);
    assert(!result.isError, result.toString());
    return runtime.convertValue(result);
  }

  evaluateAsync(String code) async {
    var result = await runtime.evaluateAsync(code);
    assert(!result.isError, result.toString());
    return runtime.convertValue(result);
  }

  void require(String fname, List namespaces) {
    JsEvalResult result = runtime.evaluate(File(fname).readAsStringSync());
    assert(
        !result.isError && namespaces.every((element) => isVarDefined(element)),
        "loading $fname failed");
  }
}

List<String> toJsCode(List x) {
  return x.map((e) {
    if (e.runtimeType == JsRef) {
      return (e as JsRef).toJsCode();
    } else {
      return jsonEncode(e);
    }
  }).toList();
}
