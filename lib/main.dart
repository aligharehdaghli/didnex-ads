import 'package:didnex_ads/didnex_ads.dart';
import 'package:flutter/material.dart';

void main() => runApp(
  DidnexAds.direct(
    packageName: 'com.example.didnex',
    adOrigin: Uri.parse('https://didnex.com'),
    child: const MaterialApp(home: AdsPage()),
  ),
);

class AdsPage extends StatefulWidget {
  const AdsPage({super.key});
  @override
  State<AdsPage> createState() => _AdsPageState();
}

class _AdsPageState extends State<AdsPage> {
  String? _inlineUnit;
  bool _busy = false;
  String _message = 'یک فرمت انتخاب کنید';
  static const units = <String, String>{
    'carousel': 'UNT_efeffb21f5874c1095aad3b88cb715d1',
  };
  Future<void> _show(String format) async {
    if (_busy) return;
    final unit = units[format]!;
    setState(() => _busy = true);
    try {
      if (format.startsWith('rewarded')) {
        final receipt = await DidnexAds.showRewarded(context, unitId: unit);
        if (mounted) {
          setState(
            () => _message = receipt == null
                ? 'جایزه‌ای ثبت نشد'
                : 'جایزه در کیف نصب دیدنکس ثبت شد',
          );
        }
      } else if (['interstitial', 'app_open', 'playable'].contains(format)) {
        final shown = await DidnexAds.showInterstitial(context, unitId: unit);
        if (mounted) {
          setState(
            () => _message = shown
                ? 'نمایش پایان یافت'
                : 'فعلاً تبلیغی موجود نیست',
          );
        }
      } else {
        setState(() => _inlineUnit = unit);
      }
    } catch (_) {
      if (mounted) {
        setState(() => _message = 'تبلیغ در دسترس نیست؛ اپ ادامه دارد');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Directionality(
    textDirection: TextDirection.rtl,
    child: Scaffold(
      appBar: AppBar(title: const Text('اتصال دیدنکس')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(_message),
          Wrap(
            spacing: 8,
            children: units.keys
                .map(
                  (f) => OutlinedButton(
                    onPressed: _busy ? null : () => _show(f),
                    child: Text(f),
                  ),
                )
                .toList(),
          ),
          if (_inlineUnit != null)
             DidnexAdSlot(
              
              key: ValueKey(_inlineUnit),
              unitId: _inlineUnit!,

              noFillBuilder: (_, _) => const SizedBox.shrink(),
              errorBuilder: (_, _) => const SizedBox.shrink(),
            ),
         
        ],
      ),
    ),
  );
}
