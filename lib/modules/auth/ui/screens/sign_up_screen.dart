import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../router/routes.dart';
import '../../../../shared/core/constants/dimensions.dart';
import '../../../../shared/widgets/buttons/primary_button.dart';
import '../../../../shared/utils/extension/context_extension.dart';
import '../../../../shared/utils/extension/string_extension.dart';
import '../../../../shared/di/service_locator.dart';
import '../../../../shared/data/repositories/user_repository.dart';
import '../../bloc/auth_bloc.dart';
import '../../bloc/auth_event.dart';
import '../../bloc/auth_state.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _agreeToTerms = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleRegister(BuildContext context) {
    if (_formKey.currentState!.validate()) {
      if (!_agreeToTerms) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('You must agree to the terms and conditions'),
          ),
        );
        return;
      }

      context.read<AuthBloc>().add(
            SignUpWithEmailAndPasswordRequested(
              email: _emailController.text.trim(),
              password: _passwordController.text,
              name: _nameController.text.trim(),
            ),
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<AuthBloc>(
      create: (context) => AuthBloc(getIt<UserRepository>()),
      child: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthFailure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.error),
                backgroundColor: const Color(0xFFD32F2F),
              ),
            );
          } else if (state is Authenticated) {
            const HomeRoute().go(context);
          }
        },
        builder: (context, state) {
          final isLoading = state is AuthLoading;
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
                      const SizedBox(height: Dimensions.space24),
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new),
                        onPressed: () => const LoginRoute().go(context),
                      ),
                      const SizedBox(height: Dimensions.space16),
                      Text(
                        context.l10n.signUpTitle,
                        style: context.typography.displaySm.bold.copyWith(
                          color: context.grey.c900,
                        ),
                      ),
                      Dimensions.v8,
                      Text(
                        'Join Recipely to start planning your custom menus.',
                        style: context.typography.textMd.regular.copyWith(
                          color: context.grey.c500,
                        ),
                      ),
                      const SizedBox(height: Dimensions.space32),
                      // Full name input
                      Text(
                        'Full Name',
                        style: context.typography.textSm.semibold.copyWith(
                          color: context.grey.c700,
                        ),
                      ),
                      Dimensions.v8,
                      TextFormField(
                        controller: _nameController,
                        style: context.typography.textMd.regular.copyWith(
                          color: context.grey.c900,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Enter your full name',
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
                            return 'Name is required';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: Dimensions.space20),
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
                            return 'Please enter a valid email';
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
                          hintText: 'Create a password',
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
                      const SizedBox(height: Dimensions.space20),
                      // Terms Checkbox
                      Row(
                        children: [
                          Checkbox(
                            value: _agreeToTerms,
                            activeColor: context.primary.c500,
                            onChanged: (value) {
                              setState(() {
                                _agreeToTerms = value ?? false;
                              });
                            },
                          ),
                          Expanded(
                            child: Text(
                              'I agree to the Terms of Service & Privacy Policy',
                              style: context.typography.textXs.regular.copyWith(
                                color: context.grey.c600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: Dimensions.space32),
                      PrimaryButton(
                        label: context.l10n.createAccount,
                        onPressed: () => _handleRegister(context),
                        isLoading: isLoading,
                      ),
                      const SizedBox(height: Dimensions.space32),
                      Center(
                        child: GestureDetector(
                          onTap: () => const LoginRoute().go(context),
                          child: RichText(
                            text: TextSpan(
                              text: 'Already have an account? ',
                              style: context.typography.textSm.regular.copyWith(
                                color: context.grey.c500,
                              ),
                              children: [
                                TextSpan(
                                  text: 'Sign In',
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
        },
      ),
    );
  }
}
