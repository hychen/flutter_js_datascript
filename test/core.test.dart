import 'package:flutter_js_context/flutter_js_context.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_js_datascript/src/core.dart';

void main() {
  test('emptyDb', () {
    final d = DataScript();
    final db1 = d.emptyDb();
    expect(d.databases[0], db1.key);
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
