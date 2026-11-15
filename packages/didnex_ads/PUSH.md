# پوش Flutter برای Android و iOS — نسخه ۱

اعلان این اتصال در نوار اعلان سیستم‌عامل نمایش داده می‌شود؛ کارت داخل اپ ساخته نمی‌شود. سرور اختصاصی ناشر، JWT و کلید خصوصی در اپ لازم نیست. روش استاندارد از FCM/APNs یا Web Push استفاده می‌کند؛ روش مستقیم از خود دیدنکس می‌خواند. مجوز و رضایت واقعی مخاطب در هر دو لازم است.

## روش دریافت را انتخاب کنید

- **استاندارد:** آماده‌سازی و کد ابتدای همین صفحه مربوط به FCM/Web Push است.
- **مستقیم، بدون Firebase:** به بخش «اتصال مستقیم بدون Firebase» در ادامه همین صفحه بروید؛ وابستگی و تنظیمات FCM بخش استاندارد را نصب نکنید. محدودیت پس‌زمینه همان‌جا نوشته شده است.
- فقط یک روش را برای هر نصب فعال کنید. برای تغییر روش، adapter قبلی را close/dispose و روش جدید را فعال کنید؛ برای توقف دریافت unsubscribe لازم است.

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

## روش استاندارد — آماده‌سازی

بسته یکپارچه didnex_ads را نصب و `integrations/didnex_fcm.dart` را در lib اپ کپی کنید. در پروژه میزبان `flutter pub add firebase_core firebase_messaging` و پیکربندی FlutterFire برای اپ واقعی Android/iOS را انجام دهید. قبل از اتصال، `Firebase.initializeApp(options:DefaultFirebaseOptions.currentPlatform)` را اجرا کنید. همان client تبلیغات را به createPush بدهید؛ client دوم لازم نیست. adapter، توکن اولیه، تمدید توکن، foreground و لمس اعلان شروع سرد را وصل می‌کند. iOS به APNs token آماده نیاز دارد؛ اگر ثبت APNs هنوز کامل نشده، enable را پس از آماده‌شدن دوباره اجرا کنید. background handler که notification+data را دوباره نمایش دهد نسازید.

## کد اتصال استاندارد

```dart
import 'package:didnex_ads/didnex_ads.dart';
import 'didnex_fcm.dart';
const placementId = "PASTE_YOUR_PLACEMENT_ID_HERE";
final client=DidnexAdClient.direct(adOrigin:Uri.parse('https://didnex.com'),packageName:'com.company.app');
final push=client.createPush(unitId:placementId,onError:(error){print('push_unavailable');});
final fcm=DidnexFcm(push,navigate:(message)async{
 // Real notification tap: navigate only to HTTPS routes allowed by your app.
},onError:(error){print('system_push_unavailable');});
// After Firebase.initializeApp(): await fcm.restore(); // No permission prompt.
// Consent button:
Future<bool> enableNotifications()async{
 try{await fcm.enable(consent:true,topics:['general']);return true;}catch(_){return false;}
}
Future<void> disableNotifications()=>fcm.unsubscribe();
// Disposal: await fcm.close(); push.dispose(); client.close();
```

## Manifest و مجوز روش استاندارد

```
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.POST_NOTIFICATIONS" />
iOS: Push Notifications capability + APNs credentials + GoogleService-Info.plist.
```

## تنظیم یک‌باره ناشر

در «پوش ← اتصال رسانه‌ها»، پوش همان رسانه فعال و تأییدشده را روشن کنید. فقط اگر روش استاندارد FCM را انتخاب کرده‌اید، JSON حساب سرویس **همان پروژه Firebase** را فقط در پنل ثبت کنید؛ کلید خصوصی Service Account نباید داخل اپ، مخزن عمومی یا مرورگر باشد. google-services.json و GoogleService-Info.plist تنظیمات کلاینت اپ هستند و با Service Account فرق دارند. iOS در روش استاندارد به کلید APNs و قابلیت Push Notifications همان bundle نیاز دارد. برای وب، VAPID را دیدنکس ایجاد می‌کند و Service Worker روی دامنه خود ناشر است. سرویس OneSignal وابستگی این اتصال نیست؛ مخاطبان، صف و آمار در دیدنکس مدیریت می‌شوند.

