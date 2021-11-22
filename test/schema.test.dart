import 'dart:convert';

import 'package:flutter_js_datascript/src/schema.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('SchemaBuilder', () {
    final builder = SchemaBuilder()
      ..attr('person/name',
          valueType: ValueType.ref,
          cardinality: Cardinality.many)
      ..attr('person/age');
    final s = builder.build();
    expect(jsonEncode(s), jsonEncode({
      "person/name": {
        ":db/valueType": ":db.type/ref",
        ":db/cardinality": ":db.cardinality/many"
      },
      "person/age": {
      }
    }));
  });
}
