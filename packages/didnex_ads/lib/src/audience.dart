import 'package:flutter/services.dart';
import 'models.dart';
import 'transport.dart';

/// A device-installation wallet and consented push client hosted by Didnex.
/// No publisher backend or app login. Keep the installation token private.
class DidnexAudience {
  DidnexAudience({required Uri origin, required this.packageName, required this.device, required DidnexTransport transport})
      : origin = didnexHttpsUri(origin), _transport = transport;
  final Uri origin;
  final String packageName, device;
  final DidnexTransport _transport;
  static const _native = MethodChannel('ir.didnex.ads/native');
  static final Map<String, String> _memory = {};
  String get _scope => '${origin.origin}:$packageName';
  static final Map<String,Future<String>> _registrations = {};
  static final Map<String,bool> _persistent = {};
  Future<String>? _pending;
  bool persistentStorageAvailable = true;
  Future<String> token(String unitId) => _pending ??= _sharedToken(unitId).catchError((Object error) { _pending = null; throw error; });
  Future<String> _sharedToken(String unitId) async {
    final scope=_scope;
    final operation=_registrations.putIfAbsent(scope,()=>_register(unitId));
    try {
      final value=await operation;
      persistentStorageAvailable=_persistent[scope]??persistentStorageAvailable;
      return value;
    } finally {
      if(identical(_registrations[scope],operation))_registrations.remove(scope);
    }
  }
  Future<String> _register(String unitId) async {
    String? saved = _memory[_scope];
    if (saved == null) { try { saved = await _native.invokeMethod<String>('audienceRead', {'scope': _scope}); } catch (_) { persistentStorageAvailable = false; } }
    final result = await _transport.postJson(origin.resolve('/ad/v1/audience'), body: {
      'action':'register','unitId':unitId,'packageName':packageName,'device':device,
      if(saved != null && saved.isNotEmpty)'installationToken':saved,
    });
    final value = result['installationToken'];
    if(value is! String || !RegExp(r'^INS_[a-f0-9]{32}\.[a-f0-9]{64}$').hasMatch(value)) throw const DidnexAdException('invalid_installation_response');
    _memory[_scope] = value;
    try { await _native.invokeMethod<void>('audienceWrite', {'scope':_scope,'token':value}); } catch (_) { persistentStorageAvailable = false; }
    _persistent[_scope]=persistentStorageAvailable;
    return value;
  }
  Future<Map<String,dynamic>> call(String unitId, String action, [Map<String,dynamic> data = const {}]) async => _transport.postJson(
    origin.resolve('/ad/v1/audience'),body:{...data,'action':action,'installationToken':await token(unitId)});
  Future<Map<String,dynamic>> next(String unitId,String op,[Map<String,dynamic> data=const {}]) async {
    try {return {'ok':true,...await call(unitId,'next',{...data,'op':op}).timeout(const Duration(seconds:15))};}
    catch(_){return {'ok':false,'code':'growth_unavailable'};}
  }
  Future<Map<String,dynamic>> balance(String unitId) => call(unitId,'balance');
  /// Use one stable externalId per feature purchase; retry the same ID on timeout.
  Future<Map<String,dynamic>> spend(String unitId,{required String label,required int amount,required String externalId}) => call(unitId,'spendReward',{'label':label,'amount':amount,'externalId':externalId});
  Future<Map<String,dynamic>> subscribeInbox(String unitId,{required bool consent,List<String> topics=const [],String language='fa'}) => call(unitId,'subscribePush',{'provider':'inbox','consent':consent,'topics':topics,'language':language});
  /// Obtain the current FCM token only after the OS notification permission flow.
  Future<Map<String,dynamic>> subscribeFcm(String unitId,{required String fcmToken,required bool consent,List<String> topics=const [],String language='fa'}) => call(unitId,'subscribePush',{'provider':'fcm','token':fcmToken,'consent':consent,'topics':topics,'language':language});
  Future<Map<String,dynamic>> unsubscribe(String unitId) => call(unitId,'unsubscribePush');
  Future<Map<String,dynamic>> inbox(String unitId) => call(unitId,'inbox');
  /// Call delivered only after display, opened only after the user opens it.
  Future<void> reportPush(Map<String,dynamic> data,String kind,{String? actionId,String? code}) async {
    if(!['delivered','received','displayed','opened','dismissed','action','failed'].contains(kind) || data['receipt'] is! String) throw const DidnexAdException('invalid_push_event');
    final target=didnexHttpsUri(data['eventUrl']);
    if(target.origin != origin.origin || target.path!='/ad/v1/push-event') throw const DidnexAdException('invalid_push_event');
    await _transport.postJson(target,body:{'receipt':data['receipt'],'kind':kind,if(actionId!=null)'actionId':actionId,if(code!=null)'code':code});
  }
}
