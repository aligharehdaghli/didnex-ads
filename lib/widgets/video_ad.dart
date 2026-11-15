import 'package:flutter/material.dart';
import 'package:didnex_ads/didnex_ads.dart';

class VideoAd extends StatelessWidget {
  const VideoAd({super.key});

  static const String unitId = 'UNT_a7b97765d708434c889e00acaaae550e';

  static const String diagnosticToken =
      'UNT_a7b97765d708434c889e00acaaae550e.1794750415161.ZK2QWM-KD7Xf02ji11c0fYkQZ1ywwvtrgn4HDD3F3Yo.INT_3f0f2ce73de74afc80343327002d32d2';

  @override
  Widget build(BuildContext context) {
    return DidnexAdSlot(
      key: const ValueKey(unitId),
      unitId: unitId,
      diagnosticToken: diagnosticToken.isEmpty ? null : diagnosticToken,
      noFillBuilder: (_, __) => const SizedBox.shrink(),
      errorBuilder: (_, __) => const SizedBox.shrink(),
    );
  }
}
