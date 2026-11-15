# اتصال Flutter — نسخه ۱

## مسیر کوتاه

۱. رسانه و جایگاه را در پنل بسازید و تأیید کنید. ۲. همین SDK را نصب کنید. ۳. شناسه UNT_ نمونه را با جایگاه همان فرمت جایگزین کنید.

اپ شما به سرور، دامنه اختصاصی، JWT یا کلید API نیاز ندارد. نشانی HTTPS مثال، سرور خود دیدنکس است. پس از تغییر دامنه پلتفرم، نشانی جدید را در همان یک تنظیم جایگزین کنید. شناسه بسته واقعی اپ باید با رسانه تأییدشده برابر باشد.

## نصب و پیش‌نیاز

ZIP را باز و پوشه didnex_ads را در packages قرار دهید. وابستگی path زیر را در pubspec.yaml اپ اضافه و flutter pub get را اجرا کنید. example/lib/quick_start.dart یک اپ کامل است؛ برای اجرا آن را در lib/main.dart اپ میزبان قرار دهید.

Flutter ≥3.27، Dart ≥3.6، Android minSdk 24، Java 17 و iOS 15. برای AGP 9 با Kotlin داخلی فعال، Flutter ≥3.47. AGP و Kotlin را میزبان تعیین می‌کند؛ SDK کلاس‌پث Gradle دیگری دانلود نمی‌کند.

```
dependencies:
  didnex_ads:
    path: packages/didnex_ads

# flutter pub get
# flutter analyze
# flutter test
```

## Manifest و تنظیمات سیستم‌عامل

فایل `sdk/flutter/didnex_ads/example/AndroidManifest.xml` کنار مثال است. قطعه‌ها را با تنظیمات موجود ادغام کنید. مجوز اینترنت در Android باید در manifest اصلی نسخه Release هم باشد. تبلیغ پایه به مجوز مکان، شناسه تبلیغاتی، دسترسی حافظه یا اعلان نیاز ندارد.

```
<!-- Merge into android/app/src/main/AndroidManifest.xml (not debug only). -->
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
 <uses-permission android:name="android.permission.INTERNET" />
 <uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />
 <application />
</manifest>

```

برای Flutter/Unity در iOS، حداقل iOS 15 و PrivacyInfo.xcprivacy بسته را رعایت کنید. ATS را برای نشانی HTTPS باز نکنید. پوش پس‌زمینه تنها پس از رضایت و تنظیم سرویس سیستم‌عامل فعال می‌شود؛ Inbox به Firebase یا مجوز اعلان نیاز ندارد.

## فونت، ظاهر و کنترل سروری

ظاهر کارت در هر دو روش مستقیم و پراکسی از پاسخ همان تبلیغ خوانده می‌شود. مدیر در تنظیمات ← ظاهر تبلیغ و SDK، رنگ، زمینه، فونت، گردی کارت، جای نشان و پخش خودکار ویدیوی معمولی را تعیین می‌کند. ابتدا یک‌بار SDK و اپ را به‌روزرسانی کنید؛ سپس تغییرات پشتیبانی‌شده در درخواست بعدی تبلیغ اعمال می‌شوند. فونت Noto Sans Arabic فارسی و لوگو از سرور خود دیدنکس کش می‌شوند؛ خطای این دارایی‌های اختیاری باعث noFill یا خطای تبلیغ نمی‌شود. Unity برای UGUI یک فونت کوچک فارسی همراه و شکل‌دهی حروف در مرز نمایش دارد. سرور کد اجرایی جدید به اپ نمی‌فرستد.

فونت حدود ۲۴۵ کیبی‌بایت است و پس از کش برای هر تبلیغ دوباره دریافت نمی‌شود؛ پاک‌شدن کش می‌تواند دریافت دوباره را لازم کند. پخش، لمس و تشخیص دیدپذیری روی دستگاه باقی می‌مانند. توقف دستی، پس‌زمینه و پایان ویدیو رعایت می‌شوند. نشان شبکه و دکمه‌های صدا، توقف و بستن، کلیک تبلیغ‌دهنده ثبت نمی‌کنند. بدنه و دکمه مقصد امضاشده مشترک دارند. لمس بازی تعاملی به خود بازی می‌رسد. در وب مبدأ دیدنکس را در `font-src` سیاست CSP مجاز کنید.

## همه فرمت‌ها

فرمت در پنل و روی جایگاه تعیین می‌شود؛ نوع متد را مطابق جدول انتخاب کنید. `playable` از مسیر تمام‌صفحه و `audio` از مسیر درون صفحه استفاده می‌کند. ویدیوی معمولی فقط هنگام فعال‌بودن اپ و حداقل ۵۰٪ دیده‌شدن، خودکار و بی‌صداست؛ صوت و جایزه نیازمند انتخاب کاربرند. محدودیت مرورگر ممکن است پخش دستی را لازم کند.

| فرمت | شناسه قراردادی | روش نمایش |
|---|---|---|
| بنر | `banner` | درون صفحه |
| بنر تطبیقی | `adaptive_banner` | درون صفحه |
| همسان | `native` | درون صفحه |
| ویدیوی همسان | `native_video` | درون صفحه |
| ویدیوی درون محتوا | `video` | درون صفحه |
| بینابینی | `interstitial` | تمام‌صفحه |
| ویدیوی جایزه‌دار | `rewarded` | جایزه‌دار |
| بینابینی جایزه‌دار | `rewarded_interstitial` | جایزه‌دار |
| آغاز اپ | `app_open` | تمام‌صفحه |
| بازی تعاملی | `playable` | تمام‌صفحه |
| صوتی | `audio` | درون صفحه |
| کاروسلی | `carousel` | درون صفحه |
| نظرسنجی | `poll` | درون صفحه |

### بنر

```
import 'package:flutter/material.dart';
import 'package:didnex_ads/didnex_ads.dart';

// Match your approved media package/bundle identifier. No app backend or JWT.
const diagnosticToken='';
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
  static const units=<String,String>{'banner':'UNT_BANNER'};
  Future<void> _show(String format) async {
    if(_busy)return;final unit=units[format]!;setState(()=>_busy=true);
    try {
      if(format.startsWith('rewarded')) {
        final receipt=await DidnexAds.showRewarded(context,unitId:unit,diagnosticToken:diagnosticToken.isEmpty?null:diagnosticToken);
        if(mounted)setState(()=>_message=receipt==null?'جایزه‌ای ثبت نشد':'جایزه در کیف نصب دیدنکس ثبت شد');
      } else if(['interstitial','app_open','playable'].contains(format)) {
        final shown=await DidnexAds.showInterstitial(context,unitId:unit,diagnosticToken:diagnosticToken.isEmpty?null:diagnosticToken);
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
      if(_inlineUnit!=null)DidnexAdSlot(key:ValueKey(_inlineUnit),unitId:_inlineUnit!,diagnosticToken:diagnosticToken.isEmpty?null:diagnosticToken,
        noFillBuilder:(_,__)=>const SizedBox.shrink(),
        errorBuilder:(_,__)=>const SizedBox.shrink()),
    ]),
  ));
}

```

### بنر تطبیقی

