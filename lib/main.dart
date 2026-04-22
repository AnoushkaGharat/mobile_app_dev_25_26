import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const kBlobAsset = 'assets/blob.png';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
  ));

  await Supabase.initialize(
    url: 'https://krylwlbyntcmuzxmssyg.supabase.co',
    anonKey: 'sb_publishable_ZUxKQwJN4KQsfT7zGFPYlw_d0kfs_Ym',
  );

  runApp(const FBLAApp());
}

const kNavy = Color(0xFF0B2463);
const kNavyLight = Color(0xFF1A3A7A);
const kGold = Color(0xFFF5A623);
const kWhite = Colors.white;
const kBg = Color(0xFFF0F4FF);
const kMuted = Color(0xFF6B7A99);
const kBorder = Color(0x220B2463);
const kGlassWhite = Color(0xCCFFFFFF);
const kGlassCard = Color(0xB3FFFFFF);
const kRed = Color(0xFFE53E3E);
const kGreen = Color(0xFF38A169);
const kTeal = Color(0xFF0EA5A0);

SupabaseClient get _client => Supabase.instance.client;

User? _currentUser(AuthState? state) {
  return state?.session?.user ?? _client.auth.currentUser;
}

String _usernameFromUser(User? user) {
  return (user?.userMetadata?['username'] as String?) ??
      user?.email?.split('@').first ??
      'User';
}

int _pointsFromUser(User? user) {
  final raw = user?.userMetadata?['points'];

  if (raw is int) return raw;
  if (raw is num) return raw.toInt();
  if (raw is String) return int.tryParse(raw) ?? 0;

  return 0;
}

int _levelFromPoints(int points) {
  return (points ~/ 100) + 1;
}

String _initialsFromName(String name) {
  final initials = name
      .trim()
      .split(RegExp(r'\s+'))
      .where((part) => part.isNotEmpty)
      .take(2)
      .map((part) => part[0].toUpperCase())
      .join();

  return initials.isEmpty ? 'U' : initials;
}

