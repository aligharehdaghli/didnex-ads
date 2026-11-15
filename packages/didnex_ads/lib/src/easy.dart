import 'package:flutter/services.dart';
import 'package:flutter/material.dart';

import 'client.dart';
import 'inspector.dart';
import 'fullscreen.dart';
import 'models.dart';
import 'pro_models.dart';
import 'view.dart';

/// Configure once above MaterialApp. The scope owns and closes its client.
/// Authentication, rewards and measurement still use DidnexAdClient.
class DidnexAds extends StatefulWidget {
  static bool _fullscreenBusy = false;
  /// Local configuration only. The first ad/push call connects in the background.
  /// Keep this client for the application lifetime and close it after all users.
  static Future<DidnexAdClient?> initialize({Uri? origin,String? packageName}) async {
    try {
      final app=packageName??await const MethodChannel('ir.didnex.ads/native').invokeMethod<String>('appInfo');
      if(app==null||app.isEmpty)throw const DidnexAdException('package_name_required');
      return DidnexAdClient.direct(adOrigin:origin??Uri.parse('https://didnex.com'),packageName:app);
    } catch(error,stack){DidnexInspector.capture(error,stack,stage:'initialize');return null;}
  }
  const DidnexAds({
    super.key,
    required Uri proxyUrl,
    required Future<String> Function() sessionToken,
    required this.child,
    this.adOrigin,
    this.onRevenue,
    this.enableIntegrity=false,this.storyConsent=false,
    this.adContext = const DidnexContext(),
  }) : proxyUrl = proxyUrl, sessionToken = sessionToken, client = null, packageName = null;

  /// Direct connection for apps without a publisher backend or login.
  const DidnexAds.direct({
    super.key,
    Uri? adOrigin,
    required String packageName,
    required this.child,
    this.onRevenue,
    this.enableIntegrity=false,this.storyConsent=false,
    this.adContext = const DidnexContext(),
  }) : adOrigin = adOrigin, packageName = packageName,
       proxyUrl = null, sessionToken = null, client = null;

  /// The caller retains ownership and must close this client after all views.
  const DidnexAds.withClient({
    super.key,
    required DidnexAdClient client,
    required this.child,
  }) : client = client, proxyUrl = null, sessionToken = null,
       adOrigin = null, packageName = null, onRevenue = null, enableIntegrity=false,storyConsent=false,adContext = const DidnexContext();

  final bool enableIntegrity,storyConsent;
  final Uri? proxyUrl, adOrigin;
  final String? packageName;
  final Future<String> Function()? sessionToken;
  final DidnexAdClient? client;
  final void Function(DidnexRevenue)? onRevenue;
  final DidnexContext adContext;
  final Widget child;

  static DidnexAdClient of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<_DidnexAdsScope>();
    if (scope == null) throw const DidnexAdException('ads_scope_required');
    return scope.client;
  }

  /// Optional lookup for a screen that can render without advertising.
  static DidnexAdClient? maybeOf(BuildContext context) => context
      .dependOnInheritedWidgetOfExactType<_DidnexAdsScope>()?.client;

  /// Returns false on no-fill or when the screen is gone before loading.
  /// app_open units may also be used at an app-selected natural break.
  static Future<bool> showInterstitial(BuildContext context, {
    required String unitId,
    String? diagnosticToken,
    bool childDirected = false,
  }) async {
    if (_fullscreenBusy) return false;
    _fullscreenBusy = true;
    try {
      final client = of(context);
      final loaded = await DidnexFullscreenAd.load(
        client: client, unitId: unitId, diagnosticToken: diagnosticToken,
        childDirected: childDirected,
      );
      if (loaded == null || !context.mounted) return false;
      if (loaded.ad.format.isRewarded) {
        throw const DidnexAdException('use_show_rewarded');
      }
      await loaded.show(context);
      return true;
    } catch (error,stack) { DidnexInspector.capture(error,stack,stage:'fullscreen'); return false; } finally { _fullscreenBusy = false; }
  }

  /// Returns only a server-verified AND applied receipt, or null.
  /// Refresh account state in onReward; never credit the client balance here.
  static Future<DidnexRewardReceipt?> showRewarded(BuildContext context, {
    required String unitId,
    String? diagnosticToken,
    bool childDirected = false,
    void Function(DidnexRewardReceipt)? onReward,
  }) async {
    if (_fullscreenBusy) return null;
    _fullscreenBusy = true;
    try {
      final client = of(context);
      final loaded = await DidnexFullscreenAd.load(
        client: client, unitId: unitId, rewarded: true,
        diagnosticToken: diagnosticToken,
        childDirected: childDirected,
      );
      if (loaded == null || !context.mounted) return null;
      if (!loaded.ad.diagnostic && !loaded.ad.format.isRewarded) {
        throw const DidnexAdException('rewarded_unit_required');
      }
      return await loaded.show(context, onReward: onReward);
    } catch (error,stack) { DidnexInspector.capture(error,stack,stage:'rewarded'); return null; } finally { _fullscreenBusy = false; }
  }

  @override
  State<DidnexAds> createState() => _DidnexAdsState();
}

