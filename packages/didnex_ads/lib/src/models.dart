import 'dart:math';

class DidnexAdException implements Exception {
  const DidnexAdException(this.code, [this.statusCode]);
  final String code;
  final int? statusCode;
  @override
  String toString() =>
      'DidnexAdException($code${statusCode == null ? '' : ', $statusCode'})';
}

enum DidnexPlatform { android, ios }

/// A coarse layout class; never a device or advertising identifier.
enum DidnexDeviceClass { mobile, tablet, unknown }

enum DidnexAdFormat {
  banner('banner'),
  adaptiveBanner('adaptive_banner'),
  native('native'),
  nativeVideo('native_video'),
  video('video'),
  interstitial('interstitial'),
  rewarded('rewarded'),
  rewardedInterstitial('rewarded_interstitial'),
  appOpen('app_open'),
  playable('playable'),
  audio('audio'),
  carousel('carousel'),
  poll('poll');

  const DidnexAdFormat(this.wireName);
  final String wireName;
  bool get isRewarded => this == rewarded || this == rewardedInterstitial;
  bool get isFullscreen =>
      isRewarded || this == interstitial || this == appOpen || this == playable;
  static DidnexAdFormat fromWire(Object? value) => values.firstWhere(
        (v) => v.wireName == value,
        orElse: () => throw const DidnexAdException('unsupported_format'),
      );
}

enum DidnexAdEventType {
  loaded,
  impression,
  click,
  noFill,
  error,
  expired,
  videoStart,
  videoComplete,
  audioStart,
  audioComplete,
}

class DidnexAdEvent {
  const DidnexAdEvent(
    this.type, {
    this.requestId,
    this.code,
    this.latency,
    this.diagnostic = false,
  });
  final DidnexAdEventType type;
  final String? requestId;
  final String? code;
  final Duration? latency;
  final bool diagnostic;
}

Uri didnexHttpsUri(Object? value) {
  final uri = value is Uri ? value : Uri.tryParse(value is String ? value : '');
  if (uri == null ||
      uri.scheme != 'https' ||
      uri.host.isEmpty ||
      uri.userInfo.isNotEmpty) {
    throw const DidnexAdException('https_required');
  }
  return uri;
}

class DidnexAdPolicy {
  const DidnexAdPolicy({
    this.sessionCap = 5,
    this.minimumInterval = Duration.zero,
    this.timeout = const Duration(seconds: 5),
    this.maxVideoDuration = const Duration(seconds: 30),
    this.maxMediaBytes = 20971520, this.preferLowData = false, this.preloadWifiOnly = false,
  });
  final int sessionCap;
  final Duration minimumInterval;
  final Duration timeout;
  final Duration maxVideoDuration;
  final int maxMediaBytes;
  final bool preferLowData, preloadWifiOnly;
  factory DidnexAdPolicy.fromJson(Object? json) {
    final d = json is Map ? json : const <String, Object>{};
    int number(String key, int fallback, int low, int high) {
      final n = d[key];
      return n is num && n.isFinite
          ? n.toInt().clamp(low, high).toInt()
          : fallback;
    }

    return DidnexAdPolicy(
      maxMediaBytes: number('max_media_bytes',20971520,65536,20971520),
      preferLowData: d['prefer_low_data']==true, preloadWifiOnly: d['preload_wifi_only']==true,
      sessionCap: number('session_cap', 5, 1, 30),
      minimumInterval: Duration(
        milliseconds: number('min_interval_ms', 0, 0, 600000),
      ),
      timeout: Duration(milliseconds: number('timeout_ms', 5000, 1000, 15000)),
      maxVideoDuration: Duration(
        milliseconds: number('max_video_ms', 30000, 5000, 180000),
      ),
    );
  }
}