Future<void> _addPoints({
  required int amount,
  required String reason,
}) async {
  final user = _client.auth.currentUser;
  if (user == null) return;

  final metadata = Map<String, dynamic>.from(user.userMetadata ?? {});
  final currentPoints = _pointsFromUser(user);
  final newPoints = currentPoints + amount;

  metadata['username'] = _usernameFromUser(user);
  metadata['points'] = newPoints;
  metadata['last_activity'] = reason;

  await _client.auth.updateUser(
    UserAttributes(data: metadata),
  );
}

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
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(foregroundColor: kWhite),
        ),
      ),
      home: const AuthGate(),
    );
  }
}

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  bool _showResetPassword = false;

  @override
  void initState() {
    super.initState();

    _client.auth.onAuthStateChange.listen((data) {
      if (!mounted) return;
      if (data.event == AuthChangeEvent.passwordRecovery) {
        setState(() => _showResetPassword = true);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_showResetPassword) {
      return const ResetPasswordPage();
    }

    return StreamBuilder<AuthState>(
      stream: _client.auth.onAuthStateChange,
      initialData: AuthState(
        AuthChangeEvent.initialSession,
        _client.auth.currentSession,
      ),
      builder: (context, snapshot) {
        final session = snapshot.data?.session;
        if (session == null) return const LoginPage();
        return const Shell();
      },
    );
  }
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> logIn() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isLoading = true);

    try {
      await _client.auth.signInWithPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      await _addPoints(
        amount: 5,
        reason: 'Logged in',
      );
    } on AuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> resetPassword() async {
    final email = _emailController.text.trim();

    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter your email first.')),
      );
      return;
    }

    try {
      await _client.auth.resetPasswordForEmail(
        email,
        redirectTo: 'fbla-link://reset-password',
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password reset email sent.')),
      );
    } on AuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _AuthBackground(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 28),
                  const Text(
                    'Welcome back',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 30,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 15),
                  const Text(
                    'Log in',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                  const SizedBox(height: 32),
                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _emailController,
                          decoration: _authFieldDecoration(
                            label: 'Email',
                            hint: 'you@example.com',
                            prefixIcon: const Icon(Icons.email_outlined),
                          ),
                          validator: (value) {
                            final text = value?.trim() ?? '';
                            if (text.isEmpty) return 'Please enter your email';
                            if (!text.contains('@')) return 'Enter a valid email';
                            return null;
                          },
                        ),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: resetPassword,
                            child: const Text('Forgot password?'),
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          decoration: _authFieldDecoration(
                            label: 'Password',
                            hint: 'Enter your password',
                            prefixIcon: const Icon(Icons.lock_outline),
                            suffixIcon: IconButton(
                              onPressed: () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                              ),
                            ),
                          ),
                          validator: (value) {
                            final text = value ?? '';
                            if (text.isEmpty) return 'Please enter your password';
                            if (text.length < 6) {
                              return 'Password must be at least 6 characters';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: FilledButton(
                            onPressed: _isLoading ? null : logIn,
                            style: FilledButton.styleFrom(
                              backgroundColor: const Color.fromRGBO(
                                10,
                                46,
                                127,
                                1.0,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                              ),
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    height: 24,
                                    width: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text('Log In'),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        "Don't have an account?",
                        style: TextStyle(color: Colors.white),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const SignUpPage(),
                            ),
                          );
                        },
                        child: const Text('Sign up'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class ResetPasswordPage extends StatefulWidget {
  const ResetPasswordPage({super.key});

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  final _passwordController = TextEditingController();
  bool _loading = false;

  Future<void> _updatePassword() async {
    final password = _passwordController.text.trim();

    if (password.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password must be at least 6 characters.')),
      );
      return;
    }

    setState(() => _loading = true);

    try {
      await _client.auth.updateUser(
        UserAttributes(password: password),
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password updated successfully.')),
      );

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginPage()),
        (route) => false,
      );
    } on AuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _AuthBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                const Text(
                  'Reset Password',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: _authFieldDecoration(
                    label: 'New Password',
                    hint: 'Enter your new password',
                    prefixIcon: const Icon(Icons.lock_outline),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: FilledButton(
                    onPressed: _loading ? null : _updatePassword,
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color.fromRGBO(10, 46, 127, 1.0),
                    ),
                    child: _loading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('Save New Password'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _usernameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _usernameController.dispose();
    super.dispose();
  }

  Future<void> signUp() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isLoading = true);

    try {
      await _client.auth.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        data: {
          'username': _usernameController.text.trim(),
          'points': 25,
          'last_activity': 'Created account',
        },
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Account created. You can now log in.')),
      );
      Navigator.pop(context);
    } on AuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _AuthBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Sign Up',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: _usernameController,
                    decoration: _authFieldDecoration(
                      label: 'Username',
                      hint: 'Enter your username',
                    ),
                    validator: (value) {
                      if ((value ?? '').trim().isEmpty) {
                        return 'Enter a username';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: _authFieldDecoration(
                      label: 'Email',
                      hint: 'you@example.com',
                      prefixIcon: const Icon(Icons.email_outlined),
                    ),
                    validator: (value) {
                      final text = value?.trim() ?? '';
                      if (text.isEmpty) return 'Enter your email';
                      if (!text.contains('@')) return 'Enter a valid email';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    decoration: _authFieldDecoration(
                      label: 'Password',
                      hint: 'Enter your password',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                          color: Colors.black54,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                    ),
                    validator: (value) {
                      final text = value ?? '';
                      if (text.isEmpty) return 'Enter a password';
                      if (text.length < 6) return 'At least 6 characters';
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: FilledButton(
                      onPressed: _isLoading ? null : signUp,
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color.fromRGBO(10, 46, 127, 1.0),
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text('Create Account'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AuthBackground extends StatelessWidget {
  final Widget child;

  const _AuthBackground({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/GRADIENT.png'),
          fit: BoxFit.cover,
        ),
      ),
      child: child,
    );
  }
}

InputDecoration _authFieldDecoration({
  required String label,
  required String hint,
  Widget? prefixIcon,
  Widget? suffixIcon,
}) {
  return InputDecoration(
    labelText: label,
    hintText: hint,
    prefixIcon: prefixIcon,
    suffixIcon: suffixIcon,
    filled: true,
    fillColor: Colors.white,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(18),
      borderSide: BorderSide.none,
    ),
  );
}

class Shell extends StatefulWidget {
  const Shell({super.key});

  @override
  State<Shell> createState() => _ShellState();
}

class _ShellState extends State<Shell> {
  int _tab = 0;

  final _pages = const [
    DashboardPage(),
    EventsPage(),
    ReportsPage(),
    ProfilePage(),
  ];

  void _onTap(int i) {
    setState(() => _tab = i);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      body: _pages[_tab],
      bottomNavigationBar: _GlassNav(current: _tab, onTap: _onTap),
    );
  }
}

class _GlassNav extends StatelessWidget {
  final int current;
  final ValueChanged<int> onTap;

  static const _icons = [
    Icons.home_rounded,
    Icons.event_rounded,
    Icons.bar_chart_rounded,
    Icons.person_rounded,
  ];

  static const _labels = ['Home', 'Events', 'Reports', 'Profile'];

  const _GlassNav({required this.current, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          decoration: BoxDecoration(
            color: kGlassWhite,
            border: const Border(top: BorderSide(color: kBorder, width: 1)),
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
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 46,
                            height: 34,
                            decoration: BoxDecoration(
                              color: active
                                  ? const Color(0x33F5A623)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: active
                                    ? const Color(0x66F5A623)
                                    : Colors.transparent,
                              ),
                            ),
                            child: Icon(
                              _icons[i],
                              size: 20,
                              color: active ? kNavy : kMuted,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            _labels[i],
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: active
                                  ? FontWeight.w800
                                  : FontWeight.w500,
                              color: active ? kNavy : kMuted,
                            ),
                          ),
                        ],
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
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: kGold,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                  child: Text(
                    'F',
                    style: TextStyle(
                      color: kNavy,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: kWhite,
                    ),
                  ),
                  if (subtitle.isNotEmpty)
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xCCFFD97D),
                      ),
                    ),
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

  const _GlassCard({
    required this.child,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding ?? const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: kGlassCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: kBorder),
      ),
      child: child,
    );
  }
}

