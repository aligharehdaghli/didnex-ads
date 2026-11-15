// Copy into the app after adding firebase_core and firebase_messaging.
import 'dart:async';
import 'dart:io';
import 'package:flutter/widgets.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:didnex_ads/didnex_ads.dart';
class DidnexFcm with WidgetsBindingObserver {
  DidnexFcm(this.push,{required this.navigate,required this.onError});
  final DidnexPush push;
  final Future<void> Function(Map<String,dynamic>) navigate;
  final void Function(Object) onError;
  final List<StreamSubscription<dynamic>> _subscriptions=[];
  bool _enabled=false;
  int _generation=0;
  Future<void> _guard(Future<void> Function() action) async{try{await action();}catch(e){try{onError(e);}catch(_){}}}
  final Set<String> _opened={};
  Future<void> _open(Map<String,dynamic> data) async{final key='${data['jobId']??data['id']??''}';final expiry=int.tryParse('${data['expiresAt']}')??0;if(!_enabled||!push.validSystemMessage(data)||key.isEmpty||expiry<=DateTime.now().millisecondsSinceEpoch||_opened.contains(key))return;_opened.add(key);if(_opened.length>500)_opened.remove(_opened.first);try{await push.opened(data);}finally{await navigate(data);}}
  Future<void> _takeOpened() async{if(_enabled&&Platform.isAndroid)await _open(await push.takeOpened());}
  @override void didChangeAppLifecycleState(AppLifecycleState state){if(state==AppLifecycleState.resumed)unawaited(_guard(_takeOpened));}
  Future<void> enable({required bool consent,List<String> topics=const [],String language='fa',bool requestPermission=true}) async {
    if(!consent)throw ArgumentError('push_consent_required');await close();final gen=++_generation;
    final permission=requestPermission?await FirebaseMessaging.instance.requestPermission(alert:true,badge:true,sound:true):await FirebaseMessaging.instance.getNotificationSettings();
    if(permission.authorizationStatus!=AuthorizationStatus.authorized&&permission.authorizationStatus!=AuthorizationStatus.provisional)throw StateError('notification_permission_denied');
    if(Platform.isIOS&&await FirebaseMessaging.instance.getAPNSToken()==null)throw StateError('apns_token_not_ready_retry_after_registration');
    if(gen!=_generation)return;_enabled=true;WidgetsBinding.instance.addObserver(this);
    if(Platform.isIOS)await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(alert:true,badge:true,sound:true);
    DidnexPush.native.setMethodCallHandler((call)async{if(call.method=='didnexPushOpened')await _guard(_takeOpened);});
    Future<void> register(String token) async {if(_enabled&&gen==_generation)await push.subscribeFcm(token,consent:true,topics:topics,language:language);}
    _subscriptions.add(FirebaseMessaging.instance.onTokenRefresh.listen((token){unawaited(_guard(()=>register(token)));},onError:(Object e){try{onError(e);}catch(_){}}));
    _subscriptions.add(FirebaseMessaging.onMessage.listen((m){if(_enabled&&gen==_generation)unawaited(_guard(() async {await push.receive(Map<String,dynamic>.from(m.data),alreadyPresented:Platform.isIOS);}));},onError:(Object e){try{onError(e);}catch(_){}}));
    Future<void> opened(RemoteMessage message) async {if(!_enabled||gen!=_generation)return;await _open(Map<String,dynamic>.from(message.data));}
    _subscriptions.add(FirebaseMessaging.onMessageOpenedApp.listen((m){unawaited(_guard(()=>opened(m)));},onError:(Object e){try{onError(e);}catch(_){}}));
    final token=await FirebaseMessaging.instance.getToken();if(token==null)throw StateError('fcm_token_not_ready');await register(token);
    final initial=await FirebaseMessaging.instance.getInitialMessage();if(initial!=null)await opened(initial);await _takeOpened();
  }
  Future<bool> restore({List<String> topics=const [],String language='fa'}) async{if(await push.systemTransport()!='fcm'||!await push.hasSystemConsent()||!await push.notificationsEnabled())return false;try{await enable(consent:true,topics:topics,language:language,requestPermission:false);return true;}catch(e){try{onError(e);}catch(_){}return false;}}
  Future<void> close() async {WidgetsBinding.instance.removeObserver(this);_enabled=false;_generation++;for(final subscription in _subscriptions){await subscription.cancel();}_subscriptions.clear();}
  Future<void> unsubscribe() async {await close();await push.unsubscribe();}
}
