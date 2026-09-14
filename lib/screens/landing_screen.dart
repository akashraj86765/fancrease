import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../theme.dart';
import 'login_screen.dart';
import 'register_screen.dart';

class LandingScreen extends StatefulWidget {
  const LandingScreen({super.key});

  @override
  State<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends State<LandingScreen> {
  final _scrollController = ScrollController();
  final _platformsKey = GlobalKey();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToPlatforms() {
    final ctx = _platformsKey.currentContext;
    if (ctx != null) {
      Scrollable.ensureVisible(
        ctx,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        controller: _scrollController,
        child: Column(
          children: [
            const _Header(),
            _HeroWithAuth(onViewServices: _scrollToPlatforms),
            Container(key: _platformsKey, child: const _PlatformStrip()),
            const _Features(),
            const _HowItWorks(),
            const _Services(),
            const _Testimonials(),
            const _Faq(),
            const _FinalCta(),
            const _Footer(),
          ],
        ),
      ),
    );
  }
}

// ==========================================================
// PAGE WIDTH
// ==========================================================
class _PageWidth extends StatelessWidget {
  final Widget child;
  final double maxWidth;
  const _PageWidth({required this.child, this.maxWidth = 1200});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}

// ==========================================================
// HEADER
// ==========================================================
class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final isDesktop = w >= 1100;
    final isTablet = w >= 720 && w < 1100;
    final isTiny = w < 400;

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: AppColors.background,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: _PageWidth(
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: isTiny ? 12 : 24,
            vertical: 16,
          ),
          child: Row(
            children: [
              const _Logo(),
              const SizedBox(width: 32),
              if (isDesktop) ...[
                _NavLink('Services', () {}),
                _NavLink('API', () {}),
                _NavLink('Read Blog', () {}),
                _NavLink('Terms', () {}),
                _NavLink('Privacy Policy', () {}),
                _NavLink('Refund Policy', () {}),
              ],
              const Spacer(),
              if (isDesktop) ...[
                _TextBtn(
                  'Sign In',
                  () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const LoginScreen())),
                ),
                const SizedBox(width: 8),
                _PrimaryBtn(
                  'Sign Up',
                  () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const RegisterScreen())),
                ),
              ] else if (isTablet) ...[
                _NavLink('Services', () {}),
                _NavLink('API', () {}),
                const SizedBox(width: 12),
                _TextBtn(
                  'Sign In',
                  () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const LoginScreen())),
                ),
                const SizedBox(width: 8),
                _PrimaryBtn(
                  'Sign Up',
                  () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const RegisterScreen())),
                ),
              ] else ...[
                _CompactTextBtn(
                  'Sign In',
                  () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const LoginScreen())),
                ),
                const SizedBox(width: 4),
                _PrimaryBtn(
                  'Sign Up',
                  () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const RegisterScreen())),
                ),
                const SizedBox(width: 2),
                IconButton(
                  icon: const Icon(Icons.menu, color: AppColors.textPrimary),
                  onPressed: () => _openMenu(context),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _openMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.background,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              _menuTile(context, 'Sign In', () {
                Navigator.pop(context);
                Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()));
              }),
              _menuTile(context, 'Sign Up', () {
                Navigator.pop(context);
                Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const RegisterScreen()));
              }),
              const Divider(color: AppColors.border),
              _menuTile(context, 'Services', () => Navigator.pop(context)),
              _menuTile(context, 'API', () => Navigator.pop(context)),
              _menuTile(context, 'Read Blog', () => Navigator.pop(context)),
              const Divider(color: AppColors.border),
              _menuTile(context, 'Terms', () => Navigator.pop(context)),
              _menuTile(
                  context, 'Privacy Policy', () => Navigator.pop(context)),
              _menuTile(
                  context, 'Refund Policy', () => Navigator.pop(context)),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _menuTile(BuildContext context, String label, VoidCallback onTap) {
    return ListTile(
      title: Text(label,
          style: const TextStyle(color: AppColors.textPrimary, fontSize: 15)),
      onTap: onTap,
    );
  }
}

class _Logo extends StatelessWidget {
  const _Logo();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.bolt, color: Colors.white, size: 18),
        ),
        const SizedBox(width: 8),
        const Text(
          'Fancrease',
          style: TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
            letterSpacing: -0.5,
          ),
        ),
      ],
    );
  }
}

