import 'dart:async';
import 'client.dart';
import 'models.dart';

/// One consumable, expiring ad per unit. No background refresh or reward preload.
class DidnexAdCache {
  DidnexAdCache(this.client, {this.maximumEntries = 4, this.allowPreload});
  final DidnexAdClient client;
  final int maximumEntries;
  /// Return false for a metered/offline connection or a busy app.
  final FutureOr<bool> Function()? allowPreload;
  final Map<String, ({DidnexAd ad, int generation})> _ads = {};
  final Map<String, Future<DidnexAdResult>> _pending = {};
  int _generation = 0;
  bool _closed = false;
  Future<DidnexAdResult> preload(String unitId) {
    if (_closed) return Future.value(const DidnexAdResult(noFillReason:'cache_closed'));
    if (maximumEntries < 1 || maximumEntries > 20) throw const DidnexAdException('invalid_cache_size');
    final cached = _ads[unitId];
    if (cached != null && _usable(cached.ad, cached.generation)) return Future.value(DidnexAdResult(ad: cached.ad, requestId: cached.ad.requestId));
    _ads.remove(unitId);
    final existing = _pending[unitId];
    if (existing != null) return existing;
    final generation = _generation, consentGeneration = client.consentGeneration;
    final future = Future<DidnexAdResult>.microtask(() async {
      if (allowPreload != null && !await allowPreload!()) return const DidnexAdResult(noFillReason: 'preload_disallowed');
      final result = await client.requestAd(unitId);
      final ad = result.ad;
      if(ad?.policy.preloadWifiOnly==true&&(allowPreload==null||!await allowPreload!()))return const DidnexAdResult(noFillReason:'wifi_confirmation_required');
      if (ad != null && !ad.format.isRewarded && !ad.diagnostic && !_closed && generation == _generation && consentGeneration == client.consentGeneration) {
        if (!ad.isVideo) await client.loadImage(ad);
        if (!_closed && generation == _generation && consentGeneration == client.consentGeneration && !ad.isExpired) {
          while (_ads.length >= maximumEntries) _ads.remove(_ads.keys.first);
          _ads[unitId] = (ad: ad, generation: consentGeneration);
        }
      }
      if (_closed || generation != _generation || consentGeneration != client.consentGeneration) return const DidnexAdResult(noFillReason: 'preload_invalidated');
      if (ad?.format.isRewarded == true) return const DidnexAdResult(noFillReason: 'reward_preload_unsupported');
      return result;
    }).whenComplete(() { _pending.remove(unitId); });
    _pending[unitId] = future;
    return future;
  }
  bool _usable(DidnexAd ad, int generation) => generation == client.consentGeneration && ad.expiresAt.difference(DateTime.now()) > const Duration(seconds: 10);
  DidnexAd? take(String unitId) {
    if (_closed) return null;
    final entry = _ads.remove(unitId);
    return entry != null && _usable(entry.ad, entry.generation) ? entry.ad : null;
  }
  void clear() { _generation++; _ads.clear(); client.clearImageCache(); }
  void close() { _closed = true; clear(); }
}
