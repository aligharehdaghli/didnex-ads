import 'dart:async';
import 'inspector.dart';
import 'package:flutter/services.dart';
import 'audience.dart';
import 'push.dart';
import 'package:flutter/foundation.dart';

import 'models.dart';
import 'transport.dart';
import 'pro_models.dart';

class DidnexAdClient {
  DidnexAdClient({
    required Uri proxyUrl,
    required this.sessionToken,
    this.packageName,
    this.enableIntegrity=false,this.storyConsent=false,this.strictErrors=false,
    DidnexPlatform? platform,
    DidnexDeviceClass? deviceClass,
    String? sessionId,
    DidnexTransport? transport,
    this.adOrigin, this.onRevenue, this.measurementAdapter, this.onMeasurementStatus,
    DidnexContext context = const DidnexContext(),
    this.requestTimeout = const Duration(seconds: 5),
  })  : _context = context, proxyUrl = didnexHttpsUri(proxyUrl),
        platform = platform ?? _platform(),
        _deviceClassOverride = deviceClass,
        sessionId = sessionId ?? DidnexSession.id,
        _transport = transport ?? DidnexHttpTransport() {
    if (packageName != null && (!RegExp(r'^[A-Za-z][A-Za-z0-9_]*(\.[A-Za-z][A-Za-z0-9_]*)+$').hasMatch(packageName!) || proxyUrl.path != '/ad/v1/app' || adOrigin == null || proxyUrl.origin != adOrigin!.origin)) {
      throw const DidnexAdException('invalid_direct_configuration');
    }
    if (this.sessionId.length < 16 || this.sessionId.length > 128) {
      throw const DidnexAdException('invalid_session_id');
    }
    if (requestTimeout <= Duration.zero ||
        requestTimeout > const Duration(seconds: 15)) {
      throw const DidnexAdException('invalid_request_timeout');
    }
  }
  /// No publisher backend, app login or private API key is needed.
  /// Secure account rewards remain available through the proxy constructor.
  factory DidnexAdClient.direct({
    required Uri adOrigin,
    required String packageName,
    bool enableIntegrity=false,bool storyConsent=false,bool strictErrors=false,
    DidnexPlatform? platform,
    DidnexDeviceClass? deviceClass,
    String? sessionId,
    DidnexTransport? transport,
    void Function(DidnexRevenue)? onRevenue,
    DidnexMeasurementAdapter? measurementAdapter,
    void Function(String, String)? onMeasurementStatus,
    DidnexContext context = const DidnexContext(),
    Duration requestTimeout = const Duration(seconds: 5),
  }) {
    final origin = didnexHttpsUri(adOrigin);
    if ((origin.path.isNotEmpty && origin.path != '/') || origin.hasQuery || origin.hasFragment) {
      throw const DidnexAdException('service_origin_required');
    }
    return DidnexAdClient(
      proxyUrl: origin.resolve('/ad/v1/app'), sessionToken: () async => '',
      packageName: packageName, adOrigin: origin, platform: platform,enableIntegrity:enableIntegrity,storyConsent:storyConsent,strictErrors:strictErrors,
      deviceClass: deviceClass, sessionId: sessionId, transport: transport,
      onRevenue: onRevenue, measurementAdapter: measurementAdapter,
      onMeasurementStatus: onMeasurementStatus, context: context,
      requestTimeout: requestTimeout,
    );
  }
  bool enableIntegrity,storyConsent;
  final bool strictErrors;
  final String? packageName;
  bool get isDirect => packageName != null;
  DidnexAudience? _hostedAudience;
  DidnexAudience get audience {
    if (!isDirect) throw const DidnexAdException('use_direct_audience_client');
    return _hostedAudience ??= DidnexAudience(origin: adOrigin!, packageName: packageName!, device: platform.name, transport: _transport);
  }
  final Set<DidnexPush> _pushControllers={};
  DidnexAudience? _proxyPushAudience;
  DidnexPush createPush({required String unitId,Future<bool> Function(Map<String,dynamic>)? onMessage,required void Function(Object) onError,String? appPackageName}) {
    if(_closed)throw const DidnexAdException('client_closed');
    final DidnexAudience shared;
    if(isDirect){shared=audience;}else{
      if(adOrigin==null||appPackageName==null||!RegExp(r'^[A-Za-z][A-Za-z0-9_]*(\.[A-Za-z][A-Za-z0-9_]*)+$').hasMatch(appPackageName)){throw const DidnexAdException('push_origin_and_package_required');}
      shared=_proxyPushAudience??=DidnexAudience(origin:adOrigin!,packageName:appPackageName,device:platform.name,transport:_transport);
    }
    late final DidnexPush controller;
    controller=DidnexPush(audience:shared,unitId:unitId,onMessage:onMessage,onError:onError,onDispose:()=>_pushControllers.remove(controller));
    _pushControllers.add(controller);return controller;
  }
  Future<Map<String, String>> _headers(Duration timeout) async {
    if (isDirect) return {};
    final jwt = await sessionToken().timeout(timeout);
    if (jwt.isEmpty || jwt.startsWith('md_') || jwt.contains('\r') || jwt.contains('\n')) {
      throw const DidnexAdException('app_session_required_not_madar_key');
    }
    return {'Authorization': 'Bearer $jwt'};
  }
  static const version = '3.12.2';
  final Uri? adOrigin;
  final void Function(DidnexRevenue)? onRevenue;
  final DidnexMeasurementAdapter? measurementAdapter;
  final void Function(String requestId, String status)? onMeasurementStatus;
  final Map<String, Future<void>> _measurementStarts = {};
  final Set<String> _measurementReady = {};
  DidnexContext _context;
  DidnexContext get context => _context;
  set context(DidnexContext value) { _context = value; consentGeneration++; clearImageCache(); }
  final Map<String, DidnexConsent> _consents = {};
  int consentGeneration = 0;
  final Map<String, Uint8List> _images = {};
  final Set<String> _revenueSent = {};
  final Uri proxyUrl;
  final Future<String> Function() sessionToken;
  final DidnexPlatform platform;
  final DidnexDeviceClass? _deviceClassOverride;
  DidnexDeviceClass get deviceClass {
    if (_deviceClassOverride != null) return _deviceClassOverride;
    final view = PlatformDispatcher.instance.implicitView;
    if (view == null || view.physicalSize.isEmpty || view.devicePixelRatio <= 0)
      return DidnexDeviceClass.unknown;
    return view.physicalSize.shortestSide / view.devicePixelRatio >= 600
        ? DidnexDeviceClass.tablet
        : DidnexDeviceClass.mobile;
  }

