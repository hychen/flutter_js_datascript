import 'package:json_annotation/json_annotation.dart';
import 'datom.dart';

part 'txreport.g.dart';

txDataFromJson(List txData) {
  return toEavt(txData);
}

/// Transaction Report
@JsonSerializable(fieldRename: FieldRename.snake)
class TxReport {
  /// db value before transaction
  final Map dbBefore;

  /// db value after transaction
  final Map dbAfter;

  /// plain datoms that were added/retracted from db-before
  @JsonKey(fromJson: txDataFromJson)
  final List txData;

  /// map of tempid from tx-data => assigned entid in db-after
  final Map tempids;

  /// the exact value you passed as `tx-meta`
  final dynamic txMeta;

  TxReport(
      {required this.dbBefore,
      required this.dbAfter,
      required this.tempids,
      required this.txData,
      this.txMeta});

  factory TxReport.fromJson(Map<String, dynamic> json) =>
      _$TxReportFromJson(json);
  Map<String, dynamic> toJson() => _$TxReportToJson(this);
}
