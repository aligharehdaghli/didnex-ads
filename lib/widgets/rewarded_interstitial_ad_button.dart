import 'package:flutter/material.dart';
import 'package:didnex_ads/didnex_ads.dart';

class RewardedInterstitialAdButton extends StatefulWidget {
  const RewardedInterstitialAdButton({super.key});

  @override
  State<RewardedInterstitialAdButton> createState() =>
      _RewardedInterstitialAdButtonState();
}

class _RewardedInterstitialAdButtonState
    extends State<RewardedInterstitialAdButton> {
  static const String unitId = 'UNT_b4b0a1eb4868493793edc25d93dcbdfd';
 
  bool _busy = false;
  String _message = 'برای دریافت جایزه، تبلیغ را تماشا کنید';

  Future<void> _showAd() async {
    if (_busy) return;

    setState(() {
      _busy = true;
      _message = 'در حال بارگذاری تبلیغ...';
    });

    try {
      final receipt = await DidnexAds.showRewarded(
        context,
        unitId: unitId,
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
          onPressed: _busy ? null : _showAd,
          child: _busy
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('تماشای Rewarded Interstitial'),
        ),
        const SizedBox(height: 8),
        Text(_message, textAlign: TextAlign.center),
      ],
    );
  }
}