  final String sessionId;
  final Duration requestTimeout;
  final DidnexTransport _transport;
  final Map<String, Future<void>> _pending = {};
  final Set<String> _sent = {};
  final Map<String, DidnexAdPolicy> _policies = {};
  bool _closed = false;
  final Map<String, Future<DidnexRewardReceipt>> _rewardClaims = {};
  final Map<String,String> _rewardUnits = {};
  static DidnexPlatform _platform() => switch (defaultTargetPlatform) {
        TargetPlatform.android => DidnexPlatform.android,
        TargetPlatform.iOS => DidnexPlatform.ios,
        _ => throw const DidnexAdException('unsupported_platform'),
      };
  DateTime? _requestBlockedUntil;
  int _requestFailures=0;
  /// Safe default: outages are a no-fill result. strictErrors is an explicit
  /// debugging opt-in; never enable it in a fire-and-forget application call.
  Future<Map<String,dynamic>> vote(DidnexAd ad,int choice) async {final url=didnexHttpsUri(ad.playableConfig['voteUrl']);if(url.origin!=ad.clickUrl.origin||url.path!='/ad/v1/poll-vote')throw const DidnexAdException('invalid_poll_endpoint');return _transport.postJson(url,body:{'choice':choice},timeout:ad.policy.timeout);}
  Future<DidnexAdResult> requestAd(
    String unitId, {bool childDirected=false,bool rewarded=false,
    String? enrollmentToken,String? diagnosticToken}) async {
    if(!strictErrors && _requestBlockedUntil?.isAfter(DateTime.now())==true) {
      return const DidnexAdResult(noFillReason:'service_backoff');
    }
    try {
      final result=await _requestAd(unitId,childDirected:childDirected,rewarded:rewarded,
        enrollmentToken:enrollmentToken,diagnosticToken:diagnosticToken)
        .timeout(_policies[unitId]?.timeout ?? requestTimeout);
      if(result.noFill && const ['network_unavailable','request_unavailable','request_timeout','http_error','invalid_json_response'].contains(result.noFillReason)) {
        _requestFailures=(_requestFailures+1).clamp(1,6).toInt();
        _requestBlockedUntil=DateTime.now().add(Duration(seconds:1<<_requestFailures));
      } else { _requestFailures=0;_requestBlockedUntil=null; }
      return result;
    } on TimeoutException {
      _requestBlockedUntil=DateTime.now().add(const Duration(seconds:4));
      if(strictErrors) throw const DidnexAdException('request_timeout');
      return const DidnexAdResult(noFillReason:'request_timeout');
    } catch (_) {
      if(strictErrors) rethrow;
      _requestBlockedUntil=DateTime.now().add(const Duration(seconds:4));
      return const DidnexAdResult(noFillReason:'request_unavailable');
    }
  }
  Future<DidnexAdResult> _requestAd(
    String unitId, {
    bool childDirected = false,
    bool rewarded = false,
    String? enrollmentToken,
    String? diagnosticToken,
  }) async {
    if (_closed) { if(strictErrors) throw const DidnexAdException('client_closed'); return const DidnexAdResult(noFillReason:'client_closed'); }
    if (unitId.trim().length < 5 || unitId.length > 100) { if(strictErrors) throw const DidnexAdException('invalid_unit_id');return const DidnexAdResult(noFillReason:'invalid_unit_id'); }
    final timeout = _policies[unitId]?.timeout ?? requestTimeout;
    final watch = Stopwatch()..start();
    if(diagnosticToken != null) DidnexInspector.enableDiagnostic();
    DidnexInspector.record("request");
    try {
      final headers=await _headers(timeout);final requestNonce=DidnexSession.create();Map<String,dynamic> proof={};
      if(enableIntegrity&&diagnosticToken==null){try{proof=await const MethodChannel('ir.didnex.ads/native').invokeMapMethod<String,dynamic>('integrityProof',{'serviceOrigin':adOrigin?.origin,'unitId':unitId,'requestNonce':requestNonce,if(isDirect)'installationToken':await audience.token(unitId)}).timeout(timeout)??{};}catch(_){DidnexInspector.record('integrity',code:'unavailable');}}
      final json = await _transport.postJson(
        proxyUrl,
        headers: headers,
        timeout: timeout,
        body: {
          'sdk': {'platform':'flutter','version':version},
          'unitId': unitId,
          if (isDirect) 'packageName': packageName,
          if (isDirect && diagnosticToken == null) 'installationToken': await audience.token(unitId),
          'supportedPlayableTemplates': ["tap_target","memory_pairs","color_match","quick_math","number_order","sequence_memory"],
          'supportedFormats':
              DidnexAdFormat.values.map((f) => f.wireName).toList(),
          'requestNonce':requestNonce,'storyConsent':storyConsent,...proof,
          'rewarded': rewarded,
          'device': platform.name,
          'formFactor': deviceClass.name,
          'sessionId': sessionId,
          'personalized': false,
          'childDirected': childDirected,
          'context': context.toJson(),
          if (_consents[unitId] != null && !_consents[unitId]!.expired) 'consentReceipt': _consents[unitId]!.receipt,
          if (enrollmentToken != null) 'enrollmentToken': enrollmentToken,
          if (diagnosticToken != null) 'diagnosticToken': diagnosticToken,
        },
      );
      DidnexInspector.record('response',code:json['noFill']==true?'no_fill':json['format'] as String?,requestId:json['requestId'] as String?,latencyMs:watch.elapsedMilliseconds);
      _policies[unitId] = DidnexAdPolicy.fromJson(json['policy']);
      if (json['noFill'] == true) {
        return DidnexAdResult(
          noFillReason:
              json['reason'] is String ? json['reason'] as String : 'no_fill',
          requestId:
              json['requestId'] is String ? json['requestId'] as String : null,
        );
      }
      final ad = DidnexAd.fromJson(json, expectedOrigin: adOrigin);
      if (isDirect && ad.format.isRewarded) { _rewardUnits[ad.requestId] = unitId; if (_rewardUnits.length>100) _rewardUnits.remove(_rewardUnits.keys.first); }
      return DidnexAdResult(ad: ad, requestId: ad.requestId);
    } on DidnexAdException catch(error) {
      DidnexInspector.record("request_error",code:error.code,latencyMs:watch.elapsedMilliseconds);
      if(strictErrors) rethrow;
      return DidnexAdResult(noFillReason:error.code);
    } catch (_) {
      DidnexInspector.record('request_error',code:'request_unavailable',latencyMs:watch.elapsedMilliseconds);
      if(strictErrors) throw const DidnexAdException('request_unavailable');
      return const DidnexAdResult(noFillReason:'request_unavailable');
    }
  }

