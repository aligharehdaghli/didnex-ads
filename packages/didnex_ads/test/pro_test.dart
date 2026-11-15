import 'package:flutter_test/flutter_test.dart';
import 'package:didnex_ads/didnex_ads.dart';
import 'fixtures.dart';

void main() {
  test('preload coalesces concurrent callers, warms media without impressions and consumes once', () async {
    final transport = FakeTransport(), client = testClient(transport);
    final cache = DidnexAdCache(client, allowPreload: () async => true);
    final results = await Future.wait([cache.preload('UNIT_123'), cache.preload('UNIT_123')]);
    expect(results.every((r) => r.ad != null), true);
    expect(transport.requests.where((r) => r.uri.path == '/proxy'), hasLength(1));
    expect(transport.requests.where((r) => r.uri.path == '/ad/v1/event'), isEmpty);
    expect(cache.take('UNIT_123'), isNotNull);
    expect(cache.take('UNIT_123'), isNull);
    cache.close(); client.close();
  });
  test('preload honors the network gate and context change invalidates a cached ad', () async {
    final transport = FakeTransport(), client = testClient(transport);
    final denied = DidnexAdCache(client, allowPreload: () => false);
    expect((await denied.preload('UNIT_123')).noFillReason, 'preload_disallowed');
    expect(transport.requests, isEmpty);
    final cache = DidnexAdCache(client);
    await cache.preload('UNIT_123');
    client.context = const DidnexContext(topics: ['education']);
    expect(cache.take('UNIT_123'), isNull);
    denied.close(); cache.close(); client.close();
  });
  test('external media origins are separated from signed serving URLs and pinned when requested', () {
    final input = adJson()..['servingOrigin'] = 'https://ads.example';
    input['creativeUrl'] = 'https://cdn.partner.example/banner.jpg';
    input['external'] = true;
    final ad = DidnexAd.fromJson(input, expectedOrigin: Uri.parse('https://ads.example'));
    expect(ad.external, true);
    expect(ad.creativeUrl.host, 'cdn.partner.example');
    expect(() => DidnexAd.fromJson(input, expectedOrigin: Uri.parse('https://forged.example')), throwsA(isA<DidnexAdException>()));
    input['events'] = {'impression':'https://forged.example/event','click':'https://ads.example/event'};
    expect(() => DidnexAd.fromJson(input), throwsA(isA<DidnexAdException>()));
  });
  test('revenue keeps estimated and recognized money distinct', () {
    final revenue = DidnexRevenue.fromJson({'deliveryId':'REQ_one','currency':'IRR','amountRial':0,'estimatedRial':12.5,'status':'reserved','precision':'estimated'});
    expect(revenue.amountRial, 0); expect(revenue.estimatedRial, 12.5);
    expect(() => DidnexRevenue.fromJson({'deliveryId':'REQ_one','currency':'USD'}), throwsA(isA<DidnexAdException>()));
  });
}
