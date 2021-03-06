import 'dart:convert';

import 'package:flutter_js_context/flutter_js_context.dart';
import 'package:stringr/stringr.dart';

String _entityFactory(JsRef db, lookup) {
  return "vendor.ds.entity(${db.toJsCode()}, ${jsonEncode(lookup)})";
}

class ImmutableError implements Exception {}

class EntityJsApi {
  final JsContext context;
  final JsRef db;
  final dynamic lookup;

  EntityJsApi(this.context, this.db, this.lookup);

  @override
  noSuchMethod(Invocation i) {
    final String s = i.memberName.toString();
    assert(i.isMethod, "$s not supported.");

    final String jsfnName = s.substring(8, s.length - 2).snakeCase();
    String next;
    if (i.positionalArguments.isNotEmpty) {
      // @FIXME: should cache entity.
      // @FIXME: the order of values/keys is incorrect.
      next =
          ".$jsfnName.apply(${_entityFactory(db, lookup)}, ${jsonEncode(i.positionalArguments)});";
    } else {
      next = ".$jsfnName()";
    }
    try {
      return _loadThen(next);
    } catch (e) {
      print(next);
      print(e);
    }
  }

  _loadThen(next) {
    return context.evaluate(_entityFactory(db, lookup) + next);
  }
}

/// An entity is just an immutable [Map] of facts fetched from db inside
/// javascript runtime.
class Entity implements Map {
  final dynamic _api;
  Entity(context, db, lookup) : _api = EntityJsApi(context, db, lookup);

  JsRef get db => _api.db;

  @override
  operator [](Object? key) {
    aux(element) {
      // @FIXME: nested nvigation is not implemented.
      // the element is navigate ref, then we should just returns its eid
      // because it is a pure js object without functions we want to
      // use.
      if (element is Map) {
        int eid = element['eid'];
        return eid;
      } else {
        return element;
      }
    }

    ;

    final e = _api.get(key);
    if (e is List) {
      return e.map(aux).toList();
    } else {
      return aux(e);
    }
  }

  @override
  void operator []=(key, value) {
    throw ImmutableError();
  }

  @override
  void addAll(Map other) {
    throw ImmutableError();
  }

  @override
  void addEntries(Iterable<MapEntry> newEntries) {
    throw ImmutableError();
  }

  @override
  Map<RK, RV> cast<RK, RV>() {
    throw UnimplementedError();
  }

  @override
  void clear() {
    throw ImmutableError();
  }

  @override
  bool containsKey(Object? key) {
    return (_api.keySet() as List).any((e) {
      return e == key;
    });
  }

  @override
  bool containsValue(Object? value) {
    return (_api.valueSet() as List).any((e) {
      return e == value;
    });
  }

  @override
  Iterable<MapEntry> get entries {
    return (_api.entrySet() as List).map((e) {
      return MapEntry(e[0], e[1]);
    });
  }

  @override
  void forEach(void Function(dynamic key, dynamic value) action) {
    for (var e in entries) {
      action(e.key, e.value);
    }
  }

  @override
  bool get isEmpty => length == 0;

  @override
  bool get isNotEmpty => !isEmpty;

  @override
  Iterable get keys => _api.keySet();

  @override
  int get length => _api.keySet().length;

  @override
  Map<K2, V2> map<K2, V2>(
      MapEntry<K2, V2> Function(dynamic key, dynamic value) convert) {
    final Map<K2, V2> nm = {};
    for (var e in entries) {
      final ne = convert(e.key, e.value);
      nm[ne.key] = ne.value;
    }
    return nm;
  }

  @override
  putIfAbsent(key, Function() ifAbsent) {
    throw ImmutableError();
  }

  @override
  remove(Object? key) {
    throw ImmutableError();
  }

  @override
  void removeWhere(bool Function(dynamic key, dynamic value) test) {
    throw ImmutableError();
  }

  @override
  update(key, Function(dynamic value) update, {Function()? ifAbsent}) {
    throw ImmutableError();
  }

  @override
  void updateAll(Function(dynamic key, dynamic value) update) {
    throw ImmutableError();
  }

  @override
  Iterable get values => _api.valueSet();
}
