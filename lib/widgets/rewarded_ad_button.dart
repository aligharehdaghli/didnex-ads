import 'package:flutter/material.dart';
import 'package:didnex_ads/didnex_ads.dart';

class RewardedAdButton extends StatefulWidget {
  const RewardedAdButton({super.key});

  @override
  State<RewardedAdButton> createState() => _RewardedAdButtonState();
}

class _RewardedAdButtonState extends State<RewardedAdButton> {
  static const String unitId = 'UNT_4069278edf14454193e444ab73f52876';

  static const String diagnosticToken =
      'UNT_4069278edf14454193e444ab73f52876.1794750773329.CYegm5I2HpTpa3DEI72HrEzij3dskDb5iLnMXgeFlWY.INT_e87336c59bb14e85820c10b9f3223677';

  bool _busy = false;
  String _message = 'برای دریافت جایزه، تبلیغ را تماشا کنید';

  Future<void> _showRewarded() async {
    if (_busy) return;

    setState(() {
      _busy = true;
      _message = 'در حال بارگذاری تبلیغ...';
    });

    try {
      final receipt = await DidnexAds.showRewarded(
        context,
        unitId: unitId,
        diagnosticToken: diagnosticToken.isEmpty ? null : diagnosticToken,
      );

      if (!mounted) return;

      setState(() {
        _message = receipt == null
            ? 'جایزه‌ای ثبت نشد'
            : 'جایزه در کیف نصب دیدنکس ثبت شد';
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _message = 'تبلیغ در دسترس نیست؛ اپ ادامه دارد';
      });
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ElevatedButton(
          onPressed: _busy ? null : _showRewarded,
          child: _busy
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('تماشای تبلیغ و دریافت جایزه'),
        ),
        const SizedBox(height: 8),
        Text(_message, textAlign: TextAlign.center),
      ],
    );
  }
}