```
import 'package:flutter/material.dart';
import 'package:didnex_ads/didnex_ads.dart';

// Match your approved media package/bundle identifier. No app backend or JWT.
const diagnosticToken='';
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
  static const units=<String,String>{'adaptive_banner':'UNT_ADAPTIVE_BANNER'};
  Future<void> _show(String format) async {
    if(_busy)return;final unit=units[format]!;setState(()=>_busy=true);
    try {
      if(format.startsWith('rewarded')) {
        final receipt=await DidnexAds.showRewarded(context,unitId:unit,diagnosticToken:diagnosticToken.isEmpty?null:diagnosticToken);
        if(mounted)setState(()=>_message=receipt==null?'جایزه‌ای ثبت نشد':'جایزه در کیف نصب دیدنکس ثبت شد');
      } else if(['interstitial','app_open','playable'].contains(format)) {
        final shown=await DidnexAds.showInterstitial(context,unitId:unit,diagnosticToken:diagnosticToken.isEmpty?null:diagnosticToken);
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
      if(_inlineUnit!=null)DidnexAdSlot(key:ValueKey(_inlineUnit),unitId:_inlineUnit!,diagnosticToken:diagnosticToken.isEmpty?null:diagnosticToken,
        noFillBuilder:(_,__)=>const SizedBox.shrink(),
        errorBuilder:(_,__)=>const SizedBox.shrink()),
    ]),
  ));
}

```

### همسان

```
import 'package:flutter/material.dart';
import 'package:didnex_ads/didnex_ads.dart';

// Match your approved media package/bundle identifier. No app backend or JWT.
const diagnosticToken='';
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
  static const units=<String,String>{'native':'UNT_NATIVE'};
  Future<void> _show(String format) async {
    if(_busy)return;final unit=units[format]!;setState(()=>_busy=true);
    try {
      if(format.startsWith('rewarded')) {
        final receipt=await DidnexAds.showRewarded(context,unitId:unit,diagnosticToken:diagnosticToken.isEmpty?null:diagnosticToken);
        if(mounted)setState(()=>_message=receipt==null?'جایزه‌ای ثبت نشد':'جایزه در کیف نصب دیدنکس ثبت شد');
      } else if(['interstitial','app_open','playable'].contains(format)) {
        final shown=await DidnexAds.showInterstitial(context,unitId:unit,diagnosticToken:diagnosticToken.isEmpty?null:diagnosticToken);
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
      if(_inlineUnit!=null)DidnexAdSlot(key:ValueKey(_inlineUnit),unitId:_inlineUnit!,diagnosticToken:diagnosticToken.isEmpty?null:diagnosticToken,
        noFillBuilder:(_,__)=>const SizedBox.shrink(),
        errorBuilder:(_,__)=>const SizedBox.shrink()),
    ]),
  ));
}

```

### ویدیوی همسان

```
import 'package:flutter/material.dart';
import 'package:didnex_ads/didnex_ads.dart';

// Match your approved media package/bundle identifier. No app backend or JWT.
const diagnosticToken='';
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
  static const units=<String,String>{'native_video':'UNT_NATIVE_VIDEO'};
  Future<void> _show(String format) async {
    if(_busy)return;final unit=units[format]!;setState(()=>_busy=true);
    try {
      if(format.startsWith('rewarded')) {
        final receipt=await DidnexAds.showRewarded(context,unitId:unit,diagnosticToken:diagnosticToken.isEmpty?null:diagnosticToken);
        if(mounted)setState(()=>_message=receipt==null?'جایزه‌ای ثبت نشد':'جایزه در کیف نصب دیدنکس ثبت شد');
      } else if(['interstitial','app_open','playable'].contains(format)) {
        final shown=await DidnexAds.showInterstitial(context,unitId:unit,diagnosticToken:diagnosticToken.isEmpty?null:diagnosticToken);
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
      if(_inlineUnit!=null)DidnexAdSlot(key:ValueKey(_inlineUnit),unitId:_inlineUnit!,diagnosticToken:diagnosticToken.isEmpty?null:diagnosticToken,
        noFillBuilder:(_,__)=>const SizedBox.shrink(),
        errorBuilder:(_,__)=>const SizedBox.shrink()),
    ]),
  ));
}

```

### ویدیوی درون محتوا

```
import 'package:flutter/material.dart';
import 'package:didnex_ads/didnex_ads.dart';

// Match your approved media package/bundle identifier. No app backend or JWT.
const diagnosticToken='';
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
  static const units=<String,String>{'video':'UNT_VIDEO'};
  Future<void> _show(String format) async {
    if(_busy)return;final unit=units[format]!;setState(()=>_busy=true);
    try {
      if(format.startsWith('rewarded')) {
        final receipt=await DidnexAds.showRewarded(context,unitId:unit,diagnosticToken:diagnosticToken.isEmpty?null:diagnosticToken);
        if(mounted)setState(()=>_message=receipt==null?'جایزه‌ای ثبت نشد':'جایزه در کیف نصب دیدنکس ثبت شد');
      } else if(['interstitial','app_open','playable'].contains(format)) {
        final shown=await DidnexAds.showInterstitial(context,unitId:unit,diagnosticToken:diagnosticToken.isEmpty?null:diagnosticToken);
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
      if(_inlineUnit!=null)DidnexAdSlot(key:ValueKey(_inlineUnit),unitId:_inlineUnit!,diagnosticToken:diagnosticToken.isEmpty?null:diagnosticToken,
        noFillBuilder:(_,__)=>const SizedBox.shrink(),
        errorBuilder:(_,__)=>const SizedBox.shrink()),
    ]),
  ));
}

```

### بینابینی

```
import 'package:flutter/material.dart';
import 'package:didnex_ads/didnex_ads.dart';

// Match your approved media package/bundle identifier. No app backend or JWT.
const diagnosticToken='';
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
  static const units=<String,String>{'interstitial':'UNT_INTERSTITIAL'};
  Future<void> _show(String format) async {
    if(_busy)return;final unit=units[format]!;setState(()=>_busy=true);
    try {
      if(format.startsWith('rewarded')) {
        final receipt=await DidnexAds.showRewarded(context,unitId:unit,diagnosticToken:diagnosticToken.isEmpty?null:diagnosticToken);
        if(mounted)setState(()=>_message=receipt==null?'جایزه‌ای ثبت نشد':'جایزه در کیف نصب دیدنکس ثبت شد');
      } else if(['interstitial','app_open','playable'].contains(format)) {
        final shown=await DidnexAds.showInterstitial(context,unitId:unit,diagnosticToken:diagnosticToken.isEmpty?null:diagnosticToken);
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
      if(_inlineUnit!=null)DidnexAdSlot(key:ValueKey(_inlineUnit),unitId:_inlineUnit!,diagnosticToken:diagnosticToken.isEmpty?null:diagnosticToken,
        noFillBuilder:(_,__)=>const SizedBox.shrink(),
        errorBuilder:(_,__)=>const SizedBox.shrink()),
    ]),
  ));
}

```

### ویدیوی جایزه‌دار

```
import 'package:flutter/material.dart';
import 'package:didnex_ads/didnex_ads.dart';

// Match your approved media package/bundle identifier. No app backend or JWT.
const diagnosticToken='';
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
  static const units=<String,String>{'rewarded':'UNT_REWARDED'};
  Future<void> _show(String format) async {
    if(_busy)return;final unit=units[format]!;setState(()=>_busy=true);
    try {
      if(format.startsWith('rewarded')) {
        final receipt=await DidnexAds.showRewarded(context,unitId:unit,diagnosticToken:diagnosticToken.isEmpty?null:diagnosticToken);
        if(mounted)setState(()=>_message=receipt==null?'جایزه‌ای ثبت نشد':'جایزه در کیف نصب دیدنکس ثبت شد');
      } else if(['interstitial','app_open','playable'].contains(format)) {
        final shown=await DidnexAds.showInterstitial(context,unitId:unit,diagnosticToken:diagnosticToken.isEmpty?null:diagnosticToken);
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
      if(_inlineUnit!=null)DidnexAdSlot(key:ValueKey(_inlineUnit),unitId:_inlineUnit!,diagnosticToken:diagnosticToken.isEmpty?null:diagnosticToken,
        noFillBuilder:(_,__)=>const SizedBox.shrink(),
        errorBuilder:(_,__)=>const SizedBox.shrink()),
    ]),
  ));
}

```

