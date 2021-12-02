import 'package:flutter/foundation.dart';
import 'package:flutter_js_context/flutter_js_context.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_js_datascript/src/core.dart';
import 'package:flutter_js_datascript/src/schema.dart';

import 'package:collection/collection.dart';

void main() {
  test('emptyDb', () {
    final d = DataScript();
    final db1 = d.emptyDb();
    expect(d.databases[0], db1.key);
  });

  test('entity', () async {
    var d = DataScript();
    var schema = {
      "aka": {":db/cardinality": ":db.cardinality/many"}
    };
    var db = await d.dbWith(d.emptyDb(schema: schema), [
      {
        ":db/id": 1,
        "name": "Ivan",
        "aka": ["X", "Y"]
      },
      {":db/id": 2}
    ]);
    var e = d.entity(db, 1);
    expect("Ivan", e["name"]);
    expect(["X", "Y"], e["aka"]);
    expect(1, e[":db/id"]);

    expect(db, e.db);

    var e2 = d.entity(db, 2);
    expect(null, e2["name"]);
    expect(null, e2["aka"]);
    expect(2, e2[":db/id"]);

    // Dart/map interface
    expect(["name", "aka"].reversed, e.keys);
    expect(
        [
          "Ivan",
          ["X", "Y"]
        ].reversed,
        e.values);
    var a =
        [
          const MapEntry("name", "Ivan"),
          const MapEntry("aka", ["X", "Y"])
        ].reversed.toList()[0];
    var b = e.entries.toList()[0];
    expect(a.key,b.key);


    var foreach = [];
    e.forEach((v, a) {
      foreach.add([a, v]);
    });
    expect(
        [
          const MapEntry("name", "Ivan"),
          const MapEntry("aka", ["X", "Y"])
        ].reversed.toList()[0].key,
        foreach[0][1]);
  });

  test('entity_refs', () async {
    var d = DataScript();
    var schema = {"father": {":db/valueType": ":db.type/ref"},
      "children": {":db/valueType": ":db.type/ref",
        ":db/cardinality": ":db.cardinality/many"}};
    var db = await d.dbWith(d.emptyDb(schema: schema),
        [{":db/id": 1, "children": [10]},
          {":db/id": 10, "father": 1, "children": [100, 101]},
          {":db/id": 100, "father": 10}]);

    e(id) {
      return d.entity(db, id);
    };

    expect([10], e(1)["children"]);
    expect([101, 100].reversed, e(10)["children"]);

    // empty attribute
    expect(null, e(100)["children"]);

    // nested navigation
    // expect([100, 101], e(1)["children"][0].get("children"));
    // expect(10, e(10)["children"][0].get("father").get(":db/id"));
    // expect([10], e(10)[("father")].("children"));
    //
    // // backward navigation
    // expect(null, e(1).get("_children"));
    // expect([10], e(1).get("_father"));
    // expect([1], e(10).get("_children"));
    // expect([100], e(10).get("_father"));
    // expect([1], e(100).get("_children")[0].get("_children"));
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

    var meq = const MapEquality();
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

    schema = SchemaBuilder()..attr("user/profile", valueType: ValueType.ref);
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
