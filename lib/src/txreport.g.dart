// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'txreport.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TxReport _$TxReportFromJson(Map<String, dynamic> json) => TxReport(
      dbBefore: json['db_before'] as Map<String, dynamic>,
      dbAfter: json['db_after'] as Map<String, dynamic>,
      tempids: json['tempids'] as Map<String, dynamic>,
      txData: json['tx_data'] as List<dynamic>,
      txMeta: json['tx_meta'],
    );

Map<String, dynamic> _$TxReportToJson(TxReport instance) => <String, dynamic>{
      'db_before': instance.dbBefore,
      'db_after': instance.dbAfter,
      'tx_data': instance.txData,
      'tempids': instance.tempids,
      'tx_meta': instance.txMeta,
    };