### بینابینی جایزه‌دار

```
import 'package:flutter/material.dart';
import 'package:didnex_ads/didnex_ads.dart';

// Match your approved media package/bundle identifier. No app backend or JWT.
const diagnosticToken='';
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
  static const units=<String,String>{'rewarded_interstitial':'UNT_REWARDED_INTERSTITIAL'};
  Future<void> _show(String format) async {
    if(_busy)return;final unit=units[format]!;setState(()=>_busy=true);
    try {
      if(format.startsWith('rewarded')) {
        final receipt=await DidnexAds.showRewarded(context,unitId:unit,diagnosticToken:diagnosticToken.isEmpty?null:diagnosticToken);
        if(mounted)setState(()=>_message=receipt==null?'جایزه‌ای ثبت نشد':'جایزه در کیف نصب دیدنکس ثبت شد');
      } else if(['interstitial','app_open','playable'].contains(format)) {
        final shown=await DidnexAds.showInterstitial(context,unitId:unit,diagnosticToken:diagnosticToken.isEmpty?null:diagnosticToken);
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
      if(_inlineUnit!=null)DidnexAdSlot(key:ValueKey(_inlineUnit),unitId:_inlineUnit!,diagnosticToken:diagnosticToken.isEmpty?null:diagnosticToken,
        noFillBuilder:(_,__)=>const SizedBox.shrink(),
        errorBuilder:(_,__)=>const SizedBox.shrink()),
    ]),
  ));
}

```

### آغاز اپ

```
import 'package:flutter/material.dart';
import 'package:didnex_ads/didnex_ads.dart';

// Match your approved media package/bundle identifier. No app backend or JWT.
const diagnosticToken='';
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
  static const units=<String,String>{'app_open':'UNT_APP_OPEN'};
  Future<void> _show(String format) async {
    if(_busy)return;final unit=units[format]!;setState(()=>_busy=true);
    try {
      if(format.startsWith('rewarded')) {
        final receipt=await DidnexAds.showRewarded(context,unitId:unit,diagnosticToken:diagnosticToken.isEmpty?null:diagnosticToken);
        if(mounted)setState(()=>_message=receipt==null?'جایزه‌ای ثبت نشد':'جایزه در کیف نصب دیدنکس ثبت شد');
      } else if(['interstitial','app_open','playable'].contains(format)) {
        final shown=await DidnexAds.showInterstitial(context,unitId:unit,diagnosticToken:diagnosticToken.isEmpty?null:diagnosticToken);
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
      if(_inlineUnit!=null)DidnexAdSlot(key:ValueKey(_inlineUnit),unitId:_inlineUnit!,diagnosticToken:diagnosticToken.isEmpty?null:diagnosticToken,
        noFillBuilder:(_,__)=>const SizedBox.shrink(),
        errorBuilder:(_,__)=>const SizedBox.shrink()),
    ]),
  ));
}

```

### بازی تعاملی

```
import 'package:flutter/material.dart';
import 'package:didnex_ads/didnex_ads.dart';

// Match your approved media package/bundle identifier. No app backend or JWT.
const diagnosticToken='';
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
  static const units=<String,String>{'playable':'UNT_PLAYABLE'};
  Future<void> _show(String format) async {
    if(_busy)return;final unit=units[format]!;setState(()=>_busy=true);
    try {
      if(format.startsWith('rewarded')) {
        final receipt=await DidnexAds.showRewarded(context,unitId:unit,diagnosticToken:diagnosticToken.isEmpty?null:diagnosticToken);
        if(mounted)setState(()=>_message=receipt==null?'جایزه‌ای ثبت نشد':'جایزه در کیف نصب دیدنکس ثبت شد');
      } else if(['interstitial','app_open','playable'].contains(format)) {
        final shown=await DidnexAds.showInterstitial(context,unitId:unit,diagnosticToken:diagnosticToken.isEmpty?null:diagnosticToken);
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
      if(_inlineUnit!=null)DidnexAdSlot(key:ValueKey(_inlineUnit),unitId:_inlineUnit!,diagnosticToken:diagnosticToken.isEmpty?null:diagnosticToken,
        noFillBuilder:(_,__)=>const SizedBox.shrink(),
        errorBuilder:(_,__)=>const SizedBox.shrink()),
    ]),
  ));
}

```

### صوتی

```
import 'package:flutter/material.dart';
import 'package:didnex_ads/didnex_ads.dart';

// Match your approved media package/bundle identifier. No app backend or JWT.
const diagnosticToken='';
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
  static const units=<String,String>{'audio':'UNT_AUDIO'};
  Future<void> _show(String format) async {
    if(_busy)return;final unit=units[format]!;setState(()=>_busy=true);
    try {
      if(format.startsWith('rewarded')) {
        final receipt=await DidnexAds.showRewarded(context,unitId:unit,diagnosticToken:diagnosticToken.isEmpty?null:diagnosticToken);
        if(mounted)setState(()=>_message=receipt==null?'جایزه‌ای ثبت نشد':'جایزه در کیف نصب دیدنکس ثبت شد');
      } else if(['interstitial','app_open','playable'].contains(format)) {
        final shown=await DidnexAds.showInterstitial(context,unitId:unit,diagnosticToken:diagnosticToken.isEmpty?null:diagnosticToken);
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
      if(_inlineUnit!=null)DidnexAdSlot(key:ValueKey(_inlineUnit),unitId:_inlineUnit!,diagnosticToken:diagnosticToken.isEmpty?null:diagnosticToken,
        noFillBuilder:(_,__)=>const SizedBox.shrink(),
        errorBuilder:(_,__)=>const SizedBox.shrink()),
    ]),
  ));
}

```

### کاروسلی

```
import 'package:flutter/material.dart';
import 'package:didnex_ads/didnex_ads.dart';

// Match your approved media package/bundle identifier. No app backend or JWT.
const diagnosticToken='';
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
  static const units=<String,String>{'carousel':'UNT_CAROUSEL'};
  Future<void> _show(String format) async {
    if(_busy)return;final unit=units[format]!;setState(()=>_busy=true);
    try {
      if(format.startsWith('rewarded')) {
        final receipt=await DidnexAds.showRewarded(context,unitId:unit,diagnosticToken:diagnosticToken.isEmpty?null:diagnosticToken);
        if(mounted)setState(()=>_message=receipt==null?'جایزه‌ای ثبت نشد':'جایزه در کیف نصب دیدنکس ثبت شد');
      } else if(['interstitial','app_open','playable'].contains(format)) {
        final shown=await DidnexAds.showInterstitial(context,unitId:unit,diagnosticToken:diagnosticToken.isEmpty?null:diagnosticToken);
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
      if(_inlineUnit!=null)DidnexAdSlot(key:ValueKey(_inlineUnit),unitId:_inlineUnit!,diagnosticToken:diagnosticToken.isEmpty?null:diagnosticToken,
        noFillBuilder:(_,__)=>const SizedBox.shrink(),
        errorBuilder:(_,__)=>const SizedBox.shrink()),
    ]),
  ));
}

```

### نظرسنجی