class _GoldPill extends StatelessWidget {
  final String label;
  final IconData? icon;
  final bool filled;

  const _GoldPill(this.label, {this.icon, this.filled = false, super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: filled ? kGold : const Color(0x33F5A623),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0x66F5A623)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 11, color: filled ? kNavy : kGold),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: filled ? kNavy : kGold,
            ),
          ),
        ],
      ),
    );
  }
}

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: _client.auth.onAuthStateChange,
      initialData: AuthState(
        AuthChangeEvent.initialSession,
        _client.auth.currentSession,
      ),
      builder: (context, snapshot) {
        final user = _currentUser(snapshot.data);
        final username = _usernameFromUser(user);
        final points = _pointsFromUser(user);
        final level = _levelFromPoints(points);
        final initials = _initialsFromName(username);

        return Scaffold(
          backgroundColor: kBg,
          appBar: _NavyAppBar(
            'FBLA Connect',
            subtitle: 'Future Business Leaders',
            actions: [
              IconButton(
                onPressed: () => showModalBottomSheet(
                  context: context,
                  backgroundColor: Colors.transparent,
                  builder: (_) => const _NotifSheet(),
                ),
                icon: const Icon(Icons.notifications_rounded, color: Colors.white),
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              _GreetingCard(username: username, initials: initials),
              const SizedBox(height: 18),
              _PointsCard(points: points, level: level),
              const SizedBox(height: 18),
              _BlobCard(
                onPressed: () async {
                  await _addPoints(
                    amount: 15,
                    reason: 'Logged a productive action',
                  );
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('+15 points added')),
                  );
                },
              ),
              const SizedBox(height: 18),
              const _StatsRow(),
              const SizedBox(height: 18),
              const _AnnouncementBanner(),
            ],
          ),
        );
      },
    );
  }
}

class _GreetingCard extends StatelessWidget {
  final String username;
  final String initials;

