import 'dart:convert';

import 'js.dart';

typedef Schema = Map;
typedef PullResult = Map;

/// Transaction Report
class TxReport {
  /// db value before transaction
  final JsRef dbBefore;

  /// db value after transaction
  final JsRef dbAfter;

  /// plain datoms that were added/retracted from db-before
  final List txData;

  /// map of tempid from tx-data => assigned entid in db-after
  final Map tempids;

  /// the exact value you passed as `tx-meta`
  final dynamic txMeta;

  TxReport(
      {required this.dbBefore,
      required this.dbAfter,
      required this.tempids,
      required this.txData,
      this.txMeta});
}

class FlutterDatascript {
  JsContext context;
  int totalConnections = 0;

  FlutterDatascript() : context = JsContext() {
    context.require('./assets/js/bundle.js', ['vendor.ds']);
  }

  /// Returns connections ids.
  List get connections => context.evaluate("Object.keys(state.connections)");

  /// Returns database ids.
  List get databases => context.evaluate("Object.keys(state.databases)");

  // -------------------------------------------------------------------------
  // JS public APIs.
  // -------------------------------------------------------------------------

  /// Creates an empty database with an optional schema.
  Future<JsRef> emptyDb({Schema? schema}) {
    throw UnimplementedError();
  }

  /// Low-level fn for creating database quickly from a trusted sequence of
  /// datoms.
  Future<JsRef> initDb({Schema? schema}) {
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
  Future q(String query, List inputs) async {
    final List<String> args = [jsonEncode(query)] + toJsCode(inputs);
    var code = """
    vendor.ds.q.apply(this, $args);
    """;
    return await context.evaluateAsync(code);
  }

  /// Fetches data from database using recursive declarative description.
  /// See [docs.datomic.com/on-prem/pull.html](https://docs.datomic.com/on-prem/pull.html).
  Future<List<PullResult>> pull(JsRef db, pattern, int eid) {
    throw UnimplementedError();
  }

  /// Same as [[pull]], but accepts sequence of ids and returns sequence of maps.
  Future<List<PullResult>> pullMany(JsRef db, pattern, List<int> eids) {
    throw UnimplementedError();
  }

  /// Applies transaction to an immutable db value, returning new immutable db
  /// value. Same as `(:db-after (with db tx-data))`.
  Future dbWith(JsRef db, List entities) {
    throw UnimplementedError();
  }

  /// Retrieves an entity by its id from database. Entities are lazy map-like
  /// structures to navigate DataScript database content.
  Future entity(JsRef db, int eid) {
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
  Future<bool> isFiltered(JsRef db) {
    throw UnimplementedError();
  }

  /// Creates a mutable reference (a “connection”) to an empty immutable
  /// database inside JsRuntime.
  ///
  /// Returns the connection ref.
  JsRef createConn({Schema? schema}) {
    return JsRef.define(context, 'connections',
        "vendor.ds.create_conn(${jsonEncode(schema)});");
  }

  /// Creates a mutable reference to a given immutable database.
  /// See [[createConn]].
  Future connFromDb(JsRef db) {
    throw UnimplementedError();
  }

  /// Creates an empty JsRef and a mutable reference to it. See [createConn].
  Future connFromDatoms(dataoms, {Schema? schema}) {
    throw UnimplementedError();
  }

  /// Creates the underlying immutable database from a connection.
  ///
  /// Returns database Id.
  JsRef db(JsRef conn) {
    return JsRef.define(
        context, 'databases', "vendor.ds.db(${conn.toJsCode()});");
  }

  /// Applies transaction the underlying database value and atomically updates
  /// connection reference to point to the result of that transaction, new db
  /// value.
  Future<Map> transact(JsRef conn, List txDeta, {txMeta}) async {
    var code = """
    vendor.ds.transact(${conn.toJsCode()},${jsonEncode(txDeta)}, ${jsonEncode(txMeta)});
    """;
    return await context.evaluateAsync(code);
  }

  /// Forces underlying `conn` value to become `db`.
  /// Will generate a [TxReport] that will remove everything from old value
  /// and insert everything from the new one."
  Future resetConn(conn, db, {txMeta}) {
    throw UnimplementedError();
  }

  /// Listen for changes on the given connection.
  /// @FIXME: convert Js-TxReport to Dart-TxReport.
  listen(JsRef conn, String key, void Function(dynamic) callback) {
    context.runtime.onMessage(key, callback);
    var code = """
    vendor.ds.listen(${conn.toJsCode()}, '$key', (report) => {
      sendMessage('$key', JSON.stringify(report));
    });
    """;
    return context.evaluate(code);
  }

  /// Removes registered listener from connection. See also [[listen!]].
  unListen(JsRef conn, String key) {
    // FIXME: the listener should be removed properly.
    context.runtime.onMessage(key, (report) {});
    var code = """
    vendor.ds.unlisten(${conn.toJsCode()}, '$key');
    """;
    return context.evaluate(code);
  }

  /// Does a lookup in tempids map, returning an entity id that tempid was
  /// resolved to.
  resolveTempid(Map tempids, int tempid) {
    throw UnimplementedError();
  }

  /// Index lookup. Returns a sequence of datoms (lazy iterator over actual JsRef
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
  Future indexRange(JsRef db, attr, start, end) {
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