class _DidnexAdsState extends State<DidnexAds> {
  late DidnexAdClient _client;
  bool get _ownsClient => widget.client == null;

  DidnexAdClient _makeClient() => widget.client ?? (widget.packageName != null
      ? DidnexAdClient.direct(
          adOrigin: widget.adOrigin ?? Uri.parse('https://didnex.com'), packageName: widget.packageName!,
          context: widget.adContext,enableIntegrity:widget.enableIntegrity,storyConsent:widget.storyConsent,
          onRevenue: (value) => widget.onRevenue?.call(value),
        ) : DidnexAdClient(
    proxyUrl: widget.proxyUrl!,
    // Keep the latest provider/callback without resetting ads on parent builds.
    sessionToken: () => widget.sessionToken!(),
    adOrigin: widget.adOrigin,
    context: widget.adContext,enableIntegrity:widget.enableIntegrity,storyConsent:widget.storyConsent,
    onRevenue: (value) => widget.onRevenue?.call(value),
  ));

  @override
  void initState() { super.initState(); _client = _makeClient(); }

  @override
  void didUpdateWidget(covariant DidnexAds oldWidget) {
    super.didUpdateWidget(oldWidget);
    if(widget.client==null){_client.enableIntegrity=widget.enableIntegrity;_client.storyConsent=widget.storyConsent;}
    if (oldWidget.client != widget.client ||
        oldWidget.proxyUrl != widget.proxyUrl ||
        oldWidget.adOrigin != widget.adOrigin ||
        oldWidget.packageName != widget.packageName) {
      final previous = _client;
      _client = _makeClient();
      // Descendant views release the old client before it is closed.
      if (oldWidget.client == null) {
        WidgetsBinding.instance.addPostFrameCallback((_) => previous.close());
      }
    } else if (_ownsClient && oldWidget.adContext != widget.adContext) {
      _client.context = widget.adContext;
    }
  }

  @override
  void dispose() { if (_ownsClient) _client.close(); super.dispose(); }

  @override
  Widget build(BuildContext context) => _DidnexAdsScope(
    client: _client, child: widget.child,
  );
}

class _DidnexAdsScope extends InheritedWidget {
  const _DidnexAdsScope({required this.client, required super.child});
  final DidnexAdClient client;
  @override
  bool updateShouldNotify(_DidnexAdsScope oldWidget) => oldWidget.client != client;
}

/// A short inline API for banner, adaptive banner, native and inline video.
/// The unit defines the format. No ad requests occur in build itself.
class DidnexAdSlot extends StatelessWidget {
  const DidnexAdSlot({
    super.key,
    required this.unitId,
    this.active = true,
    this.childDirected = false,
    this.autoPlayVideo = true,
    this.diagnosticToken,
    this.onEvent,
    this.loadingBuilder,
    this.noFillBuilder,
    this.errorBuilder,
  });
  final String unitId;
  final bool active, childDirected, autoPlayVideo;
  final String? diagnosticToken;
  final void Function(DidnexAdEvent)? onEvent;
  final WidgetBuilder? loadingBuilder;
  final DidnexFallbackBuilder? noFillBuilder, errorBuilder;

  @override
  Widget build(BuildContext context) {
    final client=DidnexAds.maybeOf(context);
    if(client==null) return errorBuilder?.call(context,'ads_scope_required') ?? const SizedBox.shrink();
    return DidnexAdView(
    client: client, unitId: unitId,
    active: active, childDirected: childDirected,
    autoPlayVideo: autoPlayVideo, diagnosticToken: diagnosticToken,
    onEvent: onEvent, loadingBuilder: loadingBuilder,
    noFillBuilder: noFillBuilder, errorBuilder: errorBuilder,
  );
  }
}
