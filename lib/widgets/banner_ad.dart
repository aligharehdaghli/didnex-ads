import 'package:flutter/material.dart';
import 'package:didnex_ads/didnex_ads.dart';

class BannerAd extends StatelessWidget {
  const BannerAd({super.key});

  static const String unitId = 'UNT_0058689b50454df2bfa5581e10d3d1c2';

  static const String diagnosticToken =
      'UNT_0058689b50454df2bfa5581e10d3d1c2.1794749726701.tBGJrqQcSsp35i8fsjBy8tb2pUwgt7_JfFx0AIteOFc.INT_c7ec567bec8a427e8e7412867a1c89a2';

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
