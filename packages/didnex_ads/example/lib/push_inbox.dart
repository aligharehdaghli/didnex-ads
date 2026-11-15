import 'package:flutter/material.dart';
import 'package:didnex_ads/didnex_ads.dart';
void main() { WidgetsFlutterBinding.ensureInitialized(); runApp(const MaterialApp(home: InboxPage())); }
class InboxPage extends StatefulWidget {
 const InboxPage({super.key});
 @override State<InboxPage> createState()=>_InboxPageState();
}
class _InboxPageState extends State<InboxPage> {
 late final DidnexHttpTransport transport;
 late final DidnexPush push;
 Map<String,dynamic>? message;
 String status='برای فعال‌سازی، رضایت خود را ثبت کنید.';
 bool busy=false;
 @override void initState(){
  super.initState();transport=DidnexHttpTransport();
  final client=DidnexAdClient.direct(adOrigin:Uri.parse('https://didnex.com'),packageName:'com.company.app',transport:transport);
  push=client.createPush(unitId:'UNT_REPLACE_ME',onError:(e){if(mounted)setState(()=>status='$e');},onMessage:(value) async {
   if(!mounted)return false;setState(()=>message=value);await WidgetsBinding.instance.endOfFrame;return mounted;
  });
 }
 Future<void> run(Future<void> Function() action) async {
  if(busy)return;setState(()=>busy=true);
  try {await action();if(mounted)setState(()=>status='درخواست انجام شد');}
  catch(e){if(mounted)setState(()=>status='اتصال برقرار نشد: $e');}
  finally{if(mounted)setState(()=>busy=false);}
 }
 @override Widget build(BuildContext context)=>Scaffold(appBar:AppBar(title:const Text('صندوق پیام')),body:Padding(padding:const EdgeInsets.all(16),child:Column(children:[
  Text(status),
  FilledButton(onPressed:busy?null:()=>run(()=>push.enableInbox(consent:true,topics:['general'])),child:const Text('پذیرش پیام‌ها')),
  if(message!=null)Card(child:ListTile(title:Text('${message!['title']}'),subtitle:Text('${message!['body']}'),onTap:()=>run(()=>push.opened(message!)))),
  TextButton(onPressed:busy?null:()=>run(push.unsubscribe),child:const Text('لغو عضویت')),
 ])));
 @override void dispose(){push.dispose();transport.close();super.dispose();}
}
