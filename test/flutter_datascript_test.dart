import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_js_datascript/flutter_js_datascript.dart';
import 'package:collection/collection.dart';

Function eq = const DeepCollectionEquality.unordered().equals;

main() {
  final d = DataScript();
  group('DataScript', () {
    test('.dbWith()', () async {
      final db = d.emptyDb();
      final db1 = await d.dbWith(db, [
        [":db/add", 1, "name", "Ivan"],
        [":db/add", 1, "age", 17]
      ]);
      final db2 = await d.dbWith(db1, [
        {":db/id": 2, "name": "Igor", "age": 35}
      ]);
      const q = '[:find ?n ?a :where [?e "name" ?n] [?e "age" ?a]]';
      expect([
        ["Ivan", 17]
      ], await d.q(q, [db1]));
      expect([
        ["Ivan", 17],
        ["Igor", 35]
      ], await d.q(q, [db2]));
    });

    test('nested maps', () async {
      const q = '[:find ?e ?a ?v :where [?e ?a ?v]]';
      var schema = SchemaBuilder()
        ..attr("profile", valueType: ValueType.ref)
        ..attr("friend",
            valueType: ValueType.ref, cardinality: Cardinality.many);
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

    test('.initDb()', () {}, skip: 'TODO: add initDb().');

    test('db.fn/call', () {}, skip: 'TODO: add db.fn/call support');

    test('schema', () async {
      final schema = {
        "aka": {":db/cardinality": ":db.cardinality/many"}
      };
      final db = await d.dbWith(d.emptyDb(schema: schema), [
        [":db/add", -1, "name", "Ivan"],
        [":db/add", -1, "aka", "X"],
        [":db/add", -1, "aka", "Y"],
        {
          ":db/id": -2,
          "name": "Igor",
          "aka": ["F", "G"]
        }
      ]);
      const q = '[:find ?aka :in \$ ?e :where [?e "aka" ?aka]]';
      expect([
        ["X"],
        ["Y"]
      ], await d.q(q, [db, 1]));
      expect([
        ["F"],
        ["G"]
      ], await d.q(q, [db, 2]));
    });

    test('txreport', () {}, skip: 'TODO: add txreport test');

    test('.entity()', () async {
      final schema = {
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
      var a = [
        const MapEntry("name", "Ivan"),
        const MapEntry("aka", ["X", "Y"])
      ].reversed.toList()[0];
      var b = e.entries.toList()[0];
      expect(a.key, b.key);

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
      var schema = {
        "father": {":db/valueType": ":db.type/ref"},
        "children": {
          ":db/valueType": ":db.type/ref",
          ":db/cardinality": ":db.cardinality/many"
        }
      };
      var db = await d.dbWith(d.emptyDb(schema: schema), [
        {
          ":db/id": 1,
          "children": [10]
        },
        {
          ":db/id": 10,
          "father": 1,
          "children": [100, 101]
        },
        {":db/id": 100, "father": 10}
      ]);

      e(id) {
        return d.entity(db, id);
      }

      ;

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

    test('conn', () async {
      var tx0 = 0;
      var datoms = [
        [1, "age", 17, tx0 + 1],
        [1, "name", "Ivan", tx0 + 1]
      ];
      var conn = await d.connFromDatoms(datoms);
      expect(datoms, d.datoms(d.db(conn), ":eavt", null, null, null, null));

      conn = await d.connFromDb(await d.initDb()); //datoms));
      expect(datoms, d.datoms(d.db(conn), ":eavt", null, null, null, null));

      var datoms2 = [
        [1, "age", 20, tx0 + 1],
        [1, "sex", "male", tx0 + 1]
      ];
      d.resetConn(conn, await d.initDb()); //datoms2));
      expect(datoms2, d.datoms(d.db(conn), ":eavt", null, null, null, null));
    }, skip: 'TODO: add datoms, initDb, connFromDatoms..');

    test('pull', () async {
      var d = DataScript();
      var schema = {
        "father": {":db/valueType": ":db.type/ref"},
        "children": {
          ":db/valueType": ":db.type/ref",
          ":db/cardinality": ":db.cardinality/many"
        }
      };
      var db = await d.dbWith(d.emptyDb(schema: schema), [
        {
          ":db/id": 1,
          "name": "Ivan",
          "children": [10]
        },
        {
          ":db/id": 10,
          "father": 1,
          "children": [100, 101]
        },
        {":db/id": 100, "father": 10}
      ]);

      var actual, expected;

      actual = await d.pull(db, '["children"]', 1);
      expected = {
        "children": [
          {":db/id": 10}
        ]
      };
      expect(expected, actual);

      actual = await d.pull(db, '["children", {"father" ["name" :db/id]}]', 10);
      expected = {
        "children": [
          {":db/id": 100},
          {":db/id": 101}
        ],
        "father": {"name": "Ivan", ":db/id": 1}
      };
      expect(expected, actual);
    });

    test('resolve_current_tx', () {}, skip: 'tx ');
  });

  group('query', () {
    late var people_db;
    setUp(() async {
      people_db = await d.dbWith(
          d.emptyDb(schema: {
            "age": {":db/index": true}
          }),
          [
            {":db/id": 1, "name": "Ivan", "age": 15},
            {":db/id": 2, "name": "Petr", "age": 37},
            {":db/id": 3, "name": "Ivan", "age": 37}
          ]);
    });

    test('q_coll', () async {
      expect(
          [
            [1, "Ivan"],
            [2, "Petr"],
            [3, "Ivan"]
          ],
          await d.q("""[:find ?e ?name
                  :in   \$ [?name ...]
                  :where [?e "name" ?name]]""", [
            people_db,
            ["Ivan", "Petr"]
          ]));

      expect(
          [
            [1],
            [2]
          ],
          await d.q("""[:find ?x
                  :in   [?x ...]
                  :where [(pos? ?x)]]""", [
            [-2, -1, 0, 1, 2]
          ]));
    });

    test('q_relation', () async {
      var res = await d.q("""[:find ?e ?email
              :in    \$ \$b
              :where [?e "name" ?n]
          [\$b ?n ?email]]""", [
        people_db,
        [
          ["Ivan", "ivan@mail.ru"],
          ["Petr", "petr@gmail.com"]
        ]
      ]);

      expect(
          eq([
            [1, "ivan@mail.ru"],
            [2, "petr@gmail.com"],
            [3, "ivan@mail.ru"]
          ], res),
          true);

      res = await d.q("""[:find ?e ?email
              :in    \$ [[?n ?email]]
              :where [?e "name" ?n]]""", [
        people_db,
        [
          ["Ivan", "ivan@mail.ru"],
          ["Petr", "petr@gmail.com"]
        ]
      ]);

      expect(
          eq([
            [1, "ivan@mail.ru"],
            [2, "petr@gmail.com"],
            [3, "ivan@mail.ru"]
          ], res),
          true);
    });

    test('q_rules', () async {
      final res = await d.q("""[:find ?e1 ?e2
              :in    \$ %
              :where (mate ?e1 ?e2)
      [(< ?e1 ?e2)]]""", [
        people_db,
        """[[(mate ?e1 ?e2)
      [?e1 "name" ?n]
      [?e2 "name" ?n]]
      [(mate ?e1 ?e2)
      [?e1 "age" ?a]
      [?e2 "age" ?a]]]"""
      ]);
      expect([
        [1, 3],
        [2, 3]
      ], res);
    });

    test('q_fn', () {}, skip: 'TODO: add q_fn');

    test('find_specs', () async {
      var res = await d.q("""[:find [?name ...] \
              :where [_ "name" ?name]]""", [people_db]);
      expect(["Ivan", "Petr"], res);

      res = await d.q("""[:find [?name ?age]
              :where [1 "name" ?name]
          [1 "age" ?age]]""", [people_db]);
      expect(["Ivan", 15], res);

      res = await d.q("""[:find ?name .
              :where [1 "name" ?name]]""", [people_db]);
      expect("Ivan", res);
    });

    test('datoms', () {}, skip: '@TODO: add datoms, seek_datoms');

    test('filter', () {}, skip: '@TODO: add filter');
  });

  test('upsert()', () async {
    final schema = SchemaBuilder()
      ..attr(':my/tid', ident: Unique.identity);
    var conn = await d.createConn(schema: schema.build());

    d.transact(conn, [
      {":my/tid": "5x", ":my/name": "Terin"}
    ]);

    d.transact(conn, [
      {":my/tid": "5x", ":my/name": "Charlie"}
    ]);

    var names = await d.q(
        '[:find ?name :where [?e ":my/tid" "5x"] [?e ":my/name" ?name]]',
        [d.db(conn)]);
    expect([
      ["Charlie"]
    ], names);
  });
}
