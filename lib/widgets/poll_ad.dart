import 'package:flutter/material.dart';
import 'package:didnex_ads/didnex_ads.dart';

class PollAd extends StatelessWidget {
  const PollAd({super.key});

  static const String unitId = 'UNT_eb39369dbc13463db51aaaeecaa62638';

  static const String diagnosticToken =
      'UNT_eb39369dbc13463db51aaaeecaa62638.1794749024742.rvKnVBjxBswuwCc19P9cYeypKosUvKi9CtI6MEROATA.INT_b094f3ac8b9442fb9c8e75be4a6aee67';

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
