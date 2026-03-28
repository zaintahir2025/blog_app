import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:blog_app/core/utils/app_error_mapper.dart';
import 'package:blog_app/core/utils/app_feedback.dart';
import 'package:blog_app/core/utils/app_validators.dart';
import 'package:blog_app/features/auth/providers/auth_provider.dart';
import 'package:blog_app/features/auth/widgets/auth_shell.dart';

class SignUpScreen extends ConsumerStatefulWidget {
  const SignUpScreen({super.key});

  @override
  ConsumerState<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends ConsumerState<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _fullNameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signUp() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      final signedInImmediately = await ref.read(authRepositoryProvider).signUp(
            email: _emailController.text.trim(),
            password: _passwordController.text.trim(),
            fullName: _fullNameController.text.trim(),
            username: _usernameController.text.trim().toLowerCase(),
          );

      if (!mounted) {
        return;
      }
      if (signedInImmediately) {
        AppFeedback.showSuccess(
          context,
          'Account created successfully. Welcome to Inkwell.',
        );
        context.go('/home');
      } else {
        AppFeedback.showSuccess(
          context,
          'Account created. Please check your email to confirm your address before signing in.',
        );
        context.go('/login');
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

  @override
  Widget build(BuildContext context) {
    return AuthShell(
      title: 'Create account',
      subtitle: 'Start your writing space in a few quick steps.',
      heroTitle: 'Start your story with a clean desk.',
      heroBody:
          'Publish, draft, bookmark, and manage your writing across mobile, desktop, and web.',
      footer: TextButton(
        onPressed: () => context.go('/login'),
        child: Text(
          'Already have an account? Login',
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
                controller: _fullNameController,
                textCapitalization: TextCapitalization.words,
                autofillHints: const [AutofillHints.name],
                validator: AppValidators.fullName,
                decoration: const InputDecoration(
                  labelText: 'Full Name',
                  prefixIcon: Icon(Icons.person_outline),
                ),
              ).animate().fade(delay: 180.ms).slideX(begin: -0.04),
              const SizedBox(height: 16),
              TextFormField(
                controller: _usernameController,
                autocorrect: false,
                validator: AppValidators.username,
                decoration: const InputDecoration(
                  labelText: 'Username',
                  prefixIcon: Icon(Icons.alternate_email),
                ),
              ).animate().fade(delay: 240.ms).slideX(begin: -0.04),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                autofillHints: const [AutofillHints.email],
                validator: AppValidators.email,
                decoration: const InputDecoration(
                  labelText: 'Email Address',
                  prefixIcon: Icon(Icons.email_outlined),
                ),
              ).animate().fade(delay: 300.ms).slideX(begin: -0.04),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                autofillHints: const [AutofillHints.newPassword],
                validator: (value) =>
                    AppValidators.password(value, minLength: 6),
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
              ).animate().fade(delay: 360.ms).slideX(begin: -0.04),
              const SizedBox(height: 22),
              ElevatedButton(
                onPressed: _isLoading ? null : _signUp,
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
                        'Create Account',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
              ).animate().fade(delay: 430.ms).slideY(begin: 0.08),
            ],
          ),
        ),
      ),
    );
  }
}