class _NavLink extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _NavLink(this.label, this.onTap);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(4),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}

class _TextBtn extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _TextBtn(this.label, this.onTap);

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onTap,
      style: TextButton.styleFrom(
        foregroundColor: AppColors.textPrimary,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        minimumSize: const Size(0, 40),
      ),
      child: Text(label,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
    );
  }
}

class _CompactTextBtn extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _CompactTextBtn(this.label, this.onTap);

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onTap,
      style: TextButton.styleFrom(
        foregroundColor: AppColors.textPrimary,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        minimumSize: const Size(0, 36),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: Text(label,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }
}

class _PrimaryBtn extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _PrimaryBtn(this.label, this.onTap);

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        elevation: 0,
        minimumSize: const Size(0, 40),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      child: Text(label,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
    );
  }
}

// ==========================================================
// HERO WITH INLINE AUTH
// ==========================================================
class _HeroWithAuth extends StatelessWidget {
  final VoidCallback onViewServices;
  const _HeroWithAuth({required this.onViewServices});

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final isMobile = w < 900;

    if (isMobile) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 60),
        child: _PageWidth(
          maxWidth: 560,
          child: Column(
            children: [
              _HeroText(onViewServices: onViewServices),
              const SizedBox(height: 40),
              const _AuthCard(),
            ],
          ),
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 100),
      child: _PageWidth(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
                flex: 6,
                child: _HeroText(onViewServices: onViewServices)),
            const SizedBox(width: 60),
            const Expanded(flex: 5, child: _AuthCard()),
          ],
        ),
      ),
    );
  }
}

class _HeroText extends StatelessWidget {
  final VoidCallback onViewServices;
  const _HeroText({required this.onViewServices});

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final isMobile = w < 900;
    final headlineSize = isMobile ? 34.0 : 54.0;

