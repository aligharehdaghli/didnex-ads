import 'package:flutter/material.dart';
import 'package:didnex_ads/didnex_ads.dart';

class NativeVideoAd extends StatelessWidget {
  const NativeVideoAd({super.key});

  static const String unitId = 'UNT_d6fd344c4db344f684c985096c218c58';

  static const String diagnosticToken =
      'UNT_d6fd344c4db344f684c985096c218c58.1794750283018.gwlIlcIwC0Ncxc77Dqa2i4KyYrLvES4MQB2hebvFNXY.INT_deae183af9f04563ad0d0e58ab9bf715';

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
