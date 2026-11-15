import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:didnex_ads/didnex_ads.dart';
import 'fixtures.dart';

void main() {
  testWidgets('short slot shares a scoped client and preserves child privacy', (tester) async {
    final transport = FakeTransport(response: {'noFill': true, 'reason': 'no_eligible_campaign'});
    final client = testClient(transport);
    await tester.pumpWidget(DidnexAds.withClient(
      client: client,
      child: MaterialApp(home: DidnexAdSlot(
        unitId: 'UNIT_123', childDirected: true,
        noFillBuilder: (_, reason) => Text('fallback:$reason'),
      )),
    ));
    await tester.pump();
    await tester.pump();
    expect(find.text('fallback:no_eligible_campaign'), findsOneWidget);
    expect(transport.requests.first.body!['childDirected'], true);
    expect(transport.requests.first.headers['Authorization'], 'Bearer app.session.jwt');
    await tester.pumpWidget(const SizedBox.shrink());
    expect(transport.closed, false); // External ownership is explicit.
    client.close();
  });

  testWidgets('owned scope keeps the client on rebuild and reads the latest token provider', (tester) async {
    late BuildContext screen;
    Future<String> token() async => 'first-jwt';
    Widget root(Future<String> Function() provider) => DidnexAds(
      proxyUrl: Uri.parse('https://publisher.example/proxy'),
      sessionToken: provider,
      child: MaterialApp(home: Builder(builder: (context) {
        screen = context;
        return const SizedBox.shrink();
      })),
    );
    await tester.pumpWidget(root(token));
    final first = DidnexAds.of(screen);
    await tester.pumpWidget(root(() async => 'updated-jwt'));
    final second = DidnexAds.of(screen);
    expect(identical(first, second), true);
    expect(await second.sessionToken(), 'updated-jwt');
    await tester.pumpWidget(const SizedBox.shrink());
    expect((await first.requestAd('UNIT_123')).noFill, true);
  });

  testWidgets('one-call fullscreen handles no-fill and releases its loading gate', (tester) async {
    final transport = FakeTransport(response: {'noFill': true, 'reason': 'no_eligible_campaign'});
    final client = testClient(transport);
    late BuildContext screen;
    await tester.pumpWidget(DidnexAds.withClient(client: client,
      child: MaterialApp(home: Builder(builder: (context) {
        screen = context;
        return const SizedBox.shrink();
      })),
    ));
    expect(await DidnexAds.showInterstitial(screen, unitId: 'UNIT_123', childDirected: true), false);
    expect(await DidnexAds.showRewarded(screen, unitId: 'UNIT_123'), null);
    expect(transport.requests[0].body!['childDirected'], true);
    expect(transport.requests[1].body!['rewarded'], true);
    await tester.pumpWidget(const SizedBox.shrink());
    client.close();
  });

  testWidgets('short API never accepts a server key as an app session', (tester) async {
    final transport = FakeTransport(response: {'noFill': true});
    final client = testClient(transport, token: () async => 'md_server_secret');
    late BuildContext screen;
    await tester.pumpWidget(DidnexAds.withClient(client: client,
      child: MaterialApp(home: Builder(builder: (context) {
        screen = context;
        return const SizedBox.shrink();
      })),
    ));
    expect(await DidnexAds.showRewarded(screen, unitId: 'UNIT_123'), null);
    expect(transport.requests, isEmpty);
    await tester.pumpWidget(const SizedBox.shrink());
    client.close();
  });

  testWidgets('missing scope reports a configuration error before any request', (tester) async {
    late BuildContext screen;
    await tester.pumpWidget(MaterialApp(home: Builder(builder: (context) {
      screen = context;
      return const SizedBox.shrink();
    })));
    expect(() => DidnexAds.of(screen), throwsA(isA<DidnexAdException>()));
    expect(DidnexAds.maybeOf(screen), null);
    expect(await DidnexAds.showInterstitial(screen, unitId:'UNIT_123'), false);
    expect(await DidnexAds.showRewarded(screen, unitId:'UNIT_123'), null);
    await tester.pumpWidget(const MaterialApp(home:DidnexAdSlot(unitId:'UNIT_123')));
    expect(tester.takeException(), null);
  });
}