class DidnexAd {
  DidnexAd._({
    required this.requestId,
    required this.format,
    required this.title,
    required this.brand,
    required this.cta,
    required this.creativeUrl,
    required this.clickUrl,
    required this.expiresAt,
    required this.events,
    required this.policy,
    this.telemetryUrl,
    this.telemetrySignature,
    this.diagnosticToken,
    required this.diagnostic,
    required this.isVideo,
    this.videoDuration,
    this.reward,
    this.revenueUrl, this.reportUrl, this.deepLink, this.fallbackUrl,
    this.slot = const {}, this.presentation = const {}, this.audio = const {},this.playableConfig = const {}, this.mediaSources = const [],
    this.measurement = const {}, this.house = false, this.external = false,
  });
  final String requestId, title, brand, cta;
  final DidnexAdFormat format;
  final Uri creativeUrl, clickUrl;
  final DateTime expiresAt;
  final Map<String, Uri> events;
  final DidnexAdPolicy policy;
  final Uri? telemetryUrl, revenueUrl, reportUrl, deepLink, fallbackUrl;
  final Map<String, dynamic> playableConfig,audio,presentation,slot;
  bool get isAudio => format==DidnexAdFormat.audio;
  final List<Map<String,dynamic>> mediaSources;
  final Map<String, dynamic> measurement;
  final bool house, external;
  final String? telemetrySignature, diagnosticToken;
  final bool diagnostic, isVideo;
  final Duration? videoDuration;
  final DidnexReward? reward;
  bool get isExpired => !DateTime.now().isBefore(expiresAt);
  factory DidnexAd.fromJson(Map<String, dynamic> json, {Uri? expectedOrigin}) {
    String requiredText(String key) {
      final value = json[key];
      if (value is! String || value.isEmpty)
        throw const DidnexAdException('invalid_ad_response');
      return value;
    }

    final expires = json['expiresAt'];
    if (expires is! int || expires <= DateTime.now().millisecondsSinceEpoch) {
      throw const DidnexAdException('delivery_expired');
    }
    final format = DidnexAdFormat.fromWire(json['format']);
    final mediaType = json['mediaType'];
    if (mediaType != null && mediaType != 'image' && mediaType != 'video' && mediaType != 'playable' && mediaType != 'audio' && mediaType != 'carousel' && mediaType != 'poll')
      throw const DidnexAdException('invalid_media_type');
    final video = mediaType == 'video' ||
        (mediaType == null &&
            [
              DidnexAdFormat.video,
              DidnexAdFormat.nativeVideo,
              DidnexAdFormat.rewarded,
              DidnexAdFormat.rewardedInterstitial
            ].contains(format));
    if ([
              DidnexAdFormat.banner,
              DidnexAdFormat.adaptiveBanner,
              DidnexAdFormat.native
            ].contains(format) &&
            video ||
        [
              DidnexAdFormat.video,
              DidnexAdFormat.nativeVideo,
              DidnexAdFormat.rewarded,
              DidnexAdFormat.rewardedInterstitial
            ].contains(format) &&
            !video) throw const DidnexAdException('creative_format_mismatch');

    final media = didnexHttpsUri(json['creativeUrl']);
    final servingOrigin = expectedOrigin?.origin ?? (json['servingOrigin'] is String ? didnexHttpsUri(json['servingOrigin']).origin : media.origin);
    if (expectedOrigin != null && json['servingOrigin'] is String && didnexHttpsUri(json['servingOrigin']).origin != servingOrigin) throw const DidnexAdException('inconsistent_ad_origin');
    Uri servingUrl(Object? value) {
      final uri = didnexHttpsUri(value);
      if (uri.origin != servingOrigin)
        throw const DidnexAdException('inconsistent_ad_origin');
      return uri;
    }

    final isTest = json['diagnostic'] == true;
    final eventMap = <String, Uri>{};
    final rawEvents = json['events'];
    if (rawEvents is Map) {
      for (final entry in rawEvents.entries) {
        if (entry.key is String)
          eventMap[entry.key as String] = servingUrl(entry.value);
      }
    }
    if (!isTest &&
        (!eventMap.containsKey('impression') ||
            !eventMap.containsKey('click'))) {
      throw const DidnexAdException('missing_measurement_urls');
    }
    final telemetry = json['telemetry'];
    final testToken = json['diagnosticToken'];
    if (isTest && (testToken is! String || testToken.isEmpty)) {
      throw const DidnexAdException('missing_diagnostic_token');
    }
    if (format == DidnexAdFormat.playable && (mediaType != 'playable' || json['playableConfig'] is! Map)) throw const DidnexAdException('invalid_playable');
    if(format==DidnexAdFormat.audio && mediaType!='audio')throw const DidnexAdException('creative_format_mismatch');
    if (format == DidnexAdFormat.carousel || format == DidnexAdFormat.poll) {
      final config = json['playableConfig'];
      if (config is! Map || mediaType != 'playable' || config['template'] != format.wireName) throw const DidnexAdException('invalid_interactive');
      if (format == DidnexAdFormat.carousel) {
        final cards = config['cards'];
        if (cards is! List || cards.length < 2 || cards.length > 6) throw const DidnexAdException('invalid_interactive');
        for (final card in cards) {
          if (card is! Map || card['title'] is! String || (card['title'] as String).isEmpty) throw const DidnexAdException('invalid_interactive');
          servingUrl(card['imageUrl']);
        }
      } else {
        final options = config['options'];
        if (config['question'] is! String || (config['question'] as String).isEmpty || options is! List || options.length < 2 || options.length > 5 || options.any((v) => v is! String || v.isEmpty) || options.toSet().length != options.length) throw const DidnexAdException('invalid_interactive');
        if (!isTest && config['preview'] != true) servingUrl(config['voteUrl']);
      }
    }

    return DidnexAd._(
      slot:json['slot'] is Map?Map<String,dynamic>.unmodifiable(json['slot'] as Map):const {},
      presentation:json['presentation'] is Map?Map<String,dynamic>.unmodifiable(json['presentation'] as Map):const {},
      audio:json['audio'] is Map?Map<String,dynamic>.from(json['audio'] as Map):const {},
      playableConfig: json['playableConfig'] is Map ? Map<String,dynamic>.unmodifiable(json['playableConfig'] as Map) : const {},
      mediaSources: json['mediaSources'] is List ? List<Map<String,dynamic>>.unmodifiable((json['mediaSources'] as List).take(3).whereType<Map>().map((s)=>Map<String,dynamic>.from(s)).where((s)=>s['mime']=='video/mp4' && servingUrl(s['url']).origin==servingOrigin && s['bitrate'] is int && s['bitrate']>0)) : const [],
      revenueUrl: json['revenueUrl'] is String ? servingUrl(json['revenueUrl']) : null,
      reportUrl: json['reportUrl'] is String ? servingUrl(json['reportUrl']) : null,
      deepLink: json['deepLink'] is String ? didnexHttpsUri(json['deepLink']) : null,
      fallbackUrl: json['fallbackUrl'] is String ? didnexHttpsUri(json['fallbackUrl']) : null,
      measurement: json['measurement'] is Map ? Map<String,dynamic>.from(json['measurement'] as Map) : const {},
      house: json['house'] == true, external: json['external'] == true,
      requestId: requiredText('requestId'),
      format: format,
      title: requiredText('title'),
      brand: requiredText('brand'),
      cta: json['cta'] is String ? json['cta'] as String : 'بیشتر بدانید',
      creativeUrl: media,
      clickUrl: servingUrl(json['clickUrl']),
      expiresAt: DateTime.fromMillisecondsSinceEpoch(expires),
      events: Map.unmodifiable(eventMap),
      policy: DidnexAdPolicy.fromJson(json['policy']),
      diagnostic: isTest,
      isVideo: video,
      videoDuration:
          json['videoDurationMs'] is int && json['videoDurationMs'] > 0
              ? Duration(milliseconds: json['videoDurationMs'] as int)
              : null,
      reward: format.isRewarded && !isTest
          ? DidnexReward.fromJson(json['reward'])
          : null,
      diagnosticToken: isTest ? testToken as String : null,
      telemetryUrl: telemetry is Map && telemetry['url'] is String
          ? servingUrl(telemetry['url'])
          : isTest
              ? media.replace(path: '/ad/v1/telemetry', query: '')
              : null,
      telemetrySignature: telemetry is Map && telemetry['signature'] is String
          ? telemetry['signature'] as String
          : null,
    );
  }
}

