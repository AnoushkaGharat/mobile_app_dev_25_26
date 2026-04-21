import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;
import 'dart:ui';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
  ));
  runApp(const FBLAApp());
}

const kNavy        = Color(0xFF0B2463);
const kNavyLight   = Color(0xFF1A3A7A);
const kNavyGlass   = Color(0x220B2463);
const kGold        = Color(0xFFF5A623);
const kGoldLight   = Color(0xFFFFD97D);
const kGoldGlass   = Color(0x33F5A623);
const kGoldBorder  = Color(0x66F5A623);
const kWhite       = Colors.white;
const kBg          = Color(0xFFF0F4FF);
const kBgWarm      = Color(0xFFFFF8EE);
const kText        = Color(0xFF0B2463);
const kMuted       = Color(0xFF6B7A99);
const kBorder      = Color(0x220B2463);
const kGlassWhite  = Color(0xCCFFFFFF);
const kGlassCard   = Color(0xB3FFFFFF);
const kRed         = Color(0xFFE53E3E);
const kGreen       = Color(0xFF38A169);
const kTeal        = Color(0xFF0EA5A0);

class FBLAApp extends StatelessWidget {
  const FBLAApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'FBLA Link',
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: kBg,
        colorScheme: ColorScheme.fromSeed(seedColor: kNavy),
        fontFamily: 'Nunito',
      ),
      home: const Shell(),
    );
  }
}

class Shell extends StatefulWidget {
  const Shell({super.key});
  @override
  State<Shell> createState() => _ShellState();
}

class _ShellState extends State<Shell> with TickerProviderStateMixin {
  int _tab = 0;
  late List<AnimationController> _navCtrls;

  static const _pages = [DashboardPage(), EventsPage(), ReportsPage(), ProfilePage()];

  @override
  void initState() {
    super.initState();
    _navCtrls = List.generate(4, (i) => AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
      value: i == 0 ? 1.0 : 0.0,
    ));
  }

  @override
  void dispose() {
    for (final c in _navCtrls) c.dispose();
    super.dispose();
  }

  void _onTap(int i) {
    if (_tab == i) return;
    _navCtrls[_tab].reverse();
    _navCtrls[i].forward();
    setState(() => _tab = i);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 320),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeIn,
        transitionBuilder: (child, anim) => FadeTransition(
          opacity: anim,
          child: SlideTransition(
            position: Tween<Offset>(begin: const Offset(0, 0.03), end: Offset.zero).animate(anim),
            child: child,
          ),
        ),
        child: KeyedSubtree(key: ValueKey(_tab), child: _pages[_tab]),
      ),
      bottomNavigationBar: _GlassNav(current: _tab, controllers: _navCtrls, onTap: _onTap),
    );
  }
}

class _GlassNav extends StatelessWidget {
  final int current;
  final List<AnimationController> controllers;
  final ValueChanged<int> onTap;

  static const _icons  = [Icons.home_rounded, Icons.event_rounded, Icons.bar_chart_rounded, Icons.person_rounded];
  static const _labels = ['Home', 'Events', 'Reports', 'Profile'];

  const _GlassNav({required this.current, required this.controllers, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          decoration: BoxDecoration(
            color: kGlassWhite,
            border: const Border(top: BorderSide(color: kBorder, width: 1)),
            boxShadow: [
              BoxShadow(color: kNavy.withOpacity(0.06), blurRadius: 20, offset: const Offset(0, -4)),
            ],
          ),
          child: SafeArea(
            child: SizedBox(
              height: 64,
              child: Row(
                children: List.generate(4, (i) {
                  final active = current == i;
                  return Expanded(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => onTap(i),
                      child: AnimatedBuilder(
                        animation: controllers[i],
                        builder: (_, __) {
                          final t = controllers[i].value;
                          return Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Transform.scale(
                                scale: 1.0 + t * 0.2,
                                child: Container(
                                  width: 46, height: 34,
                                  decoration: BoxDecoration(
                                    color: Color.lerp(Colors.transparent, kGoldGlass, t),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: Color.lerp(Colors.transparent, kGoldBorder, t)!,
                                      width: 1,
                                    ),
                                  ),
                                  child: Icon(
                                    _icons[i], size: 20,
                                    color: Color.lerp(kMuted, kNavy, t),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(_labels[i], style: TextStyle(
                                fontSize: 10,
                                fontWeight: active ? FontWeight.w800 : FontWeight.w500,
                                color: Color.lerp(kMuted, kNavy, t),
                              )),
                            ],
                          );
                        },
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavyAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final String subtitle;
  final List<Widget>? actions;

  const _NavyAppBar(this.title, {this.subtitle = '', this.actions});

  @override
  Size get preferredSize => const Size.fromHeight(72);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [kNavy, kNavyLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(color: Color(0x330B2463), blurRadius: 16, offset: Offset(0, 4)),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Row(
            children: [
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  color: kGold,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [BoxShadow(color: kGold.withOpacity(0.5), blurRadius: 10)],
                ),
                child: const Center(
                  child: Text('F', style: TextStyle(
                    color: kNavy, fontSize: 22, fontWeight: FontWeight.w900, height: 1,
                  )),
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(title, style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.w900, color: kWhite, letterSpacing: -0.3,
                  )),
                  if (subtitle.isNotEmpty)
                    Text(subtitle, style: TextStyle(
                      fontSize: 11, color: kGoldLight.withOpacity(0.8), fontWeight: FontWeight.w500,
                    )),
                ],
              ),
              const Spacer(),
              if (actions != null) ...actions!,
            ],
          ),
        ),
      ),
    );
  }
}

class _GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final VoidCallback? onTap;
  final Color? tint;
  final double radius;

  const _GlassCard({
    required this.child,
    this.padding,
    this.onTap,
    this.tint,
    this.radius = 20,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            padding: padding ?? const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: tint ?? kGlassCard,
              borderRadius: BorderRadius.circular(radius),
              border: Border.all(color: kBorder.withOpacity(0.6)),
              boxShadow: [
                BoxShadow(color: kNavy.withOpacity(0.06), blurRadius: 20, offset: const Offset(0, 6)),
              ],
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

class _GoldPill extends StatelessWidget {
  final String label;
  final IconData? icon;
  final bool filled;

  const _GoldPill(this.label, {this.icon, this.filled = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: filled ? kGold : kGoldGlass,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: kGoldBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[Icon(icon, size: 11, color: filled ? kNavy : kGold), const SizedBox(width: 4)],
          Text(label, style: TextStyle(
            fontSize: 10, fontWeight: FontWeight.w800,
            color: filled ? kNavy : kGold,
          )),
        ],
      ),
    );
  }
}

class _NavyPill extends StatelessWidget {
  final String label;
  final Color? color;

  const _NavyPill(this.label, {this.color});

  @override
  Widget build(BuildContext context) {
    final c = color ?? kNavy;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: c.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: c.withOpacity(0.25)),
      ),
      child: Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: c)),
    );
  }
}

