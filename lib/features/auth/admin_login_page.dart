import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminLoginPage extends StatefulWidget {
  const AdminLoginPage({super.key});

  @override
  State<AdminLoginPage> createState() => _AdminLoginPageState();
}

class _AdminLoginPageState extends State<AdminLoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isLoading = false;

  Future<void> _loginAdmin() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    debugPrint('ADMIN LOGIN DEBUG: login button clicked');
    debugPrint('ADMIN LOGIN DEBUG: entered email = $email');

    if (email.isEmpty || password.isEmpty) {
      debugPrint('ADMIN LOGIN DEBUG: email or password empty');
      _showMessage('Email and password are required.', Colors.orange.shade700);
      return;
    }

    setState(() => _isLoading = true);

    try {
      debugPrint('ADMIN LOGIN DEBUG: signing in with Firebase Auth...');

      final userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: password);

      final uid = userCredential.user?.uid;
      final authEmail = userCredential.user?.email;

      debugPrint('ADMIN LOGIN DEBUG: Auth success');
      debugPrint('ADMIN LOGIN DEBUG: auth email = $authEmail');
      debugPrint('ADMIN LOGIN DEBUG: auth uid = $uid');
      debugPrint('ADMIN LOGIN DEBUG: checking Firestore path = admins/$uid');

      if (uid == null) {
        debugPrint('ADMIN LOGIN DEBUG: uid is null after auth success');
        if (!mounted) return;
        _showMessage('Login error: user id not found.', Colors.red.shade700);
        return;
      }

      final adminDoc = await FirebaseFirestore.instance
          .collection('admins')
          .doc(uid)
          .get();

      debugPrint('ADMIN LOGIN DEBUG: Firestore read success');
      debugPrint('ADMIN LOGIN DEBUG: admin doc exists = ${adminDoc.exists}');
      debugPrint('ADMIN LOGIN DEBUG: admin doc data = ${adminDoc.data()}');

      if (adminDoc.exists) {
        if (!mounted) return;
        _showMessage('Login successful.', Colors.green.shade700);
        Navigator.pushReplacementNamed(context, '/dashboard');
      } else {
        debugPrint('ADMIN LOGIN DEBUG: admin doc not found, signing out');
        await FirebaseAuth.instance.signOut();
        if (!mounted) return;
        _showMessage(
          'Access denied. This account is not an admin.',
          Colors.red.shade700,
        );
      }
    } on FirebaseAuthException catch (e) {
      debugPrint('ADMIN LOGIN DEBUG: Firebase Auth error');
      debugPrint('ADMIN LOGIN DEBUG: auth error code = ${e.code}');
      debugPrint('ADMIN LOGIN DEBUG: auth error message = ${e.message}');

      var errorMessage = 'Login failed.';
      if (e.code == 'user-not-found' || e.code == 'invalid-email') {
        errorMessage = 'No admin found for that email.';
      } else if (e.code == 'wrong-password' || e.code == 'invalid-credential') {
        errorMessage = 'Wrong password provided.';
      } else {
        errorMessage = e.message ?? errorMessage;
      }

      if (!mounted) return;
      _showMessage(errorMessage, Colors.red.shade700);
    } on FirebaseException catch (e) {
      debugPrint('ADMIN LOGIN DEBUG: Firebase/Firestore error');
      debugPrint('ADMIN LOGIN DEBUG: plugin = ${e.plugin}');
      debugPrint('ADMIN LOGIN DEBUG: code = ${e.code}');
      debugPrint('ADMIN LOGIN DEBUG: message = ${e.message}');

      if (!mounted) return;
      _showMessage('Firestore error: ${e.code}', Colors.red.shade700);
    } catch (e, stackTrace) {
      debugPrint('ADMIN LOGIN DEBUG: unknown error = $e');
      debugPrint('ADMIN LOGIN DEBUG: stackTrace = $stackTrace');

      if (!mounted) return;
      _showMessage('Error: $e', Colors.red.shade700);
    } finally {
      debugPrint('ADMIN LOGIN DEBUG: login flow finished');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showMessage(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FB),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= 920;

          return Row(
            children: [
              if (wide) const Expanded(child: _LoginBrandPanel()),
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.symmetric(
                      horizontal: wide ? 56 : 24,
                      vertical: 32,
                    ),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 430),
                      child: _LoginFormCard(
                        emailController: _emailController,
                        passwordController: _passwordController,
                        isPasswordVisible: _isPasswordVisible,
                        isLoading: _isLoading,
                        onTogglePassword: () => setState(
                          () => _isPasswordVisible = !_isPasswordVisible,
                        ),
                        onLogin: _loginAdmin,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _LoginBrandPanel extends StatelessWidget {
  const _LoginBrandPanel();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: double.infinity,
      color: const Color(0xFF111827),
      padding: const EdgeInsets.all(56),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: const Color(0xFFF59E0B),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.local_taxi_rounded,
                  color: Color(0xFF111827),
                  size: 27,
                ),
              ),
              const SizedBox(width: 14),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'AIAPRTD',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Super Admin Console',
                    style: TextStyle(
                      color: Color(0xFF9CA3AF),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const Spacer(),
          const Text(
            'Control the taxi network with clarity.',
            style: TextStyle(
              color: Colors.white,
              fontSize: 36,
              height: 1.08,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'Live members, dispatch activity, bookings, support tickets, rates, and admin approvals in one secure dashboard.',
            style: TextStyle(
              color: Color(0xFFD1D5DB),
              fontSize: 15,
              height: 1.55,
            ),
          ),
          const SizedBox(height: 34),
          const Row(
            children: [
              _BrandMetric(value: '24/7', label: 'operations'),
              SizedBox(width: 14),
              _BrandMetric(value: 'Live', label: 'tracking'),
              SizedBox(width: 14),
              _BrandMetric(value: 'Secure', label: 'access'),
            ],
          ),
          const Spacer(),
          const Text(
            '2026 AIAPRTD. All rights reserved.',
            style: TextStyle(color: Color(0xFF6B7280), fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _BrandMetric extends StatelessWidget {
  final String value;
  final String label;

  const _BrandMetric({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFF1F2937),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFF374151)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFFF59E0B),
                fontSize: 17,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFFD1D5DB),
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoginFormCard extends StatelessWidget {
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final bool isPasswordVisible;
  final bool isLoading;
  final VoidCallback onTogglePassword;
  final VoidCallback onLogin;

  const _LoginFormCard({
    required this.emailController,
    required this.passwordController,
    required this.isPasswordVisible,
    required this.isLoading,
    required this.onTogglePassword,
    required this.onLogin,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF111827).withValues(alpha: .07),
            blurRadius: 28,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: AutofillGroup(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.admin_panel_settings_rounded,
                size: 28,
                color: Color(0xFF2563EB),
              ),
            ),
            const SizedBox(height: 22),
            const Text(
              'Admin sign in',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w900,
                color: Color(0xFF111827),
              ),
            ),
            const SizedBox(height: 7),
            const Text(
              'Use your authorized admin account to continue.',
              style: TextStyle(
                color: Color(0xFF6B7280),
                fontSize: 13,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 26),
            TextField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              autofillHints: const [
                AutofillHints.username,
                AutofillHints.email,
              ],
              decoration: const InputDecoration(
                labelText: 'Admin Email',
                prefixIcon: Icon(
                  Icons.email_outlined,
                  color: Color(0xFF2563EB),
                ),
              ),
              onSubmitted: (_) => isLoading ? null : onLogin(),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: passwordController,
              obscureText: !isPasswordVisible,
              autofillHints: const [AutofillHints.password],
              decoration: InputDecoration(
                labelText: 'Password',
                prefixIcon: const Icon(
                  Icons.lock_outline_rounded,
                  color: Color(0xFF2563EB),
                ),
                suffixIcon: Tooltip(
                  message: isPasswordVisible
                      ? 'Hide password'
                      : 'Show password',
                  child: IconButton(
                    icon: Icon(
                      isPasswordVisible
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: const Color(0xFF6B7280),
                    ),
                    onPressed: onTogglePassword,
                  ),
                ),
              ),
              onSubmitted: (_) => isLoading ? null : onLogin(),
            ),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () {},
                child: const Text(
                  'Forgot password?',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: isLoading ? null : onLogin,
                icon: isLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(
                        Icons.login_rounded,
                        color: Colors.white,
                        size: 19,
                      ),
                label: Text(
                  isLoading ? 'Signing in...' : 'Secure Login',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF111827),
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
