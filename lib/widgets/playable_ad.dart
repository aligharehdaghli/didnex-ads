import 'package:flutter/material.dart';
import 'package:didnex_ads/didnex_ads.dart';

class PlayableAd extends StatelessWidget {
  const PlayableAd({super.key});

  static const String unitId = 'UNT_5ac5c18f2d714173aa5e09824b212a2c';

   
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
