import 'package:flutter_js_datascript/flutter_js_datascript.dart';
import 'package:flutter_js_datascript/src/entity.dart';
import 'package:flutter_test/flutter_test.dart';

void main() async {
  group('Entity', () {
    var d;
    var db;
    var db1;

    setUp(() async {
      d = DataScript();
      db = d.emptyDb();
      db1 = await d.dbWith(db, [
        [":db/add", 1, "name", "Ivan"],
        [":db/add", 1, "age", 17]
      ]);
    });
    test('delegated JS functions.', () async {
      dynamic e = EntityJsApi(d.context, db1, 1);
      expect(e.has('age'), true);
      expect(e.get('name'), 'Ivan');
      expect(e.get('age'), 17);
      expect(e.keySet(), ['age', 'name']);
      expect(e.valueSet(), [17, 'Ivan']);
      expect(e.entrySet(), [
        ['age', 17],
        ['name', 'Ivan']
      ]);
    });

    test('implements Map interface', () async {
      final e = Entity(d.context, db1, 1);

      expect(e['age'], 17);
      expect(e.isEmpty, false);
      expect(e.isNotEmpty, true);
      expect(e.keys, ['age', 'name']);
      expect(e.values, [17, 'Ivan']);
      expect(e.containsKey('name'), true);
      expect(e.containsKey('g'), false);
      expect(e.containsValue('Ivan'), true);
      expect(e.containsValue('g'), false);

      e.forEach((key, value) {
        expect(key == 'age' || key == 'name', true);
        expect(value == 17 || value == 'Ivan', true);
      });

      final ne = e.map((key, value) => MapEntry(key + "_", value));
      expect(ne['age_'], 17);
    });
  });
}