کلاینت تبلیغات و پوش را مشترک نگه دارید. init هیچ اجازه‌ای درخواست نمی‌کند. فعال‌سازی را فقط در پاسخ به دکمه رضایت انجام دهید؛ برای راه‌اندازی بعدی، restore صرفاً رضایت قبلی را بازیابی می‌کند و مجوز تازه نمی‌خواهد. توکن تازه را دوباره ثبت و opt-out را به unsubscribe متصل کنید. close/dispose فقط شنونده محلی را می‌بندد؛ برای لغو عضویت سرور، unsubscribe لازم است. خطاها را کنترل کنید تا اپ به کار عادی ادامه دهد. اگر Firebase یا Service Worker دارید، callbackها را ادغام کنید و سرویس/worker تکراری نسازید.

تأیید ایمیل، مربوط به حساب ناشر در پنل است؛ کاربر نهایی اپ برای دریافت تبلیغ یا پوش، به حساب دیدنکس یا ورود نیاز ندارد. رضایت و مجوز اعلان همچنان الزامی است.

## لینک مقصد اعلان

لینک لمس، دکمه و گونه می‌تواند HTTP یا HTTPS هر دامنه باشد؛ محدود به رسانه نیست. لینک اجرایی، فایل، داده و اطلاعات ورود رد می‌شوند. خالی یعنی صفحه اصلی سایت یا صفحه انتشار اپ. این مجوز برای مقصد است؛ اتصال سرویس و رسید فقط HTTPS خود دیدنکس است. Worker روی سایت ناشر نصب می‌شود. پشتیبانی HTTP در دستگاه نیازمند SDK همین انتشار است.

## تست دستگاه

۱. بسته جدید همین پلتفرم و adapter آن را در اپ جایگزین کنید؛ آپدیت سرور به‌تنهایی SDK نصب‌شده روی دستگاه را تغییر نمی‌دهد. خروجی Release واقعی بگیرید. مجوز را با دکمه فعال‌سازی دریافت کنید.

۲. در پنل باید اشتراک FCM یا Web Push دیده شود؛ Inbox برای ارسال پنل کافی نیست. اعلان آزمایشی بفرستید. در پیش‌زمینه، پس‌زمینه و شروع سرد با لمس اعلان، **نوار اعلان سیستم‌عامل** را بررسی کنید؛ صفحه اپ نباید کارت اعلان اضافه کند.

۳. رد مجوز، اینترنت قطع، پیام منقضی و پیام تکراری را بررسی کنید؛ نباید delivered جعلی ساخته شود. بعد از لغو عضویت، ارسال بعدی نباید مخاطب را صف کند. اعلان قبلاً تحویل‌شده به provider ممکن است هنوز در مسیر باشد. receipt حاوی دسترسی خصوصی است و نباید وارد گزارش عمومی شود.

۴. دریافت پذیرفته‌شده توسط FCM به معنی دیده‌شدن نیست. در بعضی اعلان‌های پس‌زمینه، OS بدون اجرای SDK نمایش می‌دهد و delivered قابل گزارش نیست؛ آن را از accepted حدس نزنید. روی Android بدون Google Play Services یا بدون دسترسی شبکه به FCM، این مسیر ممکن است آماده نباشد. محدودیت سیستم‌عامل را با پیام داخل اپ جایگزین نکنید.

## انتخاب مسیر و محدودیت مستقیم

برای فعال‌سازی روش مستقیم، روشن‌بودن پوش رسانه کافی است؛ Service Account، google-services.json و VAPID لازم نیست. هنگام ارسال پنل، همه مسیرهای اعلان به‌صورت پیش‌فرض مخاطب هستند؛ در تنظیمات بیشتر می‌توانید فقط «مستقیم» یا فقط «استاندارد» را انتخاب کنید. یک نصب هم‌زمان یک مسیر فعال دارد؛ تغییر روش، اشتراک روش قبلی را لغو می‌کند. controller/adapter قبلی را قبل از انتخاب تازه close کنید و فقط controller انتخاب‌شده را restore کنید. برای انصراف مخاطب از همه اعلان‌های این نصب unsubscribe را به کار ببرید.

