// Onboarding Tutorial Screen for new users
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Provider to track if tutorial has been shown
final tutorialSeenProvider = StateProvider<bool>((ref) => false);

/// Onboarding tutorial with feature highlights
class OnboardingTutorialScreen extends ConsumerStatefulWidget {
  const OnboardingTutorialScreen({super.key, required this.onComplete});

  final VoidCallback onComplete;

  @override
  ConsumerState<OnboardingTutorialScreen> createState() =>
      _OnboardingTutorialScreenState();
}

class _OnboardingTutorialScreenState
    extends ConsumerState<OnboardingTutorialScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<OnboardingPage> _pages = const [
    OnboardingPage(
      icon: Icons.account_balance,
      titleEn: 'Welcome to Mizan',
      titleAr: 'أهلاً بك في ميزان',
      bodyEn:
          'Your complete accounting solution for small businesses. Track transactions, manage inventory, and generate reports.',
      bodyAr:
          'نظام محاسبة متكامل للشركات الصغيرة. تتبع المعاملات، إدارة المخزون، وإنشاء التقارير.',
      color: Color(0xFF1E3A5F),
    ),
    OnboardingPage(
      icon: Icons.account_tree,
      titleEn: 'Chart of Accounts',
      titleAr: 'دليل الحسابات',
      bodyEn:
          'Organize your accounts by type: Assets, Liabilities, Equity, Revenue, and Expenses. Use hierarchies for detailed tracking.',
      bodyAr:
          'نظم حساباتك حسب النوع: الأصول، الالتزامات، حقوق الملكية، الإيرادات، والمصروفات.',
      color: Color(0xFF2E7D32),
    ),
    OnboardingPage(
      icon: Icons.receipt_long,
      titleEn: 'Track Transactions',
      titleAr: 'تتبع المعاملات',
      bodyEn:
          'Record sales, purchases, payments, and receipts. Every transaction creates a proper double-entry.',
      bodyAr:
          'سجل المبيعات والمشتريات والمدفوعات والمقبوضات. كل معاملة تُنشئ قيد مزدوج صحيح.',
      color: Color(0xFF7B1FA2),
    ),
    OnboardingPage(
      icon: Icons.precision_manufacturing,
      titleEn: 'Fixed Assets & Depreciation',
      titleAr: 'الأصول الثابتة والإهلاك',
      bodyEn:
          'Track equipment, vehicles, and property. Automatically calculate depreciation using multiple methods.',
      bodyAr:
          'تتبع المعدات والمركبات والعقارات. احسب الإهلاك تلقائياً باستخدام طرق متعددة.',
      color: Color(0xFFE65100),
    ),
    OnboardingPage(
      icon: Icons.bar_chart,
      titleEn: 'Financial Reports',
      titleAr: 'التقارير المالية',
      bodyEn:
          'Generate Balance Sheet, Income Statement, and Trial Balance reports instantly.',
      bodyAr:
          'أنشئ تقارير الميزانية العمومية وقائمة الدخل وميزان المراجعة فوراً.',
      color: Color(0xFF00838F),
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _completeTutorial();
    }
  }

  void _completeTutorial() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('tutorial_seen', true);
    ref.read(tutorialSeenProvider.notifier).state = true;
    widget.onComplete();
  }

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context);
    final isArabic = locale.languageCode == 'ar';

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Skip button
            Align(
              alignment: isArabic ? Alignment.topLeft : Alignment.topRight,
              child: TextButton(
                onPressed: _completeTutorial,
                child: Text(
                  isArabic ? 'تخطي' : 'Skip',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontSize: 16,
                  ),
                ),
              ),
            ),

            // Page content
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                itemCount: _pages.length,
                itemBuilder: (context, index) {
                  final page = _pages[index];
                  return _buildPage(page, isArabic);
                },
              ),
            ),

            // Page indicators
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _pages.length,
                (index) => AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  height: 8,
                  width: _currentPage == index ? 24 : 8,
                  decoration: BoxDecoration(
                    color: _currentPage == index
                        ? _pages[index].color
                        : Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 32),

            // Next/Done button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: FilledButton(
                  onPressed: _nextPage,
                  style: FilledButton.styleFrom(
                    backgroundColor: _pages[_currentPage].color,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    _currentPage == _pages.length - 1
                        ? (isArabic ? 'ابدأ الآن' : 'Get Started')
                        : (isArabic ? 'التالي' : 'Next'),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPage(OnboardingPage page, bool isArabic) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icon container
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: page.color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(page.icon, size: 60, color: page.color),
          ),
          const SizedBox(height: 40),

          // Title
          Text(
            isArabic ? page.titleAr : page.titleEn,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: page.color,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),

          // Body
          Text(
            isArabic ? page.bodyAr : page.bodyEn,
            style: TextStyle(fontSize: 16, color: Colors.grey.shade700),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

/// Data class for onboarding pages
class OnboardingPage {
  final IconData icon;
  final String titleEn;
  final String titleAr;
  final String bodyEn;
  final String bodyAr;
  final Color color;

  const OnboardingPage({
    required this.icon,
    required this.titleEn,
    required this.titleAr,
    required this.bodyEn,
    required this.bodyAr,
    required this.color,
  });
}
