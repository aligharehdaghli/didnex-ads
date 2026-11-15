import 'package:didnex/widgets/app_open_ad_button.dart';
import 'package:didnex/widgets/rewarded_ad_button.dart';
import 'package:didnex/widgets/rewarded_interstitial_ad_button.dart';
import 'package:flutter/material.dart';

import 'package:didnex/widgets/adaptive_banner_ad.dart';
import 'package:didnex/widgets/audio_ad.dart';
import 'package:didnex/widgets/banner_ad.dart';
import 'package:didnex/widgets/carousel_ad.dart';
import 'package:didnex/widgets/native_ad.dart';
import 'package:didnex/widgets/native_video_ad.dart';
import 'package:didnex/widgets/playable_ad.dart';
import 'package:didnex/widgets/video_ad.dart';
import 'package:didnex/widgets/interstitial_ad_button.dart';

import '../widgets/poll_ad.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _refreshKey = 0;

  Future<void> _refreshAds() async {
    setState(() {
      _refreshKey++;
    });

    // فرصت کوتاهی برای نمایش انیمیشن رفرش
    await Future.delayed(const Duration(milliseconds: 500));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Didnex.com'),
        
      ),
      body: RefreshIndicator(
        onRefresh: _refreshAds,
        child: ListView(
          key: ValueKey(_refreshKey),
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          children: const [
            Text('محتوای برنامه'),
            SizedBox(height: 16),

            Text('تبلیغات نظر سنجی'),
            PollAd(),
            SizedBox(height: 16),

            Text('تبلیغات کاروسل'),
            CarouselAd(),
            SizedBox(height: 16),

            Text('تبلیغات صوتی'),
            AudioAd(),
            SizedBox(height: 16),

            Text('تبلیغ Playable'),
            SizedBox(height: 16),
            PlayableAd(),
            SizedBox(height: 16),

            Text('تبلیغ Banner'),
            SizedBox(height: 12),
            BannerAd(),
            SizedBox(height: 16),

            Text('تبلیغ Adaptive Banner'),
            SizedBox(height: 12),
            AdaptiveBannerAd(),
            SizedBox(height: 16),

            Text('تبلیغ Native'),
            SizedBox(height: 12),
            NativeAd(),
            SizedBox(height: 16),

            Text('تبلیغ Native Video'),
            SizedBox(height: 12),
            NativeVideoAd(),
            SizedBox(height: 16),

            Text('تبلیغ Video'),
            SizedBox(height: 12),
            VideoAd(),
            SizedBox(height: 16),

            Text('تبلیغ Interstitial'),
            SizedBox(height: 12),
            InterstitialAdButton(),
            SizedBox(height: 24),

            Text('تبلیغ Rewarded'),
            SizedBox(height: 12),
            RewardedAdButton(),
            SizedBox(height: 16),

            Text('تبلیغ Rewarded Interstitial'),
            SizedBox(height: 12),
            RewardedInterstitialAdButton(),
            SizedBox(height: 16),

            Text('تبلیغ App Open'),
            SizedBox(height: 8),
            AppOpenAdButton(),
          ],
        ),
      ),
    );
  }
}
