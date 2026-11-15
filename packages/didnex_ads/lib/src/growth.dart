import 'dart:convert';
import 'package:flutter/material.dart';
import 'client.dart';
import 'fullscreen.dart';
import 'models.dart';

extension DidnexGrowthClient on DidnexAdClient {
  Future<Map<String,dynamic>> next(String unitId,String op,[Map<String,dynamic> data=const {}]) async {
    try{return await audience.next(unitId,op,{'sessionId':sessionId,...data});}
    catch(_){return {'ok':false,'code':'growth_unavailable'};}
  }
  Future<Map<String,dynamic>> sessionEvent(String unitId,String event,{String? externalId}) => next(unitId,'sessionEvent',{'event':event,'externalId':externalId??DidnexSession.create()});
  Future<Map<String,dynamic>> pairDevice(String unitId,Uri link,{required bool consent}) async {
    try{if(link.origin!=adOrigin?.origin||link.path!='/sdk/pair.html')return {'ok':false,'code':'invalid_pair_link'};final p=Uri.splitQueryString(link.fragment),code=p['code'];if(p['origin']!=adOrigin?.origin||code==null||!RegExp(r'^[a-f0-9]{64}$').hasMatch(code))return {'ok':false,'code':'invalid_pair_link'};return await next(unitId,'pair',{'code':code,'consent':consent});}
    catch(_){return {'ok':false,'code':'invalid_pair_link'};}
  }
  Future<Map<String,dynamic>> adAction(String unitId,DidnexAd ad,String op,[Map<String,dynamic> values=const {}]) => next(unitId,op,{...values,'deliveryId':ad.requestId,'signature':ad.telemetrySignature});
}
enum DidnexGrowthScreen {preferences,messages,offers}
class DidnexGrowthPanel extends StatefulWidget {
  const DidnexGrowthPanel({super.key,required this.client,required this.unitId,required this.screen,this.onReward});
  final DidnexAdClient client;final String unitId;final DidnexGrowthScreen screen;final void Function(DidnexRewardReceipt)? onReward;
  @override State<DidnexGrowthPanel> createState()=>_DidnexGrowthPanelState();
}
class _DidnexGrowthPanelState extends State<DidnexGrowthPanel> {
  Map<String,dynamic>? _data;bool _busy=false,_analytics=false,_messaging=false;int _version=0,_cap=3,_start=1320,_end=480;String? _notice;List<String> _topics=[];
  @override void initState(){super.initState();_load();}
  Future<void> _load() async {
    try{var r=await widget.client.next(widget.unitId,widget.screen.name);if(!mounted)return;
      if(r['ok']==true&&(widget.screen==DidnexGrowthScreen.preferences?r['preferences'] is! Map:r[widget.screen.name] is! List))r={'ok':false};
      setState((){_data=r;final p=r['preferences'];if(p is Map){_analytics=p['analytics']==1;_messaging=p['messaging']==1;int number(String key,int fallback,int max){final value=p[key];return value is int?value.clamp(0,max).toInt():fallback;}_version=number('version',0,1000000000);_cap=number('daily_cap',3,20);_start=number('quiet_start',1320,1439);_end=number('quiet_end',480,1439);try{final v=jsonDecode(p['topics_json'] is String?p['topics_json'] as String:'[]');_topics=v is List?v.whereType<String>().toList():[];}catch(_){_topics=[];}}});
    }catch(_){if(mounted)setState(()=>_data={'ok':false});}
  }
  Future<void> _time(bool start) async {final value=start?_start:_end,picked=await showTimePicker(context:context,initialTime:TimeOfDay(hour:value~/60,minute:value%60));if(picked!=null&&mounted)setState((){if(start){_start=picked.hour*60+picked.minute;}else{_end=picked.hour*60+picked.minute;}});}
  Future<void> _save() async {setState(()=>_busy=true);final r=await widget.client.next(widget.unitId,'preferences',{'value':{'version':_version,'analytics':_analytics,'messaging':_messaging,'quietStart':_start,'quietEnd':_end,'timezoneOffset':DateTime.now().timeZoneOffset.inMinutes,'dailyCap':_cap,'topics':_topics}});if(!mounted)return;setState((){_busy=false;_notice=r['ok']==true?'ذخیره شد.':'ذخیره انجام نشد؛ پنجره را دوباره باز کنید.';if(r['version'] is int)_version=r['version'] as int;});}
  Future<void> _offer(Map raw) async {setState(()=>_busy=true);try{final ad=await DidnexFullscreenAd.load(client:widget.client,unitId:raw['unitId'] as String,rewarded:true);if(ad==null||!mounted)return;final receipt=await ad.show(context);if(receipt!=null){try{widget.onReward?.call(receipt);}catch(_){}if(mounted)setState(()=>_notice='جایزه در دیدنکس ثبت شد؛ دوباره اعتبار ندهید.');}}catch(_){if(mounted)setState(()=>_notice='تبلیغ در دسترس نیست.');}finally{if(mounted)setState(()=>_busy=false);}}
  Future<void> _more() async {
    final cursor=_data?['nextCursor'];if(cursor==null||_busy)return;setState(()=>_busy=true);
    try{final r=await widget.client.next(widget.unitId,'messages',{'cursor':cursor});if(!mounted)return;
      if(r['ok']!=true||r['messages'] is! List){setState(()=>_notice='صفحه پیام دریافت نشد.');return;}
      final all=[...(_data?['messages'] as List? ?? []),...(r['messages'] as List)].whereType<Map>();
      final unique=<String,Map>{};for(final m in all){if(m['id'] is String)unique[m['id'] as String]=m;}
      setState(()=>_data={...r,'messages':unique.values.toList()});
    }catch(_){if(mounted)setState(()=>_notice='صفحه پیام دریافت نشد.');}
    finally{if(mounted)setState(()=>_busy=false);}
  }

