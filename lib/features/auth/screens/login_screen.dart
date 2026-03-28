import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:blog_app/core/utils/app_error_mapper.dart';
import 'package:blog_app/core/utils/app_feedback.dart';
import 'package:blog_app/core/utils/app_validators.dart';
import 'package:blog_app/features/auth/providers/auth_provider.dart';
import 'package:blog_app/features/auth/widgets/auth_shell.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);
    try {
      await ref.read(authRepositoryProvider).signIn(
            email: _emailController.text.trim(),
            password: _passwordController.text.trim(),
          );
      if (mounted) {
        context.go('/home');
      }
    } catch (e) {
      if (!mounted) {
        return;
      }
      AppFeedback.showError(context, AppErrorMapper.readable(e));
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _forgotPassword() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      AppFeedback.showInfo(context, 'Enter your email first.');
      return;
    }

    try {
      await ref.read(authRepositoryProvider).resetPassword(email);
      if (!mounted) {
        return;
      }
      AppFeedback.showSuccess(
        context,
        'Password reset instructions were sent to your email.',
      );
    } catch (e) {
      if (!mounted) {
        return;
      }
      AppFeedback.showError(context, AppErrorMapper.readable(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthShell(
      title: 'Log in',
      subtitle: 'Continue to your reading and writing workspace.',
      heroTitle: 'Tell your story with us.',
      heroBody:
          'Pick up drafts, discover thoughtful writing, and keep your work close on every screen.',
      footer: TextButton(
        onPressed: () => context.push('/signup'),
        child: Text(
          "New here? Create an account",
          style: TextStyle(
            color: Theme.of(context).colorScheme.primary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      child: Form(
        key: _formKey,
        child: AutofillGroup(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                autofillHints: const [AutofillHints.email],
                validator: AppValidators.email,
                decoration: const InputDecoration(
                  labelText: 'Email Address',
                  prefixIcon: Icon(Icons.email_outlined),
                ),
              ).animate().fade(delay: 250.ms).slideX(begin: -0.04),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                autofillHints: const [AutofillHints.password],
                onFieldSubmitted: (_) => _login(),
                validator: AppValidators.password,
                decoration: InputDecoration(
                  labelText: 'Password',
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off
                          : Icons.visibility,
                    ),
                    onPressed: () => setState(
                      () => _obscurePassword = !_obscurePassword,
                    ),
                  ),
                ),
              ).animate().fade(delay: 320.ms).slideX(begin: -0.04),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: _forgotPassword,
                  child: const Text('Forgot password?'),
                ),
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: _isLoading ? null : _login,
                child: _isLoading
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'Login',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
              ).animate().fade(delay: 380.ms).slideY(begin: 0.08),
            ],
          ),
        ),
      ),
    );
  }
}
