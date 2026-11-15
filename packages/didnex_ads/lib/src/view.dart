import 'interactive.dart';
import 'safety.dart';
import 'inspector.dart';
import 'playable.dart';
import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';

import 'client.dart';
import 'models.dart';
import 'presentation.dart';

typedef DidnexFallbackBuilder = Widget Function(
  BuildContext context,
  String code,
);

/// A single contextual placement. No timer refresh, device identifiers or API keys.
class DidnexAdView extends StatefulWidget {
  const DidnexAdView({
    super.key,
    required this.unitId,
    this.client,
    this.preloadedAd,
    this.fullscreen = false,
    this.proxyUrl,
    this.sessionToken,
    this.openUrl,
    this.enrollmentToken,
    this.diagnosticToken,
    this.childDirected = false,
    this.active = true,
    this.autoPlayVideo = true,
    this.muted = true,
    this.onEvent,
    this.loadingBuilder,
    this.noFillBuilder,
    this.errorBuilder,
    this.maxMediaHeight = 360,
  })  : assert(client != null || (proxyUrl != null && sessionToken != null)),
        assert(maxMediaHeight > 0);
  final String unitId;
  final DidnexAdClient? client;
  final DidnexAd? preloadedAd;
  final bool fullscreen;
  final Uri? proxyUrl;
  final Future<String> Function()? sessionToken;
  final Future<void> Function(Uri)? openUrl;
  final String? enrollmentToken, diagnosticToken;
  final bool childDirected, active, autoPlayVideo, muted;
  final double maxMediaHeight;
  final void Function(DidnexAdEvent)? onEvent;
  final WidgetBuilder? loadingBuilder;
  final DidnexFallbackBuilder? noFillBuilder, errorBuilder;
  @override
  State<DidnexAdView> createState() => _DidnexAdViewState();
}

