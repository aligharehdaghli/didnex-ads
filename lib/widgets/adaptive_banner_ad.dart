import 'package:flutter/material.dart';
import 'package:didnex_ads/didnex_ads.dart';

class AdaptiveBannerAd extends StatelessWidget {
  const AdaptiveBannerAd({super.key});

  static const String unitId = 'UNT_d162629ab3f54969ad1c7654827eefef';

 
  @override
  Widget build(BuildContext context) {
    return DidnexAdSlot(
      key: const ValueKey(unitId),
      unitId: unitId,
 
      noFillBuilder: (_, __) => const SizedBox.shrink(),
      errorBuilder: (_, __) => const SizedBox.shrink(),
    );
  }
}