class _BottomSheet extends StatelessWidget {
  final String title;
  final String emoji;
  final Widget child;

  const _BottomSheet({required this.title, required this.emoji, required this.child});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          decoration: const BoxDecoration(
            color: kGlassWhite,
            borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40, height: 4,
                decoration: BoxDecoration(color: kNavy.withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
              ),
              Container(
                margin: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [kNavy, kNavyLight]),
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [BoxShadow(color: kNavy.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 4))],
                ),
                child: Row(
                  children: [
                    Text(emoji, style: const TextStyle(fontSize: 24)),
                    const SizedBox(width: 10),
                    Text(title, style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w900, color: kWhite,
                    )),
                    const Spacer(),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: 28, height: 28,
                        decoration: BoxDecoration(
                          color: kWhite.withOpacity(0.15),
                          shape: BoxShape.circle,
                          border: Border.all(color: kWhite.withOpacity(0.3)),
                        ),
                        child: const Icon(Icons.close_rounded, color: kWhite, size: 14),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(20, 16, 20, 20 + MediaQuery.of(context).viewInsets.bottom),
                child: child,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      appBar: _NavyAppBar(
        'FBLA Connect',
        subtitle: 'Future Business Leaders',
        actions: [
          GestureDetector(
            onTap: () => showModalBottomSheet(
              context: context,
              backgroundColor: Colors.transparent,
              builder: (_) => const _NotifSheet(),
            ),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                    child: Container(
                      width: 40, height: 40,
                      decoration: BoxDecoration(
                        color: kWhite.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: kWhite.withOpacity(0.3)),
                      ),
                      child: const Icon(Icons.notifications_rounded, color: kWhite, size: 20),
                    ),
                  ),
                ),
                Positioned(
                  top: 7, right: 7,
                  child: Container(
                    width: 9, height: 9,
                    decoration: BoxDecoration(
                      color: kGold,
                      shape: BoxShape.circle,
                      border: Border.all(color: kNavy, width: 1.5),
                      boxShadow: [BoxShadow(color: kGold.withOpacity(0.6), blurRadius: 6)],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          Positioned(
            top: -60, right: -60,
            child: Container(
              width: 220, height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: kGold.withOpacity(0.08),
              ),
            ),
          ),
          Positioned(
            bottom: 100, left: -80,
            child: Container(
              width: 260, height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: kNavy.withOpacity(0.05),
              ),
            ),
          ),
          ListView(
            padding: const EdgeInsets.all(20),
            children: const [
              _GreetingCard(),
              SizedBox(height: 18),
              _PointsCard(),
              SizedBox(height: 18),
              _StatsRow(),
              SizedBox(height: 18),
              _AnnouncementBanner(),
              SizedBox(height: 18),
              _BadgesSection(),
              SizedBox(height: 18),
              _ReportCTA(),
              SizedBox(height: 12),
            ],
          ),
        ],
      ),
    );
  }
}