```
import 'package:flutter/material.dart';
import 'package:didnex_ads/didnex_ads.dart';

// Match your approved media package/bundle identifier. No app backend or JWT.
const diagnosticToken='';
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
  static const units=<String,String>{'poll':'UNT_POLL'};
  Future<void> _show(String format) async {
    if(_busy)return;final unit=units[format]!;setState(()=>_busy=true);
    try {
      if(format.startsWith('rewarded')) {
        final receipt=await DidnexAds.showRewarded(context,unitId:unit,diagnosticToken:diagnosticToken.isEmpty?null:diagnosticToken);
        if(mounted)setState(()=>_message=receipt==null?'جایزه‌ای ثبت نشد':'جایزه در کیف نصب دیدنکس ثبت شد');
      } else if(['interstitial','app_open','playable'].contains(format)) {
        final shown=await DidnexAds.showInterstitial(context,unitId:unit,diagnosticToken:diagnosticToken.isEmpty?null:diagnosticToken);
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
      if(_inlineUnit!=null)DidnexAdSlot(key:ValueKey(_inlineUnit),unitId:_inlineUnit!,diagnosticToken:diagnosticToken.isEmpty?null:diagnosticToken,
        noFillBuilder:(_,__)=>const SizedBox.shrink(),
        errorBuilder:(_,__)=>const SizedBox.shrink()),
    ]),
  ));
}

```

### سرور اختیاری · بنر

برای این روش، پراکسی خودتان و callback نشست فعلی اپ را تکمیل کنید؛ تابع خالی نمونه اتصال واقعی ایجاد نمی‌کند.

```
import 'package:flutter/material.dart';
import 'package:didnex_ads/didnex_ads.dart';

// Match your approved media package/bundle identifier. No app backend or JWT.
const diagnosticToken='';
// Replace this function with the current authenticated session from YOUR app.
Future<String> appSessionToken() async => '';
void main() => runApp(DidnexAds(
  proxyUrl: Uri.parse('https://YOUR-BACKEND.example/ads'),
  sessionToken: appSessionToken,
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
  static const units=<String,String>{'banner':'UNT_BANNER'};
  Future<void> _show(String format) async {
    if(_busy)return;final unit=units[format]!;setState(()=>_busy=true);
    try {
      if(format.startsWith('rewarded')) {
        final receipt=await DidnexAds.showRewarded(context,unitId:unit,diagnosticToken:diagnosticToken.isEmpty?null:diagnosticToken);
        if(mounted)setState(()=>_message=receipt==null?'جایزه‌ای ثبت نشد':'جایزه در کیف نصب دیدنکس ثبت شد');
      } else if(['interstitial','app_open','playable'].contains(format)) {
        final shown=await DidnexAds.showInterstitial(context,unitId:unit,diagnosticToken:diagnosticToken.isEmpty?null:diagnosticToken);
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
      if(_inlineUnit!=null)DidnexAdSlot(key:ValueKey(_inlineUnit),unitId:_inlineUnit!,diagnosticToken:diagnosticToken.isEmpty?null:diagnosticToken,
        noFillBuilder:(_,__)=>const SizedBox.shrink(),
        errorBuilder:(_,__)=>const SizedBox.shrink()),
    ]),
  ));
}

```

### سرور اختیاری · بنر تطبیقی

برای این روش، پراکسی خودتان و callback نشست فعلی اپ را تکمیل کنید؛ تابع خالی نمونه اتصال واقعی ایجاد نمی‌کند.

```
import 'package:flutter/material.dart';
import 'package:didnex_ads/didnex_ads.dart';

// Match your approved media package/bundle identifier. No app backend or JWT.
const diagnosticToken='';
// Replace this function with the current authenticated session from YOUR app.
Future<String> appSessionToken() async => '';
void main() => runApp(DidnexAds(
  proxyUrl: Uri.parse('https://YOUR-BACKEND.example/ads'),
  sessionToken: appSessionToken,
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
  static const units=<String,String>{'adaptive_banner':'UNT_ADAPTIVE_BANNER'};
  Future<void> _show(String format) async {
    if(_busy)return;final unit=units[format]!;setState(()=>_busy=true);
    try {
      if(format.startsWith('rewarded')) {
        final receipt=await DidnexAds.showRewarded(context,unitId:unit,diagnosticToken:diagnosticToken.isEmpty?null:diagnosticToken);
        if(mounted)setState(()=>_message=receipt==null?'جایزه‌ای ثبت نشد':'جایزه در کیف نصب دیدنکس ثبت شد');
      } else if(['interstitial','app_open','playable'].contains(format)) {
        final shown=await DidnexAds.showInterstitial(context,unitId:unit,diagnosticToken:diagnosticToken.isEmpty?null:diagnosticToken);
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
      if(_inlineUnit!=null)DidnexAdSlot(key:ValueKey(_inlineUnit),unitId:_inlineUnit!,diagnosticToken:diagnosticToken.isEmpty?null:diagnosticToken,
        noFillBuilder:(_,__)=>const SizedBox.shrink(),
        errorBuilder:(_,__)=>const SizedBox.shrink()),
    ]),
  ));
}

```

### سرور اختیاری · همسان

برای این روش، پراکسی خودتان و callback نشست فعلی اپ را تکمیل کنید؛ تابع خالی نمونه اتصال واقعی ایجاد نمی‌کند.

```
import 'package:flutter/material.dart';
import 'package:didnex_ads/didnex_ads.dart';

// Match your approved media package/bundle identifier. No app backend or JWT.
const diagnosticToken='';
// Replace this function with the current authenticated session from YOUR app.
Future<String> appSessionToken() async => '';
void main() => runApp(DidnexAds(
  proxyUrl: Uri.parse('https://YOUR-BACKEND.example/ads'),
  sessionToken: appSessionToken,
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
  static const units=<String,String>{'native':'UNT_NATIVE'};
  Future<void> _show(String format) async {
    if(_busy)return;final unit=units[format]!;setState(()=>_busy=true);
    try {
      if(format.startsWith('rewarded')) {
        final receipt=await DidnexAds.showRewarded(context,unitId:unit,diagnosticToken:diagnosticToken.isEmpty?null:diagnosticToken);
        if(mounted)setState(()=>_message=receipt==null?'جایزه‌ای ثبت نشد':'جایزه در کیف نصب دیدنکس ثبت شد');
      } else if(['interstitial','app_open','playable'].contains(format)) {
        final shown=await DidnexAds.showInterstitial(context,unitId:unit,diagnosticToken:diagnosticToken.isEmpty?null:diagnosticToken);
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
      if(_inlineUnit!=null)DidnexAdSlot(key:ValueKey(_inlineUnit),unitId:_inlineUnit!,diagnosticToken:diagnosticToken.isEmpty?null:diagnosticToken,
        noFillBuilder:(_,__)=>const SizedBox.shrink(),
        errorBuilder:(_,__)=>const SizedBox.shrink()),
    ]),
  ));
}

```

### سرور اختیاری · ویدیوی همسان

برای این روش، پراکسی خودتان و callback نشست فعلی اپ را تکمیل کنید؛ تابع خالی نمونه اتصال واقعی ایجاد نمی‌کند.

```
import 'package:flutter/material.dart';
import 'package:didnex_ads/didnex_ads.dart';

// Match your approved media package/bundle identifier. No app backend or JWT.
const diagnosticToken='';
// Replace this function with the current authenticated session from YOUR app.
Future<String> appSessionToken() async => '';
void main() => runApp(DidnexAds(
  proxyUrl: Uri.parse('https://YOUR-BACKEND.example/ads'),
  sessionToken: appSessionToken,
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
  static const units=<String,String>{'native_video':'UNT_NATIVE_VIDEO'};
  Future<void> _show(String format) async {
    if(_busy)return;final unit=units[format]!;setState(()=>_busy=true);
    try {
      if(format.startsWith('rewarded')) {
        final receipt=await DidnexAds.showRewarded(context,unitId:unit,diagnosticToken:diagnosticToken.isEmpty?null:diagnosticToken);
        if(mounted)setState(()=>_message=receipt==null?'جایزه‌ای ثبت نشد':'جایزه در کیف نصب دیدنکس ثبت شد');
      } else if(['interstitial','app_open','playable'].contains(format)) {
        final shown=await DidnexAds.showInterstitial(context,unitId:unit,diagnosticToken:diagnosticToken.isEmpty?null:diagnosticToken);
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
      if(_inlineUnit!=null)DidnexAdSlot(key:ValueKey(_inlineUnit),unitId:_inlineUnit!,diagnosticToken:diagnosticToken.isEmpty?null:diagnosticToken,
        noFillBuilder:(_,__)=>const SizedBox.shrink(),
        errorBuilder:(_,__)=>const SizedBox.shrink()),
    ]),
  ));
}

```

