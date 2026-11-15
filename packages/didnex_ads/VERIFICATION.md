# بررسی didnex_ads 3.3.0 — نسخه نمایشی ۱

تست‌های قرارداد سرور، وب، صف ایمیل و بسته‌بندی روی این انتشار اجرا می‌شوند. Flutter/Dart، Android SDK و Xcode در این محیط در دسترس نیستند؛ flutter analyze، flutter test و ساخت APK/IPA این نسخه اجرا نشده‌اند. تست‌های Dart همراه بسته‌اند و باید با tool/verify.sh یا tool/verify.ps1 در محیط توسعه اپ اجرا شوند.

Flutter ≥3.44، Dart ≥3.12، Android ≥24، Java 17 و iOS ≥15. AGP/Kotlin از میزبان؛ Kotlin داخلی AGP 9 با Flutter ≥3.47. منبع رسمی: https://docs.flutter.dev/release/breaking-changes/migrate-to-built-in-kotlin/for-plugin-authors

مثال کامل example/lib/quick_start.dart هر ۱۱ فرمت را دارد. manifest اندروید در example/AndroidManifest.xml است. Play Integrity در Android فقط با didnex.enablePlayIntegrity=true به ساخت اضافه می‌شود؛ enableIntegrity را در client نیز فعال کنید. در توزیع خارج Play، سیاست unknown پنل را آگاهانه تنظیم کنید.

هیچ انتشار pub.dev انجام نشده؛ نصب از path است. نمونه‌های شبکه و کیف از پاسخ کنترل‌شده استفاده می‌کنند و تست دستگاه، کدک یا تحویل واقعی پوش محسوب نمی‌شوند.
