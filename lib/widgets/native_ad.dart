import 'package:flutter/material.dart';
import 'package:didnex_ads/didnex_ads.dart';

class NativeAd extends StatelessWidget {
  const NativeAd({super.key});

  static const String unitId = 'UNT_c32919dc880e4c5fabb318e658ce8ad9';

  static const String diagnosticToken =
      'UNT_c32919dc880e4c5fabb318e658ce8ad9.1794750167419.rmIrhS7_fsi8fh1UWmMHK5f0FwxhIj8gVHCkvphRK6E.INT_5903bcedde9941419acba0bb66d6d4ee';

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
