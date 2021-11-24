import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_js_datascript/flutter_js_datascript.dart';

void main() {

  test('js-like example works', () async {
    var d = DataScript();

    // create DB schema, a regular JS Object
    final builder = SchemaBuilder()
      ..attr('aka', cardinality: Cardinality.many)
      ..attr('friend', valueType: ValueType.ref);
    final schema = builder.build();

    // Use JS API to create connection and add data to DB
    // create connection using schema
    var conn = d.createConn(schema: schema);

    // setup listener called main
    // pushes each entity (report) to an Array of reports
    // This is just a simple example. Make your own!
    var reports = [];
    d.listen(conn, 'main', (report) {
      reports.add(report);
    });

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
    var report = d.transact(conn, datoms, txMeta: "initial info about Igor and Ivan");

    var db = d.db(conn);

    // Fetch names of people who are friends with someone 18 years old
    // query values from conn with JS API
    var result = await d.q(
        '[:find ?n :in \$ ?a :where [?e "friend" ?f] [?e "age" ?a] [?f "name" ?n]]',
        [db, 18]);
    // print query result to console!
    expect(result, [["Igor"]]); // [["Igor"]]
  });
}
