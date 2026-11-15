import 'package:flutter/material.dart';
import 'package:didnex_ads/didnex_ads.dart';

class AudioAd extends StatelessWidget {
  const AudioAd({super.key});

  static const String unitId = 'UNT_de788cb8e4284b46b98536da8a144282';

  
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
