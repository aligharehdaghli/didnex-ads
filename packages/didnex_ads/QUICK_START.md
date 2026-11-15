# شروع سریع Flutter

## ۱. نصب
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

## ۲. راه‌اندازی
رسانه و جایگاه را در پنل ناشر بسازید. شناسهٔ نمونه را با شناسهٔ عمومی همان جایگاه عوض کنید.

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

## ۳. نمایش و تست
نمونهٔ کامل داخل بسته در `sdk/flutter/didnex_ads/example/lib/quick_start.dart` است. فرمت نمونه باید با فرمت جایگاه شما یکسان باشد. از پنل ناشر توکن تست بگیرید و نتیجه را با راهنمای تست همان پلتفرم بررسی کنید.

- [نمونه همه فرمت‌ها](https://didnex.com/docs/publisher/flutter#sdk-formats)
- [تست و رفع خطا](https://didnex.com/docs/publisher/flutter#sdk-test)
- [راهنمای پوش](https://didnex.com/docs/publisher/push-flutter)