  Future<Uri> selectVideo(DidnexAd ad) async {
    if(ad.mediaSources.isEmpty) return ad.creativeUrl;
    var quality='medium';try { quality=await const MethodChannel('ir.didnex.ads/native').invokeMethod<String>('networkQuality').timeout(const Duration(seconds:1)) ?? 'medium'; } catch (_) {}
    final sources=ad.mediaSources.where((s)=>(s['bytes'] as num? ?? 0)>0&&(s['bytes'] as num)<=ad.policy.maxMediaBytes).toList()..sort((a,b)=>(a['bitrate'] as int).compareTo(b['bitrate'] as int));
    if(sources.isEmpty)return ad.creativeUrl;
    if(ad.policy.preferLowData)quality='low';
    final selected=sources[quality=='low'?0:quality=='high'?sources.length-1:(sources.length-1)~/2];
    DidnexInspector.record('quality',code:selected['quality'] as String?,requestId:ad.requestId);
    return didnexHttpsUri(selected['url']);
  }
  Future<Uint8List> loadImage(DidnexAd ad) async {
    if (ad.isExpired) throw const DidnexAdException('delivery_expired');
    final cached = _images[ad.requestId];
    if (cached != null) return cached;
    final bytes = await _transport.imageBytes(ad.creativeUrl, timeout: ad.policy.timeout);
    if (bytes.length <= 8 * 1024 * 1024) {
      while (_images.isNotEmpty && (_images.length >= 4 || _images.values.fold<int>(0, (sum, image) => sum + image.length) + bytes.length > 8 * 1024 * 1024)) { _images.remove(_images.keys.first); }
      _images[ad.requestId] = bytes;
    }
    return bytes;
  }
  void clearImageCache() => _images.clear();
  Future<DidnexConsent> updateConsent(String unitId, {required bool externalAds, required bool analytics, String policyVersion = '1', String? tcString, String? gppString}) async {
    if (_closed) throw const DidnexAdException('client_closed');
    final result = await _transport.postJson(proxyUrl, headers: await _headers(requestTimeout), timeout: requestTimeout, body: {'action':'consent','unitId':unitId,'sessionId':sessionId,if(isDirect)'packageName':packageName,if(isDirect)'device':platform.name,if(isDirect)'formFactor':deviceClass.name,'policyVersion':policyVersion,'choices':{'externalAds':externalAds,'analytics':analytics,'personalization':false,if(tcString != null)'tcString':tcString,if(gppString != null)'gppString':gppString}});
    final consent = DidnexConsent.fromJson(result);
    _consents[unitId] = consent; consentGeneration++; clearImageCache();
    return consent;
  }
  Future<DidnexRevenue?> readRevenue(DidnexAd ad) async {
    if (ad.revenueUrl == null || ad.diagnostic || ad.house || ad.external || ad.isExpired) return null;
    final result = DidnexRevenue.fromJson(await _transport.postJson(ad.revenueUrl!, timeout: ad.policy.timeout));
    final key = '${result.deliveryId}:${result.status}';
    if (_revenueSent.add(key)) { if (_revenueSent.length > 512) _revenueSent.remove(_revenueSent.first); try { onRevenue?.call(result); } catch (_) {} }
    return result;
  }
  Future<void> reportAd(DidnexAd ad, {required String reason, String message = ''}) async {
    if (ad.reportUrl == null || ad.isExpired) throw const DidnexAdException('ad_report_unavailable');
    await _transport.postJson(ad.reportUrl!, body: {'reason':reason,'message':message}, timeout: ad.policy.timeout);
  }
  Future<void> _measurementStatus(DidnexAd ad, String kind) async {
    try { onMeasurementStatus?.call(ad.requestId, kind); } catch (_) {}
    final url = ad.measurement['eventUrl'];
    if (url is! String) return;
    try { final target = didnexHttpsUri(url); if (target.origin != ad.clickUrl.origin) return; await _transport.postJson(target, body: {'kind':kind,'sdkVersion':'flutter-$version'}, timeout: ad.policy.timeout); } catch (_) {}
  }
  Future<void> measurementStart(DidnexAd ad) {
    if (ad.measurement['omid'] is! Map || (ad.measurement['omid'] as Map)['enabled'] != true) return Future.value();
    return _measurementStarts.putIfAbsent(ad.requestId, () => Future<void>.microtask(() async {
      if (measurementAdapter == null) { await _measurementStatus(ad, 'unavailable'); return; }
      try { await measurementAdapter!.start(ad); _measurementReady.add(ad.requestId); await _measurementStatus(ad, 'session_start'); } catch (_) { await _measurementStatus(ad, 'unavailable'); }
    }));
  }
  Future<void> measurementFinish(DidnexAd ad) async {
    await _measurementStarts[ad.requestId];
    if (_measurementReady.remove(ad.requestId)) { try { await measurementAdapter?.finish(ad); await _measurementStatus(ad, 'finish'); } catch (_) {} }
    _measurementStarts.remove(ad.requestId);
  }