class DidnexAdResult {
  const DidnexAdResult({this.ad, this.noFillReason, this.requestId});
  final DidnexAd? ad;
  final String? noFillReason, requestId;
  bool get noFill => ad == null && noFillReason != null;
}

/// A random identifier kept only for this process; never a device/user ID.
class DidnexSession {
  static final String id = create();
  static String create() {
    final random = Random.secure();
    return List.generate(
      24,
      (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0'),
    ).join();
  }
}

/// Tracks continuous visible time. A hidden/paused frame resets qualification.
class DidnexViewability {
  Duration _visible = Duration.zero;
  Duration? _last;
  void reset() {
    _visible = Duration.zero;
    _last = null;
  }

  bool sample(
    Duration elapsed, {
    required bool eligible,
    required Duration requiredDuration,
  }) {
    if (!eligible) {
      reset();
      return false;
    }
    final last = _last;
    // A suspended/blocked measurement loop cannot count time it did not observe.
    if (last != null &&
        elapsed >= last &&
        elapsed - last <= const Duration(milliseconds: 600)) {
      _visible += elapsed - last;
    } else {
      _visible = Duration.zero;
    }
    _last = elapsed;
    return _visible >= requiredDuration;
  }
}

class DidnexReward {
  const DidnexReward(this.label, this.amount);
  final String label;
  final int amount;
  factory DidnexReward.fromJson(Object? value) {
    if (value is! Map ||
        value['label'] is! String ||
        (value['label'] as String).isEmpty ||
        value['amount'] is! int ||
        value['amount'] < 1 ||
        value['amount'] > 1000000) {
      throw const DidnexAdException('invalid_reward_offer');
    }
    return DidnexReward(value['label'] as String, value['amount'] as int);
  }
}

class DidnexRewardReceipt {
  const DidnexRewardReceipt(
      {required this.grantId,
      required this.deliveryId,
      required this.reward,
      required this.acknowledged,
      this.balance});
  final String grantId, deliveryId;
  final DidnexReward reward;
  final bool acknowledged;
  final int? balance;
  factory DidnexRewardReceipt.fromJson(Map<String, dynamic> json, DidnexAd ad) {
    final reward = DidnexReward.fromJson(json['reward']);
    if (json['verified'] != true ||
        json['applied'] != true ||
        json['deliveryId'] != ad.requestId ||
        json['grantId'] is! String ||
        (json['grantId'] as String).isEmpty ||
        ad.reward == null ||
        reward.label != ad.reward!.label ||
        reward.amount != ad.reward!.amount) {
      throw const DidnexAdException('reward_not_applied');
    }
    return DidnexRewardReceipt(
        grantId: json['grantId'] as String,
        deliveryId: ad.requestId,
        reward: reward,
        acknowledged: json['acknowledged'] == true,
        balance: json['balance'] is int ? json['balance'] as int : null);
  }
}
