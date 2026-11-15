import 'package:flutter/material.dart';
import 'package:didnex_ads/didnex_ads.dart';

class PlayableAd extends StatelessWidget {
  const PlayableAd({super.key});

  static const String unitId = 'UNT_5ac5c18f2d714173aa5e09824b212a2c';

  static const String diagnosticToken =
      'UNT_5ac5c18f2d714173aa5e09824b212a2c.1794749581664.8YYiSEs66LCfY0Nm1qGt4nIYXGsSgkD3LqKyiyLleco.INT_5b5311dcde9449eea1880b85d65b5277';

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