  Future<void> track(DidnexAd ad, String kind) {
    if (ad.diagnostic) return Future.value();
    if (ad.isExpired)
      return Future.error(const DidnexAdException('delivery_expired'));
    final uri = ad.events[kind];
    if (uri == null)
      return Future.error(const DidnexAdException('unsupported_event'));
    final key = '${ad.requestId}:$kind';
    if (_sent.contains(key)) return Future.value();
    final existing = _pending[key];
    if (existing != null) return existing;
    // Only the publisher-proxy request receives an app JWT. Signed events never do.
    final future =
        _transport.postJson(uri, timeout: ad.policy.timeout).then<void>((_) {
      _sent.add(key);
      if (kind == 'impression' || kind == 'click') { readRevenue(ad).catchError((_) => null); }
      measurementStart(ad).then((_) async { if (_measurementReady.contains(ad.requestId)) { try { await measurementAdapter?.event(ad, kind); } catch (_) {} } });
      if (_sent.length > 512) _sent.remove(_sent.first);
    }).whenComplete(() {
      _pending.remove(key);
    });
    _pending[key] = future;
    return future;
  }

  Future<void> report(
    DidnexAd ad,
    String kind, {
    Duration latency = Duration.zero,
    String code = '',
  }) async {
    final uri = ad.telemetryUrl;
    if (_closed || uri == null || ad.isExpired) return;
    try {
      await _transport.postJson(
        uri,
        timeout: ad.policy.timeout,
        body: {
          'requestId': ad.requestId,
          'kind': kind,
          'latencyMs': latency.inMilliseconds.clamp(0, 60000),
          'errorCode': code.length > 80 ? code.substring(0, 80) : code,
          'sdkVersion': 'flutter-$version',
          if (ad.diagnosticToken != null)
            'diagnosticToken': ad.diagnosticToken
          else
            'signature': ad.telemetrySignature,
        },
      );
    } catch (_) {
      /* Diagnostics do not block the app or create financial events. */
    }
  }

