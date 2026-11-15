import 'package:flutter/material.dart';
import 'package:didnex_ads/didnex_ads.dart';

class AudioAd extends StatelessWidget {
  const AudioAd({super.key});

  static const String unitId = 'UNT_de788cb8e4284b46b98536da8a144282';

  static const String diagnosticToken =
      'UNT_de788cb8e4284b46b98536da8a144282.1794749361047.4naFgCrvJhdjHoTIQwdDCfD7rbi1R1_DLiHrOnobEA4.INT_23a2c0e9401a4ea6bf158da24029c220';

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
