import 'safety.dart';
import 'package:flutter/material.dart';
import 'client.dart';
import 'models.dart';
import 'view.dart';

/// A loaded full-screen delivery. Show once at a natural break in your app.
class DidnexFullscreenAd {
  DidnexFullscreenAd._(this.client, this.unitId, this.ad);
  final DidnexAdClient client;
  final String unitId;
  final DidnexAd ad;
  bool _used = false;
  static bool _showing = false;
  static Future<DidnexFullscreenAd?> load(
      {required DidnexAdClient client,
      required String unitId,
      bool rewarded = false,
      bool childDirected = false,
      String? diagnosticToken,
      String? enrollmentToken}) async {
    final r = await client.requestAd(unitId,
        rewarded: rewarded,
        childDirected: childDirected,
        diagnosticToken: diagnosticToken,
        enrollmentToken: enrollmentToken);
    if (r.noFill) return null;
    final ad = r.ad!;
    if (!ad.diagnostic && !ad.format.isFullscreen) return null;
    return DidnexFullscreenAd._(client, unitId, ad);
  }

  Future<DidnexRewardReceipt?> show(BuildContext context,
      {void Function(DidnexRewardReceipt)? onReward}) async {
    if (_used) return null;
    if (_showing) return null;
    if (ad.isExpired) return null;
    final lifecycle = WidgetsBinding.instance.lifecycleState;
    if (!context.mounted ||
        (lifecycle != null && lifecycle != AppLifecycleState.resumed))
      return null;
    _used = true;
    _showing = true;
    try {
      final receipt = await showDialog<DidnexRewardReceipt>(
          context: context,
          barrierDismissible: false,
          useSafeArea: true,
          builder: (_) =>
              _FullscreenContent(client: client, unitId: unitId, ad: ad));
      if (receipt != null) didnexCallback(() { onReward?.call(receipt); });
      return receipt;
    } catch (_) {
      return null;
    } finally {
      _showing = false;
    }
  }
}

class _FullscreenContent extends StatefulWidget {
  const _FullscreenContent(
      {required this.client, required this.unitId, required this.ad});
  final DidnexAdClient client;
  final String unitId;
  final DidnexAd ad;
  @override
  State<_FullscreenContent> createState() => _FullscreenContentState();
}

class _FullscreenContentState extends State<_FullscreenContent> {
  bool _accepted = false, _claiming = false, _completed = false;
  String? _error;
  DidnexRewardReceipt? _receipt;
  Future<void> _claim() async {
    if (_claiming || _receipt != null) return;
    setState(() {
      _claiming = true;
      _error = null;
    });
    try {
      final receipt = await widget.client.claimReward(widget.ad);
      if (mounted) setState(() => _receipt = receipt);
    } catch (_) {
      if (mounted)
        setState(
            () => _error = 'ثبت جایزه هنوز تأیید نشده است؛ دوباره بررسی کنید.');
    } finally {
      if (mounted) setState(() => _claiming = false);
    }
  }

  void _close() => Navigator.of(context).pop(_receipt);
  @override
  Widget build(BuildContext context) {
    final reward = widget.ad.reward,
        needsConsent = reward != null && !_accepted;
    return PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) {
          if (!didPop) _close();
        },
        child: Dialog.fullscreen(
            child: Directionality(
                textDirection: TextDirection.rtl,
                child: SafeArea(
                    child: Column(children: [
                  Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(children: [
                        Expanded(
                            child: Text(needsConsent
                                ? 'پیشنهاد جایزه'
                                : 'تبلیغ · ${widget.ad.brand}')),
                        TextButton(
                            onPressed: _close,
                            child: const Text('بستن تبلیغ ×'))
                      ])),
                  Expanded(
                      child: SingleChildScrollView(
                          padding: const EdgeInsets.all(20),
                          child: needsConsent
                              ? Column(children: [
                                  const Icon(Icons.redeem, size: 60),
                                  const SizedBox(height: 20),
                                  Text('${reward.amount} ${reward.label}',
                                      style: Theme.of(context)
                                          .textTheme
                                          .headlineMedium),
                                  const Padding(
                                      padding:
                                          EdgeInsets.symmetric(vertical: 18),
                                      child: Text(
                                          'با انتخاب نمایش و تماشای کامل ویدیو، جایزه پس از تأیید سرور در حساب شما ثبت می‌شود. خروج زودهنگام جایزه ندارد.')),
                                  FilledButton(
                                      onPressed: () =>
                                          setState(() => _accepted = true),
                                      child: const Text(
                                          'نمایش ویدیو و دریافت جایزه')),
                                  TextButton(
                                      onPressed: _close,
                                      child: const Text('فعلاً نمی‌خواهم')),
                                ])
                              : Column(children: [
                                  DidnexAdView(
                                      client: widget.client,
                                      unitId: widget.unitId,
                                      preloadedAd: widget.ad,
                                      fullscreen: true,
                                      autoPlayVideo: true,
                                      maxMediaHeight:
                                          MediaQuery.sizeOf(context).height *
                                              .65,
                                      onEvent: (event) {
                                        if (event.type ==
                                                DidnexAdEventType
                                                    .videoComplete &&
                                            reward != null) {
                                          _completed = true;
                                          _claim();
                                        }
                                      },
                                      errorBuilder: (context, code) =>
                                          Text('نمایش انجام نشد: $code')),
                                  if (_claiming)
                                    const Padding(
                                        padding: EdgeInsets.all(16),
                                        child:
                                            Text('در حال تأیید و ثبت جایزه…')),
                                  if (_receipt != null)
                                    Padding(
                                        padding: const EdgeInsets.all(16),
                                        child: Text(
                                            'جایزه در حساب شما ثبت شد: ${_receipt!.reward.amount} ${_receipt!.reward.label}')),
                                  if (_error != null)
                                    Padding(
                                        padding: const EdgeInsets.all(12),
                                        child: Text(_error!)),
                                  if (_completed && _error != null)
                                    TextButton(
                                        onPressed: _claiming ? null : _claim,
                                        child:
                                            const Text('بررسی دوباره جایزه')),
                                ]))),
                ])))));
  }
}
