/// Each database has a schema that describes the set of attributes that
/// can be associated with entities. A schema only defines the characteristics
/// of the attributes themselves. It does not define which attributes can be
/// associated with which entities. Decisions about which attributes apply to
/// which entities are made by an application.
import 'package:json_annotation/json_annotation.dart';

part 'schema.g.dart';

@JsonEnum()
enum Unique {
  /// :db.unique/value
  @JsonValue(':db.unique/value')
  value,

  ///  :db.unique/identity
  @JsonValue(':db.unique/identity')
  identity
}

@JsonEnum()
enum ValueType {
  /// :db.type/keyword such as :color
  @JsonValue(':db.type/keyword')
  keyword,

  /// :db.type/string "Hello"
  @JsonValue(':db.type/string')
  string,

  /// :db.type/boolean true|false
  @JsonValue(':db.type/boolean')
  boolean,

  /// :db.type/ref entity reference (entity id)
  @JsonValue(':db.type/ref')
  ref,

  /// :db.type/instant time in milliseconds
  @JsonValue(':db.type/instant')
  instant,

  /// :db.type/long Long integer
  @JsonValue(':db.type/long')
  long,

  /// :db.type/bigint Big integer
  @JsonValue(':db.type/bigint')
  bigint,

  /// :db.type/double Double
  @JsonValue(':db.type/double')
  double,

  /// :db.type/bigdec Big Decimal
  @JsonValue(':db.type/bigdec')
  bigdec,

  /// :db.type/uuid UUIDs (ie. unique IDs)
  @JsonValue(':db.type/uuid')
  uuid,

  /// :db.type/uri URIs
  @JsonValue(':db.type/uri')
  uri,

  /// :db.type/bytes binary data
  @JsonValue(':db.type/bytes')
  bytes
}

@JsonEnum()
enum Cardinality {
  // :db.cardinality/one Reference ONE value
  @JsonValue(':db.cardinality/one')
  one,

  // :db.cardinality/many Reference MANY values
  @JsonValue(':db.cardinality/many')
  many
}

@JsonSerializable()
class SchemaAttribute {
  @JsonKey(name: ':db/unique', includeIfNull: false)
  final Unique? ident;

  @JsonKey(name: ':db/valueType', includeIfNull: false)
  final ValueType? valueType;

  @JsonKey(name: ':db/cardinality', includeIfNull: false)
  final Cardinality? cardinality;

  @JsonKey(name: ':db/index', includeIfNull: false)
  final bool? index;

  @JsonKey(name: ':db/doc', includeIfNull: false)
  final String? doc;

  SchemaAttribute(
      this.ident, this.valueType, this.cardinality, this.index, this.doc);

  factory SchemaAttribute.fromJson(Map<String, dynamic> json) =>
      _$SchemaAttributeFromJson(json);
  Map<String, dynamic> toJson() => _$SchemaAttributeToJson(this);
}

typedef Schema = Map<String, SchemaAttribute>;

/// Build a <Schema>.
///
/// ```
/// final builder = SchemaBuilder()
///   ..attr('aka', cardinality: Cardinality.many)
///   ..attr('friend', valueType: ValueType.ref);
/// final schema = builder.build();
/// ```
class SchemaBuilder {
  /// The schema to build.
  final Schema schema = {};

  /// Registers an attribute.
  void attr(String name,
      {Unique? ident,
      ValueType? valueType,
      Cardinality? cardinality,
      bool? index,
      String? doc}) {
    schema[name] = SchemaAttribute(ident, valueType, cardinality, index, doc);
  }

  /// Returns built schema.
  Schema build() {
    return schema;
  }
}
