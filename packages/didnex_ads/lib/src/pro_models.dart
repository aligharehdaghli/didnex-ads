import 'package:flutter/services.dart';
import 'models.dart';

class DidnexContext {
  const DidnexContext({this.topics = const [], this.keywords = const [], this.language = 'fa'});
  final List<String> topics, keywords;
  final String language;
  Map<String, dynamic> toJson() => {'topics': topics, 'keywords': keywords, 'language': language};
}

class DidnexConsent {
  const DidnexConsent({required this.receipt, required this.externalAds, required this.analytics, required this.expiresAt});
  final String receipt;
  final bool externalAds, analytics;
  final DateTime expiresAt;
  bool get expired => !DateTime.now().isBefore(expiresAt);
  factory DidnexConsent.fromJson(Map<String, dynamic> json) => DidnexConsent(
    receipt: json['receipt'] as String,
    externalAds: (json['choices'] as Map)['externalAds'] == true,
    analytics: (json['choices'] as Map)['analytics'] == true,
    expiresAt: DateTime.fromMillisecondsSinceEpoch(json['expiresAt'] as int),
  );
}

class DidnexRevenue {
  const DidnexRevenue({required this.deliveryId, required this.amountRial, required this.estimatedRial, required this.status, required this.precision});
  final String deliveryId, status, precision;
  final double amountRial, estimatedRial;
  String get currency => 'IRR';
  factory DidnexRevenue.fromJson(Map<String, dynamic> json) {
    if (json['currency'] != 'IRR' || json['deliveryId'] is! String || json['amountRial'] is! num || json['estimatedRial'] is! num) {
      throw const DidnexAdException('invalid_revenue');
    }
    return DidnexRevenue(deliveryId: json['deliveryId'] as String, amountRial: (json['amountRial'] as num).toDouble(), estimatedRial: (json['estimatedRial'] as num).toDouble(), status: json['status'] as String, precision: json['precision'] as String);
  }
}

/// Implemented by the host's licensed measurement integration.
abstract interface class DidnexMeasurementAdapter {
  Future<void> start(DidnexAd ad);
  Future<void> event(DidnexAd ad, String kind);
  Future<void> finish(DidnexAd ad);
}

/// The native host registers its licensed OM engine. No engine means unavailable.
class DidnexNativeMeasurementAdapter implements DidnexMeasurementAdapter {
  const DidnexNativeMeasurementAdapter();
  static const _channel = MethodChannel('ir.didnex.ads/native');
  @override
  Future<void> start(DidnexAd ad) async {
    await _channel.invokeMethod<void>('omidStart', {'requestId': ad.requestId, 'format': ad.format.wireName, 'measurement': ad.measurement});
  }
  @override
  Future<void> event(DidnexAd ad, String kind) async {
    await _channel.invokeMethod<void>('omidEvent', {'requestId': ad.requestId, 'kind': kind});
  }
  @override
  Future<void> finish(DidnexAd ad) async {
    await _channel.invokeMethod<void>('omidFinish', {'requestId': ad.requestId});
  }
}

class DidnexInstallReferrer {
  const DidnexInstallReferrer({required this.referrer, required this.clickAt, required this.installedAt});
  final String referrer;
  final DateTime clickAt, installedAt;
  String? get clickId => Uri.splitQueryString(referrer)['didnex_click_id'];
  static const _channel = MethodChannel('ir.didnex.ads/native');
  static Future<DidnexInstallReferrer?> read() async {
    try {
      final map = await _channel.invokeMapMethod<String, dynamic>('installReferrer');
      if (map == null) return null;
      return DidnexInstallReferrer(referrer: map['referrer'] as String, clickAt: DateTime.fromMillisecondsSinceEpoch((map['clickTimestampSeconds'] as int) * 1000), installedAt: DateTime.fromMillisecondsSinceEpoch((map['installTimestampSeconds'] as int) * 1000));
    } on MissingPluginException { return null; }
  }
}
