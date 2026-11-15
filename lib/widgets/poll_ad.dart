import 'package:flutter/material.dart';
import 'package:didnex_ads/didnex_ads.dart';

class PollAd extends StatelessWidget {
  const PollAd({super.key});

  static const String unitId = 'UNT_eb39369dbc13463db51aaaeecaa62638';

  
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
