import 'package:flutter_js_context/flutter_js_context.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_js_datascript/src/core.dart';
import 'package:flutter_js_datascript/src/schema.dart';

void main() {
  test('emptyDb', () {
    final d = DataScript();
    final db1 = d.emptyDb();
    expect(d.databases[0], db1.key);
  });

  test('dbWith', () async {
    final d = DataScript();
    final db = d.emptyDb();
    final db1 = await d.dbWith(db, [
      [":db/add", 1, "name", "Ivan"],
      [":db/add", 1, "age", 17]
    ]);
    final db2 = await d.dbWith(db1, [
      {":db/id": 2, "name": "Igor", "age": 35}
    ]);
    var q = '[:find ?n ?a :where [?e "name" ?n] [?e "age" ?a]]';
    expect([
      ["Ivan", 17]
    ], await d.q(q, [db1]));
    expect([
      ["Ivan", 17],
      ["Igor", 35]
    ], await d.q(q, [db2]));
  });

  test('nested maps', () async {
    var q = '[:find ?e ?a ?v :where [?e ?a ?v]]';
    var d = DataScript();
    var schema = SchemaBuilder()
      ..attr("profile", valueType: ValueType.ref)
      ..attr("friend", valueType: ValueType.ref, cardinality: Cardinality.many);
    var db0 = d.emptyDb(schema: schema.build());
    var db = await d.dbWith(db0, [
      {
        "name": "Igor",
        "profile": {"email": "@2"}
      }
    ]);
    expect([
      [1, "name", "Igor"],
      [1, "profile", 2],
      [2, "email", "@2"]
    ], await d.q(q, [db]));

    db = await d.dbWith(db0, [
      {":db/id": 1, "name": "Igor"},
      {
        ":db/id": 2,
        "name": "Oleg",
        "profile": {":db/id": 1}
      }
    ]);
    expect([
      [1, "name", "Igor"],
      [2, "name", "Oleg"],
      [2, "profile", 1]
    ], await d.q(q, [db]));

    db = await d.dbWith(db0, [
      {":db/id": 1, "name": "Igor"},
      {":db/id": 2, "name": "Ivan"},
      {
        ":db/id": 3,
        "name": "Oleg",
        "friend": [
          {":db/id": 1},
          {":db/id": 2}
        ]
      }
    ]);
    expect([
      [1, "name", "Igor"],
      [2, "name", "Ivan"],
      [3, "friend", 1],
      [3, "friend", 2],
      [3, "name", "Oleg"]
    ], await d.q(q, [db]));

    db = await d.dbWith(db0, [
      {
        "email": "@2",
        "_profile": {"name": "Igor"}
      }
    ]);
    expect([
      [1, "email", "@2"],
      [2, "name", "Igor"],
      [2, "profile", 1]
    ], await d.q(q, [db]));

    schema = SchemaBuilder()
      ..attr("user/profile", valueType: ValueType.ref);
    db0 = d.emptyDb(schema: schema.build());
    db = await d.dbWith(db0, [
      {
        "name": "Igor",
        "user/profile": {"email": "@2"}
      }
    ]);
    expect([
      [1, "name", "Igor"],
      [1, "user/profile", 2],
      [2, "email", "@2"]
    ], await d.q(q, [db]));

    db = await d.dbWith(db0, [
      {
        "email": "@2",
        "user/_profile": {"name": "Igor"}
      }
    ]);
    expect([
      [1, "email", "@2"],
      [2, "name", "Igor"],
      [2, "user/profile", 1]
    ], await d.q(q, [db]));
  });

  test('createConn', () {
    final d = DataScript();
    // key are not the same.
    final JsRef ref1 = d.createConn();
    final JsRef ref2 = d.createConn();
    expect(ref1.key != ref2.key, true);
    expect(d.connections[0], ref1.key);
    expect(d.connections[1], ref2.key);
  });

  test('transact', () async {
    var d = DataScript();
    var connId = await d.createConn();
    // define initial datoms to be used in transaction
    var datoms = [
      {
        ":db/id": -1,
        "name": "Ivan",
        "age": 18,
        "aka": ["X", "Y"]
      },
      {
        ":db/id": -2,
        "name": "Igor",
        "aka": ["Grigory", "Egor"]
      },
      // use :db/add to link datom -2 as friend of datom -1
      [":db/add", -1, "friend", -2]
    ];

    // Tx is Js Array of Object or Array
    // pass datoms as transaction data
    await d.transact(connId, datoms,
        txMeta: "initial info about Igor and Ivan");
  });

  test('triggers TxReport', () async {
    var d = DataScript();
    var connId = d.createConn();
    var datoms = [
      {
        ":db/id": -1,
        "name": "Ivan",
        "age": 18,
        "aka": ["X", "Y"]
      },
      {
        ":db/id": -2,
        "name": "Igor",
        "aka": ["Grigory", "Egor"]
      },
      // use :db/add to link datom -2 as friend of datom -1
      [":db/add", -1, "friend", -2]
    ];
    var r;
    d.listen(connId, 'main', expectAsync1((report) {
      r = report;
    }));

    await d.transact(connId, datoms, txMeta: "oops");
    expect(r.txMeta, 'oops');
  });
}
