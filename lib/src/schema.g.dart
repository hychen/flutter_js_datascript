// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'schema.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SchemaAttribute _$SchemaAttributeFromJson(Map<String, dynamic> json) =>
    SchemaAttribute(
      $enumDecodeNullable(_$ValueTypesEnumMap, json[':db/valueType']),
      $enumDecodeNullable(_$CardinalityEnumMap, json[':db/cardinality']),
      json[':db/doc'] as String?,
    );

Map<String, dynamic> _$SchemaAttributeToJson(SchemaAttribute instance) {
  final val = <String, dynamic>{};

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull(':db/valueType', _$ValueTypesEnumMap[instance.valueType]);
  writeNotNull(':db/cardinality', _$CardinalityEnumMap[instance.cardinality]);
  writeNotNull(':db/doc', instance.doc);
  return val;
}

const _$ValueTypesEnumMap = {
  ValueType.keyword: ':db.type/keyword',
  ValueType.string: ':db.type/string',
  ValueType.boolean: ':db.type/boolean',
  ValueType.ref: ':db.type/ref',
  ValueType.instant: ':db.type/instant',
  ValueType.long: ':db.type/long',
  ValueType.bigint: ':db.type/bigint',
  ValueType.double: ':db.type/double',
  ValueType.bigdec: ':db.type/bigdec',
  ValueType.uuid: ':db.type/uuid',
  ValueType.uri: ':db.type/uri',
  ValueType.bytes: ':db.type/bytes',
};

const _$CardinalityEnumMap = {
  Cardinality.one: ':db.cardinality/one',
  Cardinality.many: ':db.cardinality/many',
};