class _GreetingCard extends StatelessWidget {
  const _GreetingCard();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: kGoldGlass,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: kGoldBorder),
                  ),
                  child: const Text('👋  Good morning!',
                      style: TextStyle(fontSize: 11, color: kGold, fontWeight: FontWeight.w800)),
                ),
              ]),
              const SizedBox(height: 8),
              const Text('Alex Johnson',
                  style: TextStyle(
                    fontSize: 28, fontWeight: FontWeight.w900, color: kNavy,
                    letterSpacing: -0.5, height: 1.1,
                  )),
              const SizedBox(height: 6),
              Row(children: [
                Container(
                  width: 7, height: 7,
                  decoration: const BoxDecoration(color: kGreen, shape: BoxShape.circle),
                ),
                const SizedBox(width: 6),
                const Text('Westview HS  ·  WA State',
                    style: TextStyle(fontSize: 12, color: kMuted, fontWeight: FontWeight.w500)),
              ]),
            ],
          ),
        ),
        _GlowAvatar(),
      ],
    );
  }
}

class _GlowAvatar extends StatefulWidget {
  @override
  State<_GlowAvatar> createState() => _GlowAvatarState();
}

class _GlowAvatarState extends State<_GlowAvatar> with SingleTickerProviderStateMixin {
  late AnimationController _c;
  late Animation<double> _glow;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);
    _glow = Tween<double>(begin: 8.0, end: 18.0).animate(CurvedAnimation(parent: _c, curve: Curves.easeInOut));
  }

  @override
  void dispose() { _c.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _glow,
      builder: (_, child) => Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [BoxShadow(color: kGold.withOpacity(0.35), blurRadius: _glow.value, spreadRadius: 1)],
        ),
        child: child,
      ),
      child: Container(
        width: 64, height: 64,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
            colors: [kNavy, kNavyLight],
            begin: Alignment.topLeft, end: Alignment.bottomRight,
          ),
          border: Border.all(color: kGold, width: 2.5),
        ),
        child: const Center(
          child: Text('AJ', style: TextStyle(color: kWhite, fontSize: 22, fontWeight: FontWeight.w900)),
        ),
      ),
    );
  }
}

class _PointsCard extends StatefulWidget {
  const _PointsCard();
  @override
  State<_PointsCard> createState() => _PointsCardState();
}

class _PointsCardState extends State<_PointsCard> with TickerProviderStateMixin {
  late AnimationController _barCtrl;
  late AnimationController _countCtrl;
  late Animation<double> _bar;
  late Animation<double> _count;

  @override
  void initState() {
    super.initState();
    _barCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400));
    _countCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200));
    _bar = CurvedAnimation(parent: _barCtrl, curve: Curves.easeOutCubic);
    _count = CurvedAnimation(parent: _countCtrl, curve: Curves.easeOutCubic);
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) { _barCtrl.forward(); _countCtrl.forward(); }
    });
  }

  @override
  void dispose() { _barCtrl.dispose(); _countCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [kNavy, Color(0xFF0F3070)],
              begin: Alignment.topLeft, end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: kGold.withOpacity(0.3)),
            boxShadow: [
              BoxShadow(color: kNavy.withOpacity(0.35), blurRadius: 30, offset: const Offset(0, 12)),
              BoxShadow(color: kGold.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, 4)),
            ],
          ),
          padding: const EdgeInsets.all(22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                _GoldPill('CHAPTER POINTS', icon: Icons.bolt_rounded),
                const Spacer(),
                _GoldPill('🏆 State Qualifier', filled: true),
              ]),
              const SizedBox(height: 14),
              AnimatedBuilder(
                animation: _count,
                builder: (_, __) {
                  final val = (_count.value * 2847).round();
                  return Text(
                    val.toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => ','),
                    style: const TextStyle(
                      fontSize: 54, fontWeight: FontWeight.w900, color: kWhite,
                      letterSpacing: -2, height: 1,
                    ),
                  );
                },
              ),
              const Text('points earned this year',
                  style: TextStyle(fontSize: 12, color: Color(0x99FFFFFF), fontWeight: FontWeight.w500)),
              const SizedBox(height: 18),
              Stack(children: [
                Container(
                  height: 10,
                  decoration: BoxDecoration(
                    color: kWhite.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                AnimatedBuilder(
                  animation: _bar,
                  builder: (_, __) => FractionallySizedBox(
                    widthFactor: _bar.value * 0.72,
                    child: Container(
                      height: 10,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [kGold, kGoldLight]),
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [BoxShadow(color: kGold.withOpacity(0.7), blurRadius: 8)],
                      ),
                    ),
                  ),
                ),
              ]),
              const SizedBox(height: 10),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Row(children: [
                  Container(
                    width: 8, height: 8,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(colors: [kGold, kGoldLight]),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Text('72% to Nationals 🎯',
                      style: TextStyle(fontSize: 11, color: Color(0xAAFFFFFF), fontWeight: FontWeight.w600)),
                ]),
                const Text('Need 1,103 more',
                    style: TextStyle(fontSize: 11, color: Color(0x66FFFFFF))),
              ]),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  const _StatsRow();

  @override
  Widget build(BuildContext context) {
    return Row(children: const [
      Expanded(child: _StatTile('🏆', '12', 'Events', kGold)),
      SizedBox(width: 10),
      Expanded(child: _StatTile('👥', '34', 'Members', kNavy)),
      SizedBox(width: 10),
      Expanded(child: _StatTile('⭐', '5', 'Awards', kTeal)),
    ]);
  }
}

