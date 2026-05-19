import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_button.dart';

class _OnboardingSlide {
  final String emoji;
  final String title;
  final String subtitle;

  const _OnboardingSlide({
    required this.emoji,
    required this.title,
    required this.subtitle,
  });
}

const _slides = [
  _OnboardingSlide(
    emoji: '💸',
    title: 'Track Every Rupee',
    subtitle:
        'Add expenses in seconds. Stay on top of where your money goes without the hassle.',
  ),
  _OnboardingSlide(
    emoji: '📊',
    title: 'Understand Your Patterns',
    subtitle:
        'Visual charts break down your spending by category and time — insights that actually make sense.',
  ),
  _OnboardingSlide(
    emoji: '🤖',
    title: 'AI-Powered Insights',
    subtitle:
        'Type any expense and Fluxo automatically categorizes it. Smart finance, zero effort.',
  ),
];

/// 3-slide onboarding shown only on first launch.
class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final _controller = PageController();
  int _page = 0;

  Future<void> _complete() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.onboardingCompleteKey, true);
    if (mounted) context.go(AppConstants.routeLogin);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // ── Skip button ───────────────────────────────────────────────
            Align(
              alignment: Alignment.topRight,
              child: TextButton(
                onPressed: _complete,
                child: Text(
                  'Skip',
                  style: AppTextStyles.labelLarge.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ),

            // ── Page view ─────────────────────────────────────────────────
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: _slides.length,
                onPageChanged: (i) => setState(() => _page = i),
                itemBuilder: (_, i) => _SlidePage(slide: _slides[i]),
              ),
            ),

            // ── Page indicators ───────────────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _slides.length,
                (i) => AnimatedContainer(
                  duration: AppConstants.animFast,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: _page == i ? 24 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _page == i
                        ? AppColors.primary
                        : AppColors.textDisabled,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),

            // ── Action button ─────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: AppButton(
                label: _page == _slides.length - 1 ? 'Get Started' : 'Next',
                onPressed: () {
                  if (_page == _slides.length - 1) {
                    _complete();
                  } else {
                    _controller.nextPage(
                      duration: AppConstants.animNormal,
                      curve: Curves.easeInOut,
                    );
                  }
                },
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class _SlidePage extends StatelessWidget {
  final _OnboardingSlide slide;

  const _SlidePage({required this.slide});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(slide.emoji, style: const TextStyle(fontSize: 80)),
          const SizedBox(height: 40),
          Text(
            slide.title,
            style: AppTextStyles.headlineLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            slide.subtitle,
            style: AppTextStyles.bodyLarge.copyWith(
              color: AppColors.textSecondary,
              height: 1.6,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
