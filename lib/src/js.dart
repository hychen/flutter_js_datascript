/// This library implements Datascript Public Javascript APIs.
library js;

import 'dart:convert';
import 'dart:io';
import 'package:flutter_js/flutter_js.dart';
import './core.dart';

class UseJS {
  late final JavascriptRuntime jsEngine;

  UseJS() {
    jsEngine = getJavascriptRuntime(xhr: false);
    jsEngine.evaluate("""
    var window = global = globalThis;
    var state = {
      conns: []
    };
    """);
  }

  bool isJsVarDefined(String varname) {
    String used = jsEngine.evaluate("""
    (typeof $varname === 'undefined') ? 0 : 1;
    """).stringResult;
    return used == '0' ? false : true;
  }

  _loadJsFile(String fname, List namespaces) {
    JsEvalResult result = jsEngine.evaluate(File(fname).readAsStringSync());
    assert(
        !result.isError &&
            namespaces.every((element) => isJsVarDefined(element)),
        "loading $fname failed");
  }
}

class FlutterDatascript extends UseJS {
  int totalConnections = 0;

  FlutterDatascript() {
    _loadJsFile('./assets/js/bundle.js', ['vendor.ds']);
  }

  // -------------------------------------------------------------------------
  // JS public APIs.
  // -------------------------------------------------------------------------

  /// Creates an empty database with an optional schema.
  Future<DB> emptyDb({Schema? schema}) {
    throw UnimplementedError();
  }

  /// Low-level fn for creating database quickly from a trusted sequence of
  /// datoms.
  Future<DB> initDb({Schema? schema}) {
    throw UnimplementedError();
  }

  /// Converts db into a data structure (not string!) that can be fed to serializer
  /// of your choice (e.g. `js/JSON.stringify` in CLJS, `cheshire.core/generate-string`
  /// or `jsonista.core/write-value-as-string` in CLJ).
  ///
  /// On JVM, `serializable` holds a global lock that prevents any two serializations
  /// to run in parallel (an implementation constraint, be aware).
  Future serializable(db, Object? opts) {
    throw UnimplementedError();
  }

  /// Creates db from a data structure (not string!) produced by serializable.
  Future fromSerializable(serializable, opts) {
    throw UnimplementedError();
  }

  /// Executes a datalog query. See [docs.datomic.com/on-prem/query.html](https://docs.datomic.com/on-prem/query.html)
  Future q(String query, List inputs) {
    throw UnimplementedError();
  }

  /// Fetches data from database using recursive declarative description.
  /// See [docs.datomic.com/on-prem/pull.html](https://docs.datomic.com/on-prem/pull.html).
  Future<List<PullResult>> pull(DB db, pattern, int eid) {
    throw UnimplementedError();
  }

  /// Same as [[pull]], but accepts sequence of ids and returns sequence of maps.
  Future<List<PullResult>> pullMany(DB db, pattern, List<int> eids) {
    throw UnimplementedError();
  }

  /// Applies transaction to an immutable db value, returning new immutable db
  /// value. Same as `(:db-after (with db tx-data))`.
  Future dbWith(DB db, List entities) {
    throw UnimplementedError();
  }

  /// Retrieves an entity by its id from database. Entities are lazy map-like
  /// structures to navigate DataScript database content.
  Future entity(DB db, int eid) {
    throw UnimplementedError();
  }

  /// Forces all entity attributes to be eagerly fetched and cached. Only usable for debug output.
  Future touch(Object e) {
    throw UnimplementedError();
  }

  /// Returns a db that entity was created from.
  Future entityDb(Object e) {
    throw UnimplementedError();
  }

  /// Returns a view over database that has same interface but only includes
  /// datoms for which the `(pred db datom)` is true. Can be applied multiple
  /// times.
  Future filter(db, pred) {
    throw UnimplementedError();
  }

  /// Returns `true` if this database was filtered using [[filter]], `false`
  /// otherwise."
  Future<bool> isFiltered(DB db) {
    throw UnimplementedError();
  }

