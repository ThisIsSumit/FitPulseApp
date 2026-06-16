import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  int _page = 0;

  final _pages = [
    _OnboardingData(
      emoji: '🏋️',
      title: 'Train Smarter,\nNot Harder',
      subtitle:
          'AI-powered workout plans tailored to your goals, fitness level, and schedule.',
      gradient: AppColors.primaryGradient,
    ),
    _OnboardingData(
      emoji: '🥗',
      title: 'Fuel Your\nPerformance',
      subtitle:
          'Track nutrition, log meals instantly, and hit your macros every single day.',
      gradient: AppColors.purpleGradient,
    ),
    _OnboardingData(
      emoji: '🏆',
      title: 'Compete &\nConnect',
      subtitle:
          'Join challenges, celebrate wins with your community, and climb the leaderboard.',
      gradient: AppColors.orangeGradient,
    ),
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _next() {
    if (_page < _pages.length - 1) {
      _controller.nextPage(
          duration: const Duration(milliseconds: 350), curve: Curves.easeInOut);
    } else {
      context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      body: Stack(
        children: [
          // Background gradient blob
          Positioned(
            top: -100,
            right: -80,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 500),
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: _pages[_page].gradient,
              ),
            ).animate(key: ValueKey(_page)).fade(duration: 400.ms),
          ),
          Positioned(
            bottom: -60,
            left: -60,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 500),
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: _pages[_page].gradient,
              ),
            ).animate(key: ValueKey('b$_page')).fade(duration: 400.ms),
          ),

          // Blur overlay
          Positioned.fill(
            child: Container(
              color: AppColors.bgDark.withOpacity(0.85),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 20),
                // Skip button
                Align(
                  alignment: Alignment.centerRight,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 20),
                    child: TextButton(
                      onPressed: () => context.go('/login'),
                      child: const Text('Skip',
                          style: TextStyle(
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w600)),
                    ),
                  ),
                ),

                // Pages
                Expanded(
                  child: PageView.builder(
                    controller: _controller,
                    onPageChanged: (i) => setState(() => _page = i),
                    itemCount: _pages.length,
                    itemBuilder: (_, i) => _PageContent(data: _pages[i]),
                  ),
                ),

                // Indicator + button
                Padding(
                  padding: const EdgeInsets.fromLTRB(28, 0, 28, 40),
                  child: Column(
                    children: [
                      SmoothPageIndicator(
                        controller: _controller,
                        count: _pages.length,
                        effect: ExpandingDotsEffect(
                          activeDotColor: AppColors.primary,
                          dotColor: AppColors.bgSurface,
                          dotHeight: 8,
                          dotWidth: 8,
                          expansionFactor: 3,
                        ),
                      ),
                      const SizedBox(height: 32),
                      GradientButton(
                        label: _page == _pages.length - 1
                            ? 'Get Started'
                            : 'Continue',
                        onTap: _next,
                        gradient: _pages[_page].gradient,
                      ),
                      const SizedBox(height: 16),
                      if (_page == _pages.length - 1)
                        TextButton(
                          onPressed: () => context.go('/login'),
                          child: const Text(
                            'Already have an account? Sign In',
                            style: TextStyle(
                                color: AppColors.textSecondary, fontSize: 14),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PageContent extends StatelessWidget {
  final _OnboardingData data;

  const _PageContent({required this.data});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: constraints.maxHeight,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 140,
                    height: 140,
                    decoration: BoxDecoration(
                      gradient: data.gradient,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        data.emoji,
                        style: const TextStyle(fontSize: 64),
                      ),
                    ),
                  )
                      .animate()
                      .scale(
                        duration: 500.ms,
                        curve: Curves.elasticOut,
                      )
                      .fade(duration: 300.ms),
                  const SizedBox(height: 40),
                  Text(
                    data.title,
                    style: AppTextStyles.displayLarge.copyWith(height: 1.1),
                    textAlign: TextAlign.center,
                  )
                      .animate()
                      .fadeIn(delay: 150.ms, duration: 400.ms)
                      .slideY(begin: 0.3, end: 0),
                  const SizedBox(height: 16),
                  Text(
                    data.subtitle,
                    style: AppTextStyles.bodyLarge.copyWith(
                      color: AppColors.textSecondary,
                      height: 1.6,
                    ),
                    textAlign: TextAlign.center,
                  )
                      .animate()
                      .fadeIn(delay: 250.ms, duration: 400.ms)
                      .slideY(begin: 0.3, end: 0),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _OnboardingData {
  final String emoji;
  final String title;
  final String subtitle;
  final Gradient gradient;

  _OnboardingData({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.gradient,
  });
}