  const _GreetingCard({
    required this.username,
    required this.initials,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                username,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: kNavy,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Westview HS  ·  WA State',
                style: TextStyle(fontSize: 12, color: kMuted),
              ),
            ],
          ),
        ),
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(colors: [kNavy, kNavyLight]),
            border: Border.all(color: kGold, width: 2.5),
          ),
          child: Center(
            child: Text(
              initials,
              style: const TextStyle(
                color: kWhite,
                fontSize: 22,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _PointsCard extends StatelessWidget {
  final int points;
  final int level;

  const _PointsCard({
    required this.points,
    required this.level,
  });

  @override
  Widget build(BuildContext context) {
    final progress = ((points % 100) / 100).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [kNavy, kNavyLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const _GoldPill('PRODUCTIVITY POINTS', icon: Icons.bolt_rounded),
              const Spacer(),
              _GoldPill('Level $level', filled: true),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            '$points',
            style: const TextStyle(
              fontSize: 54,
              fontWeight: FontWeight.w900,
              color: kWhite,
            ),
          ),
          const Text(
            'points earned so far',
            style: TextStyle(fontSize: 12, color: Colors.white70),
          ),
          const SizedBox(height: 18),
          Stack(
            children: [
              Container(
                height: 10,
                decoration: BoxDecoration(
                  color: const Color(0x1AFFFFFF),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              FractionallySizedBox(
                widthFactor: progress == 0 ? 0.02 : progress,
                child: Container(
                  height: 10,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [kGold, Color(0xFFFFD97D)],
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BlobCard extends StatelessWidget {
  final Future<void> Function() onPressed;

  const _BlobCard({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return _GlassCard(
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.asset(
              kBlobAsset,
              width: 90,
              height: 90,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) {
                return Container(
                  width: 90,
                  height: 90,
                  color: kNavy.withOpacity(0.08),
                  child: const Icon(
                    Icons.image_outlined,
                    color: kNavy,
                    size: 32,
                  ),
                );
              },
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Productivity Buddy',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: kNavy,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Tap below whenever you finish something productive and we will add points to your level.',
                  style: TextStyle(fontSize: 12, color: kMuted, height: 1.4),
                ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: onPressed,
                  style: FilledButton.styleFrom(
                    backgroundColor: kNavy,
                  ),
                  icon: const Icon(Icons.add_task_rounded, color: Colors.white),
                  label: const Text('Add Productive Action'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  const _StatsRow();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Expanded(child: _StatTile('🏆', '12', 'Events', kGold)),
        SizedBox(width: 10),
        Expanded(child: _StatTile('👥', '34', 'Members', kNavy)),
        SizedBox(width: 10),
        Expanded(child: _StatTile('⭐', '5', 'Awards', kTeal)),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  final String emoji;
  final String value;
  final String label;
  final Color color;

  const _StatTile(this.emoji, this.value, this.label, this.color);

  @override
  Widget build(BuildContext context) {
    return _GlassCard(
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 8),
      child: Column(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              shape: BoxShape.circle,
              border: Border.all(color: color.withOpacity(0.25)),
            ),
            child: Center(
              child: Text(emoji, style: const TextStyle(fontSize: 20)),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              color: kMuted,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _AnnouncementBanner extends StatelessWidget {
  const _AnnouncementBanner();

  @override
  Widget build(BuildContext context) {
    return _GlassCard(
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [kGold, Color(0xFFFFD97D)],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Center(
              child: Text('📣', style: TextStyle(fontSize: 22)),
            ),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'State Conf Registration Open! 🎉',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: kNavy,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Deadline April 30 — don\'t miss your spot!',
                  style: TextStyle(fontSize: 11, color: kMuted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class EventsPage extends StatelessWidget {
  const EventsPage({super.key});

  static const _events = [
    ('Chapter Meeting', 'Room 204 · 3:30 PM', 'Apr 24', '📌', kGreen, 10),
    ('Leadership Workshop', 'Library B · 4:00 PM', 'Apr 28', '💡', kNavy, 15),
    ('State Conference', 'Seattle Convention Ctr', 'May 03', '🗺️', kGold, 25),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      appBar: const _NavyAppBar('Events', subtitle: 'Chapter Calendar'),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: _events.map((event) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _EventCard(
              title: event.$1,
              location: event.$2,
              date: event.$3,
              emoji: event.$4,
              color: event.$5,
              points: event.$6,
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _EventCard extends StatelessWidget {
  final String title;
  final String location;
  final String date;
  final String emoji;
  final Color color;
  final int points;

  const _EventCard({
    required this.title,
    required this.location,
    required this.date,
    required this.emoji,
    required this.color,
    required this.points,
  });

  @override
  Widget build(BuildContext context) {
    return _GlassCard(
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: color.withOpacity(0.18),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Text(emoji, style: const TextStyle(fontSize: 24)),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: kNavy,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  location,
                  style: const TextStyle(fontSize: 11, color: kMuted),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () async {
                    await _addPoints(
                      amount: points,
                      reason: 'Completed $title',
                    );
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('+$points points for $title')),
                    );
                  },
                  child: Text('Mark Complete (+$points)'),
                ),
              ],
            ),
          ),
          _GoldPill(date, filled: false),
        ],
      ),
    );
  }
}

class ReportsPage extends StatelessWidget {
  const ReportsPage({super.key});

  static const _reports = [
    (
      'Mobile App Development',
      'Full chapter activity summary',
      'https://docs.google.com/document/d/mobile-app-developement_materials',
      20,
    ),
    (
      'Digital Video Production',
      'Budget and expenses',
      'https://docs.google.com/document/d/digital-video-production_materials',
      20,
    ),
    (
      'Public Speaking',
      'Active members and dues status',
      'https://docs.google.com/document/d/public-speaking_materials',
      20,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      appBar: const _NavyAppBar('Reports', subtitle: 'Chapter Documents'),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: _reports.map((report) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _SimpleReportCard(
              title: report.$1,
              desc: report.$2,
              fakeLink: report.$3,
              points: report.$4,
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _SimpleReportCard extends StatelessWidget {
  final String title;
  final String desc;
  final String fakeLink;
  final int points;

  const _SimpleReportCard({
    required this.title,
    required this.desc,
    required this.fakeLink,
    required this.points,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        await _addPoints(
          amount: points,
          reason: 'Opened $title',
        );

        if (!context.mounted) return;

        showDialog<void>(
          context: context,
          builder: (_) => AlertDialog(
            title: Text(title),
            content: SelectableText('$fakeLink\n\n+$points points added'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          ),
        );
      },
      child: _GlassCard(
        child: Row(
          children: [
            Image.asset(
              kBlobAsset,
              width: 48,
              height: 48,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) {
                return const Icon(Icons.description_rounded, size: 36, color: kNavy);
              },
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: kNavy,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    desc,
                    style: const TextStyle(fontSize: 11, color: kMuted),
                  ),
                ],
              ),
            ),
            Text(
              '+$points',
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                color: kGreen,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: _client.auth.onAuthStateChange,
      initialData: AuthState(
        AuthChangeEvent.initialSession,
        _client.auth.currentSession,
      ),
      builder: (context, snapshot) {
        final user = _currentUser(snapshot.data);
        final username = _usernameFromUser(user);
        final points = _pointsFromUser(user);
        final level = _levelFromPoints(points);
        final initials = _initialsFromName(username);
        final lastActivity =
            (user?.userMetadata?['last_activity'] as String?) ?? 'No activity yet';

        return Scaffold(
          backgroundColor: kBg,
          appBar: const _NavyAppBar('My Profile', subtitle: 'Member Details'),
          body: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Center(
                child: Column(
                  children: [
                    Container(
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          colors: [kNavy, kNavyLight],
                        ),
                        border: Border.all(color: kGold, width: 3),
                      ),
                      child: Center(
                        child: Text(
                          initials,
                          style: const TextStyle(
                            color: kWhite,
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      username,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        color: kNavy,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _GoldPill('Level $level · $points pts', filled: true),
                    const SizedBox(height: 18),
                    Image.asset(
                      kBlobAsset,
                      height: 120,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) {
                        return const SizedBox.shrink();
                      },
                    ),
                    const SizedBox(height: 22),
                    _InfoSection(
                      'Chapter Info',
                      [
                        const _InfoRow('School', 'ABC High School', kNavy),
                        const _InfoRow('State', 'Washington', kTeal),
                        _InfoRow('Last Activity', lastActivity, kGreen),
                      ],
                    ),
                    const SizedBox(height: 16),
                    GestureDetector(
                      onTap: () async {
                        await _client.auth.signOut();
                      },
                      child: Container(
                        height: 52,
                        decoration: BoxDecoration(
                          color: kRed.withOpacity(0.07),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: kRed.withOpacity(0.3)),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.logout_rounded, color: kRed, size: 18),
                            SizedBox(width: 8),
                            Text(
                              'Sign Out',
                              style: TextStyle(
                                color: kRed,
                                fontWeight: FontWeight.w800,
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _InfoSection extends StatelessWidget {
  final String title;
  final List<_InfoRow> rows;

  const _InfoSection(this.title, this.rows, {super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title.toUpperCase(),
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w800,
            color: kMuted,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: kGlassCard,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: kBorder),
          ),
          child: Column(children: rows),
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _InfoRow(this.label, this.value, this.color, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: color.withOpacity(0.2)),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            label,
            style: const TextStyle(fontSize: 13, color: kMuted),
          ),
          const Spacer(),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NotifSheet extends StatelessWidget {
  const _NotifSheet();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: kGlassWhite,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: const Text('Notifications'),
    );
  }
}