    return Column(
      crossAxisAlignment:
          isMobile ? CrossAxisAlignment.center : CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(30),
            border:
                Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.bolt, color: AppColors.primary, size: 14),
              SizedBox(width: 6),
              Text(
                'Trusted by 10,000+ Indian creators',
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'Grow your social\nmedia. Starting at ₹5.',
          textAlign: isMobile ? TextAlign.center : TextAlign.left,
          style: TextStyle(
            fontSize: headlineSize,
            height: 1.15,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
            letterSpacing: -2,
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'Real followers, likes, views, and subscribers for Instagram, YouTube, Facebook, and Telegram. No password needed. No hidden fees.',
          textAlign: isMobile ? TextAlign.center : TextAlign.left,
          style: TextStyle(
            fontSize: isMobile ? 15 : 16,
            color: AppColors.textSecondary,
            height: 1.6,
          ),
        ),
        const SizedBox(height: 32),
        Wrap(
          alignment: isMobile ? WrapAlignment.center : WrapAlignment.start,
          spacing: 12,
          runSpacing: 12,
          children: [
            ElevatedButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const RegisterScreen()),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 28, vertical: 18),
                elevation: 0,
                minimumSize: const Size(0, 52),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Get Started Free',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
              ),
            ),
            OutlinedButton(
              onPressed: onViewServices,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.textPrimary,
                side: const BorderSide(color: AppColors.border, width: 1.5),
                padding:
                    const EdgeInsets.symmetric(horizontal: 28, vertical: 18),
                minimumSize: const Size(0, 52),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'View Services',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ==========================================================
// INLINE AUTH CARD
// ==========================================================
class _AuthCard extends StatefulWidget {
  const _AuthCard();

  @override
  State<_AuthCard> createState() => _AuthCardState();
}

class _AuthCardState extends State<_AuthCard> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    setState(() => _error = null);

    if (_emailController.text.trim().isEmpty ||
        _passwordController.text.trim().isEmpty) {
      setState(() => _error = 'Please fill in both fields.');
      return;
    }

    final auth = context.read<AuthProvider>();
    final ok = await auth.login(
      _emailController.text.trim(),
      _passwordController.text.trim(),
    );

    if (!ok && mounted && auth.error != null) {
      setState(() => _error = auth.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Sign in to your account',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Access your dashboard instantly.',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            style:
                const TextStyle(color: AppColors.textPrimary, fontSize: 14),
            decoration: const InputDecoration(
              labelText: 'Email',
              prefixIcon:
                  Icon(Icons.email_outlined, color: AppColors.textMuted),
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _passwordController,
            obscureText: true,
            style:
                const TextStyle(color: AppColors.textPrimary, fontSize: 14),
            decoration: const InputDecoration(
              labelText: 'Password',
              prefixIcon:
                  Icon(Icons.lock_outline, color: AppColors.textMuted),
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: AppColors.error.withValues(alpha: 0.25)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline,
                      color: AppColors.error, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(_error!,
                        style: const TextStyle(
                            color: AppColors.error, fontSize: 12)),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 20),
          SizedBox(
            height: 50,
            child: ElevatedButton(
              onPressed: auth.isLoading ? null : _login,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: auth.isLoading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Text(
                      'Sign In',
                      style: TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w700),
                    ),
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: Wrap(
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                const Text(
                  "Don't have an account? ",
                  style: TextStyle(
                      color: AppColors.textSecondary, fontSize: 13),
                ),
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const RegisterScreen()),
                    ),
                    borderRadius: BorderRadius.circular(4),
                    child: const Padding(
                      padding:
                          EdgeInsets.symmetric(horizontal: 2, vertical: 2),
                      child: Text(
                        'Register now',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
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

// ==========================================================
// PLATFORM STRIP — 5 platforms with brand icons
// ==========================================================
class _PlatformStrip extends StatelessWidget {
  const _PlatformStrip();

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final isMobile = w < 720;
    final isTablet = w >= 720 && w < 1100;
    final isWide = w >= 1100;

    final items = <Map<String, dynamic>>[
      {
        'name': 'Instagram',
        'icon': FontAwesomeIcons.instagram,
        'color': AppColors.instagram,
        'from': '₹5',
      },
      {
        'name': 'YouTube',
        'icon': FontAwesomeIcons.youtube,
        'color': AppColors.youtube,
        'from': '₹18',
      },
      {
        'name': 'Facebook',
        'icon': FontAwesomeIcons.facebookF,
        'color': AppColors.facebook,
        'from': '₹22',
      },
      {
        'name': 'Telegram',
        'icon': FontAwesomeIcons.telegram,
        'color': AppColors.telegram,
        'from': '₹42',
      },
      {
        'name': 'Website Traffic',
        'icon': FontAwesomeIcons.globe,
        'color': const Color(0xFF10B981),
        'from': '₹15',
      },
    ];

    final cardWidth = isMobile
        ? 300.0
        : isTablet
            ? (w - 48 - 16) / 2
            : isWide
                ? (1200 - 64) / 5
                : 220.0;

    return Container(
      width: double.infinity,
      color: AppColors.surface,
      padding: EdgeInsets.symmetric(
        horizontal: 24,
        vertical: isMobile ? 60 : 80,
      ),
      child: _PageWidth(
        child: Column(
          children: [
            const Text(
              'Platforms we support',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
                letterSpacing: -0.8,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Five platforms that matter most for Indian creators.',
              textAlign: TextAlign.center,
              style:
                  TextStyle(color: AppColors.textSecondary, fontSize: 14),
            ),
            const SizedBox(height: 40),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 14,
              runSpacing: 14,
              children: items
                  .map((p) => SizedBox(
                        width: cardWidth,
                        child: _PlatformTile(
                          name: p['name'] as String,
                          icon: p['icon'] as FaIconData,
                          color: p['color'] as Color,
                          from: p['from'] as String,
                        ),
                      ))
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlatformTile extends StatelessWidget {
  final String name;
  final FaIconData icon;
  final Color color;
  final String from;

  const _PlatformTile({
    required this.name,
    required this.icon,
    required this.color,
    required this.from,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 170,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: FaIcon(icon, color: color, size: 18),
          ),
          const SizedBox(height: 14),
          Text(
            name,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.3,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const Spacer(),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text('From ',
                  style: TextStyle(
                      color: AppColors.textMuted, fontSize: 10)),
              Text(
                from,
                style: TextStyle(
                  color: color,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(width: 2),
              const Text('/1000',
                  style: TextStyle(
                      color: AppColors.textMuted, fontSize: 9)),
            ],
          ),
        ],
      ),
    );
  }
}

// ==========================================================
// FEATURES
// ==========================================================
class _Features extends StatelessWidget {
  const _Features();

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final isMobile = w < 720;
    final isTablet = w >= 720 && w < 1100;

    final items = [
      {'icon': Icons.verified_rounded, 'title': 'Fantastic Services', 'desc': 'Quality that surprises. Try our cheapest SMM services.'},
      {'icon': Icons.payments_rounded, 'title': 'Many Payment Methods', 'desc': 'UPI, cards, netbanking, crypto — fund your way.'},
      {'icon': Icons.local_offer_rounded, 'title': 'Superb Prices', 'desc': 'We keep prices low. Compare with any panel.'},
      {'icon': Icons.flash_on_rounded, 'title': 'Instant Results', 'desc': 'Orders deliver faster than you expect.'},
      {'icon': Icons.support_agent_rounded, 'title': '24/7 Support', 'desc': 'Dedicated team, round the clock.'},
      {'icon': Icons.gps_fixed_rounded, 'title': 'Targeted Engagement', 'desc': 'Reach by country, region, or city.'},
    ];

    final cardWidth = isMobile
        ? double.infinity
        : isTablet
            ? (w - 48 - 20) / 2
            : 340.0;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: 24,
        vertical: isMobile ? 60 : 100,
      ),
      child: _PageWidth(
        child: Column(
          children: [
            const Text(
              'Why choose Fancrease?',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
                letterSpacing: -1,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Everything you need to manage social media marketing campaigns.',
              textAlign: TextAlign.center,
              style:
                  TextStyle(color: AppColors.textSecondary, fontSize: 15),
            ),
            const SizedBox(height: 48),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 20,
              runSpacing: 20,
              children: items
                  .map((f) => SizedBox(
                        width:
                            cardWidth == double.infinity ? 320 : cardWidth,
                        child: _FeatureTile(
                          icon: f['icon'] as IconData,
                          title: f['title'] as String,
                          desc: f['desc'] as String,
                        ),
                      ))
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeatureTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String desc;
  const _FeatureTile({
    required this.icon,
    required this.title,
    required this.desc,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 180,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppColors.primary, size: 20),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 6),
          Expanded(
            child: Text(
              desc,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ==========================================================
// HOW IT WORKS
// ==========================================================
class _HowItWorks extends StatelessWidget {
  const _HowItWorks();

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final isMobile = w < 720;
    final isTablet = w >= 720 && w < 1100;

    final steps = [
      {'n': '1', 't': 'Sign up & log in', 'd': 'Create a free account in seconds.'},
      {'n': '2', 't': 'Make a deposit', 'd': 'Add funds via your preferred method.'},
      {'n': '3', 't': 'Place an order', 'd': 'Pick a service and submit your link.'},
      {'n': '4', 't': 'Quick results', 'd': 'Sit back — your order completes fast.'},
    ];

    final cardWidth = isMobile
        ? double.infinity
        : isTablet
            ? (w - 48 - 16) / 2
            : 260.0;

    return Container(
      width: double.infinity,
      color: AppColors.surface,
      padding: EdgeInsets.symmetric(
        horizontal: 24,
        vertical: isMobile ? 60 : 100,
      ),
      child: _PageWidth(
        child: Column(
          children: [
            const Text(
              'Our work process',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
                letterSpacing: -1,
              ),
            ),
            const SizedBox(height: 48),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 16,
              runSpacing: 20,
              children: steps
                  .map((s) => SizedBox(
                        width:
                            cardWidth == double.infinity ? 320 : cardWidth,
                        child: _StepTile(
                          number: s['n']!,
                          title: s['t']!,
                          desc: s['d']!,
                        ),
                      ))
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }
}

class _StepTile extends StatelessWidget {
  final String number;
  final String title;
  final String desc;
  const _StepTile({
    required this.number,
    required this.title,
    required this.desc,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: const BoxDecoration(
            color: AppColors.primary,
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Text(
            number,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          title,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          desc,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 13,
            height: 1.5,
          ),
        ),
      ],
    );
  }
}

// ==========================================================
// SERVICES PREVIEW
// ==========================================================
class _Services extends StatelessWidget {
  const _Services();

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final isMobile = w < 720;
    final isTablet = w >= 720 && w < 1100;

    final services = [
      {'name': 'Instagram Followers', 'price': '₹29.90', 'tag': 'Best seller'},
      {'name': 'Instagram Likes', 'price': '₹8.50', 'tag': 'Fastest'},
      {'name': 'YouTube Views', 'price': '₹18.20', 'tag': 'High retention'},
      {'name': 'YouTube Subscribers', 'price': '₹62.00', 'tag': 'Non-drop'},
      {'name': 'Facebook Page Likes', 'price': '₹22.00', 'tag': 'Real users'},
      {'name': 'Website Traffic', 'price': '₹15.00', 'tag': 'AdSense safe'},
    ];

    final cardWidth = isMobile
        ? double.infinity
        : isTablet
            ? (w - 48 - 14) / 2
            : 380.0;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: 24,
        vertical: isMobile ? 60 : 100,
      ),
      child: _PageWidth(
        child: Column(
          children: [
            const Text(
              'Popular services',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
                letterSpacing: -1,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Real prices. No hidden fees. No subscription.',
              textAlign: TextAlign.center,
              style:
                  TextStyle(color: AppColors.textSecondary, fontSize: 15),
            ),
            const SizedBox(height: 48),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 14,
              runSpacing: 14,
              children: services
                  .map((s) => SizedBox(
                        width:
                            cardWidth == double.infinity ? 320 : cardWidth,
                        child: _ServiceCard(
                          name: s['name']!,
                          price: s['price']!,
                          tag: s['tag']!,
                        ),
                      ))
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }
}

class _ServiceCard extends StatelessWidget {
  final String name;
  final String price;
  final String tag;
  const _ServiceCard({
    required this.name,
    required this.price,
    required this.tag,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    tag,
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                price,
                style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
              const Text(
                '/1000',
                style:
                    TextStyle(color: AppColors.textMuted, fontSize: 10),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ==========================================================
// TESTIMONIALS
// ==========================================================
class _Testimonials extends StatelessWidget {
  const _Testimonials();

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final isMobile = w < 720;
    final isTablet = w >= 720 && w < 1100;

    final items = [
      {'name': 'Priya M.', 'role': 'Fashion creator', 'text': 'Grew from 2K to 48K followers in 4 months. Orders start within seconds and engagement looks totally natural.'},
      {'name': 'Arjun S.', 'role': 'Boutique owner', 'text': 'Spent ₹500 on Instagram promo. Got ₹15,000 in real orders. Best investment this year.'},
      {'name': 'Nisha K.', 'role': 'YouTuber', 'text': 'Crossed 10K subscribers in 6 weeks. Views are from real users. Zero issues so far.'},
    ];

    final cardWidth = isMobile
        ? double.infinity
        : isTablet
            ? (w - 48 - 20) / 2
            : 360.0;

    return Container(
      width: double.infinity,
      color: AppColors.surface,
      padding: EdgeInsets.symmetric(
        horizontal: 24,
        vertical: isMobile ? 60 : 100,
      ),
      child: _PageWidth(
        child: Column(
          children: [
            const Text(
              'Success stories',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
                letterSpacing: -1,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Wondering what other customers think? See reviews below.',
              textAlign: TextAlign.center,
              style:
                  TextStyle(color: AppColors.textSecondary, fontSize: 15),
            ),
            const SizedBox(height: 48),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 20,
              runSpacing: 20,
              children: items
                  .map((t) => SizedBox(
                        width:
                            cardWidth == double.infinity ? 320 : cardWidth,
                        child: _TestimonialCard(
                          name: t['name']!,
                          role: t['role']!,
                          text: t['text']!,
                        ),
                      ))
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }
}

class _TestimonialCard extends StatelessWidget {
  final String name;
  final String role;
  final String text;
  const _TestimonialCard({
    required this.name,
    required this.role,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: List.generate(
              5,
              (_) => const Icon(Icons.star,
                  color: Color(0xFFFBBF24), size: 16),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            '"$text"',
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 14,
              height: 1.65,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            name,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            role,
            style:
                const TextStyle(color: AppColors.textMuted, fontSize: 11),
          ),
        ],
      ),
    );
  }
}

// ==========================================================
// FAQ
// ==========================================================
class _Faq extends StatelessWidget {
  const _Faq();

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final isMobile = w < 720;

    final items = [
      {'q': 'What is an SMM Panel and why do you need one?', 'a': 'An SMM panel helps you grow your social media presence. It provides likes, followers, views, and other engagement services you can order in bulk at lower cost.'},
      {'q': 'Is it safe to order SMM services on your panel?', 'a': 'Yes. Our services are compliance-friendly and won\'t get your accounts banned. We never ask for your password.'},
      {'q': 'What are the cheapest SMM panels?', 'a': 'An SMM panel is an online store selling services at the cheapest rate. If you want to grow fast, you can buy followers and likes from us at low prices starting at ₹5.'},
      {'q': 'What does "mass order" mean?', 'a': 'This feature lets you place several orders with different links at once — perfect for agencies handling multiple clients.'},
      {'q': 'What does "drip-feed" mean?', 'a': 'Drip-feed spreads your order over time to look natural. For example, 2000 likes could be delivered as 200/day for 10 days.'},
    ];

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: 24,
        vertical: isMobile ? 60 : 100,
      ),
      child: _PageWidth(
        maxWidth: 800,
        child: Column(
          children: [
            const Text(
              'Frequently asked questions',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
                letterSpacing: -1,
              ),
            ),
            const SizedBox(height: 48),
            ...items.map((f) => _FaqTile(q: f['q']!, a: f['a']!)),
          ],
        ),
      ),
    );
  }
}

class _FaqTile extends StatefulWidget {
  final String q;
  final String a;
  const _FaqTile({required this.q, required this.a});

  @override
  State<_FaqTile> createState() => _FaqTileState();
}

class _FaqTileState extends State<_FaqTile> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: _open
              ? AppColors.primary.withValues(alpha: 0.4)
              : AppColors.border,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => setState(() => _open = !_open),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        widget.q,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Icon(
                      _open ? Icons.remove : Icons.add,
                      color: AppColors.primary,
                      size: 20,
                    ),
                  ],
                ),
                if (_open) ...[
                  const SizedBox(height: 12),
                  Text(
                    widget.a,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                      height: 1.65,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ==========================================================
// FINAL CTA
// ==========================================================
class _FinalCta extends StatelessWidget {
  const _FinalCta();

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final isMobile = w < 720;

    return Container(
      width: double.infinity,
      color: AppColors.surface,
      padding: EdgeInsets.symmetric(
        horizontal: 24,
        vertical: isMobile ? 60 : 80,
      ),
      child: _PageWidth(
        maxWidth: 1000,
        child: Container(
          padding: EdgeInsets.all(isMobile ? 32 : 56),
          decoration: BoxDecoration(
            color: AppColors.textPrimary,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            children: [
              Text(
                'Ready to grow?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: isMobile ? 28 : 40,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: -1.5,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Join 10,000+ Indian creators growing with Fancrease.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Color(0xFF94A3B8), fontSize: 15),
              ),
              const SizedBox(height: 32),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 12,
                runSpacing: 12,
                children: [
                  ElevatedButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const RegisterScreen()),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 32, vertical: 18),
                      elevation: 0,
                      minimumSize: const Size(0, 52),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Create Free Account',
                      style: TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w700),
                    ),
                  ),
                  OutlinedButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const LoginScreen()),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Color(0xFF334155)),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 32, vertical: 18),
                      minimumSize: const Size(0, 52),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Sign In',
                      style: TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ==========================================================
// FOOTER
// ==========================================================
class _Footer extends StatelessWidget {
  const _Footer();

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final isMobile = w < 720;

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: AppColors.background,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: _PageWidth(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
          child: Column(
            children: [
              if (!isMobile)
                Row(
                  children: [
                    const _Logo(),
                    const Spacer(),
                    _FooterLink('Services', () {}),
                    _FooterLink('API', () {}),
                    _FooterLink('Read Blog', () {}),
                    _FooterLink('Terms', () {}),
                    _FooterLink('Privacy Policy', () {}),
                    _FooterLink('Refund Policy', () {}),
                  ],
                )
              else
                Column(
                  children: [
                    const _Logo(),
                    const SizedBox(height: 20),
                    Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 16,
                      runSpacing: 8,
                      children: [
                        _FooterLink('Services', () {}),
                        _FooterLink('API', () {}),
                        _FooterLink('Read Blog', () {}),
                        _FooterLink('Terms', () {}),
                        _FooterLink('Privacy Policy', () {}),
                        _FooterLink('Refund Policy', () {}),
                      ],
                    ),
                  ],
                ),
              const SizedBox(height: 30),
              const Text(
                '© 2026 Fancrease. All rights reserved.',
                style:
                    TextStyle(color: AppColors.textMuted, fontSize: 11),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FooterLink extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _FooterLink(this.label, this.onTap);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(4),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}