### سرور اختیاری · ویدیوی درون محتوا

برای این روش، پراکسی خودتان و callback نشست فعلی اپ را تکمیل کنید؛ تابع خالی نمونه اتصال واقعی ایجاد نمی‌کند.

```
import 'package:flutter/material.dart';
import 'package:didnex_ads/didnex_ads.dart';

// Match your approved media package/bundle identifier. No app backend or JWT.
const diagnosticToken='';
// Replace this function with the current authenticated session from YOUR app.
Future<String> appSessionToken() async => '';
void main() => runApp(DidnexAds(
  proxyUrl: Uri.parse('https://YOUR-BACKEND.example/ads'),
  sessionToken: appSessionToken,
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
  static const units=<String,String>{'video':'UNT_VIDEO'};
  Future<void> _show(String format) async {
    if(_busy)return;final unit=units[format]!;setState(()=>_busy=true);
    try {
      if(format.startsWith('rewarded')) {
        final receipt=await DidnexAds.showRewarded(context,unitId:unit,diagnosticToken:diagnosticToken.isEmpty?null:diagnosticToken);
        if(mounted)setState(()=>_message=receipt==null?'جایزه‌ای ثبت نشد':'جایزه در کیف نصب دیدنکس ثبت شد');
      } else if(['interstitial','app_open','playable'].contains(format)) {
        final shown=await DidnexAds.showInterstitial(context,unitId:unit,diagnosticToken:diagnosticToken.isEmpty?null:diagnosticToken);
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
      if(_inlineUnit!=null)DidnexAdSlot(key:ValueKey(_inlineUnit),unitId:_inlineUnit!,diagnosticToken:diagnosticToken.isEmpty?null:diagnosticToken,
        noFillBuilder:(_,__)=>const SizedBox.shrink(),
        errorBuilder:(_,__)=>const SizedBox.shrink()),
    ]),
  ));
}

```

### سرور اختیاری · بینابینی

برای این روش، پراکسی خودتان و callback نشست فعلی اپ را تکمیل کنید؛ تابع خالی نمونه اتصال واقعی ایجاد نمی‌کند.

```
import 'package:flutter/material.dart';
import 'package:didnex_ads/didnex_ads.dart';

// Match your approved media package/bundle identifier. No app backend or JWT.
const diagnosticToken='';
// Replace this function with the current authenticated session from YOUR app.
Future<String> appSessionToken() async => '';
void main() => runApp(DidnexAds(
  proxyUrl: Uri.parse('https://YOUR-BACKEND.example/ads'),
  sessionToken: appSessionToken,
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
  static const units=<String,String>{'interstitial':'UNT_INTERSTITIAL'};
  Future<void> _show(String format) async {
    if(_busy)return;final unit=units[format]!;setState(()=>_busy=true);
    try {
      if(format.startsWith('rewarded')) {
        final receipt=await DidnexAds.showRewarded(context,unitId:unit,diagnosticToken:diagnosticToken.isEmpty?null:diagnosticToken);
        if(mounted)setState(()=>_message=receipt==null?'جایزه‌ای ثبت نشد':'جایزه در کیف نصب دیدنکس ثبت شد');
      } else if(['interstitial','app_open','playable'].contains(format)) {
        final shown=await DidnexAds.showInterstitial(context,unitId:unit,diagnosticToken:diagnosticToken.isEmpty?null:diagnosticToken);
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
      if(_inlineUnit!=null)DidnexAdSlot(key:ValueKey(_inlineUnit),unitId:_inlineUnit!,diagnosticToken:diagnosticToken.isEmpty?null:diagnosticToken,
        noFillBuilder:(_,__)=>const SizedBox.shrink(),
        errorBuilder:(_,__)=>const SizedBox.shrink()),
    ]),
  ));
}

```

### سرور اختیاری · ویدیوی جایزه‌دار

برای این روش، پراکسی خودتان و callback نشست فعلی اپ را تکمیل کنید؛ تابع خالی نمونه اتصال واقعی ایجاد نمی‌کند.

```
import 'package:flutter/material.dart';
import 'package:didnex_ads/didnex_ads.dart';

// Match your approved media package/bundle identifier. No app backend or JWT.
const diagnosticToken='';
// Replace this function with the current authenticated session from YOUR app.
Future<String> appSessionToken() async => '';
void main() => runApp(DidnexAds(
  proxyUrl: Uri.parse('https://YOUR-BACKEND.example/ads'),
  sessionToken: appSessionToken,
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
  static const units=<String,String>{'rewarded':'UNT_REWARDED'};
  Future<void> _show(String format) async {
    if(_busy)return;final unit=units[format]!;setState(()=>_busy=true);
    try {
      if(format.startsWith('rewarded')) {
        final receipt=await DidnexAds.showRewarded(context,unitId:unit,diagnosticToken:diagnosticToken.isEmpty?null:diagnosticToken);
        if(mounted)setState(()=>_message=receipt==null?'جایزه‌ای ثبت نشد':'جایزه در کیف نصب دیدنکس ثبت شد');
      } else if(['interstitial','app_open','playable'].contains(format)) {
        final shown=await DidnexAds.showInterstitial(context,unitId:unit,diagnosticToken:diagnosticToken.isEmpty?null:diagnosticToken);
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
      if(_inlineUnit!=null)DidnexAdSlot(key:ValueKey(_inlineUnit),unitId:_inlineUnit!,diagnosticToken:diagnosticToken.isEmpty?null:diagnosticToken,
        noFillBuilder:(_,__)=>const SizedBox.shrink(),
        errorBuilder:(_,__)=>const SizedBox.shrink()),
    ]),
  ));
}

```

### سرور اختیاری · بینابینی جایزه‌دار

برای این روش، پراکسی خودتان و callback نشست فعلی اپ را تکمیل کنید؛ تابع خالی نمونه اتصال واقعی ایجاد نمی‌کند.

```
import 'package:flutter/material.dart';
import 'package:didnex_ads/didnex_ads.dart';

// Match your approved media package/bundle identifier. No app backend or JWT.
const diagnosticToken='';
// Replace this function with the current authenticated session from YOUR app.
Future<String> appSessionToken() async => '';
void main() => runApp(DidnexAds(
  proxyUrl: Uri.parse('https://YOUR-BACKEND.example/ads'),
  sessionToken: appSessionToken,
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
  static const units=<String,String>{'rewarded_interstitial':'UNT_REWARDED_INTERSTITIAL'};
  Future<void> _show(String format) async {
    if(_busy)return;final unit=units[format]!;setState(()=>_busy=true);
    try {
      if(format.startsWith('rewarded')) {
        final receipt=await DidnexAds.showRewarded(context,unitId:unit,diagnosticToken:diagnosticToken.isEmpty?null:diagnosticToken);
        if(mounted)setState(()=>_message=receipt==null?'جایزه‌ای ثبت نشد':'جایزه در کیف نصب دیدنکس ثبت شد');
      } else if(['interstitial','app_open','playable'].contains(format)) {
        final shown=await DidnexAds.showInterstitial(context,unitId:unit,diagnosticToken:diagnosticToken.isEmpty?null:diagnosticToken);
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
      if(_inlineUnit!=null)DidnexAdSlot(key:ValueKey(_inlineUnit),unitId:_inlineUnit!,diagnosticToken:diagnosticToken.isEmpty?null:diagnosticToken,
        noFillBuilder:(_,__)=>const SizedBox.shrink(),
        errorBuilder:(_,__)=>const SizedBox.shrink()),
    ]),
  ));
}

```