class _StatTile extends StatefulWidget {
  final String emoji, value, label;
  final Color color;
  const _StatTile(this.emoji, this.value, this.label, this.color);
  @override
  State<_StatTile> createState() => _StatTileState();
}

class _StatTileState extends State<_StatTile> with SingleTickerProviderStateMixin {
  late AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 130),
        lowerBound: 0.93, upperBound: 1.0, value: 1.0);
  }

  @override
  void dispose() { _c.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _c.reverse(),
      onTapUp: (_) => _c.forward(),
      onTapCancel: () => _c.forward(),
      child: ScaleTransition(
        scale: _c,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 8),
              decoration: BoxDecoration(
                color: kGlassCard,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: widget.color.withOpacity(0.2)),
                boxShadow: [
                  BoxShadow(color: widget.color.withOpacity(0.08), blurRadius: 16, offset: const Offset(0, 4)),
                ],
              ),
              child: Column(children: [
                Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(
                    color: widget.color.withOpacity(0.12),
                    shape: BoxShape.circle,
                    border: Border.all(color: widget.color.withOpacity(0.25)),
                  ),
                  child: Center(child: Text(widget.emoji, style: const TextStyle(fontSize: 20))),
                ),
                const SizedBox(height: 10),
                Text(widget.value, style: TextStyle(
                  fontSize: 26, fontWeight: FontWeight.w900,
                  color: widget.color, letterSpacing: -0.5,
                )),
                const SizedBox(height: 2),
                Text(widget.label, style: const TextStyle(
                  fontSize: 10, color: kMuted, fontWeight: FontWeight.w700,
                )),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}

class _AnnouncementBanner extends StatelessWidget {
  const _AnnouncementBanner();

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: kBgWarm.withOpacity(0.85),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: kGoldBorder),
            boxShadow: [BoxShadow(color: kGold.withOpacity(0.12), blurRadius: 16, offset: const Offset(0, 4))],
          ),
          child: Row(children: [
            Container(
              width: 48, height: 48,
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [kGold, kGoldLight]),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: kGold.withOpacity(0.4), blurRadius: 10)],
              ),
              child: const Center(child: Text('📣', style: TextStyle(fontSize: 22))),
            ),
            const SizedBox(width: 14),
            const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('State Conf Registration Open! 🎉',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: kNavy)),
              SizedBox(height: 4),
              Text('Deadline April 30 — don\'t miss your spot!',
                  style: TextStyle(fontSize: 11, color: kMuted, height: 1.4)),
            ])),
            Container(
              width: 32, height: 32,
              decoration: BoxDecoration(
                color: kGold,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [BoxShadow(color: kGold.withOpacity(0.4), blurRadius: 8)],
              ),
              child: const Icon(Icons.arrow_forward_ios_rounded, color: kNavy, size: 13),
            ),
          ]),
        ),
      ),
    );
  }
}

class _BadgesSection extends StatelessWidget {
  const _BadgesSection();

  static const _badges = [
    ('🏅', 'Top Coder',  kGold,   true),
    ('🎤', 'Speaker',    kNavy,   true),
    ('📋', 'Officer',    kTeal,   true),
    ('💯', '100 Hrs',    kGold,   true),
    ('🔮', 'Mystery',    kMuted,  false),
    ('🌟', 'Star',       kMuted,  false),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        const Text('ACHIEVEMENTS', style: TextStyle(
          fontSize: 10, fontWeight: FontWeight.w800, color: kMuted, letterSpacing: 2,
        )),
        const SizedBox(width: 8),
        _NavyPill('4 / 6', color: kGreen),
      ]),
      const SizedBox(height: 14),
      SizedBox(
        height: 100,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: _badges.length,
          separatorBuilder: (_, __) => const SizedBox(width: 12),
          itemBuilder: (_, i) {
            final b = _badges[i];
            return _Badge(emoji: b.$1, label: b.$2, color: b.$3, unlocked: b.$4);
          },
        ),
      ),
    ]);
  }
}

class _Badge extends StatefulWidget {
  final String emoji, label;
  final Color color;
  final bool unlocked;
  const _Badge({required this.emoji, required this.label, required this.color, required this.unlocked});
  @override
  State<_Badge> createState() => _BadgeState();
}

class _BadgeState extends State<_Badge> with SingleTickerProviderStateMixin {
  late AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 120),
        lowerBound: 0.88, upperBound: 1.0, value: 1.0);
  }

  @override
  void dispose() { _c.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _c.reverse(),
      onTapUp: (_) => _c.forward(),
      onTapCancel: () => _c.forward(),
      child: ScaleTransition(
        scale: _c,
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          ClipOval(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
              child: Container(
                width: 64, height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: widget.unlocked ? widget.color.withOpacity(0.12) : kBorder.withOpacity(0.3),
                  border: Border.all(
                    color: widget.unlocked ? widget.color.withOpacity(0.5) : kBorder,
                    width: widget.unlocked ? 2 : 1,
                  ),
                  boxShadow: widget.unlocked
                      ? [BoxShadow(color: widget.color.withOpacity(0.25), blurRadius: 12, spreadRadius: 1)]
                      : null,
                ),
                child: Center(
                  child: Opacity(
                    opacity: widget.unlocked ? 1.0 : 0.25,
                    child: Text(widget.emoji, style: const TextStyle(fontSize: 26)),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(widget.label, style: TextStyle(
            fontSize: 9, fontWeight: FontWeight.w700,
            color: widget.unlocked ? kNavy : kMuted,
          )),
        ]),
      ),
    );
  }
}

