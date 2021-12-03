import 'dart:convert';

import 'package:flutter_js_context/flutter_js_context.dart';
import 'package:flutter_js_datascript/src/txreport.dart';
import 'package:flutter_js_datascript/src/entity.dart';
import 'datom.dart';
import 'schema.dart';
import 'assets.dart';

class DataScript {
  JsContext context;

  DataScript() : context = JsContext() {
    context.evaluate(jsBundle);
  }

  /// Returns connections ids.
  List get connections =>
      context.evaluate("Object.keys(${context.stateVarName}.connections)");

  /// Returns database ids.
  List get databases =>
      context.evaluate("Object.keys(${context.stateVarName}.databases)");

  // -------------------------------------------------------------------------
  // JS public APIs.
  // -------------------------------------------------------------------------

  /// Creates an empty database with an optional schema.
  JsRef emptyDb({dynamic schema}) {
    return JsRef.define(
        context, 'databases', "vendor.ds.empty_db(${jsonEncode(schema)});");
  }

  /// Low-level fn for creating database quickly from a trusted sequence of
  /// datoms.
  JsRef initDb(datoms, {Schema? schema}) {
    return JsRef.define(context, 'databases',
        "vendor.ds.init_db(${jsonEncode(datoms)}, ${jsonEncode(schema)});");
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
  Future<dynamic> pull(JsRef db, pattern, lookup) {
    final code = """
    vendor.ds.pull(${db.toJsCode()}, '$pattern', ${jsonEncode(lookup)});
    """;
    return context.evaluateAsync(code);
  }

  /// Same as [pull], but accepts sequence of ids and returns sequence of maps.
  Future<dynamic> pullMany(JsRef db, pattern, List lookup) {
    assert(lookup.isNotEmpty);
    final code = """
    vendor.ds.pull_many(${db.toJsCode()}, '$pattern', ${jsonEncode(lookup)});
    """;
    return context.evaluateAsync(code);
  }

  /// Applies transaction to an immutable db value, returning new immutable db
  /// value. Same as `(:db-after (with db tx-data))`.
  ///
  /// ```
  /// var db = d.emptyDb();
  /// var db1 = await d.dbWith(db, [[":db/add", 1, "name", "Ivan"],
  ///                               [":db/add", 1, "age", 17]]);
  /// ```
  Future<JsRef> dbWith(JsRef db, List entities) async {
    return JsRef.define(context, 'databases',
        """vendor.ds.db_with(${db.toJsCode()}, ${jsonEncode(entities)});""");
  }

  /// Retrieves an entity by its id from database. Entities are lazy map-like
  /// structures to navigate DataScript database content.
  Entity entity(JsRef db, eid) {
    return Entity(context, db, eid);
  }

  /// Forces all entity attributes to be eagerly fetched and cached. Only usable for debug output.
  List touch(Entity e) {
    return e.entries.toList();
  }

  /// Returns a db that entity was created from.
  JsRef entityDb(Entity e) {
    return e.db;
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
  /// See [createConn].
  JsRef connFromDb(JsRef db) {
    return JsRef.define(
        context, 'databases', "vendor.ds.conn_from_db(${db.toJsCode()});");
  }

  /// Creates an empty JsRef and a mutable reference to it. See [createConn].
  JsRef connFromDatoms(dataoms, {Schema? schema}) {
    return JsRef.define(context, 'databases',
        "vendor.ds.conn_from_datoms(${jsonEncode(dataoms)}, ${jsonEncode(schema)});");
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
  Future<TxReport> transact(JsRef conn, List txData, {txMeta}) async {
    var code = """
    vendor.ds.transact(${conn.toJsCode()},${jsonEncode(txData)}, ${jsonEncode(txMeta)});
    """;
    return TxReport.fromJson(await context.evaluateAsync(code));
  }

  /// Forces underlying `conn` value to become `db`.
  /// Will generate a [TxReport] that will remove everything from old value
  /// and insert everything from the new one."
  resetConn(JsRef conn, JsRef db, {txMeta}) {
    final code = """
    vendor.ds.reset_conn(${conn.toJsCode()}, ${db.toJsCode()}, ${jsonEncode(txMeta)});
    """;
    return context.evaluate(code);
  }

  /// Listen for changes on the given connection.
  listen(JsRef conn, String key, void Function(dynamic) callback) {
    context.runtime.onMessage(key, (json) => callback(TxReport.fromJson(json)));
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
  resolveTempid(Map tempids, tempid) {
    return tempids[tempid.toString()];
  }

  /// Index lookup. Returns a sequence of datoms (lazy iterator over actual Db
  /// index) which components (e, a, v) match passed arguments.
  datoms(
      JsRef db, String index, Object? c1, Object? c2, Object? c3, Object? c4) {
    final code = """
    vendor.ds.datoms(${db.toJsCode()}, '$index', ${jsonEncode(c1)}, ${jsonEncode(c2)}, ${jsonEncode(c3)}, ${jsonEncode(c4)});
    """;
    var res = context.evaluate(code) as List;
    return toEavt(res);
  }

  /// Similar to [[datoms]], but will return datoms starting from specified
  /// components and including rest of the database until the end of the index.
  seekDatoms(db, index, Object? c1, Object? c2, Object? c3, Object? c4) {
    final code = """
    vendor.ds.seek_datoms(${db.toJsCode()}, '$index', ${jsonEncode(c1)}, ${jsonEncode(c2)}, ${jsonEncode(c3)}, ${jsonEncode(c4)});
    """;
    var res = context.evaluate(code) as List;
    return toEavt(res);
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
