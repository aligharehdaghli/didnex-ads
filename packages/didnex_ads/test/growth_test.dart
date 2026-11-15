import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:didnex_ads/didnex_ads.dart';
class GrowthFailure implements DidnexTransport {
 @override Future<Map<String,dynamic>> postJson(Uri uri,{Map<String,dynamic>? body,Map<String,String> headers=const {},Duration timeout=const Duration(seconds:5)}) async=>throw const DidnexAdException('network_unavailable');
 @override Future<Uint8List> imageBytes(Uri uri,{Duration timeout=const Duration(seconds:5)})async=>throw const DidnexAdException('media_unavailable');
 @override void close(){}
}
void main(){
 TestWidgetsFlutterBinding.ensureInitialized();
 test('optional growth reports network failure without throwing to app',()async{final client=DidnexAdClient.direct(adOrigin:Uri.parse('https://ads.example'),packageName:'com.growth.failure',transport:GrowthFailure());final result=await client.next('UNT_TEST','messages');expect(result['ok'],false);client.close();});
 test('pair link cannot redirect the SDK to another origin',()async{final client=DidnexAdClient.direct(adOrigin:Uri.parse('https://ads.example'),packageName:'com.growth.pair',transport:GrowthFailure());final result=await client.pairDevice('UNT_TEST',Uri.parse('https://other.example/sdk/pair.html#code=invalid'),consent:true);expect(result['code'],'invalid_pair_link');client.close();});
 test('session event failure remains optional',()async{final client=DidnexAdClient.direct(adOrigin:Uri.parse('https://ads.example'),packageName:'com.growth.event',transport:GrowthFailure());expect((await client.sessionEvent('UNT_TEST','checkout_start'))['ok'],false);client.close();});
}
