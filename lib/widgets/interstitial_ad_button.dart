import 'package:flutter/material.dart';
import 'package:didnex_ads/didnex_ads.dart';

class InterstitialAdButton extends StatefulWidget {
  const InterstitialAdButton({super.key});

  @override
  State<InterstitialAdButton> createState() => _InterstitialAdButtonState();
}

class _InterstitialAdButtonState extends State<InterstitialAdButton> {
  static const String unitId = 'UNT_9ef8860e4a7940b3bcd5117d2c94be04';

  static const String diagnosticToken =
      'UNT_9ef8860e4a7940b3bcd5117d2c94be04.1794750574626.x7qn6w1Z3xUdMB218UQm8TEVwXe4VQuNLFSytntMkak.INT_97e7a134eb9046a7a673a3f3cf19ae1d';

  bool _busy = false;
  String _message = 'برای نمایش تبلیغ کلیک کنید';

  Future<void> _showAd() async {
    if (_busy) return;

    setState(() {
      _busy = true;
      _message = 'در حال بارگذاری تبلیغ...';
    });

    try {
      final shown = await DidnexAds.showInterstitial(
        context,
        unitId: unitId,
        diagnosticToken: diagnosticToken.isEmpty ? null : diagnosticToken,
      );

      if (!mounted) return;

      setState(() {
        _message = shown ? 'نمایش تبلیغ پایان یافت' : 'فعلاً تبلیغی موجود نیست';
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _message = 'تبلیغ در دسترس نیست';
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
              : const Text('نمایش تبلیغ Interstitial'),
        ),
        const SizedBox(height: 8),
        Text(_message, textAlign: TextAlign.center),
      ],
    );
  }
}
