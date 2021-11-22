import 'package:flutter_js_context/flutter_js_context.dart';

/// Transaction Report
class TxReport {
  /// db value before transaction
  final JsRef dbBefore;

  /// db value after transaction
  final JsRef dbAfter;

  /// plain datoms that were added/retracted from db-before
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
}
