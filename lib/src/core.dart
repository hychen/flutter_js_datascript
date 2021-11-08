typedef DB = Object;
typedef Schema = Map;
typedef PullResult = Map;

/// Transaction Report
class TxReport {
  /// db value before transaction
  final DB dbBefore;

  /// db value after transaction
  final DB dbAfter;

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
