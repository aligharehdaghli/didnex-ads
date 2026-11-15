import 'dart:convert';
import 'dart:typed_data';

import 'package:didnex_ads/didnex_ads.dart';

Map<String, dynamic> adJson({
  bool diagnostic = false,
  String format = 'banner',
}) =>
    {
      'requestId': 'REQ_example',
      'expiresAt': DateTime.now()
          .add(const Duration(minutes: 10))
          .millisecondsSinceEpoch,
      'format': format,
      'title': 'تبلیغ نمونه آزمون',
      'brand': 'برند آزمون',
      'cta': 'مشاهده پیشنهاد',
      'creativeUrl': 'https://ads.example/creative/image',
      'clickUrl': 'https://ads.example/ad/v1/click?d=REQ_example&sig=test',
      'events': diagnostic
          ? <String, dynamic>{}
          : {
              for (final kind in [
                'impression',
                'click',
                'start',
                'firstQuartile',
                'midpoint',
                'thirdQuartile',
                'complete',
              ])
                kind:
                    'https://ads.example/ad/v1/event?d=REQ_example&sig=test&kind=$kind',
            },
      'telemetry': {
        'url': 'https://ads.example/ad/v1/telemetry',
        'signature': 'test',
      },
      'policy': {
        'session_cap': 5,
        'min_interval_ms': 0,
        'timeout_ms': 5000,
        'max_video_ms': 30000,
      },
      if (diagnostic) 'diagnostic': true,
      if (diagnostic) 'diagnosticToken': 'UNIT_EXPIRY_TEST_SIGNATURE',
    };

class RecordedRequest {
  RecordedRequest(this.uri, this.body, this.headers);
  final Uri uri;
  final Map<String, dynamic>? body;
  final Map<String, String> headers;
}

class FakeTransport implements DidnexTransport {
  FakeTransport({Map<String, dynamic>? response})
      : response = response ?? adJson();
  final Map<String, dynamic> response;
  final List<RecordedRequest> requests = [];
  bool closed = false, failEvents = false;
  @override
  Future<Map<String, dynamic>> postJson(
    Uri uri, {
    Map<String, dynamic>? body,
    Map<String, String> headers = const {},
    Duration timeout = const Duration(seconds: 5),
  }) async {
    requests.add(RecordedRequest(uri, body, headers));
    if (uri.path == '/ad/v1/audience' && body?['action'] == 'register') return {'installationToken': 'INS_${'a' * 32}.${'b' * 64}', 'rewardScope': 'installation'};
    if (uri.path == '/proxy' || uri.path == '/ad/v1/app') return response;
    if (failEvents && uri.path == '/ad/v1/event')
      throw const DidnexAdException('network_unavailable');
    return {'accepted': true};
  }

  @override
  Future<Uint8List> imageBytes(
    Uri uri, {
    Duration timeout = const Duration(seconds: 5),
  }) async =>
      base64Decode(
        'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAAC0lEQVR4nGP4DwQACfsD/fteaysAAAAASUVORK5CYII=',
      );
  @override
  void close() => closed = true;
}

DidnexAdClient testClient(
  FakeTransport transport, {
  Future<String> Function()? token,
}) =>
    DidnexAdClient(
      strictErrors: true,
      proxyUrl: Uri.parse('https://publisher.example/proxy'),
      sessionToken: token ?? () async => 'app.session.jwt',
      platform: DidnexPlatform.android,
      transport: transport,
      sessionId: 'random-test-session-1234567',
    );
