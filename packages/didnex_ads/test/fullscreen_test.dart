import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:didnex_ads/didnex_ads.dart';
import 'package:video_player_platform_interface/video_player_platform_interface.dart';
import 'fixtures.dart';

Map<String, dynamic> fullJson(String format) => {
      ...adJson(format: format),
      'mediaType': ['playable', 'carousel', 'poll'].contains(format) ? 'playable' : format == 'audio' ? 'audio' : [
        'video',
        'native_video',
        'rewarded',
        'rewarded_interstitial'
      ].contains(format)
          ? 'video'
          : 'image',
      'videoDurationMs': 5000,
      if (format == 'playable') 'playableConfig': {'template': 'tap_target'},
      if (format == 'carousel') 'playableConfig': {
        'template': 'carousel',
        'cards': [
          {'title': 'First', 'imageUrl': 'https://ads.example/creative/first'},
          {'title': 'Second', 'imageUrl': 'https://ads.example/creative/second'},
        ],
      },
      if (format == 'poll') 'playableConfig': {
        'template': 'poll', 'question': 'Which?', 'options': ['First', 'Second'],
        'voteUrl': 'https://ads.example/ad/v1/vote',
      },
      if (format == 'rewarded' || format == 'rewarded_interstitial')
        'reward': {'label': 'سکه', 'amount': 10},
    };
DidnexAdClient client(FakeTransport transport) => DidnexAdClient(
    proxyUrl: Uri.parse('https://publisher.example/proxy'),
    sessionToken: () async => 'app-jwt',
    platform: DidnexPlatform.android,
    transport: transport);

class RewardTransport extends FakeTransport {
  RewardTransport() : super(response: fullJson('rewarded'));
  int claims = 0;
  bool applied = true, acknowledged = true;
  @override
  Future<Map<String, dynamic>> postJson(Uri uri,
      {Map<String, dynamic>? body,
      Map<String, String> headers = const {},
      Duration timeout = const Duration(seconds: 5)}) async {
    if (body?['action'] == 'claimReward') {
      claims++;
      requests.add(RecordedRequest(uri, body, headers));
      return {
        'verified': true,
        'applied': applied,
        'acknowledged': acknowledged,
        'grantId': 'RWG_unique',
        'deliveryId': 'REQ_example',
        'reward': {'label': 'سکه', 'amount': 10},
        'balance': 10
      };
    }
    return super.postJson(uri, body: body, headers: headers, timeout: timeout);
  }
}

class StubVideoPlatform extends VideoPlayerPlatform {
  int created = 0, paused = 0, disposed = 0;
  @override
  Future<void> init() async {}
  @override
  Future<int?> createWithOptions(VideoCreationOptions options) async {
    created++;
    return 1;
  }

  late final StreamController<VideoEvent> events =
      StreamController<VideoEvent>.broadcast(onListen: () {
    events.add(VideoEvent(
        eventType: VideoEventType.initialized,
        duration: const Duration(seconds: 5),
        size: const Size(320, 180)));
  });
  @override
  Stream<VideoEvent> videoEventsFor(int playerId) => events.stream;
  @override
  Widget buildView(int playerId) => const SizedBox(width: 320, height: 180);
  @override
  Future<void> setLooping(int playerId, bool looping) async {}
  @override
  Future<void> setVolume(int playerId, double volume) async {}
  @override
  Future<void> setPlaybackSpeed(int playerId, double speed) async {}
  @override
  Future<void> play(int playerId) async {}
  @override
  Future<void> pause(int playerId) async {
    paused++;
  }

  @override
  Future<Duration> getPosition(int playerId) async => Duration.zero;
  @override
  Future<void> dispose(int playerId) async {
    disposed++;
    await events.close();
  }
}