### سرور اختیاری · آغاز اپ

برای این روش، پراکسی خودتان و callback نشست فعلی اپ را تکمیل کنید؛ تابع خالی نمونه اتصال واقعی ایجاد نمی‌کند.

```
import 'package:flutter/material.dart';
import 'package:didnex_ads/didnex_ads.dart';

// Match your approved media package/bundle identifier. No app backend or JWT.
const diagnosticToken='';
// Replace this function with the current authenticated session from YOUR app.
Future<String> appSessionToken() async => '';
void main() => runApp(DidnexAds(
  proxyUrl: Uri.parse('https://YOUR-BACKEND.example/ads'),
  sessionToken: appSessionToken,
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
  static const units=<String,String>{'app_open':'UNT_APP_OPEN'};
  Future<void> _show(String format) async {
    if(_busy)return;final unit=units[format]!;setState(()=>_busy=true);
    try {
      if(format.startsWith('rewarded')) {
        final receipt=await DidnexAds.showRewarded(context,unitId:unit,diagnosticToken:diagnosticToken.isEmpty?null:diagnosticToken);
        if(mounted)setState(()=>_message=receipt==null?'جایزه‌ای ثبت نشد':'جایزه در کیف نصب دیدنکس ثبت شد');
      } else if(['interstitial','app_open','playable'].contains(format)) {
        final shown=await DidnexAds.showInterstitial(context,unitId:unit,diagnosticToken:diagnosticToken.isEmpty?null:diagnosticToken);
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
      if(_inlineUnit!=null)DidnexAdSlot(key:ValueKey(_inlineUnit),unitId:_inlineUnit!,diagnosticToken:diagnosticToken.isEmpty?null:diagnosticToken,
        noFillBuilder:(_,__)=>const SizedBox.shrink(),
        errorBuilder:(_,__)=>const SizedBox.shrink()),
    ]),
  ));
}

```

### سرور اختیاری · بازی تعاملی

برای این روش، پراکسی خودتان و callback نشست فعلی اپ را تکمیل کنید؛ تابع خالی نمونه اتصال واقعی ایجاد نمی‌کند.

```
import 'package:flutter/material.dart';
import 'package:didnex_ads/didnex_ads.dart';

// Match your approved media package/bundle identifier. No app backend or JWT.
const diagnosticToken='';
// Replace this function with the current authenticated session from YOUR app.
Future<String> appSessionToken() async => '';
void main() => runApp(DidnexAds(
  proxyUrl: Uri.parse('https://YOUR-BACKEND.example/ads'),
  sessionToken: appSessionToken,
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
  static const units=<String,String>{'playable':'UNT_PLAYABLE'};
  Future<void> _show(String format) async {
    if(_busy)return;final unit=units[format]!;setState(()=>_busy=true);
    try {
      if(format.startsWith('rewarded')) {
        final receipt=await DidnexAds.showRewarded(context,unitId:unit,diagnosticToken:diagnosticToken.isEmpty?null:diagnosticToken);
        if(mounted)setState(()=>_message=receipt==null?'جایزه‌ای ثبت نشد':'جایزه در کیف نصب دیدنکس ثبت شد');
      } else if(['interstitial','app_open','playable'].contains(format)) {
        final shown=await DidnexAds.showInterstitial(context,unitId:unit,diagnosticToken:diagnosticToken.isEmpty?null:diagnosticToken);
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
      if(_inlineUnit!=null)DidnexAdSlot(key:ValueKey(_inlineUnit),unitId:_inlineUnit!,diagnosticToken:diagnosticToken.isEmpty?null:diagnosticToken,
        noFillBuilder:(_,__)=>const SizedBox.shrink(),
        errorBuilder:(_,__)=>const SizedBox.shrink()),
    ]),
  ));
}

```

### سرور اختیاری · صوتی

برای این روش، پراکسی خودتان و callback نشست فعلی اپ را تکمیل کنید؛ تابع خالی نمونه اتصال واقعی ایجاد نمی‌کند.

```
import 'package:flutter/material.dart';
import 'package:didnex_ads/didnex_ads.dart';

// Match your approved media package/bundle identifier. No app backend or JWT.
const diagnosticToken='';
// Replace this function with the current authenticated session from YOUR app.
Future<String> appSessionToken() async => '';
void main() => runApp(DidnexAds(
  proxyUrl: Uri.parse('https://YOUR-BACKEND.example/ads'),
  sessionToken: appSessionToken,
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
  static const units=<String,String>{'audio':'UNT_AUDIO'};
  Future<void> _show(String format) async {
    if(_busy)return;final unit=units[format]!;setState(()=>_busy=true);
    try {
      if(format.startsWith('rewarded')) {
        final receipt=await DidnexAds.showRewarded(context,unitId:unit,diagnosticToken:diagnosticToken.isEmpty?null:diagnosticToken);
        if(mounted)setState(()=>_message=receipt==null?'جایزه‌ای ثبت نشد':'جایزه در کیف نصب دیدنکس ثبت شد');
      } else if(['interstitial','app_open','playable'].contains(format)) {
        final shown=await DidnexAds.showInterstitial(context,unitId:unit,diagnosticToken:diagnosticToken.isEmpty?null:diagnosticToken);
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
      if(_inlineUnit!=null)DidnexAdSlot(key:ValueKey(_inlineUnit),unitId:_inlineUnit!,diagnosticToken:diagnosticToken.isEmpty?null:diagnosticToken,
        noFillBuilder:(_,__)=>const SizedBox.shrink(),
        errorBuilder:(_,__)=>const SizedBox.shrink()),
    ]),
  ));
}

```

### سرور اختیاری · کاروسلی

برای این روش، پراکسی خودتان و callback نشست فعلی اپ را تکمیل کنید؛ تابع خالی نمونه اتصال واقعی ایجاد نمی‌کند.

```
import 'package:flutter/material.dart';
import 'package:didnex_ads/didnex_ads.dart';

// Match your approved media package/bundle identifier. No app backend or JWT.
const diagnosticToken='';
// Replace this function with the current authenticated session from YOUR app.
Future<String> appSessionToken() async => '';
void main() => runApp(DidnexAds(
  proxyUrl: Uri.parse('https://YOUR-BACKEND.example/ads'),
  sessionToken: appSessionToken,
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
  static const units=<String,String>{'carousel':'UNT_CAROUSEL'};
  Future<void> _show(String format) async {
    if(_busy)return;final unit=units[format]!;setState(()=>_busy=true);
    try {
      if(format.startsWith('rewarded')) {
        final receipt=await DidnexAds.showRewarded(context,unitId:unit,diagnosticToken:diagnosticToken.isEmpty?null:diagnosticToken);
        if(mounted)setState(()=>_message=receipt==null?'جایزه‌ای ثبت نشد':'جایزه در کیف نصب دیدنکس ثبت شد');
      } else if(['interstitial','app_open','playable'].contains(format)) {
        final shown=await DidnexAds.showInterstitial(context,unitId:unit,diagnosticToken:diagnosticToken.isEmpty?null:diagnosticToken);
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
      if(_inlineUnit!=null)DidnexAdSlot(key:ValueKey(_inlineUnit),unitId:_inlineUnit!,diagnosticToken:diagnosticToken.isEmpty?null:diagnosticToken,
        noFillBuilder:(_,__)=>const SizedBox.shrink(),
        errorBuilder:(_,__)=>const SizedBox.shrink()),
    ]),
  ));
}

```

### سرور اختیاری · نظرسنجی

