import 'package:flutter_test/flutter_test.dart';
import 'package:didnex_ads/didnex_ads.dart';

import 'fixtures.dart';

void main() {
  test('direct mode advertises all thirteen formats and enrolls installation without publisher credentials', () async {
    final transport = FakeTransport();
    final client = DidnexAdClient.direct(
      adOrigin: Uri.parse('https://ads.example'), packageName: 'com.publisher.test',
      platform: DidnexPlatform.android, transport: transport,
    );
    await client.requestAd('UNIT_123');
    final request = transport.requests.where((r) => r.uri.path == '/ad/v1/app').single;
    expect(request.uri.toString(), 'https://ads.example/ad/v1/app');
    expect(request.headers, isEmpty);
    expect(request.body!['packageName'], 'com.publisher.test');
    expect(request.body!['supportedFormats'], hasLength(13));
    expect(request.body!['supportedFormats'], containsAll(['rewarded','rewarded_interstitial','app_open']));
    await client.requestAd('UNIT_REWARD', rewarded: true);
    final enrollment = transport.requests.where((r) => r.body?['action'] == 'register').single;
    expect(enrollment.uri.path, '/ad/v1/audience');
    expect(enrollment.headers, isEmpty);
    expect(enrollment.body!['packageName'], 'com.publisher.test');
    final rewardRequest = transport.requests.last;
    expect(rewardRequest.body!['installationToken'], startsWith('INS_'));
    expect(rewardRequest.headers, isEmpty);
    expect(rewardRequest.body!['requestNonce'], isNotEmpty);
    client.close();
  });

  test('explicit device class reaches proxy without platform identifiers',
      () async {
    for (final kind in DidnexDeviceClass.values) {
      final transport = FakeTransport();
      final c = DidnexAdClient(
          proxyUrl: Uri.parse('https://publisher.example/proxy'),
          sessionToken: () async => 'app-session',
          platform: DidnexPlatform.android,
          deviceClass: kind,
          transport: transport);
      await c.requestAd('UNT_device_test');
      expect(transport.requests.single.body!['formFactor'], kind.name);
      expect(transport.requests.single.body!.containsKey('deviceId'), false);
      c.close();
    }
  });

  test(
    'proxy receives app session, stable nonce and contextual-only options',
    () async {
      final transport = FakeTransport();
      final client = testClient(transport);
      final result = await client.requestAd(
        'UNIT_123',
        enrollmentToken: 'signed-enrollment',
        childDirected: true,
      );
      expect(result.ad!.format, DidnexAdFormat.banner);
      final r = transport.requests.single;
      expect(r.headers, {'Authorization': 'Bearer app.session.jwt'});
      expect(r.body!['personalized'], false);
      expect(r.body!['childDirected'], true);
      expect(r.body!['sessionId'], 'random-test-session-1234567');
      expect(r.body!['enrollmentToken'], 'signed-enrollment');
      client.close();
    },
  );
  test('a Didnex server API key is rejected before any network call', () async {
    final transport = FakeTransport();
    final client = testClient(
      transport,
      token: () async => 'md_this_is_not_an_app_session',
    );
    await expectLater(
      client.requestAd('UNIT_123'),
      throwsA(
        isA<DidnexAdException>().having(
          (e) => e.code,
          'code',
          'app_session_required_not_madar_key',
        ),
      ),
    );
    expect(transport.requests, isEmpty);
    client.close();
  });
  test(
    'measurement coalesces duplicate events and never forwards app JWT',
    () async {
      final transport = FakeTransport();
      final client = testClient(transport);
      final ad = (await client.requestAd('UNIT_123')).ad!;
      await Future.wait([
        client.track(ad, 'impression'),
        client.track(ad, 'impression'),
      ]);
      await client.track(ad, 'impression');
      final events = transport.requests
          .where((r) => r.uri.path == '/ad/v1/event')
          .toList();
      expect(events, hasLength(1));
      expect(events.single.headers, isEmpty);
      await client.report(ad, 'loaded');
      expect(transport.requests.last.headers, isEmpty);
      client.close();
    },
  );
  test(
    'failed measurement remains retryable, successful retry deduplicates',
    () async {
      final transport = FakeTransport()..failEvents = true;
      final client = testClient(transport);
      final ad = (await client.requestAd('UNIT_123')).ad!;
      await expectLater(
        client.track(ad, 'impression'),
        throwsA(isA<DidnexAdException>()),
      );
      transport.failEvents = false;
      await client.track(ad, 'impression');
      await client.track(ad, 'impression');
      expect(
        transport.requests.where((r) => r.uri.path == '/ad/v1/event'),
        hasLength(2),
      );
      client.close();
    },
  );
  test(
    'no-fill is a result, not a fabricated ad or a financial event',
    () async {
      final transport = FakeTransport(
        response: {
          'noFill': true,
          'reason': 'session_cap',
          'requestId': 'REQ_empty',
        },
      );
      final client = testClient(transport);
      final result = await client.requestAd('UNIT_123');
      expect(result.noFill, true);
      expect(result.ad, isNull);
      expect(result.noFillReason, 'session_cap');
      expect(transport.requests, hasLength(1));
      client.close();
    },
  );
  test('diagnostic never sends billable impression or click events', () async {
    final transport = FakeTransport(response: adJson(diagnostic: true));
    final client = testClient(transport);
    final ad = (await client.requestAd(
      'UNIT_123',
      diagnosticToken: 'test',
    ))
        .ad!;
    await client.track(ad, 'impression');
    await client.track(ad, 'click');
    await client.report(ad, 'loaded');
    expect(
      transport.requests.where((r) => r.uri.path == '/ad/v1/event'),
      isEmpty,
    );
    expect(
      transport.requests.last.body!['diagnosticToken'],
      'UNIT_EXPIRY_TEST_SIGNATURE',
    );
    client.close();
  });
  test('expired, cross-origin and non-HTTPS ad responses are rejected', () {
    expect(
      () => DidnexAd.fromJson({...adJson(), 'expiresAt': 0}),
      throwsA(isA<DidnexAdException>()),
    );
    expect(
      () => DidnexAd.fromJson({
        ...adJson(),
        'creativeUrl': 'http://ads.example/file',
      }),
      throwsA(isA<DidnexAdException>()),
    );
    expect(
      () => DidnexAd.fromJson({
        ...adJson(),
        'clickUrl': 'https://untrusted.example/click',
      }),
      throwsA(isA<DidnexAdException>()),
    );
    expect(
      () => DidnexAd.fromJson({...adJson(), 'events': {}}),
      throwsA(isA<DidnexAdException>()),
    );
  });
  test('video response keeps all signed milestones', () {
    final ad = DidnexAd.fromJson(adJson(format: 'video'));
    expect(ad.format, DidnexAdFormat.video);
    expect(
      ad.events.keys,
      containsAll([
        'start',
        'firstQuartile',
        'midpoint',
        'thirdQuartile',
        'complete',
      ]),
    );
    expect(ad.policy.maxVideoDuration, const Duration(seconds: 30));
  });
  test(
    'viewability needs uninterrupted observations and rejects suspended gaps',
    () {
      final v = DidnexViewability();
      bool sample(int ms, bool visible, int requiredMs) => v.sample(
            Duration(milliseconds: ms),
            eligible: visible,
            requiredDuration: Duration(milliseconds: requiredMs),
          );
      expect(sample(0, true, 1000), false);
      expect(sample(400, true, 1000), false);
      expect(sample(800, false, 1000), false);
      expect(sample(1000, true, 1000), false);
      expect(sample(1400, true, 1000), false);
      expect(sample(1800, true, 1000), false);
      expect(sample(2000, true, 1000), true);
      v.reset();
      sample(0, true, 2000);
      expect(sample(5000, true, 2000), false);
      expect(sample(5200, true, 2000), false);
    },
  );
  test('client closing is idempotent and stops new ad requests', () async {
    final transport = FakeTransport();
    final client = testClient(transport);
    client.close();
    client.close();
    expect(transport.closed, true);
    await expectLater(
      client.requestAd('UNIT_123'),
      throwsA(isA<DidnexAdException>()),
    );
    expect(transport.requests, isEmpty);
  });
}