class _ReportCTA extends StatefulWidget {
  const _ReportCTA();
  @override
  State<_ReportCTA> createState() => _ReportCTAState();
}

class _ReportCTAState extends State<_ReportCTA> with SingleTickerProviderStateMixin {
  late AnimationController _c;
  bool _pressed = false;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..repeat(reverse: true);
  }

  @override
  void dispose() { _c.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        showModalBottomSheet(
          context: context, backgroundColor: Colors.transparent,
          isScrollControlled: true, builder: (_) => const _BlockReportSheet(),
        );
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 120),
        child: AnimatedBuilder(
          animation: _c,
          builder: (_, child) => Container(
            height: 58,
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [kNavy, kNavyLight]),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: Color.lerp(kGold.withOpacity(0.3), kGold.withOpacity(0.8), _c.value)!,
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: kNavy.withOpacity(0.3 + _c.value * 0.15),
                  blurRadius: 16, offset: const Offset(0, 6),
                ),
                BoxShadow(
                  color: kGold.withOpacity(0.08 + _c.value * 0.12),
                  blurRadius: 20, offset: const Offset(0, 2),
                ),
              ],
            ),
            child: child,
          ),
          child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Text('📊', style: TextStyle(fontSize: 20)),
            SizedBox(width: 10),
            Text('Generate Block Report',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: kWhite, letterSpacing: 0.1)),
            SizedBox(width: 8),
            Icon(Icons.arrow_forward_rounded, color: kGold, size: 18),
          ]),
        ),
      ),
    );
  }
}

class _NotifSheet extends StatelessWidget {
  const _NotifSheet();

  @override
  Widget build(BuildContext context) {
    return _BottomSheet(
      title: 'Notifications',
      emoji: '🔔',
      child: Column(children: const [
        _NotifItem('📣', 'New Announcement', 'State conf entries due April 30!', kGold),
        SizedBox(height: 10),
        _NotifItem('⚡', 'Points Updated', '+120 pts for mock interview event.', kNavy),
        SizedBox(height: 10),
        _NotifItem('🏆', 'Achievement Unlocked', 'You earned "100 Service Hours"!', kGreen),
      ]),
    );
  }
}

class _NotifItem extends StatelessWidget {
  final String emoji, title, body;
  final Color color;
  const _NotifItem(this.emoji, this.title, this.body, this.color);

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: color.withOpacity(0.07),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withOpacity(0.2)),
          ),
          child: Row(children: [
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                shape: BoxShape.circle,
                border: Border.all(color: color.withOpacity(0.25)),
              ),
              child: Center(child: Text(emoji, style: const TextStyle(fontSize: 18))),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: kNavy)),
              const SizedBox(height: 3),
              Text(body, style: const TextStyle(fontSize: 11, color: kMuted, height: 1.4)),
            ])),
            Container(
              width: 7, height: 7,
              decoration: BoxDecoration(
                color: color, shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: color.withOpacity(0.5), blurRadius: 6)],
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

class _BlockReportSheet extends StatelessWidget {
  const _BlockReportSheet();

  static const _stats = [
    ('Total Members', '34', '👥', kNavy),
    ('Chapter Points', '2,847', '⚡', kGold),
    ('Competitive Events', '12', '🏆', kTeal),
    ('Service Hours', '416', '💚', kGreen),
    ('State Qualifiers', '8', '🎯', kNavy),
    ('Meetings Held', '22', '📅', kGold),
  ];

  @override
  Widget build(BuildContext context) {
    return _BottomSheet(
      title: 'Block Report',
      emoji: '📊',
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Westview HS Chapter · Spring 2025',
            style: TextStyle(fontSize: 12, color: kMuted, fontWeight: FontWeight.w600)),
        const SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2, childAspectRatio: 2.0,
            crossAxisSpacing: 10, mainAxisSpacing: 10,
          ),
          itemCount: _stats.length,
          itemBuilder: (_, i) {
            final s = _stats[i];
            final color = s.$4 as Color;
            return ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.07),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: color.withOpacity(0.2)),
                  ),
                  child: Row(children: [
                    Text(s.$3, style: const TextStyle(fontSize: 22)),
                    const SizedBox(width: 10),
                    Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
                      Text(s.$2, style: TextStyle(
                        fontSize: 20, fontWeight: FontWeight.w900, color: color, height: 1,
                      )),
                      Text(s.$1, style: const TextStyle(
                        fontSize: 9, color: kMuted, fontWeight: FontWeight.w700,
                      )),
                    ]),
                  ]),
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 16),
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            width: double.infinity, height: 52,
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [kNavy, kNavyLight]),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: kGoldBorder),
              boxShadow: [BoxShadow(color: kNavy.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 4))],
            ),
            child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Text('📄', style: TextStyle(fontSize: 18)),
              SizedBox(width: 8),
              Text('Export PDF', style: TextStyle(
                fontSize: 15, fontWeight: FontWeight.w900, color: kWhite,
              )),
            ]),
          ),
        ),
      ]),
    );
  }
}

