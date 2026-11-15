import 'package:didnex_ads/didnex_ads.dart';
import 'package:flutter/material.dart';

class CarouselAd extends StatelessWidget {
  const CarouselAd({super.key});

  static const String unitId = 'UNT_efeffb21f5874c1095aad3b88cb715d1';

  @override
  Widget build(BuildContext context) {
    return DidnexAdSlot(
      key: const ValueKey(unitId),
      unitId: unitId,
      noFillBuilder: (_, _) => const SizedBox.shrink(),
      errorBuilder: (_, _) => const SizedBox.shrink(),
    );
  }
}