  @override Widget build(BuildContext context){final data=_data;if(data==null)return const Center(child:CircularProgressIndicator());if(data['ok']!=true)return Column(mainAxisSize:MainAxisSize.min,children:[const Text('ارتباط برقرار نشد.'),TextButton(onPressed:_load,child:const Text('تلاش دوباره'))]);final items=<Widget>[];
   if(widget.screen==DidnexGrowthScreen.preferences){items.addAll([SwitchListTile(title:const Text('اجازه تحلیل اختیاری'),value:_analytics,onChanged:_busy?null:(v)=>setState(()=>_analytics=v)),SwitchListTile(title:const Text('دریافت پیام‌های رسانه'),value:_messaging,onChanged:_busy?null:(v)=>setState(()=>_messaging=v)),ListTile(title:const Text('شروع سکوت'),trailing:Text('${_start~/60}:${(_start%60).toString().padLeft(2,'0')}'),onTap:()=>_time(true)),ListTile(title:const Text('پایان سکوت'),trailing:Text('${_end~/60}:${(_end%60).toString().padLeft(2,'0')}'),onTap:()=>_time(false)),ListTile(title:const Text('سقف پیام روزانه'),trailing:DropdownButton<int>(value:_cap,items:List.generate(21,(i)=>DropdownMenuItem(value:i,child:Text('$i'))),onChanged:_busy?null:(v){if(v!=null)setState(()=>_cap=v);})),TextFormField(initialValue:_topics.join(','),decoration:const InputDecoration(labelText:'موضوع‌ها با ویرگول لاتین؛ خالی یعنی همه'),onChanged:(v)=>_topics=v.split(',').map((x)=>x.trim()).where((x)=>x.isNotEmpty).toList()),FilledButton(onPressed:_busy?null:_save,child:const Text('ذخیره ترجیحات'))]);}
   else if(widget.screen==DidnexGrowthScreen.messages){final messages=(data['messages'] as List?)?.whereType<Map>().toList()??[];if(messages.isEmpty)items.add(const Text('پیامی ندارید.'));for(final m in messages)items.add(Card(child:ListTile(title:Text(m['title']?.toString() ?? ''),subtitle:Text(m['message']?.toString() ?? ''),trailing:Icon(m['read_at']==null?Icons.mark_email_unread_outlined:Icons.mark_email_read_outlined),onTap:()async{await widget.client.next(widget.unitId,'readMessage',{'messageId':m['id']});if(mounted)await _load();})));if(data['nextCursor']!=null)items.add(TextButton(onPressed:_more,child:const Text('پیام‌های قدیمی‌تر')));}
   else{final offers=(data['offers'] as List?)?.whereType<Map>().toList()??[];if(offers.isEmpty)items.add(const Text('پیشنهادی فعال نیست.'));for(final offer in offers)items.add(Card(child:ListTile(title:Text(offer['title']?.toString() ?? ''),subtitle:Text('${offer['rewardAmount']} ${offer['rewardLabel']} · ${offer['description']??''}'),trailing:FilledButton(onPressed:_busy?null:()=>_offer(offer),child:const Text('انتخاب و تماشا')))));}
   if(_notice!=null)items.add(Padding(padding:const EdgeInsets.all(12),child:Text(_notice!)));return Directionality(textDirection:TextDirection.rtl,child:ListView(padding:const EdgeInsets.all(16),shrinkWrap:true,children:items));
  }
}
