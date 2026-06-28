import 'package:flutter/material.dart';
import '../../../../router/routes.dart';
import '../../../../shared/core/constants/dimensions.dart';
import '../../../../shared/widgets/buttons/primary_button.dart';
import '../../../../shared/widgets/buttons/secondary_button.dart';
import '../../../../shared/utils/extension/context_extension.dart';
import '../../../../shared/utils/extension/string_extension.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleLogin() {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      // Mock authentication delay
      Future.delayed(const Duration(milliseconds: 1500), () {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
          // Redirect straight to home dashboard shell
          const HomeRoute().go(context);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.white.c50,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(Dimensions.space24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: Dimensions.space40),
                Text(
                  context.l10n.loginTitle,
                  style: context.typography.displaySm.bold.copyWith(
                    color: context.grey.c900,
                  ),
                ),
                Dimensions.v8,
                Text(
                  'Sign in to explore custom recipes and plan weekly meals.',
                  style: context.typography.textMd.regular.copyWith(
                    color: context.grey.c500,
                  ),
                ),
                const SizedBox(height: Dimensions.space40),
                // Email input
                Text(
                  'Email Address',
                  style: context.typography.textSm.semibold.copyWith(
                    color: context.grey.c700,
                  ),
                ),
                Dimensions.v8,
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  style: context.typography.textMd.regular.copyWith(
                    color: context.grey.c900,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Enter your email',
                    hintStyle: TextStyle(color: context.grey.c400),
                    filled: true,
                    fillColor: context.grey.c50,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(Dimensions.radiusMd),
                      borderSide: BorderSide(color: context.grey.c200),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(Dimensions.radiusMd),
                      borderSide: BorderSide(color: context.grey.c200),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(Dimensions.radiusMd),
                      borderSide: BorderSide(color: context.primary.c500),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: Dimensions.space16,
                      vertical: Dimensions.space16,
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Email is required';
                    }
                    if (!value.trim().isValidEmail) {
                      return 'Please enter a valid email address';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: Dimensions.space20),
                // Password input
                Text(
                  'Password',
                  style: context.typography.textSm.semibold.copyWith(
                    color: context.grey.c700,
                  ),
                ),
                Dimensions.v8,
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  style: context.typography.textMd.regular.copyWith(
                    color: context.grey.c900,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Enter your password',
                    hintStyle: TextStyle(color: context.grey.c400),
                    filled: true,
                    fillColor: context.grey.c50,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(Dimensions.radiusMd),
                      borderSide: BorderSide(color: context.grey.c200),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(Dimensions.radiusMd),
                      borderSide: BorderSide(color: context.grey.c200),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(Dimensions.radiusMd),
                      borderSide: BorderSide(color: context.primary.c500),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: Dimensions.space16,
                      vertical: Dimensions.space16,
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                        color: context.grey.c500,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Password is required';
                    }
                    if (!value.isValidPassword) {
                      return 'Password must be at least 6 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: Dimensions.space32),
                PrimaryButton(
                  label: context.l10n.signIn,
                  onPressed: _handleLogin,
                  isLoading: _isLoading,
                ),
                const SizedBox(height: Dimensions.space24),
                // Or separator
                Row(
                  children: [
                    Expanded(child: Divider(color: context.grey.c200)),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: Dimensions.space16,
                      ),
                      child: Text(
                        'Or Sign In With',
                        style: context.typography.textXs.regular.copyWith(
                          color: context.grey.c400,
                        ),
                      ),
                    ),
                    Expanded(child: Divider(color: context.grey.c200)),
                  ],
                ),
                const SizedBox(height: Dimensions.space24),
                Row(
                  children: [
                    Expanded(
                      child: SecondaryButton(
                        label: 'Google',
                        icon: Icons.g_mobiledata,
                        onPressed: () {},
                      ),
                    ),
                    const SizedBox(width: Dimensions.space16),
                    Expanded(
                      child: SecondaryButton(
                        label: 'Apple',
                        icon: Icons.apple,
                        onPressed: () {},
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: Dimensions.space40),
                Center(
                  child: GestureDetector(
                    onTap: () => const SignUpRoute().go(context),
                    child: RichText(
                      text: TextSpan(
                        text: "Don't have an account? ",
                        style: context.typography.textSm.regular.copyWith(
                          color: context.grey.c500,
                        ),
                        children: [
                          TextSpan(
                            text: 'Sign Up',
                            style: context.typography.textSm.bold.copyWith(
                              color: context.primary.c500,
                            ),
                          ),
                        ],
                      ),
                    ),
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
