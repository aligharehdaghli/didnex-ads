
import 'dart:math' as math;

import 'package:flutter/material.dart';

class DidnexInteractive extends StatefulWidget {
  const DidnexInteractive({
    super.key,
    required this.config,
    required this.origin,
    required this.onReady,
    required this.onCard,
    required this.onVote,
  });

  final Map<String, dynamic> config;
  final Uri origin;
  final VoidCallback onReady;
  final void Function(int) onCard;
  final Future<Map<String, dynamic>> Function(int) onVote;

  @override
  State<DidnexInteractive> createState() => _DidnexInteractiveState();
}

class _DidnexInteractiveState extends State<DidnexInteractive> {
  late final PageController _pages;

  int _page = 0;

  bool _ready = false;
  bool _voting = false;
  bool _voted = false;

  String? _error;
  List<dynamic>? _counts;

  bool get _isCarousel => widget.config['template'] == 'carousel';

  List<Map<String, dynamic>> get _cards {
    final raw = widget.config['cards'];

    if (raw is! List) return [];

    return raw
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList(growable: false);
  }

  List<String> get _options {
    final raw = widget.config['options'];

    if (raw is! List) return [];

    return raw.whereType<String>().toList(growable: false);
  }

  @override
  void initState() {
    super.initState();

    _pages = PageController(
      viewportFraction: 0.88,
    );
  }

