import 'package:flutter/material.dart';
import 'package:didnex_ads/didnex_ads.dart';

class AdaptiveBannerAd extends StatelessWidget {
  const AdaptiveBannerAd({super.key});

  static const String unitId = 'UNT_d162629ab3f54969ad1c7654827eefef';

  static const String diagnosticToken =
      'UNT_d162629ab3f54969ad1c7654827eefef.1794750062282.v5_uhLFLNSBc7ooF7v676jWQTi_gSQo_JkesFFCutIo.INT_d7f348cb512a49fb956ba5b658bbbae7';

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
