import 'package:flutter/material.dart';
import 'package:didnex_ads/didnex_ads.dart';

// Match your approved media package/bundle identifier. No app backend or JWT.
void main() => runApp(DidnexAds.direct(
  packageName: 'com.company.app',
  adOrigin: Uri.parse('https://didnex.com'),
  child: const MaterialApp(home: AdsPage()),
));
class AdsPage extends StatefulWidget {
  const AdsPage({super.key});
  @override State<AdsPage> createState() => _AdsPageState();
}
class _AdsPageState extends State<AdsPage> {
  String? _inlineUnit;
  bool _busy=false;
  String _message='یک فرمت انتخاب کنید';
  static const units=<String,String>{
    'banner':'UNT_BANNER','adaptive_banner':'UNT_ADAPTIVE_BANNER',
    'native':'UNT_NATIVE','native_video':'UNT_NATIVE_VIDEO','video':'UNT_VIDEO',
    'interstitial':'UNT_INTERSTITIAL','rewarded':'UNT_REWARDED',
    'rewarded_interstitial':'UNT_REWARDED_INTERSTITIAL','app_open':'UNT_APP_OPEN',
    'playable':'UNT_PLAYABLE','audio':'UNT_AUDIO','carousel':'UNT_CAROUSEL','poll':'UNT_POLL',
  };
  Future<void> _show(String format) async {
    if(_busy)return;final unit=units[format]!;setState(()=>_busy=true);
    try {
      if(format.startsWith('rewarded')) {
        final receipt=await DidnexAds.showRewarded(context,unitId:unit);
        if(mounted)setState(()=>_message=receipt==null?'جایزه‌ای ثبت نشد':'جایزه در کیف نصب دیدنکس ثبت شد');
      } else if(['interstitial','app_open','playable'].contains(format)) {
        final shown=await DidnexAds.showInterstitial(context,unitId:unit);
        if(mounted)setState(()=>_message=shown?'نمایش پایان یافت':'فعلاً تبلیغی موجود نیست');
      } else {setState(()=>_inlineUnit=unit);}
    } catch(_) {if(mounted)setState(()=>_message='تبلیغ در دسترس نیست؛ اپ ادامه دارد');}
    finally {if(mounted)setState(()=>_busy=false);}
  }
  @override Widget build(BuildContext context)=>Directionality(textDirection:TextDirection.rtl,child:Scaffold(
    appBar:AppBar(title:const Text('اتصال دیدنکس')),
    body:ListView(padding:const EdgeInsets.all(16),children:[
      Text(_message),
      Wrap(spacing:8,children:units.keys.map((f)=>OutlinedButton(onPressed:_busy?null:()=>_show(f),child:Text(f))).toList()),
      if(_inlineUnit!=null)DidnexAdSlot(key:ValueKey(_inlineUnit),unitId:_inlineUnit!,
        noFillBuilder:(_,__)=>const SizedBox.shrink(),
        errorBuilder:(_,__)=>const SizedBox.shrink()),
    ]),
  ));
}