  @override
  void didUpdateWidget(covariant DidnexInteractive oldWidget) {
    super.didUpdateWidget(oldWidget);

    final oldCards = _readCardCount(oldWidget.config);
    final newCards = _cards.length;

    if (oldCards != newCards) {
      _page = _page.clamp(
        0,
        newCards > 0 ? newCards - 1 : 0,
      ).toInt();

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !_pages.hasClients || newCards == 0) return;

        _pages.jumpToPage(_page);
      });
    }

    if (oldWidget.config['template'] != widget.config['template']) {
      _resetPoll();
    }
  }

  int _readCardCount(Map<String, dynamic> config) {
    final raw = config['cards'];

    if (raw is! List) return 0;

    return raw.whereType<Map>().length;
  }

  void _resetPoll() {
    _voting = false;
    _voted = false;
    _error = null;
    _counts = null;
  }

  void _notifyReady() {
    if (_ready) return;

    _ready = true;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) widget.onReady();
    });
  }

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _notifyReady();

    return _isCarousel ? _buildCarousel() : _buildPoll();
  }

  // ===========================================================================
  // RESPONSIVE CAROUSEL
  // ===========================================================================

  Widget _buildCarousel() {
    final cards = _cards;

    if (cards.isEmpty) {
      return const SizedBox.shrink();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;

        final hasLimitedHeight =
            constraints.maxHeight.isFinite;

        // Controls become smaller when the available height is limited.
        final controlsHeight = hasLimitedHeight
            ? (constraints.maxHeight * 0.22).clamp(18.0, 42.0)
            : 40.0;

        // If the parent specifies a height, use that height.
        // Otherwise calculate the height from the available width.
        final calculatedHeight = hasLimitedHeight
            ? constraints.maxHeight - controlsHeight
            : width * 0.42;

        final cardHeight = calculatedHeight.clamp(
          60.0,
          420.0,
        );

        // Hide controls when the widget is extremely small.
        final showControls = !hasLimitedHeight ||
            constraints.maxHeight >= 100;

        final currentPage = _page
            .clamp(0, cards.length - 1)
            .toInt();

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: cardHeight,
              child: PageView.builder(
                controller: _pages,
                itemCount: cards.length,
                onPageChanged: (index) {
                  if (_page == index) return;

                  setState(() {
                    _page = index;
                  });
                },
                itemBuilder: (context, index) {
                  return _buildCard(
                    cards[index],
                    index,
                  );
                },
              ),
            ),

            if (showControls)
              SizedBox(
                height: controlsHeight,
                child: _buildPageControls(
                  currentPage,
                  cards.length,
                ),
              ),
          ],
        );
      },
    );
  }

  // ===========================================================================
  // RESPONSIVE CARD
  // ===========================================================================

  Widget _buildCard(
    Map<String, dynamic> card,
    int index,
  ) {
    final imageUri = _getImageUri(card['imageUrl']);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Card(
        margin: const EdgeInsets.all(4),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => widget.onCard(index),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              final height = constraints.maxHeight;

              // Text size adapts to both card width and height.
              final widthScale = width / 260;
              final heightScale = height / 170;

              final scale = math.min(
                widthScale,
                heightScale,
              ).clamp(0.65, 1.35);

              final titleSize = 15.0 * scale;
              final descriptionSize = 12.0 * scale;
              final ctaSize = 12.0 * scale;

              final showDescription = height >= 135 &&
                  width >= 180 &&
                  card['description'] is String;

              final showCta = height >= 90 &&
                  width >= 140;

              final horizontalPadding =
                  (width * 0.045).clamp(8.0, 18.0);

              final bottomPadding =
                  (height * 0.07).clamp(5.0, 14.0);

              return Stack(
                fit: StackFit.expand,
                children: [
                  // Full-size background image.
                  if (imageUri != null)
                    Image.network(
                      imageUri.toString(),
                      fit: BoxFit.cover,
                      cacheWidth: 1000,
                      errorBuilder: (_, __, ___) {
                        return const ColoredBox(
                          color: Colors.black12,
                          child: Center(
                            child: Icon(
                              Icons.broken_image_outlined,
                              color: Colors.white,
                            ),
                          ),
                        );
                      },
                    )
                  else
                    const ColoredBox(
                      color: Colors.black12,
                      child: Center(
                        child: Text(
                          'تصویر در دسترس نیست',
                          style: TextStyle(
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),

                  // Responsive dark gradient.
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black12,
                          Colors.black87,
                        ],
                        stops: [
                          0.20,
                          0.55,
                          1.0,
                        ],
                      ),
                    ),
                  ),

                  // Responsive text overlay.
                  Positioned(
                    left: horizontalPadding,
                    right: horizontalPadding,
                    bottom: bottomPadding,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${card['title'] ?? ''}',
                          maxLines: height < 100 ? 1 : 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: titleSize,
                            height: 1.2,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        if (showDescription) ...[
                          SizedBox(height: 5 * scale),
                          Text(
                            card['description'] as String,
                            maxLines: height >= 190 ? 3 : 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: descriptionSize,
                              height: 1.25,
                            ),
                          ),
                        ],

                        if (showCta) ...[
                          SizedBox(height: 7 * scale),
                          Text(
                            '${card['cta'] ?? 'مشاهده'} ←',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: ctaSize,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // IMAGE URL VALIDATION
  // ===========================================================================

  Uri? _getImageUri(dynamic value) {
    if (value is! String || value.isEmpty) {
      return null;
    }

    final uri = Uri.tryParse(value);

    if (uri == null ||
        uri.scheme != 'https' ||
        uri.origin != widget.origin.origin) {
      return null;
    }

    return uri;
  }

  // ===========================================================================
  // PAGE CONTROLS
  // ===========================================================================

  Widget _buildPageControls(
    int page,
    int total,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxHeight < 32;

        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              visualDensity: VisualDensity.compact,
              padding: EdgeInsets.zero,
              constraints: BoxConstraints(
                minWidth: compact ? 24 : 36,
                minHeight: compact ? 24 : 36,
              ),
              tooltip: 'کارت قبلی',
              onPressed: page > 0
                  ? () => _changePage(page - 1)
                  : null,
              icon: const Icon(
                Icons.chevron_right,
                size: 22,
              ),
            ),

            Text(
              '${page + 1} / $total',
              style: TextStyle(
                fontSize: compact ? 10 : 12,
              ),
            ),

            IconButton(
              visualDensity: VisualDensity.compact,
              padding: EdgeInsets.zero,
              constraints: BoxConstraints(
                minWidth: compact ? 24 : 36,
                minHeight: compact ? 24 : 36,
              ),
              tooltip: 'کارت بعدی',
              onPressed: page < total - 1
                  ? () => _changePage(page + 1)
                  : null,
              icon: const Icon(
                Icons.chevron_left,
                size: 22,
              ),
            ),
          ],
        );
      },
    );
  }

  void _changePage(int page) {
    if (!_pages.hasClients) return;

    _pages.animateToPage(
      page,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  // ===========================================================================
  // POLL
  // ===========================================================================

  Widget _buildPoll() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;

        final scale = (width / 320).clamp(
          0.75,
          1.3,
        );

        final options = _options;

        return Padding(
          padding: EdgeInsets.all(16 * scale),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                '${widget.config['question'] ?? ''}',
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(
                      fontSize: 20 * scale,
                    ),
              ),

              SizedBox(height: 12 * scale),

              for (var i = 0; i < options.length; i++)
                _buildPollOption(
                  options[i],
                  i,
                  scale,
                ),

              if (_voting) ...[
                SizedBox(height: 8 * scale),
                const Center(
                  child: CircularProgressIndicator(),
                ),
              ],

              if (_voted) ...[
                SizedBox(height: 8 * scale),
                const Text('پاسخ ثبت شد'),
              ],

              if (_error != null) ...[
                SizedBox(height: 8 * scale),
                Text(
                  _error!,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.error,
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildPollOption(
    String option,
    int index,
    double scale,
  ) {
    final count = _counts != null && index < _counts!.length
        ? ' · ${_counts![index]}'
        : '';

    return Padding(
      padding: EdgeInsets.only(
        bottom: 8 * scale,
      ),
      child: OutlinedButton(
        onPressed: _voting || _voted
            ? null
            : () => _submitVote(index),
        child: Text(
          '$option$count',
          style: TextStyle(
            fontSize: 14 * scale,
          ),
        ),
      ),
    );
  }

  Future<void> _submitVote(int index) async {
    if (_voting || _voted) return;

    setState(() {
      _voting = true;
      _error = null;
    });

    try {
      if (widget.config['preview'] == true) {
        if (mounted) {
          setState(() {
            _voted = true;
          });
        }

        return;
      }

      final result = await widget.onVote(index);

      if (!mounted) return;

      setState(() {
        final counts = result['counts'];

        _counts = counts is List ? counts : null;
        _voted = true;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _error = 'پس از نمایش تبلیغ، دوباره تلاش کنید.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _voting = false;
        });
      }
    }
  }
}
