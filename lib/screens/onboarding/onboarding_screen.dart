// Multi-page onboarding flow for first-time Vynex V2 users.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../widgets/common/vynex_button.dart';
import 'onboarding_page.dart';

/// Five-slide onboarding shown before PIN setup on fresh installs.
class OnboardingScreen extends StatefulWidget {
  /// Creates the onboarding screen.
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  static const int _pageCount = 5;

  final PageController _pageController = PageController();
  int _currentPage = 0;

  static const List<OnboardingPage> _pages = [
    OnboardingPage(
      icon: Icons.inventory_2_rounded,
      title: 'Welcome to Vynex',
      subtitle:
          'Your complete offline business manager. '
          'Track sales, stock, customers and more. '
          'No internet needed, ever.',
      highlight: 'Works 100% offline on your phone',
    ),
    OnboardingPage(
      icon: Icons.qr_code_scanner_rounded,
      title: 'Smart Product Catalog',
      subtitle:
          'Add your products once and track their '
          'stock automatically. Scan barcodes or '
          'search by name. Know what you have at '
          'a glance.',
      highlight: 'Stock updates when you sell or restock',
    ),
    OnboardingPage(
      icon: Icons.point_of_sale_rounded,
      iconColor: AppColors.success,
      iconBgColor: AppColors.onboardingSuccessBg,
      title: 'Track Every Sale',
      subtitle:
          'Record sales from your stock, spot buys '
          'or services. Profit is calculated '
          'automatically. Accept Cash, M-Pesa '
          'or Paybill.',
      highlight: 'Spot buy: sell items you got on the spot',
    ),
    OnboardingPage(
      icon: Icons.people_rounded,
      iconColor: AppColors.customerBlue,
      iconBgColor: AppColors.onboardingCustomerBg,
      title: 'Know Your Customers',
      subtitle:
          'Build a customer database and track '
          'everything they have bought. Generate '
          'professional invoices and share them '
          'via WhatsApp instantly.',
    ),
    OnboardingPage(
      icon: Icons.bar_chart_rounded,
      title: 'Understand Your Business',
      subtitle:
          'View daily and monthly charts, filter '
          'by payment method, see your top products, '
          'and export everything to Excel. Make '
          'smarter decisions.',
      highlight: 'Export to Excel and share reports',
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _goToPage(int page) {
    _pageController.animateToPage(
      page,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOut,
    );
  }

  void _onNext() {
    if (_currentPage < _pageCount - 1) {
      _goToPage(_currentPage + 1);
    }
  }

  void _onSkip() {
    _goToPage(_pageCount - 1);
  }

  Future<void> _onGetStarted() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_complete', true);
    if (!mounted) return;
    context.go(AppRoutes.splash);
  }

  @override
  Widget build(BuildContext context) {
    final isLastPage = _currentPage == _pageCount - 1;

    return Scaffold(
      backgroundColor: AppColors.black,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              flex: 3,
              child: PageView.builder(
                controller: _pageController,
                itemCount: _pageCount,
                onPageChanged: (index) {
                  setState(() => _currentPage = index);
                },
                itemBuilder: (context, index) => _pages[index],
              ),
            ),
            SizedBox(
              height: 160,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(_pageCount, (index) {
                        final isActive = index == _currentPage;
                        return Container(
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isActive
                                ? AppColors.gold
                                : AppColors.darkGrey,
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 16),
                    if (isLastPage)
                      VynexButton.primary(
                        label: 'Get Started',
                        onPressed: _onGetStarted,
                      )
                    else
                      Row(
                        children: [
                          TextButton(
                            onPressed: _onSkip,
                            child: const Text(
                              'Skip',
                              style: TextStyle(color: AppColors.midGrey),
                            ),
                          ),
                          const Spacer(),
                          ElevatedButton(
                            onPressed: _onNext,
                            child: const Text('Next'),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