  /// Creates a mutable reference (a “connection”) to an empty immutable
  /// database inside JsRuntime.
  ///
  /// Returns the connection index number.
  int createConn({Schema? schema}) {
    String code = """
    state.conns.push(vendor.ds.create_conn(${jsonEncode(schema)}));
    """;
    final JsEvalResult result = jsEngine.evaluate(code);
    totalConnections += 1;
    return totalConnections - 1;
  }

  /// Creates a mutable reference to a given immutable database.
  /// See [[createConn]].
  Future connFromDb(DB db) {
    throw UnimplementedError();
  }

  /// Creates an empty DB and a mutable reference to it. See [createConn].
  Future connFromDatoms(dataoms, {Schema? schema}) {
    throw UnimplementedError();
  }

  /// Returns the underlying immutable database value from a connection.
  Future<DB> db(conn) {
    throw UnimplementedError();
  }

  /// Applies transaction the underlying database value and atomically updates
  /// connection reference to point to the result of that transaction, new db
  /// value.
  Future<void> transact(int conn, List txDeta, {txMeta}) async {
    var code = """
    vendor.ds.transact(state.conns[$conn],${jsonEncode(txDeta)}, ${jsonEncode(txMeta)});
    """;
    var result = await jsEngine.evaluateAsync(code);
    assert(!result.isError);
  }

  /// Forces underlying `conn` value to become `db`.
  /// Will generate a [TxReport] that will remove everything from old value
  /// and insert everything from the new one."
  Future resetConn(conn, db, {txMeta}) {
    throw UnimplementedError();
  }

  /// Listen for changes on the given connection.
  listen(int conn, String key, void Function (dynamic) callback) {
    jsEngine.onMessage(key, callback);
    var code = """
    vendor.ds.listen(state.conns[$conn], '$key', (report) => {
      sendMessage('$key', JSON.stringify(report));
    });
    """;
    var result = jsEngine.evaluate(code);
    assert(!result.isError, result.toString());
  }

  /// Removes registered listener from connection. See also [[listen!]].
  unListen(int conn, String key) {
    // FIXME: the listener should be removed properly.
    jsEngine.onMessage(key, (report) { });
    var code = """
    vendor.ds.unlisten(state.conns[$conn], '$key');
    """;
    var result = jsEngine.evaluate(code);
    assert(!result.isError, result.toString());
  }

  /// Does a lookup in tempids map, returning an entity id that tempid was
  /// resolved to.
  resolveTempid(Map tempids, int tempid) {
    throw UnimplementedError();
  }

  /// Index lookup. Returns a sequence of datoms (lazy iterator over actual DB
  /// index) which components (e, a, v) match passed arguments.
  Future<Function> datoms(
      db, index, Object? c1, Object? c2, Object? c3, Object? c4) {
    throw UnimplementedError();
  }

  /// Similar to [[datoms]], but will return datoms starting from specified
  /// components and including rest of the database until the end of the index.
  Future seekDatoms(db, index, Object? c1, Object? c2, Object? c3, Object? c4) {
    throw UnimplementedError();
  }

  /// Returns part of `:avet` index between `[_ attr start]` and `[_ attr end]`
  /// in AVET sort order.
  ///
  /// Same properties as [datoms].
  Future indexRange(DB db, attr, start, end) {
    throw UnimplementedError();
  }

  /// Generates a UUID that grow with time. Such UUIDs will always go to the
  /// end of the index and that will minimize insertions in the middle.
  ///
  /// @TODO: implemented by n Dart.
  Future<String> squuid({int? msec}) {
    throw UnimplementedError();
  }

  /// Returns time that was used in [[squuid]] call, in milliseconds, rounded
  /// to the closest second.
  ///
  /// @TODO: implemented by Dart.
  Future<int> squuidTimeMillis(uuid) {
    throw UnimplementedError();
  }
}
