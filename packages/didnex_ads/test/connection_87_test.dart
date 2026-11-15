import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:didnex_ads/didnex_ads.dart';
import 'fixtures.dart';
void main(){
 testWidgets('noFill takes zero height in a normal inline layout',(tester) async {
  final client=testClient(FakeTransport(response:{'noFill':true,'reason':'no_eligible_campaign'}));
  await tester.pumpWidget(MaterialApp(home:Scaffold(body:Column(children:[const Text('before'),DidnexAdView(client:client,unitId:'UNIT_123'),const Text('after')]))));
  await tester.pump();await tester.pump();
  expect(tester.getSize(find.byType(DidnexAdView)).height,0);
  await tester.pumpWidget(const SizedBox.shrink());client.close();
 });
 test('inspector retains exception type and frame name without message or path',(){
  DidnexInspector.entries.value=[];
  DidnexInspector.capture(StateError('https://secret.example/?jwt=PRIVATE_TOKEN'),StackTrace.fromString('#0 example (C:/private/user/main.dart:12:1)'));
  final report=DidnexInspector.report();
  expect(report,contains('StateError'));expect(report,contains('example'));
  expect(report, isNot(contains('PRIVATE_TOKEN')));expect(report,isNot(contains('secret.example')));expect(report,isNot(contains('C:/private')));
 });
}