class EventsPage extends StatelessWidget {
  const EventsPage({super.key});

  static const _events = [
    _Ev('Chapter Meeting', 'Room 204 · 3:30 PM', 'Apr', '24', '📌', 'Today', kGreen),
    _Ev('Leadership Workshop', 'Library B · 4:00 PM', 'Apr', '28', '💡', 'Upcoming', kNavy),
    _Ev('State Conference', 'Seattle Convention Ctr', 'May', '03', '🗺️', 'Reg. Open', kGold),
    _Ev('Mock Interview Day', 'Gym · All Day', 'May', '10', '🎤', 'Upcoming', kTeal),
    _Ev('NLC — Atlanta, GA', 'National Leadership Conf', 'Jun', '21', '✈️', 'Nationals', kRed),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      appBar: _NavyAppBar('Events', subtitle: 'Chapter Calendar'),
      body: Stack(
        children: [
          Positioned(top: -40, right: -40,
            child: Container(width: 180, height: 180, decoration: BoxDecoration(
              shape: BoxShape.circle, color: kGold.withOpacity(0.07),
            ))),
          ListView(
            padding: const EdgeInsets.all(20),
            children: [
              const Text('UPCOMING EVENTS', style: TextStyle(
                fontSize: 10, fontWeight: FontWeight.w800, color: kMuted, letterSpacing: 2,
              )),
              const SizedBox(height: 16),
              ..._events.asMap().entries.map((e) => _SlideInEventCard(ev: e.value, index: e.key)),
            ],
          ),
        ],
      ),
    );
  }
}

class _Ev {
  final String title, location, month, day, emoji, badge;
  final Color color;
  const _Ev(this.title, this.location, this.month, this.day, this.emoji, this.badge, this.color);
}

class _SlideInEventCard extends StatefulWidget {
  final _Ev ev;
  final int index;
  const _SlideInEventCard({required this.ev, required this.index});
  @override
  State<_SlideInEventCard> createState() => _SlideInEventCardState();
}

class _SlideInEventCardState extends State<_SlideInEventCard> with SingleTickerProviderStateMixin {
  late AnimationController _c;
  late Animation<Offset> _slide;
  late Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 450));
    _slide = Tween<Offset>(begin: const Offset(0.07, 0), end: Offset.zero)
        .animate(CurvedAnimation(parent: _c, curve: Curves.easeOutCubic));
    _fade = CurvedAnimation(parent: _c, curve: Curves.easeOut);
    Future.delayed(Duration(milliseconds: 70 * widget.index), () { if (mounted) _c.forward(); });
  }

  @override
  void dispose() { _c.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(
        position: _slide,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _GlassCard(
            tint: kGlassCard,
            child: Row(children: [
              Container(
                width: 56, height: 56,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [widget.ev.color, widget.ev.color.withOpacity(0.7)],
                    begin: Alignment.topLeft, end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: widget.ev.color.withOpacity(0.35), blurRadius: 10)],
                ),
                child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Text(widget.ev.month.toUpperCase(), style: const TextStyle(
                    fontSize: 9, color: kWhite, fontWeight: FontWeight.w800, letterSpacing: 1,
                  )),
                  Text(widget.ev.day, style: const TextStyle(
                    fontSize: 22, color: kWhite, fontWeight: FontWeight.w900, height: 1.1,
                  )),
                ]),
              ),
              const SizedBox(width: 14),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Text(widget.ev.emoji, style: const TextStyle(fontSize: 15)),
                  const SizedBox(width: 6),
                  Expanded(child: Text(widget.ev.title, style: const TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w800, color: kNavy,
                  ))),
                ]),
                const SizedBox(height: 4),
                Text(widget.ev.location, style: const TextStyle(fontSize: 11, color: kMuted)),
              ])),
              _NavyPill(widget.ev.badge, color: widget.ev.color),
            ]),
          ),
        ),
      ),
    );
  }
}

class ReportsPage extends StatelessWidget {
  const ReportsPage({super.key});

  static const _reports = [
    ('📊', 'Block Report', 'Full chapter activity summary', kNavy, [kNavy, kNavyLight]),
    ('💰', 'Financial Report', 'Budget and expenses', kGold, [kGold, kGoldLight]),
    ('👥', 'Member Roster', 'Active members and dues status', kTeal, [kTeal, Color(0xFF0EA5A0)]),
    ('⏱️', 'Service Hours', 'Community service log', kGreen, [kGreen, Color(0xFF48BB78)]),
    ('🏆', 'Points Ledger', 'Event-by-event point history', kRed, [kRed, Color(0xFFFC8181)]),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      appBar: _NavyAppBar('Reports', subtitle: 'Chapter Documents'),
      body: Stack(
        children: [
          Positioned(bottom: 80, right: -50,
            child: Container(width: 200, height: 200, decoration: BoxDecoration(
              shape: BoxShape.circle, color: kNavy.withOpacity(0.04),
            ))),
          ListView(
            padding: const EdgeInsets.all(20),
            children: [
              const Text('GENERATE REPORTS', style: TextStyle(
                fontSize: 10, fontWeight: FontWeight.w800, color: kMuted, letterSpacing: 2,
              )),
              const SizedBox(height: 16),
              ..._reports.map((r) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _ReportCard(
                  emoji: r.$1, title: r.$2, desc: r.$3,
                  color: r.$4 as Color, gradient: r.$5 as List<Color>,
                ),
              )),
            ],
          ),
        ],
      ),
    );
  }
}

