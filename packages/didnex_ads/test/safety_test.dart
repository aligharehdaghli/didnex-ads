import 'dart:async';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:didnex_ads/didnex_ads.dart';

class FailingTransport implements DidnexTransport {
  int calls=0;
  bool closed=false;
  @override
  Future<Map<String,dynamic>> postJson(Uri uri,{Map<String,dynamic>? body,Map<String,String> headers=const {},Duration timeout=const Duration(seconds:5)}) async {
    calls++;throw const DidnexAdException('network_unavailable');
  }
  @override
  Future<Uint8List> imageBytes(Uri uri,{Duration timeout=const Duration(seconds:5)}) async => throw const DidnexAdException('media_unavailable');
  @override
  void close(){closed=true;}
}
class StalledTransport extends FailingTransport {
  @override
  Future<Map<String,dynamic>> postJson(Uri uri,{Map<String,dynamic>? body,Map<String,String> headers=const {},Duration timeout=const Duration(seconds:5)}) => Completer<Map<String,dynamic>>().future;
}
void main(){
  test('default direct request returns no-fill and backs off when service is unavailable',() async {
    final t=FailingTransport(),client=DidnexAdClient.direct(adOrigin:Uri.parse('https://ads.example'),packageName:'com.example.app',platform:DidnexPlatform.android,transport:t);
    final first=await client.requestAd('UNIT_EXAMPLE');expect(first.noFill,true);expect(first.noFillReason,'network_unavailable');
    final retry=await client.requestAd('UNIT_EXAMPLE');expect(retry.noFillReason,'service_backoff');expect(t.calls,1);client.close();expect(t.closed,true);
  });
  test('overall deadline protects the application even if a custom transport never completes',() async {
    final client=DidnexAdClient.direct(adOrigin:Uri.parse('https://ads.example'),packageName:'com.example.app',platform:DidnexPlatform.android,transport:StalledTransport(),requestTimeout:const Duration(milliseconds:20));
    expect((await client.requestAd('UNIT_EXAMPLE')).noFillReason,'request_timeout');client.close();
  });
  test('strict debugging mode remains an explicit throwing API',() async {
    final client=DidnexAdClient.direct(adOrigin:Uri.parse('https://ads.example'),packageName:'com.example.app',platform:DidnexPlatform.android,transport:FailingTransport(),strictErrors:true);
    await expectLater(client.requestAd('UNIT_EXAMPLE'),throwsA(isA<DidnexAdException>()));client.close();
  });
  test('detached SDK futures and host callbacks have local boundaries',() async {
    didnexCallback(()=>throw StateError('host callback'));
    didnexIgnore(Future<void>.error(StateError('detached player')));
    await Future<void>.delayed(Duration.zero);
  });
}
