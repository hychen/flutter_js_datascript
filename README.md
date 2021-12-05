<!--
This README describes the package. If you publish this package to pub.dev,
this README's contents appear on the landing page for your package.

For information about how to write a good package README, see the guide for
[writing package pages](https://dart.dev/guides/libraries/writing-package-pages).

For general information about developing packages, see the Dart guide for
[creating packages](https://dart.dev/guides/libraries/create-library-packages)
and the Flutter guide for
[developing packages and plugins](https://flutter.dev/developing-packages).
-->

Using DataScript in Flutter Apps.

> This package is in very early stage and only be tested on MacOS. Use it with caution and file
any potential issues you see.

## Features

Use this package to
- Transact with Datoms.
- Query result by using [datalog](https://en.wikipedia.org/wiki/Datalog) language.

### Supported APIs:
  - creteConn
  - q
  - listen
  - unlisten
  - initDb
  - datoms
  - pull
  - pullMany
  - connFromDb
  - connFromDatoms
  - resetConn
  - initDb
  - dbWith
  - emptyDb
  - entityDb
  - entity
  - touch
  - resolveTempids

## Getting started

```shell
flutter pub add flutter_js_datascript
```

## Usage

```dart
import 'package:flutter_js_datascript/flutter_js_datascript.dart';

void main() async {
    var d = Datascript();

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
    print(result);  // [["Igor"]]
}
```