برای این روش، پراکسی خودتان و callback نشست فعلی اپ را تکمیل کنید؛ تابع خالی نمونه اتصال واقعی ایجاد نمی‌کند.

```
import 'package:flutter/material.dart';
import 'package:didnex_ads/didnex_ads.dart';

// Match your approved media package/bundle identifier. No app backend or JWT.
const diagnosticToken='';
// Replace this function with the current authenticated session from YOUR app.
Future<String> appSessionToken() async => '';
void main() => runApp(DidnexAds(
  proxyUrl: Uri.parse('https://YOUR-BACKEND.example/ads'),
  sessionToken: appSessionToken,
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
  static const units=<String,String>{'poll':'UNT_POLL'};
  Future<void> _show(String format) async {
    if(_busy)return;final unit=units[format]!;setState(()=>_busy=true);
    try {
      if(format.startsWith('rewarded')) {
        final receipt=await DidnexAds.showRewarded(context,unitId:unit,diagnosticToken:diagnosticToken.isEmpty?null:diagnosticToken);
        if(mounted)setState(()=>_message=receipt==null?'جایزه‌ای ثبت نشد':'جایزه در کیف نصب دیدنکس ثبت شد');
      } else if(['interstitial','app_open','playable'].contains(format)) {
        final shown=await DidnexAds.showInterstitial(context,unitId:unit,diagnosticToken:diagnosticToken.isEmpty?null:diagnosticToken);
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
      if(_inlineUnit!=null)DidnexAdSlot(key:ValueKey(_inlineUnit),unitId:_inlineUnit!,diagnosticToken:diagnosticToken.isEmpty?null:diagnosticToken,
        noFillBuilder:(_,__)=>const SizedBox.shrink(),
        errorBuilder:(_,__)=>const SizedBox.shrink()),
    ]),
  ));
}

```

## نمونه کامل قابل استفاده

فایل `sdk/flutter/didnex_ads/example/lib/quick_start.dart` در همین بسته قرار دارد. نام package/namespace مثال متعلق به اپ نمونه است؛ آن را با پروژه میزبان هماهنگ کنید. شناسه‌های UNT_ جایگزین‌اند و برای دریافت تبلیغ واقعی باید عوض شوند.

```
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

```

## اعتبارسنجی اختیاری اپ

برای Flutter فقط در صورت استفاده از Play Integrity، در android/gradle.properties مقدار `didnex.enablePlayIntegrity=true` و در client گزینه enableIntegrity را فعال کنید. اتصال پایه بدون این وابستگی کار می‌کند. برای Android بومی، DidnexIntegrity.kt و وابستگی Google Play را اضافه کنید؛ provider باید با سیاست پنل هماهنگ باشد. این قابلیت برای توزیع خارج Google Play الزام عمومی نیست.

## خطا، چرخه عمر و جایزه

نداشتن تبلیغ، قطع اینترنت یا خطای سرور باید فقط فضای تبلیغ را جمع کند؛ شروع اپ را به تبلیغ وابسته نکنید. بی‌وقفه retry نکنید؛ درخواست بعدی را به فرصت طبیعی بعدی اپ موکول کنید. برای تمام‌صفحه یک نمونه تازه، صفحه قابل نمایش و اقدام مناسب کاربر لازم است؛ از resume برای نمایش خودکار استفاده نکنید.

تست اتصال را با diagnosticToken از پنل انجام دهید. رسانهٔ تست متناسب با فرمت بارگذاری می‌شود؛ هزینه، درآمد یا جایزه ندارد. بارگذاری گزارش‌شده تأیید کامپایل یا پخش روی همهٔ دستگاه‌ها نیست. برای آزمون رسانه و درآمد، کمپین و رسانه تأییدشده و بودجه واقعی لازم است. هیچ جایزه‌ای با صرف loaded، click یا نمایش ناقص ایجاد نکنید. فقط رسید `verified=true` و `applied=true` از سمت سرور معتبر است؛ SDK جایزه را پیش‌تر در کیف نصب ثبت کرده، دوباره اعتبار ندهید. برای مصرف، externalId را پیش از ارسال ذخیره کنید و در retry عوض نکنید.

## کیف، پوش و سرور اختیاری

- کیف نصب و محدودیت بازیابی: https://didnex.com/docs/publisher/wallet
- پوش اختصاصی همین پلتفرم، Manifest، FCM/APNs و نمونه پس‌زمینه: https://didnex.com/docs/publisher/push-flutter
- روش سروری برای اتصال جایزه به حساب موجود اپ: https://didnex.com/docs/publisher/server

همه ۱۳ فرمت در اتصال مستقیم و پراکسی اختیاری موجودند. پراکسی فقط روی سرور خودتان کلید خصوصی md_ را نگه می‌دارد. هیچ JWT یا کلید را در فایل نمونه یا پنل کپی کد ثابت نکنید. برای APIهای کیف، رضایت و پوش، شکست واقعی را کنترل کنید؛ موجودی یا موفقیت جعلی نشان ندهید.

## تشخیص خطا

| وضعیت | بررسی |
|---|---|
| noFill | رسانه و جایگاه فعال، کمپین سازگار، بودجه، زمان و فیلتر دستگاه/لوکیشن |
| package mismatch | شناسه واقعی خروجی اپ و رسانه ثبت‌شده؛ debug flavor ممکن است پسوند داشته باشد |
| 403 در وب | Origin دقیق سایت تأییدشده و HTTPS |
| شبکه/مهلت | دسترسی دامنه دیدنکس از دستگاه، INTERNET نسخه Release و تنظیم TLS |
| تصویر تست فقط | diagnosticToken را پس از پایان تست بردارید؛ کارت تست کمپین زنده نیست |
| جایزه ثبت نشد | رضایت، تماشای کامل، ترتیب رویدادها و رسید سرور؛ موجودی را محلی تغییر ندهید |
| پوش دیده نشد | ابتدا Inbox را بررسی کنید؛ سپس رضایت، توکن تازه، تنظیم provider و مجوز سیستم‌عامل |

## وضعیت آزمون

آزمون‌های قرارداد سرور، وب و بسته‌بندی در مخزن اجرا می‌شوند. وضعیت کامپایل منطبق با هش منبع در SDK Lab و releases.json ثبت می‌شود؛ اجرای دستگاه فقط با رسید مستقل device_playback قابل تأیید است.

قبل از انتشار اپ: ساخت Release، اینترنت قطع، DNS نامعتبر، پاسخ ۵۰۰/JSON خراب، رسانه خراب، خروج صفحه حین درخواست، pause/resume و تکرار claim را بررسی کنید. فایل‌های tool/verify یا scripts/sdk-build.mjs مسیر تکرار آزمون را مشخص می‌کنند. هیچ انتشار pub.dev/Maven عمومی در این بسته ادعا نمی‌شود.

## تبلیغات و پوش در یک بسته

کنترلر پوش از همان کلاینت تبلیغات ساخته می‌شود؛ دانلود یا نصب بسته دوم لازم نیست. راهنمای `PUSH.md` داخل همین بسته شامل نمونه اتصال مشترک، رضایت، دریافت، گزارش و چرخه عمر است. روش‌های قدیمی Initialize همچنان سازگارند؛ فایل‌های SDK را از دو ZIP هم‌زمان به پروژه کپی نکنید.

## شناسه جایگاه چیست و از کجا بگیرم؟

پوش در دیدنکس از **شناسه عمومی یکی از جایگاه‌های فعال همان رسانه** برای پیدا کردن اپ یا سایت شما استفاده می‌کند. پیشوند واقعی این شناسه `UNT_` است. این مقدار نام اپ، شناسه بسته، شناسه رسانه با پیشوند `AST_`، توکن FCM یا کلید API نیست و محرمانه نیست.

