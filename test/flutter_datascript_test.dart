import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_datascript/flutter_datascript.dart';

void main() {
  test('createConn', () {
    var d = FlutterDatascript();
    d.createConn();
    d.createConn();
    expect(d.createConn(), 2);
    expect(d.totalConnections, 3);
  });

  test('transact', () async {
    var d = FlutterDatascript();
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
    await d.transact(connId, datoms, txMeta: "initial info about Igor and Ivan");
  });

  test('js-like example works', () async {
    var d = FlutterDatascript();

    // create DB schema, a regular JS Object
    var schema = {
      "aka": {":db/cardinality": ":db.cardinality/many"},
      "friend": {":db/valueType": ":db.type/ref"}
    };

    // Use JS API to create connection and add data to DB
    // create connection using schema
    var conn = await d.createConn(schema: schema);

    // setup listener called main
    // pushes each entity (report) to an Array of reports
    // This is just a simple example. Make your own!
    var reports = [];
    d.listen(conn, (report) => {reports.add(report)}, key: 'main');

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
    await d.transact(conn, datoms, txMeta: "initial info about Igor and Ivan");

    var db = await d.db(conn);
    // Fetch names of people who are friends with someone 18 years old
    // query values from conn with JS API
    var result = await d.q(
        '[:find ?n :in \$ ?a :where [?e "friend" ?f] [?e "age" ?a] [?f "name" ?n]]',
        [db, 18]);

    // print query result to console!
    expect(result, [["Igor"]]); // [["Igor"]]
  });
}
