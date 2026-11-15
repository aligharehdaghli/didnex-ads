import 'package:flutter/material.dart';
import 'package:didnex_ads/didnex_ads.dart';

class AppOpenAdButton extends StatefulWidget {
  const AppOpenAdButton({super.key});

  @override
  State<AppOpenAdButton> createState() => _AppOpenAdButtonState();
}

class _AppOpenAdButtonState extends State<AppOpenAdButton> {
  static const String unitId = 'UNT_0aa1674c4ff24cee935055e01dacc7a0';

   
  bool _busy = false;

  Future<void> _showAd() async {
    if (_busy) return;

    setState(() => _busy = true);

    try {
      final shown = await DidnexAds.showInterstitial(
        context,
        unitId: unitId,
      
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            shown ? 'نمایش تبلیغ پایان یافت' : 'فعلاً تبلیغی موجود نیست',
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تبلیغ در دسترس نیست؛ اپ ادامه دارد')),
      );
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _busy ? null : _showAd,
        child: _busy
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Text('نمایش تبلیغ App Open'),
      ),
    );
  }
}