در پنل ناشر، «جایگاه‌های تبلیغ» را باز کنید؛ شناسه زیر نام جایگاه دیده می‌شود. همان شناسه کامل را کپی کنید. راه ساده‌تر: در «پوش ← اتصال رسانه‌ها»، برای رسانه خود «کد پوش» را بزنید و پلتفرم را انتخاب کنید؛ کد با شناسه واقعی شما ساخته می‌شود و نیازی به حدس یا جایگزینی دستی ندارد.

در مثال عمومی زیر، `placementId` یا `PlacementId` یا `PLACEMENT_ID` متغیری برای نگهداری همین شناسه است. متن `PASTE_YOUR_PLACEMENT_ID_HERE` فقط محل جایگزینی است و شناسه قابل استفاده نیست. آن را با شناسه کامل جایگاه خودتان که با `UNT_` شروع می‌شود عوض کنید. یک جایگاه فعال کافی است؛ جایگاه مخصوص پوش و نمایش تبلیغ برای عضوکردن مخاطب لازم نیست. رسانه نیز باید فعال و تأییدشده باشد و پوش آن در پنل فعال شده باشد.

| مقدار | محل دریافت / کاربرد |
| --- | --- |
| شناسه جایگاه (`UNT_…`) | پنل ناشر ← جایگاه‌های تبلیغ؛ ورودی ایجاد کنترلر پوش |
| شناسه بسته | تنظیمات پروژه اپ؛ باید با رسانه اپ ثبت‌شده یکسان باشد |
| دامنه دیدنکس | نشانی همین سرویس؛ سرور اختصاصی ناشر لازم نیست |
| کلید خصوصی API | داخل اپ یا مرورگر قرار نمی‌گیرد |

اگر `inactive_inventory` دیدید، فعال و تأییدبودن رسانه و فعال‌بودن جایگاه همان رسانه را بررسی کنید. کپی‌کردن شناسه از یک حساب یا رسانه دیگر اتصال را درست نمی‌کند.

## اتصال ساده با شناسه روشن — ۸.۱۷

یک کلاینت را در طول عمر اپ نگه دارید و همان را برای تبلیغ و پوش به کار ببرید. این فراخوانی فقط تنظیم محلی است؛ موفقیت اتصال شبکه با دریافت تبلیغ یا عضویت موفق مشخص می‌شود. init خودکار اجازه اعلان نمی‌گیرد و هیچ پیام واقعی ارسال نمی‌کند. برای تغییر دامنه، origin همان یک تنظیم را تغییر دهید. شناسه عمومی جایگاه (`UNT_…`) باید متعلق به رسانه فعال و تأییدشده خودتان باشد؛ کلید خصوصی وارد اپ نکنید.

```
const placementId = "PASTE_YOUR_PLACEMENT_ID_HERE";
WidgetsFlutterBinding.ensureInitialized();
final client = await DidnexAds.initialize(origin: Uri.parse('https://didnex.com')); // Android/iOS identifier read locally
if (client != null) {
  final push = client.createPush(
    unitId: placementId,
    onMessage: (message) async => false, // Return true only after actual UI display.
    onError: (error) => debugPrint("DidnexPush: $error"),
  );
  // Keep push with the owner and dispose it when that owner ends.
  // Keep this client for app lifetime. Share it with views and push.
  runApp(DidnexAds.withClient(client: client, child: const MyApp()));
} else {
  runApp(const MyApp()); // App continues when SDK setup is unavailable.
}
```

این قطعه، الگوی راه‌اندازی است؛ مثال کامل همه فرمت‌ها، مدیریت خطا و چرخه عمر در ادامه همین راهنما و پوشه Examples بسته قرار دارد. در Flutter کد بالا داخل `Future<void> main() async` قرار می‌گیرد؛ `MyApp` ویجت واقعی اپ شماست. در B4A فایل جدید `Didnex.bas` هم به‌عنوان Class اضافه شود. برای دامنه اختصاصی B4A، initializer اصلی `DidnexAds.Initialize(Me,"Ads",origin,Application.PackageName)` همچنان معتبر است. روش اختیاری پراکسی همان قرارداد نمایش را دارد و برای اتصال مستقیم هیچ سرور ناشری لازم نیست.

### قرارداد اندازه

`slot.version=1` و `slot.profile` از جایگاه می‌آیند. نسبت یا ارتفاع فایلِ دانلودشده اندازه بیرونی را تغییر نمی‌دهد. تصویر و ویدیو با contain داخل کادر قرار می‌گیرند؛ برای `noFill` و خطا کادر جمع می‌شود. پس از یک‌بار به‌روزرسانی SDK، تعویض فایل هم‌اندازه یا شروع پخش ویدیو باعث تغییر چیدمان نمی‌شود. برای پروفایل غیراستانداردِ پیش‌فرض، متادیتای جایگاه و اندازه میزبان را مطابق همان پروفایل تنظیم کنید؛ در Unity/Godot مستطیل میزبان تحت کنترل اپ است.

| پروفایل | نسبت رسانه / اندازه مرجع | نوار ثابت زیر رسانه |
|---|---|---|
| بنر کوچک / بزرگ | ۳۲۰×۵۰ / ۳۲۰×۱۰۰ | ندارد |
| بنر مستطیل / عریض | ۳۰۰×۲۵۰ / ۷۲۸×۹۰ | ندارد |
| تطبیقی | نسبت ۳۲۰×۵۰ با عرض میزبان | ندارد |
| همسان تصویری | ۱۶:۹ یا مربع | ۸۴ پیکسل منطقی |
| همسان ویدیویی / کاروسل | ۱۶:۹ | ۸۴ پیکسل منطقی |
| ویدیوی درون محتوا | ۱۶:۹ | ندارد |
| صوتی | کادر ۹۶ پیکسل منطقی | ندارد |
| نظرسنجی | کادر مرجع ۳۲۰×۳۰۰ | ۸۴ پیکسل منطقی |
| بینابینی، جایزه، آغاز اپ و بازی | میزبان تمام‌صفحه با حاشیه امن | قالب ثابت میزبان |

این‌ها پروفایل محصول دیدنکس‌اند؛ ادعای گواهی IAB یا ابعاد پیکسلی واحد جهانی برای تمام فرمت‌ها ندارند. فایل می‌تواند چند برابر اندازه مرجع باشد. تصویر کوچکِ خارج از حداقل یا نسبت نامطابق پیش از ثبت کمپین رد می‌شود؛ حداقل و نسبت دقیق در فرم کمپین و `GET /api/display-profiles` قابل دریافت‌اند. برای ویدیوی افقی حداقل ۳۲۰×۱۸۰ و پیشنهاد ۶۴۰×۳۶۰ است. فایل‌های کمپین قدیمی بدون پروفایل با حفظ نسبت داخل کادر ثابت قرار می‌گیرند. برای اعمال renderer جدید در SDK نصب‌شده، اپ باید یک بار به‌روزرسانی شود؛ تغییر سرور به‌تنهایی کد قدیمی را عوض نمی‌کند.

### حدود آزمون این نسخه

آزمون قرارداد سرور، رسیدها، noFill، فایل خراب، قطع ارتباط و یکپارچگی بسته‌ها در مخزن وجود دارد. ساخت بومی با هش همین سورس فقط وقتی در `releases.json` مقدار `nativeBuild=passed` دارد تأیید شده است. نبود چنین رسیدی یعنی کامپایل بومی/پخش روی دستگاه تأیید نشده؛ موفقیت تست جاوااسکریپت جای آن را نمی‌گیرد. AARهای قدیمی داخل پوشه سازگاری را معادل ساخت جدید تلقی نکنید؛ برای Android و Godot از پروژه سورس و gradlew استفاده کنید.
