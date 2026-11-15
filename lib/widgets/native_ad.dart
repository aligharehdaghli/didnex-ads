import 'package:flutter/material.dart';
import 'package:didnex_ads/didnex_ads.dart';

class NativeAd extends StatelessWidget {
  const NativeAd({super.key});

  static const String unitId = 'UNT_c32919dc880e4c5fabb318e658ce8ad9';

 
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