class _DidnexAdViewState extends State<DidnexAdView>
    with WidgetsBindingObserver {
  final GlobalKey _mediaKey = GlobalKey();
  final DidnexViewability _viewability = DidnexViewability();
  final Stopwatch _clock = Stopwatch();
  late DidnexAdClient _client;
  bool _ownsClient = false,
      _resumed = true,
      _ready = false,
      _impressed = false,
      _sending = false,
      _clicking = false,
      _loadedNotified = false,
      _userPaused = false;
  int _generation = 0, _impressionAttempts = 0;
  String? _error, _noFill;
  DidnexAd? _ad;
  Uint8List? _image;
  VideoPlayerController? _video;
  Timer? _timer;
  final Set<String> _milestones = {};
  bool get _routeActive =>
      widget.active && (ModalRoute.of(context)?.isCurrent ?? true);
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _resumed = WidgetsBinding.instance.lifecycleState == null ||
        WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed;
    _configureClient();
    didnexIgnore(_load());
  }

  String? _fontFamily;
  void _configureClient() {
    _ownsClient = widget.client == null;
    _client = widget.client ??
        DidnexAdClient(
          proxyUrl: widget.proxyUrl!,
          sessionToken: () => widget.sessionToken!(),
        );
  }

  @override
  void didUpdateWidget(covariant DidnexAdView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.client != widget.client ||
        oldWidget.proxyUrl != widget.proxyUrl) {
      if (_ownsClient) _client.close();
      _configureClient();
      didnexIgnore(_load());
    } else if (oldWidget.unitId != widget.unitId ||
        oldWidget.preloadedAd != widget.preloadedAd ||
        oldWidget.enrollmentToken != widget.enrollmentToken ||
        oldWidget.diagnosticToken != widget.diagnosticToken ||
        oldWidget.childDirected != widget.childDirected) {
      didnexIgnore(_load());
    }
    if (!widget.active) {
      _viewability.reset();
      didnexIgnore(_video?.pause() ?? Future.value());
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _resumed = state == AppLifecycleState.resumed;
    if (!_resumed) {
      _viewability.reset();
      didnexIgnore(_video?.pause() ?? Future.value());
    }
  }

  void _emit(DidnexAdEventType type, {String? code}) {
    DidnexInspector.record(type.name,
        code: code,
        requestId: _ad?.requestId,
        latencyMs: _clock.elapsedMilliseconds);
    if (!mounted) return;
    didnexCallback(() {
      widget.onEvent?.call(
        DidnexAdEvent(
          type,
          code: code,
          requestId: _ad?.requestId,
          latency: _clock.elapsed,
          diagnostic: _ad?.diagnostic ?? false,
        ),
      );
    });
  }

  Future<void> _load() async {
    final generation = ++_generation;
    _timer?.cancel();
    _timer = null;
    final previous = _video;
    _video = null;
    if (previous != null) didnexIgnore(previous.dispose());
    _viewability.reset();
    _milestones.clear();
    _videoQueue = Future.value();
    _audioWatched = 0;
    _audioPosition = 0;
    _audioWall = 0;
    _ad = null;
    _image = null;
    _error = null;
    _noFill = null;
    _ready = false;
    _impressed = false;
    _sending = false;
    _loadedNotified = false;
    _userPaused = false;
    _impressionAttempts = 0;
    _clock.reset();
    _clock.start();
    if (mounted) setState(() {});
    try {
      final result = widget.preloadedAd != null
          ? DidnexAdResult(ad: widget.preloadedAd)
          : await _client.requestAd(
              widget.unitId,
              childDirected: widget.childDirected,
              enrollmentToken: widget.enrollmentToken,
              diagnosticToken: widget.diagnosticToken,
            );
      if (!mounted || generation != _generation) return;
      if (result.noFill) {
        setState(() => _noFill = result.noFillReason);
        didnexCallback(() {
          widget.onEvent?.call(
            DidnexAdEvent(
              DidnexAdEventType.noFill,
              requestId: result.requestId,
              code: result.noFillReason,
            ),
          );
        });
        return;
      }
      final ad = result.ad!;
      if (!ad.diagnostic && ad.format.isFullscreen != widget.fullscreen)
        throw const DidnexAdException('use_fullscreen_api');
      _ad = ad;
      _fontFamily = null;
      didnexIgnore(DidnexPresentation(ad).loadFont().then((family) {
        if (mounted && generation == _generation)
          setState(() => _fontFamily = family);
      }));
      if ([
        DidnexAdFormat.playable,
        DidnexAdFormat.carousel,
        DidnexAdFormat.poll
      ].contains(ad.format)) {
        setState(() {});
      } else if (ad.isVideo || ad.isAudio) {
        final selected = await _client.selectVideo(ad);
        if (!mounted || generation != _generation) return;
        var player = VideoPlayerController.networkUrl(selected);
        _video = player;
        try {
          await player.initialize().timeout(ad.policy.timeout);
        } catch (_) {
          if (!mounted ||
              generation != _generation ||
              selected == ad.creativeUrl) rethrow;
          await player.dispose();
          player = VideoPlayerController.networkUrl(ad.creativeUrl);
          _video = player;
          await player.initialize().timeout(ad.policy.timeout);
          DidnexInspector.record('fallback', code: 'original_video');
        }
        if (!mounted || generation != _generation) {
          await player.dispose();
          return;
        }
        if (player.value.duration <= Duration.zero ||
            player.value.duration >
                (ad.isAudio
                    ? const Duration(seconds: 180)
                    : ad.policy.maxVideoDuration)) {
          throw const DidnexAdException('video_duration_policy');
        }
        if (ad.format.isRewarded &&
            (ad.videoDuration == null ||
                (player.value.duration - ad.videoDuration!)
                        .inMilliseconds
                        .abs() >
                    1000))
          throw const DidnexAdException('reward_video_duration_mismatch');
        await player.setLooping(false);
        await player.setVolume(ad.isAudio
            ? 1
            : (widget.autoPlayVideo || widget.muted)
                ? 0
                : 1);
        if (!mounted || generation != _generation) return;
        player.addListener(_videoChanged);
        setState(() {});
        _mediaReady();
      } else {
        final bytes = await _client.loadImage(ad);
        if (!mounted || generation != _generation) return;
        setState(() => _image = bytes);
      }
      if (mounted && generation == _generation) {
        _timer = Timer.periodic(
          const Duration(milliseconds: 200),
          (_) => _measure(),
        );
      }
    } catch (error, stack) {
      DidnexInspector.capture(error, stack, stage: 'media_load');
      if (!mounted || generation != _generation) return;
      _fail(error is DidnexAdException ? error.code : 'media_load_error');
    }
  }

  void _mediaReady() {
    if (!mounted || _ad == null || _loadedNotified || _error != null) return;
    _ready = true;
    _loadedNotified = true;
    didnexIgnore(_client.measurementStart(_ad!));
    didnexIgnore(_client.report(_ad!, 'loaded', latency: _clock.elapsed));
    _emit(DidnexAdEventType.loaded);
  }

  void _fail(String code) {
    if (!mounted || _error != null) return;
    _timer?.cancel();
    _timer = null;
    _viewability.reset();
    final player = _video;
    _video = null;
    if (player != null) didnexIgnore(player.dispose());
    final ad = _ad;
    if (ad != null)
      didnexIgnore(
        _client.report(ad, 'error', latency: _clock.elapsed, code: code),
      );
    setState(() => _error = code);
    _emit(DidnexAdEventType.error, code: code);
  }

  void _videoChanged() {
    final player = _video;
    if (!mounted || player == null || _error != null) return;
    if (player.value.hasError) {
      _fail('video_playback_error');
      return;
    }
    // Rebuild only for play/pause state through ValueListenableBuilder below.
  }

  double _visibleFraction() {
    final root = _mediaKey.currentContext?.findRenderObject();
    RenderImage? image;
    void findImage(RenderObject node) {
      if (node is RenderImage) {
        image = node;
      } else if (image == null) {
        node.visitChildren(findImage);
      }
    }

    if (_ad?.diagnostic == false && _ad?.isVideo != true && root != null) {
      findImage(root);
    }
    final object = image ?? root;
    if (object is! RenderBox ||
        !object.attached ||
        !object.hasSize ||
        object.size.isEmpty) return 0;
    Rect local = Offset.zero & object.size;
    final pixels = image?.image;
    if (image != null && pixels != null) {
      // Letterbox padding is not painted ad media and cannot qualify a view.
      final fitted = applyBoxFit(
          image!.fit ?? BoxFit.scaleDown,
          Size(pixels.width / image!.scale, pixels.height / image!.scale),
          object.size);
      local = image!.alignment
          .resolve(image!.textDirection)
          .inscribe(fitted.destination, local);
    }
    final rect = object.localToGlobal(local.topLeft) & local.size;
    if (!rect.left.isFinite || !rect.top.isFinite) return 0;
    Rect visible = rect.intersect(Offset.zero & MediaQuery.sizeOf(context));
    RenderObject? ancestor = object.parent;
    while (ancestor != null) {
      if (ancestor is RenderOffstage && ancestor.offstage) return 0;
      if (ancestor is RenderOpacity && ancestor.opacity <= 0) return 0;
      if (ancestor is RenderBox &&
          (ancestor is RenderViewport ||
              ancestor is RenderShrinkWrappingViewport ||
              ancestor is RenderClipRect ||
              ancestor is RenderClipRRect ||
              ancestor is RenderClipPath)) {
        visible = visible.intersect(
          ancestor.localToGlobal(Offset.zero) & ancestor.size,
        );
      }
      ancestor = ancestor.parent;
    }
    if (visible.isEmpty) return 0;
    return (visible.width * visible.height / (rect.width * rect.height))
        .clamp(0.0, 1.0)
        .toDouble();
  }

  void _measure() {
    final ad = _ad;
    if (!mounted || ad == null || _error != null) return;
    if (ad.isExpired) {
      _timer?.cancel();
      _timer = null;
      _viewability.reset();
      final expiredPlayer = _video;
      _video = null;
      if (expiredPlayer != null) didnexIgnore(expiredPlayer.dispose());
      setState(() => _error = 'delivery_expired');
      _emit(DidnexAdEventType.expired, code: 'delivery_expired');
      return;
    }
    final visible =
        _resumed && _routeActive && _ready && _visibleFraction() >= .5;
    final player = _video;
    if (!visible && player?.value.isPlaying == true)
      didnexIgnore(player!.pause());
    if (visible &&
        player != null &&
        widget.autoPlayVideo &&
        DidnexPresentation(ad).autoplay &&
        !ad.isAudio &&
        !ad.format.isRewarded &&
        !_userPaused &&
        !player.value.isPlaying &&
        !player.value.isCompleted) didnexIgnore(player.play());
    if (player != null && _ready) _videoEvents(player);
    final playing = player == null ||
        (player.value.isPlaying &&
            !player.value.isBuffering &&
            player.value.position > Duration.zero);
    final qualified = _viewability.sample(
      _clock.elapsed,
      eligible: visible &&
          playing &&
          (!ad.isAudio || (player?.value.volume ?? 0) > 0),
      requiredDuration: player == null
          ? const Duration(seconds: 1)
          : const Duration(seconds: 2),
    );
    if (qualified && !_impressed && !_sending && _impressionAttempts < 3) {
      didnexIgnore(_countImpression(ad, _generation));
    }
  }

  Future<void> _countImpression(DidnexAd ad, int generation) async {
    _sending = true;
    _impressionAttempts++;
    try {
      await _client.track(ad, 'impression');
      if (!mounted || generation != _generation) return;
      _impressed = true;
      didnexIgnore(_client.report(ad, 'impression'));
      _emit(DidnexAdEventType.impression);
    } catch (_) {
      if (mounted && generation == _generation) {
        _viewability.reset();
        if (_impressionAttempts >= 3) _fail('impression_unavailable');
      }
    } finally {
      if (generation == _generation) _sending = false;
    }
  }

  int _audioWatched = 0, _audioPosition = 0, _audioWall = 0;
  Future<void> _videoQueue = Future.value();
  void _queueVideo(String kind) {
    final generation = _generation;
    _videoQueue = _videoQueue.then((_) async {
      if (mounted && generation == _generation && _error == null)
        await _trackVideo(kind);
    });
  }

  void _videoEvents(VideoPlayerController player) {
    final value = player.value, duration = player.value.duration.inMilliseconds;
    if (_ad?.isAudio == true) {
      final wall = _clock.elapsedMilliseconds,
          position = value.position.inMilliseconds,
          elapsed = wall - _audioWall,
          advance = position - _audioPosition;
      final eligible = _resumed &&
          _routeActive &&
          _ready &&
          _visibleFraction() >= .5 &&
          value.volume > 0 &&
          (value.isPlaying || value.isCompleted);
      if (eligible &&
          _audioWall > 0 &&
          advance >= 0 &&
          advance <= elapsed * 2 + 250)
        _audioWatched += advance.clamp(0, elapsed + 250).toInt();
      _audioWall = wall;
      _audioPosition = position;
      if (!eligible || duration <= 0) return;
      for (final entry in <String, double>{
        'start': 0,
        'firstQuartile': .25,
        'midpoint': .5,
        'thirdQuartile': .75
      }.entries) {
        if (_audioWatched >= duration * entry.value &&
            _milestones.add(entry.key)) _queueVideo(entry.key);
      }
      if (value.isCompleted &&
          _impressed &&
          _audioWatched + 300 >= duration &&
          _milestones.add('complete')) _queueVideo('complete');
      return;
    }
    if (duration <= 0) return;
    final position = value.position.inMilliseconds;
    if (position <= 0) return;
    for (final entry in <String, double>{
      'start': 0,
      'firstQuartile': .25,
      'midpoint': .5,
      'thirdQuartile': .75,
    }.entries) {
      if (position / duration >= entry.value && _milestones.add(entry.key)) {
        _queueVideo(entry.key);
      }
    }
    if (value.isCompleted && _milestones.add('complete'))
      _queueVideo('complete');
  }

  Future<void> _trackVideo(String kind) async {
    final ad = _ad;
    if (ad == null) return;
    final generation = _generation;
    try {
      for (var attempt = 0;; attempt++) {
        try {
          await _client.track(ad, kind);
          break;
        } on DidnexAdException catch (e) {
          if (e.statusCode != 409 || attempt >= 2) rethrow;
          await Future<void>.delayed(const Duration(milliseconds: 650));
        }
      }
      if (!mounted || generation != _generation) return;
      if (kind == 'start')
        _emit(ad.isAudio
            ? DidnexAdEventType.audioStart
            : DidnexAdEventType.videoStart);
      if (kind == 'complete')
        _emit(ad.isAudio
            ? DidnexAdEventType.audioComplete
            : DidnexAdEventType.videoComplete);
    } catch (_) {
      if (ad.format.isRewarded && mounted && generation == _generation)
        _fail('video_measurement_unavailable');
    }
  }

  Future<void> _click({int? card}) async {
    final ad = _ad;
    if (ad == null || ad.isExpired || !_resumed || !_routeActive || _clicking)
      return;
    _clicking = true;
    final generation = _generation;
    final clickTarget = card == null
        ? ad.clickUrl
        : ad.clickUrl.replace(
            queryParameters: {...ad.clickUrl.queryParameters, 'card': '$card'});
    try {
      if (_impressed && !ad.diagnostic) {
        try {
          await _client.track(ad, 'click');
        } catch (_) {
          _emit(DidnexAdEventType.error, code: 'click_measurement_unavailable');
        }
      }
      if (!mounted || generation != _generation || !_routeActive) return;
      await (_video?.pause() ?? Future.value());
      if (widget.openUrl != null)
        await widget.openUrl!(clickTarget);
      else {
        bool opened = false;
        if (ad.deepLink != null) {
          try {
            opened = await launchUrl(
                ad.deepLink!.replace(queryParameters: {
                  ...ad.deepLink!.queryParameters,
                  'didnex_click_id': ad.requestId
                }),
                mode: LaunchMode.externalNonBrowserApplication);
          } catch (_) {}
        }
        if (!opened &&
            !await launchUrl(
                ad.deepLink != null
                    ? clickTarget.replace(queryParameters: {
                        ...clickTarget.queryParameters,
                        'fallback': '1'
                      })
                    : clickTarget,
                mode: LaunchMode.externalApplication)) {
          throw const DidnexAdException('destination_unavailable');
        }
      }
      _emit(DidnexAdEventType.click);
    } catch (_) {
      if (mounted)
        _emit(DidnexAdEventType.error, code: 'destination_unavailable');
    } finally {
      _clicking = false;
    }
  }

  Future<void> _toggleVideo() async {
    final player = _video;
    if (player == null || !_resumed || !_routeActive) return;
    if (player.value.isPlaying) {
      _userPaused = true;
      await player.pause();
    } else if (!player.value.isCompleted && _visibleFraction() >= .5) {
      _userPaused = false;
      await player.play();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null)
      return widget.errorBuilder?.call(context, _error!) ??
          const SizedBox.shrink();
    if (_noFill != null)
      return widget.noFillBuilder?.call(context, _noFill!) ??
          const SizedBox.shrink();
    final ad = _ad;
    final frameGeneration = _generation;
    if (ad == null)
      return widget.loadingBuilder?.call(context) ?? const SizedBox.shrink();
    Widget media;
    final player = _video;
    if (ad.format == DidnexAdFormat.carousel ||
        ad.format == DidnexAdFormat.poll) {
      media = KeyedSubtree(
          key: _mediaKey,
          child: DidnexInteractive(
              key: ValueKey(ad.requestId),
              config: ad.playableConfig,
              origin: ad.creativeUrl,
              onReady: _mediaReady,
              onCard: (index) {
                didnexIgnore(_click(card: index));
              },
              onVote: (index) => _client.vote(ad, index)));
    } else if (ad.format == DidnexAdFormat.playable) {
      media = SizedBox(
          key: _mediaKey,
          child: DidnexPlayable(
              key: ValueKey(ad.requestId),
              config: ad.playableConfig,
              onReady: _mediaReady));
    } else if (ad.isAudio) {
      media = Container(
          key: _mediaKey,
          padding: const EdgeInsets.fromLTRB(12, 32, 12, 8),
          alignment: Alignment.centerRight,
          child: Row(children: [
            const Icon(Icons.graphic_eq, size: 24),
            const SizedBox(width: 8),
            Expanded(
                child: Text(ad.title,
                    maxLines: 2, overflow: TextOverflow.ellipsis)),
            const SizedBox(width: 110)
          ]));
    } else if (ad.isVideo) {
      media = player != null && player.value.isInitialized
          ? ConstrainedBox(
              key: _mediaKey,
              constraints: BoxConstraints(maxHeight: widget.maxMediaHeight),
              child: AspectRatio(
                aspectRatio: player.value.aspectRatio > 0
                    ? player.value.aspectRatio
                    : 16 / 9,
                child: VideoPlayer(player),
              ),
            )
          : const SizedBox(
              height: 160,
              child: Center(child: CircularProgressIndicator()),
            );
    } else {
      media = _image == null
          ? const SizedBox(
              height: 160,
              child: Center(child: CircularProgressIndicator()),
            )
          : ConstrainedBox(
              key: _mediaKey,
              constraints: BoxConstraints(maxHeight: widget.maxMediaHeight),
              child: Image.memory(
                _image!,
                width: double.infinity,
                fit: BoxFit.contain,
                cacheWidth: 1080,
                frameBuilder: (context, child, frame, synchronouslyLoaded) {
                  if (frame != null && !_loadedNotified)
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted && frameGeneration == _generation)
                        _mediaReady();
                    });
                  return child;
                },
                errorBuilder: (context, error, stack) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted && frameGeneration == _generation)
                      _fail('image_decode_error');
                  });
                  return const SizedBox.shrink();
                },
              ),
            );
    }
    final slot = ad.slot;
    final fallbackRatio = [DidnexAdFormat.banner, DidnexAdFormat.adaptiveBanner]
            .contains(ad.format)
        ? 6.4
        : ad.isAudio
            ? 320 / 96
            : ad.format == DidnexAdFormat.poll
                ? 320 / 300
                : 16 / 9;
    final rawRatio = slot['version'] == 1 ? slot['mediaAspectRatio'] : null;
    final slotRatio = rawRatio is num &&
            rawRatio.isFinite &&
            rawRatio >= .25 &&
            rawRatio <= 10
        ? rawRatio.toDouble()
        : fallbackRatio;
    final footerValue = slot['version'] == 1 ? slot['footerDp'] : null;
    final footer = footerValue is num
        ? footerValue.clamp(0, 100).toDouble()
        : [
            DidnexAdFormat.banner,
            DidnexAdFormat.adaptiveBanner,
            DidnexAdFormat.video,
            DidnexAdFormat.audio
          ].contains(ad.format)
            ? 0.0
            : 84.0;
    final originalMedia = media;
    media = LayoutBuilder(builder: (context, c) {
      final width = c.hasBoundedWidth ? c.maxWidth : 320.0;
      final height = ad.isAudio
          ? 96.0
          : (width / slotRatio).clamp(1.0, widget.maxMediaHeight).toDouble();
      return SizedBox(
          width: width,
          height: height,
          child: ClipRect(child: Center(child: originalMedia)));
    });
    final p = DidnexPresentation(ad);
    final badge = Material(
        color: const Color(0xf7ffffff),
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
            onTap: () => showDialog<void>(
                context: context,
                builder: (context) => AlertDialog(
                        title: Text(p.name),
                        content: const Text(
                            'این محتوا تبلیغ است. بدنه یا دکمه، صفحه تبلیغ‌دهنده را باز می‌کند.'),
                        actions: [
                          TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('متوجه شدم'))
                        ])),
            child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 170),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      if (p.logo != null)
                        Image.network(p.logo.toString(),
                            width: 22,
                            height: 22,
                            errorBuilder: (_, __, ___) =>
                                const SizedBox.shrink()),
                      const SizedBox(width: 5),
                      Flexible(
                          child: Text('${p.name} · تبلیغ',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  fontSize: 10, color: Color(0xff293970))))
                    ])))));
    final controls = player != null && player.value.isInitialized
        ? ValueListenableBuilder<VideoPlayerValue>(
            valueListenable: player,
            builder: (context, value, child) => Material(
                color: const Color(0xb317213e),
                borderRadius: BorderRadius.circular(24),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  if (ad.format.isRewarded &&
                      !value.isPlaying &&
                      value.position == Duration.zero)
                    TextButton(
                        onPressed: _toggleVideo,
                        child: const Text('تماشا و دریافت جایزه',
                            style: TextStyle(color: Colors.white))),
                  IconButton(
                      onPressed: value.isCompleted ? null : _toggleVideo,
                      tooltip: value.isPlaying ? 'توقف پخش' : 'شروع پخش',
                      color: Colors.white,
                      icon: Icon(
                          value.isPlaying ? Icons.pause : Icons.play_arrow)),
                  IconButton(
                      tooltip: value.volume == 0 ? 'فعال‌کردن صدا' : 'بی‌صدا',
                      onPressed: () => didnexIgnore(
                          player.setVolume(value.volume == 0 ? 1 : 0)),
                      color: Colors.white,
                      icon: Icon(value.volume == 0
                          ? Icons.volume_off
                          : Icons.volume_up)),
                ])))
        : const SizedBox.shrink();
    return Theme(
        data: Theme.of(context).copyWith(
            textTheme:
                Theme.of(context).textTheme.apply(fontFamily: _fontFamily)),
        child: Directionality(
            textDirection: TextDirection.rtl,
            child: DefaultTextStyle(
                style: TextStyle(
                    fontFamily: _fontFamily,
                    fontSize: 14,
                    height: 1.8,
                    color: p.text),
                child: Material(
                    color: p.surface,
                    borderRadius: BorderRadius.circular(p.radius),
                    clipBehavior: Clip.antiAlias,
                    child: Container(
                        decoration: BoxDecoration(
                            border: Border.all(color: p.border),
                            borderRadius: BorderRadius.circular(p.radius)),
                        child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Stack(children: [
                                if ([
                                      DidnexAdFormat.playable,
                                      DidnexAdFormat.carousel,
                                      DidnexAdFormat.poll
                                    ].contains(ad.format) ||
                                    ad.isAudio)
                                  media
                                else
                                  GestureDetector(
                                      behavior: HitTestBehavior.opaque,
                                      onTap: _click,
                                      child: media),
                                Positioned(
                                    top: 8,
                                    left: p.left ? 8 : null,
                                    right: p.left ? null : 8,
                                    child: badge),
                                if (player != null)
                                  Positioned(
                                      bottom: 8, left: 8, child: controls)
                              ]),
                              if (footer > 0)
                                SizedBox(
                                  height: footer,
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 8),
                                    child: Row(children: [
                                      Expanded(
                                          child: GestureDetector(
                                              onTap: _click,
                                              child: Column(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(ad.brand,
                                                      maxLines: 1,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                      style: const TextStyle(
                                                          fontSize: 10)),
                                                  Text(ad.title,
                                                      maxLines: 2,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                      style: const TextStyle(
                                                          fontSize: 12,
                                                          fontWeight:
                                                              FontWeight.w600)),
                                                ],
                                              ))),
                                      const SizedBox(width: 8),
                                      ConstrainedBox(
                                        constraints:
                                            const BoxConstraints(maxWidth: 130),
                                        child: FilledButton(
                                          style: FilledButton.styleFrom(
                                              backgroundColor: p.primary,
                                              foregroundColor: p.onPrimary,
                                              textStyle: TextStyle(
                                                  fontFamily: _fontFamily,
                                                  fontSize: 12)),
                                          onPressed: _click,
                                          child: Text(ad.cta,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis),
                                        ),
                                      ),
                                    ]),
                                  ),
                                ),
                            ]))))));
  }

  @override
  void dispose() {
    ++_generation;
    _timer?.cancel();
    _clock.stop();
    WidgetsBinding.instance.removeObserver(this);
    final player = _video;
    _video = null;
    if (player != null) didnexIgnore(player.dispose());
    if (_ad != null) {
      didnexIgnore(_client.measurementFinish(_ad!));
      didnexIgnore(_client.report(_ad!, 'destroy'));
    }
    if (_ownsClient) _client.close();
    super.dispose();
  }
}
