import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:didnex_ads/didnex_ads.dart';

import 'fixtures.dart';

void main() {
  testWidgets(
    'renders an actual image response and opens only the signed destination',
    (tester) async {
      final transport = FakeTransport(response: adJson(format: 'native'));
      final client = testClient(transport);
      Uri? opened;
      final events = <DidnexAdEvent>[];
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 320,
              child: DidnexAdView(
                unitId: 'UNIT_123',
                client: client,
                maxMediaHeight: 160,
                openUrl: (uri) async {
                  opened = uri;
                },
                onEvent: events.add,
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.text('تبلیغ نمونه آزمون'), findsOneWidget);
      expect(find.text('مشاهده پیشنهاد'), findsOneWidget);
      expect(find.byType(Image), findsOneWidget);
      await tester.tap(find.text('مشاهده پیشنهاد'));
      await tester.pump();
      expect(opened?.host, 'ads.example');
      expect(opened?.path, '/ad/v1/click');
      // Clicking before qualifying viewability must not generate a billable click.
      expect(
        transport.requests.where(
          (r) => r.uri.queryParameters['kind'] == 'click',
        ),
        isEmpty,
      );
      await tester.pumpWidget(const SizedBox.shrink());
      client.close();
    },
  );
  testWidgets('no-fill renders the host fallback without an image', (
    tester,
  ) async {
    final transport = FakeTransport(
      response: {'noFill': true, 'reason': 'no_eligible_campaign'},
    );
    final client = testClient(transport);
    await tester.pumpWidget(
      MaterialApp(
        home: DidnexAdView(
          unitId: 'UNIT_123',
          client: client,
          noFillBuilder: (_, reason) => Text('fallback:$reason'),
        ),
      ),
    );
    await tester.pump();
    expect(find.text('fallback:no_eligible_campaign'), findsOneWidget);
    expect(find.byType(Image), findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
    client.close();
  });
  testWidgets('diagnostic uses the real image path and reports no financial event', (
    tester,
  ) async {
    final transport = FakeTransport(response: adJson(diagnostic: true, format: 'native'));
    final client = testClient(transport);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 320,
            child: DidnexAdView(
              unitId: 'UNIT_123',
              client: client,
              diagnosticToken: 'test',
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.text('تبلیغ نمونه آزمون'), findsOneWidget);
    expect(find.byType(Image), findsOneWidget);
    // Image decoding runs outside the widget test's fake clock. Wait for its
    // first frame before asserting the SDK's actual loaded telemetry.
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
    await tester.pump();
    await tester.pump();
    expect(
      transport.requests.where((r) => r.uri.path == '/ad/v1/event'),
      isEmpty,
    );
    expect(
      transport.requests.where((r) => r.body?['kind'] == 'loaded'),
      hasLength(1),
    );
    await tester.pumpWidget(const SizedBox.shrink());
    client.close();
  });
  testWidgets(
    'late request completion after disposal does not rebuild a removed view',
    (tester) async {
      final transport = FakeTransport();
      final token = Completer<String>();
      final client = testClient(transport, token: () => token.future);
      await tester.pumpWidget(
        MaterialApp(
          home: DidnexAdView(unitId: 'UNIT_123', client: client),
        ),
      );
      expect(transport.requests, isEmpty);
      await tester.pumpWidget(const SizedBox.shrink());
      token.complete('app.session.jwt');
      await tester.pump();
      await tester.pump();
      expect(tester.takeException(), isNull);
      client.close();
    },
  );
}