class _ReportCard extends StatefulWidget {
  final String emoji, title, desc;
  final Color color;
  final List<Color> gradient;
  const _ReportCard({required this.emoji, required this.title, required this.desc, required this.color, required this.gradient});
  @override
  State<_ReportCard> createState() => _ReportCardState();
}

class _ReportCardState extends State<_ReportCard> with SingleTickerProviderStateMixin {
  late AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 120),
        lowerBound: 0.96, upperBound: 1.0, value: 1.0);
  }

  @override
  void dispose() { _c.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _c.reverse(),
      onTapUp: (_) {
        _c.forward();
        showModalBottomSheet(
          context: context, backgroundColor: Colors.transparent,
          isScrollControlled: true, builder: (_) => const _BlockReportSheet(),
        );
      },
      onTapCancel: () => _c.forward(),
      child: ScaleTransition(
        scale: _c,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              decoration: BoxDecoration(
                color: kGlassCard,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: widget.color.withOpacity(0.2)),
                boxShadow: [
                  BoxShadow(color: widget.color.withOpacity(0.07), blurRadius: 16, offset: const Offset(0, 4)),
                ],
              ),
              child: Row(children: [
                Container(
                  width: 6, height: 70,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: widget.gradient,
                      begin: Alignment.topCenter, end: Alignment.bottomCenter,
                    ),
                    borderRadius: const BorderRadius.horizontal(left: Radius.circular(20)),
                  ),
                ),
                const SizedBox(width: 14),
                Container(
                  width: 46, height: 46,
                  decoration: BoxDecoration(
                    color: widget.color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: widget.color.withOpacity(0.2)),
                  ),
                  child: Center(child: Text(widget.emoji, style: const TextStyle(fontSize: 22))),
                ),
                const SizedBox(width: 14),
                Expanded(child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(widget.title, style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w800, color: kNavy,
                    )),
                    const SizedBox(height: 3),
                    Text(widget.desc, style: const TextStyle(fontSize: 11, color: kMuted)),
                  ]),
                )),
                Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: Container(
                    width: 32, height: 32,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: widget.gradient),
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [BoxShadow(color: widget.color.withOpacity(0.3), blurRadius: 8)],
                    ),
                    child: const Icon(Icons.arrow_forward_ios_rounded, color: kWhite, size: 13),
                  ),
                ),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});
  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> with TickerProviderStateMixin {
  late AnimationController _enterCtrl;
  late AnimationController _orbitCtrl;
  late Animation<double> _fade;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _enterCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _orbitCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 7))..repeat();
    _fade = CurvedAnimation(parent: _enterCtrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(begin: const Offset(0, 0.05), end: Offset.zero)
        .animate(CurvedAnimation(parent: _enterCtrl, curve: Curves.easeOut));
    _enterCtrl.forward();
  }

  @override
  void dispose() { _enterCtrl.dispose(); _orbitCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      appBar: _NavyAppBar('My Profile', subtitle: 'Member Details'),
      body: Stack(
        children: [
          Positioned(top: -30, left: -30,
            child: Container(width: 160, height: 160, decoration: BoxDecoration(
              shape: BoxShape.circle, color: kGold.withOpacity(0.08),
            ))),
          FadeTransition(
            opacity: _fade,
            child: SlideTransition(
              position: _slide,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  _ProfileHero(orbitCtrl: _orbitCtrl),
                  const SizedBox(height: 22),
                  _MiniStatsRow(),
                  const SizedBox(height: 22),
                  _InfoSection('Chapter Info', [
                    _InfoRow('🏫', 'School', 'Westview High School', kNavy),
                    _InfoRow('📍', 'State', 'Washington', kTeal),
                    _InfoRow('🪪', 'Member ID', '#WA-2847', kNavy),
                    _InfoRow('📅', 'Member Since', 'Sep 2022', kGold),
                  ]),
                  const SizedBox(height: 16),
                  _InfoSection('My Record', [
                    _InfoRow('🎯', 'Events Competed', '12', kNavy),
                    _InfoRow('🥇', 'Awards Won', '5', kGold),
                    _InfoRow('💳', 'Dues Status', 'Paid ✓', kGreen),
                  ]),
                  const SizedBox(height: 24),
                  GestureDetector(
                    onTap: () {},
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                        child: Container(
                          height: 52,
                          decoration: BoxDecoration(
                            color: kRed.withOpacity(0.07),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: kRed.withOpacity(0.3)),
                          ),
                          child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                            Icon(Icons.logout_rounded, color: kRed, size: 18),
                            SizedBox(width: 8),
                            Text('Sign Out', style: TextStyle(
                              color: kRed, fontWeight: FontWeight.w800, fontSize: 15,
                            )),
                          ]),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileHero extends StatelessWidget {
  final AnimationController orbitCtrl;
  const _ProfileHero({required this.orbitCtrl});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(children: [
        Stack(alignment: Alignment.center, children: [
          AnimatedBuilder(
            animation: orbitCtrl,
            builder: (_, __) => CustomPaint(
              size: const Size(120, 120),
              painter: _OrbitPainter(orbitCtrl.value * 2 * math.pi),
            ),
          ),
          Container(
            width: 90, height: 90,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [kNavy, kNavyLight],
                begin: Alignment.topLeft, end: Alignment.bottomRight,
              ),
              border: Border.all(color: kGold, width: 3),
              boxShadow: [
                BoxShadow(color: kNavy.withOpacity(0.3), blurRadius: 20, spreadRadius: 2),
                BoxShadow(color: kGold.withOpacity(0.2), blurRadius: 14),
              ],
            ),
            child: const Center(
              child: Text('AJ', style: TextStyle(color: kWhite, fontSize: 30, fontWeight: FontWeight.w900)),
            ),
          ),
        ]),
        const SizedBox(height: 16),
        const Text('Alex Johnson', style: TextStyle(
          fontSize: 26, fontWeight: FontWeight.w900, color: kNavy, letterSpacing: -0.4,
        )),
        const SizedBox(height: 8),
        _GoldPill('Chapter Vice President 🎖️', filled: true),
        const SizedBox(height: 6),
        const Text('Westview HS · Washington State',
            style: TextStyle(fontSize: 12, color: kMuted, fontWeight: FontWeight.w500)),
      ]),
    );
  }
}

