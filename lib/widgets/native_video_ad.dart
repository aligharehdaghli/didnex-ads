import 'package:flutter/material.dart';
import 'package:didnex_ads/didnex_ads.dart';

class NativeVideoAd extends StatelessWidget {
  const NativeVideoAd({super.key});

  static const String unitId = 'UNT_d6fd344c4db344f684c985096c218c58';

   
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