void main() {
  test('all thirteen wire formats and independent full-screen media parse', () {
    expect(DidnexAdFormat.values.length, 13);
    for (final f in DidnexAdFormat.values) {
      final ad = DidnexAd.fromJson(fullJson(f.wireName));
      expect(ad.format, f);
      expect(
          ad.isVideo,
          ['video', 'native_video', 'rewarded', 'rewarded_interstitial']
              .contains(f.wireName));
    }
    final video =
        DidnexAd.fromJson({...fullJson('interstitial'), 'mediaType': 'video'});
    expect(video.isVideo, true);
    expect(video.format.isFullscreen, true);
  });
  test(
      'client announces all formats with fresh request nonce and reward intent',
      () async {
    final t = FakeTransport(), c = client(t);
    await c.requestAd('UNT_test', rewarded: true);
    await c.requestAd('UNT_test', rewarded: true);
    expect(t.requests.first.body!['supportedFormats'],
        DidnexAdFormat.values.map((f) => f.wireName).toList());
    expect(t.requests.first.body!['requestNonce'],
        isNot(t.requests.last.body!['requestNonce']));
    expect(t.requests.first.body!['rewarded'], true);
    c.close();
  });
  test('reward claim coalesces and accepts only applied matching receipt',
      () async {
    final t = RewardTransport(),
        c = client(t),
        ad = DidnexAd.fromJson(fullJson('rewarded'));
    final values = await Future.wait([c.claimReward(ad), c.claimReward(ad)]);
    expect(t.claims, 1);
    expect(values.first.grantId, 'RWG_unique');
    expect(values.last.balance, 10);
    expect(t.requests.last.headers['Authorization'], 'Bearer app-jwt');
    c.close();
  });
  test('unapplied reward is rejected and can be retried after failure',
      () async {
    final t = RewardTransport()..applied = false,
        c = client(t),
        ad = DidnexAd.fromJson(fullJson('rewarded'));
    await expectLater(c.claimReward(ad), throwsA(isA<DidnexAdException>()));
    t.applied = true;
    t.acknowledged = false;
    expect((await c.claimReward(ad)).reward.amount, 10);
    expect(t.claims, 2);
    t.acknowledged = true;
    expect((await c.claimReward(ad)).acknowledged, true);
    expect(t.claims, 3);
    c.close();
  });
  testWidgets('reward intro can be declined without starting media or events',
      (tester) async {
    final t = FakeTransport(response: fullJson('rewarded')),
        c = client(t),
        loaded = await DidnexFullscreenAd.load(
            client: c, unitId: 'UNT_test', rewarded: true);
    late BuildContext context;
    await tester.pumpWidget(MaterialApp(home: Builder(builder: (c) {
      context = c;
      return const Scaffold(body: Text('Host'));
    })));
    final showing = loaded!.show(context);
    await tester.pumpAndSettle();
    expect(find.text('10 سکه'), findsOneWidget);
    expect(find.byType(DidnexAdView), findsNothing);
    await tester.tap(find.text('فعلاً نمی‌خواهم'));
    await tester.pumpAndSettle();
    expect(await showing, isNull);
    expect(t.requests.length, 1);
    c.close();
  });
  testWidgets(
      'full-screen image uses preloaded delivery once and remains closable',
      (tester) async {
    final t = FakeTransport(response: fullJson('interstitial')),
        c = client(t),
        loaded = await DidnexFullscreenAd.load(client: c, unitId: 'UNT_test');
    late BuildContext context;
    await tester.pumpWidget(MaterialApp(home: Builder(builder: (c) {
      context = c;
      return const Scaffold(body: Text('Host'));
    })));
    final showing = loaded!.show(context);
    await tester.pumpAndSettle();
    expect(find.byType(DidnexAdView), findsOneWidget);
    expect(t.requests.where((r) => r.uri.path == '/proxy').length, 1);
    await tester.tap(find.text('بستن تبلیغ ×'));
    await tester.pumpAndSettle();
    await showing;
    expect(await loaded.show(context), isNull);
    expect(find.byType(DidnexAdView), findsNothing);
    expect(t.requests.where((r) => r.uri.path == '/proxy').length, 1);
    c.close();
  });
  testWidgets('inline renderer rejects full-screen response', (tester) async {
    final t = FakeTransport(response: fullJson('interstitial')), c = client(t);
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: DidnexAdView(
                client: c,
                unitId: 'UNT_test',
                errorBuilder: (_, code) => Text(code)))));
    await tester.pumpAndSettle();
    expect(find.text('use_fullscreen_api'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    c.close();
  });
  testWidgets(
      'native-video renderer initializes pauses and disposes platform controller',
      (tester) async {
    final previous = VideoPlayerPlatform.instance, stub = StubVideoPlatform();
    VideoPlayerPlatform.instance = stub;
    final t = FakeTransport(response: fullJson('native_video')), c = client(t);
    try {
      await tester.pumpWidget(MaterialApp(
          home: Scaffold(body: DidnexAdView(client: c, unitId: 'UNT_test'))));
      await tester.pumpAndSettle();
      expect(stub.created, 1);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await tester.pump();
      expect(stub.paused, greaterThan(0));
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 20)));
      expect(find.byType(DidnexAdView), findsNothing);
      expect(stub.disposed, 1);
    } finally {
      VideoPlayerPlatform.instance = previous;
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      c.close();
    }
  });
}
