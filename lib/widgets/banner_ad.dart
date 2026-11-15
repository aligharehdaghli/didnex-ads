import 'package:flutter/material.dart';
import 'package:didnex_ads/didnex_ads.dart';

class BannerAd extends StatelessWidget {
  const BannerAd({super.key});

  static const String unitId = 'UNT_0058689b50454df2bfa5581e10d3d1c2';
 
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