class _OrbitPainter extends CustomPainter {
  final double angle;
  _OrbitPainter(this.angle);

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = size.width / 2 - 4;

    canvas.drawCircle(
      Offset(cx, cy), r,
      Paint()
        ..color = kGold.withOpacity(0.15)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    final x = cx + r * math.cos(angle);
    final y = cy + r * math.sin(angle);

    canvas.drawCircle(Offset(x, y), 7,
        Paint()..color = kGold.withOpacity(0.3)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7));
    canvas.drawCircle(Offset(x, y), 5, Paint()..color = kGold);
  }

  @override
  bool shouldRepaint(_OrbitPainter old) => old.angle != angle;
}

class _MiniStatsRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: const [
      _MiniStat('2,847', 'Points', '⚡', kGold),
      _MiniStat('12', 'Events', '🏆', kNavy),
      _MiniStat('112', 'Hrs', '💚', kGreen),
    ]);
  }
}

class _MiniStat extends StatelessWidget {
  final String value, label, emoji;
  final Color color;
  const _MiniStat(this.value, this.label, this.emoji, this.color);

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          width: 96, padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: kGlassCard,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: color.withOpacity(0.2)),
            boxShadow: [BoxShadow(color: color.withOpacity(0.08), blurRadius: 12, offset: const Offset(0, 4))],
          ),
          child: Column(children: [
            Text(emoji, style: const TextStyle(fontSize: 22)),
            const SizedBox(height: 6),
            Text(value, style: TextStyle(
              fontSize: 20, fontWeight: FontWeight.w900, color: color, letterSpacing: -0.5,
            )),
            Text(label, style: const TextStyle(fontSize: 10, color: kMuted, fontWeight: FontWeight.w700)),
          ]),
        ),
      ),
    );
  }
}

class _InfoSection extends StatelessWidget {
  final String title;
  final List<_InfoRow> rows;
  const _InfoSection(this.title, this.rows, {super.key});

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title.toUpperCase(), style: const TextStyle(
        fontSize: 10, fontWeight: FontWeight.w800, color: kMuted, letterSpacing: 2,
      )),
      const SizedBox(height: 10),
      ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              color: kGlassCard,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: kBorder),
              boxShadow: [BoxShadow(color: kNavy.withOpacity(0.05), blurRadius: 16, offset: const Offset(0, 4))],
            ),
            child: Column(
              children: rows.asMap().entries.map((e) => Column(children: [
                e.value,
                if (e.key < rows.length - 1) Divider(height: 1, indent: 60, color: kBorder.withOpacity(0.5)),
              ])).toList(),
            ),
          ),
        ),
      ),
    ]);
  }
}

class _InfoRow extends StatelessWidget {
  final String emoji, label, value;
  final Color color;
  const _InfoRow(this.emoji, this.label, this.value, this.color, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(children: [
        Container(
          width: 32, height: 32,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: color.withOpacity(0.2)),
          ),
          child: Center(child: Text(emoji, style: const TextStyle(fontSize: 15))),
        ),
        const SizedBox(width: 12),
        Text(label, style: const TextStyle(fontSize: 13, color: kMuted, fontWeight: FontWeight.w500)),
        const Spacer(),
        Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: color)),
      ]),
    );
  }
}