  Future<DidnexRewardReceipt> claimReward(DidnexAd ad) {
    if (_closed) return Future.error(const DidnexAdException('client_closed'));
    if (!ad.format.isRewarded || ad.diagnostic || ad.reward == null)
      return Future.error(const DidnexAdException('reward_not_available'));
    final existing = _rewardClaims[ad.requestId];
    if (existing != null) return existing;
    final future = Future<DidnexRewardReceipt>.microtask(() async {
      try {
        final json = isDirect
            ? await audience.call(_rewardUnits[ad.requestId] ?? '', 'claimReward', {'deliveryId':ad.requestId})
            : await _transport.postJson(proxyUrl,
                headers: await _headers(requestTimeout), timeout: requestTimeout,
                body: {'action':'claimReward','deliveryId':ad.requestId});
        final receipt = DidnexRewardReceipt.fromJson(json, ad);
        if (!receipt.acknowledged) _rewardClaims.remove(ad.requestId);
        return receipt;
      } catch (_) {
        _rewardClaims.remove(ad.requestId);
        rethrow;
      }
    });
    _rewardClaims[ad.requestId] = future;
    if (_rewardClaims.length > 100)
      _rewardClaims.remove(_rewardClaims.keys.first);
    return future;
  }

  void close() {
    if (_closed) return;
    _closed = true;
    for(final push in _pushControllers.toList()){push.dispose();}
    _pushControllers.clear();
    _images.clear(); _consents.clear();
    _transport.close();
  }
}