در Android بومی، B4A، Flutter Android، Unity Android و Godot Android دریافت دوره‌ای JobScheduler با حداقل ۱۵ دقیقه ممکن است. این زمان‌بندی دقیق نیست و سیستم می‌تواند آن را عقب بیندازد. در iOS، React Native و وب دریافت مستقیم فقط زمان فعالیت اپ/صفحه است؛ برای دریافت از راه دور هنگام بسته‌بودن، مسیر استاندارد را انتخاب کنید. nativeBuild=not_run را به معنی تست دستگاه نگیرید.

## API قدیمی

Inbox صرفاً برای سازگاری و ارسال صریح deliveryChannel=inbox باقی مانده و مسیر پنل نیست. برچسب‌ها، بخش مخاطب، quiet hours و هویت امضاشده در همان کنترلر قابل استفاده‌اند. اتصال عادی به سرور اختصاصی ناشر نیاز ندارد؛ اگر هویت امضاشده کاربر خودتان را می‌خواهید، فقط تولید همان proof به سرور امن خودتان نیاز دارد.

## رفتار اعلان استاندارد

پیام notification+data در پس‌زمینه توسط provider به سیستم‌عامل می‌رسد؛ آن را دوباره نمایش ندهید. در پیش‌زمینه، adapter این بسته اعلان بومی می‌سازد. accepted پذیرش سرویس است؛ delivered ثبت اعلان در سیستم‌عامل از دید SDK و opened لمس واقعی است. حالت مزاحم نشوید، محدودیت باتری یا Force Stop ممکن است نمایش را محدود کند.

## مرجع رسمی

https://firebase.google.com/docs/cloud-messaging/flutter/receive-messages

## اتصال مستقیم بدون Firebase

همان بسته یکپارچه didnex_ads کافی است؛ این روش Firebase Core/Messaging یا google-services.json نمی‌خواهد. پیش از استفاده در main، WidgetsFlutterBinding.ensureInitialized() را اجرا کنید. فعال‌سازی را به دکمه رضایت وصل کنید. نمایش و دریافت Android بومی است؛ در iOS فقط زمان فعالیت اپ دریافت می‌شود.

```dart
import 'package:flutter/widgets.dart';
import 'package:didnex_ads/didnex_ads.dart';
const placementId="PASTE_YOUR_PLACEMENT_ID_HERE";
final client=DidnexAdClient.direct(adOrigin:Uri.parse('https://didnex.com'),packageName:'com.company.app');
final push=client.createPush(unitId:placementId,onError:(error){print('direct_push_unavailable');});
Future<void> restoreNotifications()async{WidgetsFlutterBinding.ensureInitialized();await push.restoreDirect();}
Future<bool> enableFromConsentButton()async{
 try{if(!await push.requestPermission())return false;return await push.enableDirect(consent:true,backgroundPolling:true,topics:['general']);}catch(_){return false;}
}
Future<void> disableNotifications()=>push.unsubscribe();
// Optional: push.onOpened=(message)async{ /* Navigate through your HTTPS allowlist. */ };
// Disposal: push.dispose(); client.close();
```

### Manifest مستقیم

```
Android: INTERNET + POST_NOTIFICATIONS + RECEIVE_BOOT_COMPLETED and DidnexDirectPush$Job (already merged by the plugin manifest).
iOS: UserNotifications permission; no Firebase or APNs credential needed for this foreground-only transport.
```

### محدودیت دریافت مستقیم

Android دریافت فعال و JobScheduler دوره‌ای با حداقل ۱۵ دقیقه دارد. در iOS دریافت مستقیم فقط در زمان فعالیت اپ است؛ برای دریافت از راه دور هنگام بسته‌بودن اپ، روش استاندارد مبتنی بر APNs را انتخاب کنید.
