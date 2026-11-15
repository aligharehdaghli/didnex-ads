library didnex_push;
import 'dart:async';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'audience.dart';
import 'safety.dart';

/// Receipts acknowledge actual UI display and an explicit user open separately.
class DidnexPush with WidgetsBindingObserver {
  DidnexPush({required this.audience,required this.unitId,this.onMessage,required this.onError,this.onDispose,this.interval=const Duration(seconds:60)});
  final DidnexAudience audience;
  final String unitId;
  final Future<bool> Function(Map<String,dynamic>)? onMessage;
  static const native=MethodChannel('ir.didnex.ads/native');
  Future<bool> hasSystemConsent() async=>await native.invokeMethod<bool>('pushConsent')??false;
  Future<bool> notificationsEnabled() async=>await native.invokeMethod<bool>('pushPermission')??false;
  Future<void> _configureSystem(bool consent,{String transport='fcm'}) async{await native.invokeMethod('pushConfigure',{'origin':audience.origin.origin,'consent':consent,'transport':transport});}
  Future<Map<String,dynamic>> takeOpened() async{final raw=await native.invokeMethod<String>('pushTakeOpened');return raw==null?<String,dynamic>{}:Map<String,dynamic>.from(jsonDecode(raw) as Map);}
  final void Function(Object) onError;
  final Duration interval;
  final void Function()? onDispose;
  String? _directToken;bool _direct=false;
  Future<void> Function(Map<String,dynamic>)? onOpened;
  bool get _android=>!kIsWeb&&defaultTargetPlatform==TargetPlatform.android;
  Future<bool> requestPermission() async=>await native.invokeMethod<bool>('pushRequestPermission')??false;
  Future<String> systemTransport() async=>await native.invokeMethod<String>('pushTransport')??'fcm';
  final Set<String> _shown={};
  final Map<String,Future<bool>> _systemPending={};
  Timer? _timer;
  bool _active=false,_disposed=false,_busy=false,_observing=false;
  int _generation=0,_controlVersion=0;
  final Set<Future<Map<String,dynamic>>> _registrations={};
  Future<void>? _optOut;
  Future<Map<String,dynamic>> _registration(Future<Map<String,dynamic>> pending) async {_registrations.add(pending);try{return await pending;}finally{_registrations.remove(pending);}}
  void _checkRegistration(){if(_disposed)throw StateError('push_disposed');if(_optOut!=null)throw StateError('push_opt_out_pending');}
  bool get _visible=>WidgetsBinding.instance.lifecycleState==null||WidgetsBinding.instance.lifecycleState==AppLifecycleState.resumed;
  bool _valid(Map<String,dynamic> m){try{final expiry=int.tryParse('${m['expiresAt']??m['expires_at']}')??0;final endpoint=Uri.parse('${m['eventUrl']}'),target=Uri.parse('${m['url']}');return m['receipt'] is String&&(m['receipt'] as String).isNotEmpty&&'${m['jobId']??m['id']??''}'.isNotEmpty&&m['title'] is String&&m['body'] is String&&expiry>DateTime.now().millisecondsSinceEpoch&&endpoint.scheme=='https'&&endpoint.origin==audience.origin.origin&&endpoint.userInfo.isEmpty&&!endpoint.hasQuery&&!endpoint.hasFragment&&endpoint.path=='/ad/v1/push-event'&&['https','http'].contains(target.scheme)&&target.host.isNotEmpty&&target.userInfo.isEmpty;}catch(_){return false;}}
  bool validSystemMessage(Map<String,dynamic> message)=>!_disposed&&_optOut==null&&_valid(message);
  Future<void> enableInbox({required bool consent,List<String> topics=const [],String language='fa'}) async {
    _checkRegistration();if(!consent)throw ArgumentError('push_consent_required');
    final control=++_controlVersion;await _registration(audience.subscribeInbox(unitId,consent:true,topics:topics,language:language));if(_disposed||control!=_controlVersion)return;
    if(!_observing){WidgetsBinding.instance.addObserver(this);_observing=true;}_active=true;_generation++;await _poll();
  }
  Future<void> subscribeFcm(String token,{required bool consent,List<String> topics=const [],String language='fa'}) async{_checkRegistration();if(!consent)throw ArgumentError('push_consent_required');stop();_direct=false;_directToken=null;if(!await notificationsEnabled())throw StateError('notification_permission_required');final control=++_controlVersion;await _registration(audience.subscribeFcm(unitId,fcmToken:token,consent:consent,topics:topics,language:language));if(!_disposed&&control==_controlVersion)await _configureSystem(true);}
  Future<bool> enableDirect({required bool consent,bool backgroundPolling=true,List<String> topics=const []}) async {
    try{_checkRegistration();final intent=_controlVersion;final allowed=consent&&await notificationsEnabled();_checkRegistration();if(intent!=_controlVersion)return false;if(!allowed)throw StateError('notification_permission_or_consent_required');stop();final control=++_controlVersion;
      final grant=await _registration(audience.call(unitId,'subscribePush',{'provider':'direct','consent':true,'topics':topics}));if(_disposed||_optOut!=null||control!=_controlVersion)return false;
      _directToken=grant['directToken'] as String?;if(_directToken==null)return false;_direct=true;
      if(!_observing){WidgetsBinding.instance.addObserver(this);_observing=true;}
      native.setMethodCallHandler((call) async{if(call.method=='didnexPushOpened')await _takeDirectOpened();});
      if(_android){final raw=await native.invokeMethod<String>('pushDirectConfigure',{'origin':audience.origin.origin,'token':_directToken,'expiresAt':grant['directTokenExpiresAt'],'background':backgroundPolling});if(raw==null||jsonDecode(raw)['enabled']!=true)return false;}
      else{await _configureSystem(true,transport:'direct');_active=true;await _poll();}
      await _takeDirectOpened();return true;
    }catch(e){didnexCallback(()=>onError(e));return false;}
  }
  Future<void> _takeDirectOpened() async{if(!_direct||_disposed)return;try{final value=await takeOpened();if(!validSystemMessage(value))return;try{await opened(value);}catch(e){didnexCallback(()=>onError(e));}await onOpened?.call(value);}catch(e){didnexCallback(()=>onError(e));}}
  Future<bool> restoreDirect({bool backgroundPolling=true,List<String> topics=const []}) async{try{if(await systemTransport()!='direct'||!await hasSystemConsent())return false;return await enableDirect(consent:true,backgroundPolling:backgroundPolling,topics:topics);}catch(e){didnexCallback(()=>onError(e));return false;}}
  /// Can be used by the optional foreground FCM adapter as well as Inbox.
  Future<bool> receive(Map<String,dynamic> message,{bool alreadyPresented=false,bool legacyInbox=false}) async {
    if(!validSystemMessage(message))return false;
    if(legacyInbox)return _receive(message,alreadyPresented:alreadyPresented,legacyInbox:true);
    final key='${message['jobId']??message['id']}';final pending=_systemPending[key];if(pending!=null)return pending;
    final work=_receive(message,alreadyPresented:alreadyPresented);_systemPending[key]=work;try{return await work;}finally{_systemPending.remove(key);}
  }
  Future<bool> _receive(Map<String,dynamic> message,{bool alreadyPresented=false,bool legacyInbox=false}) async {
    if(_disposed||_optOut!=null||(legacyInbox&&!_visible)||!_valid(message))return false;try{await audience.reportPush(message,'received');}catch(_){}final key='${message['jobId']??message['id']??''}';if(key.isEmpty)return false;
    if(!_shown.contains(key)){final gen=_generation;bool displayed=false;try{if(legacyInbox){displayed=await onMessage?.call(message)??false;}else if(alreadyPresented){displayed=await notificationsEnabled();}else{displayed=await native.invokeMethod<bool>('pushPresent',{'json':jsonEncode(message)})??false;}}catch(e){didnexCallback(()=>onError(e));}if(!displayed){if(!legacyInbox){try{await audience.reportPush(message,'failed',code:'notification_display_failed');}catch(_){}}return false;}if(_disposed||_optOut!=null||(legacyInbox&&(!_visible||gen!=_generation)))return false;_shown.add(key);if(_shown.length>500)_shown.remove(_shown.first);}
    await audience.reportPush(message,'delivered');return true;
  }
  Future<Map<String,dynamic>> profile()=>audience.call(unitId,'pushProfile');
  Future<Map<String,dynamic>> setTags(Map<String,String> tags,{int version=0})=>audience.call(unitId,'pushTags',{'tags':tags,'version':version});
  Future<Map<String,dynamic>> login(String identityToken)=>audience.call(unitId,'pushIdentity',{'identityToken':identityToken});
  Future<Map<String,dynamic>> logout()=>audience.call(unitId,'pushLogout');
  Future<void> report(Map<String,dynamic> message,String kind,{String? actionId,String? code})=>audience.reportPush(message,kind,actionId:actionId,code:code);
  Future<void> opened(Map<String,dynamic> message) async {if(!validSystemMessage(message))return;await audience.reportPush(message,'opened');}
  void _arm(){_timer?.cancel();if(_active&&!_disposed&&_visible)_timer=Timer(interval.inSeconds<15?const Duration(seconds:15):interval,_poll);}
  Future<void> _poll() async {
    if(!_active||_disposed||!_visible||_busy)return;final gen=_generation;_busy=true;
    try{final value=_direct?await audience.call(unitId,'directInbox'):await audience.inbox(unitId);for(final raw in (value['messages'] as List? ?? [])){if(gen!=_generation||!_active||_disposed||!_visible)break;if(raw is Map)await receive(Map<String,dynamic>.from(raw),legacyInbox:!_direct);}}
    catch(e){if(!_disposed&&gen==_generation)didnexCallback(() { onError(e); });}finally{_busy=false;_arm();}
  }
  @override void didChangeAppLifecycleState(AppLifecycleState state){_generation++;_timer?.cancel();if(state==AppLifecycleState.resumed&&_direct)didnexIgnore(_takeDirectOpened());if(state==AppLifecycleState.resumed&&_active)didnexIgnore(_poll());}
  void stop(){_active=false;_generation++;_controlVersion++;_timer?.cancel();}
  Future<void> unsubscribe(){stop();return _optOut??=_unsubscribe().whenComplete(()=>_optOut=null);}
  Future<void> _unsubscribe() async {if(_android){try{await native.invokeMethod('pushDirectStop',{'revoke':true});}catch(_){}}_direct=false;_directToken=null;try{await _configureSystem(false);}catch(_){}await Future.wait(_registrations.toList().map((future) async {try{await future;}catch(_){}}));await Future.wait(_systemPending.values.toList().map((future) async {try{await future;}catch(_){}}));try{await _configureSystem(false);}catch(_){}await audience.unsubscribe(unitId);}
  void dispose(){if(_disposed)return;stop();_disposed=true;if(_observing)WidgetsBinding.instance.removeObserver(this);didnexCallback((){onDispose?.call();});}
}
