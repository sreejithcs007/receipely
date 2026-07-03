import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../router/routes.dart';
import '../../bloc/settings_bloc.dart';
import '../../bloc/settings_event.dart';
import '../../bloc/settings_state.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => SettingsBloc()..add(LoadSettings()),
      child: BlocBuilder<SettingsBloc, SettingsState>(
        builder: (context, state) {
          final isMain = state.activeSubSection == 'main';
          final title = _getSectionTitle(state.activeSubSection);

          return Scaffold(
            backgroundColor: const Color(0xFFFAF7F2), // Canvas
            appBar: AppBar(
              backgroundColor: const Color(0xFFFAF7F2),
              elevation: 0,
              leading: GestureDetector(
                onTap: () {
                  if (isMain) {
                    Navigator.pop(context);
                  } else {
                    context.read<SettingsBloc>().add(const SelectSubSection('main'));
                  }
                },
                child: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: Color(0xFF1F1E1C),
                  size: 20,
                ),
              ),
              title: Text(
                title,
                style: GoogleFonts.playfairDisplay(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1F1E1C),
                ),
              ),
              centerTitle: true,
            ),
            body: SafeArea(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: _buildBody(context, state),
              ),
            ),
          );
        },
      ),
    );
  }

  String _getSectionTitle(String section) {
    switch (section) {
      case 'terms':
        return 'Terms & Conditions';
      case 'privacy':
        return 'Data & Privacy';
      case 'about':
        return 'About Recipely';
      default:
        return 'Settings';
    }
  }

  Widget _buildBody(BuildContext context, SettingsState state) {
    switch (state.activeSubSection) {
      case 'terms':
        return _buildTermsView();
      case 'privacy':
        return _buildPrivacyView();
      case 'about':
        return _buildAboutView();
      default:
        return _buildMainSettings(context, state);
    }
  }

  Widget _buildMainSettings(BuildContext context, SettingsState state) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Account Category ────────────────────────────────────────────────
          _buildCategoryHeader('Account Settings'),
          const SizedBox(height: 12),
          _buildGroupContainer([
            _buildSettingTile(
              icon: Icons.person_outline_rounded,
              title: 'Profile Details',
              subtitle: 'Sarah Johnson, Home Chef',
              onTap: () {},
            ),
            const Divider(color: Color(0xFFEFEBE4), height: 1),
            _buildSettingTile(
              icon: Icons.alternate_email_rounded,
              title: 'Email Address',
              subtitle: 'sarah.j@recipely.com',
              onTap: () {},
            ),
          ]),

          const SizedBox(height: 28),

          // ── Preferences Category ────────────────────────────────────────────
          _buildCategoryHeader('App Preferences'),
          const SizedBox(height: 12),
          _buildGroupContainer([
            // Push Notifications Switch
            ListTile(
              leading: const Icon(Icons.notifications_none_rounded, color: Color(0xFF8C8A87)),
              title: Text(
                'Push Notifications',
                style: GoogleFonts.poppins(fontSize: 14.5, fontWeight: FontWeight.w500, color: const Color(0xFF1F1E1C)),
              ),
              trailing: Switch(
                value: state.pushNotifications,
                activeTrackColor: const Color(0xFFFFE0A3),
                activeThumbColor: const Color(0xFFF47B20),
                onChanged: (value) {
                  context.read<SettingsBloc>().add(TogglePushNotifications());
                },
              ),
            ),
            const Divider(color: Color(0xFFEFEBE4), height: 1),
            // Newsletter Switch
            ListTile(
              leading: const Icon(Icons.mail_outline_rounded, color: Color(0xFF8C8A87)),
              title: Text(
                'Email Newsletters',
                style: GoogleFonts.poppins(fontSize: 14.5, fontWeight: FontWeight.w500, color: const Color(0xFF1F1E1C)),
              ),
              trailing: Switch(
                value: state.emailNewsletters,
                activeTrackColor: const Color(0xFFFFE0A3),
                activeThumbColor: const Color(0xFFF47B20),
                onChanged: (value) {
                  context.read<SettingsBloc>().add(ToggleEmailNewsletters());
                },
              ),
            ),
            const Divider(color: Color(0xFFEFEBE4), height: 1),
            // Theme Mode
            _buildSettingTile(
              icon: Icons.dark_mode_outlined,
              title: 'Theme Mode',
              subtitle: state.activeTheme.toUpperCase(),
              onTap: () => _showThemeSelector(context),
            ),
          ]),

          const SizedBox(height: 28),

          // ── Legal & Info Category ───────────────────────────────────────────
          _buildCategoryHeader('Legal & Information'),
          const SizedBox(height: 12),
          _buildGroupContainer([
            _buildSettingTile(
              icon: Icons.description_outlined,
              title: 'Terms and Conditions',
              subtitle: 'Usage guidelines & safety',
              onTap: () {
                context.read<SettingsBloc>().add(const SelectSubSection('terms'));
              },
            ),
            const Divider(color: Color(0xFFEFEBE4), height: 1),
            _buildSettingTile(
              icon: Icons.privacy_tip_outlined,
              title: 'Data and Privacy',
              subtitle: 'Data usage & cookie policies',
              onTap: () {
                context.read<SettingsBloc>().add(const SelectSubSection('privacy'));
              },
            ),
            const Divider(color: Color(0xFFEFEBE4), height: 1),
            _buildSettingTile(
              icon: Icons.info_outline_rounded,
              title: 'About Recipely',
              subtitle: 'App version & details',
              onTap: () {
                context.read<SettingsBloc>().add(const SelectSubSection('about'));
              },
            ),
          ]),

          const SizedBox(height: 36),

          // ── Log Out Button ──────────────────────────────────────────────────
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFDECEB),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: const BorderSide(color: Color(0xFFF8B2B2), width: 1.0),
                ),
              ),
              onPressed: () {
                const LoginRoute().go(context);
              },
              child: Text(
                'Log Out',
                style: GoogleFonts.poppins(
                  color: const Color(0xFFD32F2F),
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildCategoryHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4.0),
      child: Text(
        title,
        style: GoogleFonts.poppins(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: const Color(0xFFF47B20),
        ),
      ),
    );
  }

  Widget _buildGroupContainer(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF3A2818).withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: children,
      ),
    );
  }

  Widget _buildSettingTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFF8C8A87), size: 22),
      title: Text(
        title,
        style: GoogleFonts.poppins(
          fontSize: 14.5,
          fontWeight: FontWeight.w500,
          color: const Color(0xFF1F1E1C),
        ),
      ),
      subtitle: Text(
        subtitle,
        style: GoogleFonts.poppins(
          fontSize: 12,
          color: const Color(0xFF8C8A87),
        ),
      ),
      trailing: const Icon(
        Icons.chevron_right_rounded,
        color: Color(0xFFB5B3B0),
        size: 20,
      ),
      onTap: onTap,
    );
  }

  void _showThemeSelector(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            'Select Theme',
            style: GoogleFonts.playfairDisplay(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: Text('System Default', style: GoogleFonts.poppins(fontSize: 14)),
                onTap: () {
                  context.read<SettingsBloc>().add(const UpdateThemeMode('system'));
                  Navigator.pop(dialogContext);
                },
              ),
              ListTile(
                title: Text('Light Mode', style: GoogleFonts.poppins(fontSize: 14)),
                onTap: () {
                  context.read<SettingsBloc>().add(const UpdateThemeMode('light'));
                  Navigator.pop(dialogContext);
                },
              ),
              ListTile(
                title: Text('Dark Mode', style: GoogleFonts.poppins(fontSize: 14)),
                onTap: () {
                  context.read<SettingsBloc>().add(const UpdateThemeMode('dark'));
                  Navigator.pop(dialogContext);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // ── Terms & Conditions sub-view ──────────────────────────────────────────
  Widget _buildTermsView() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildLegalHeader('1. Acceptance of Terms'),
          _buildLegalBody(
            'By accessing or using Recipely, you agree to comply with and be bound by these Terms and Conditions. Please review them carefully before using our application.',
          ),
          const SizedBox(height: 20),
          _buildLegalHeader('2. Cooking & Food Safety'),
          _buildLegalBody(
            'Recipely provides cooking guidelines, ingredients, and recipe step guides for general reference. It is your responsibility to verify food allergens, ensure safe internal temperatures for meats, and handle kitchen utensils with appropriate caution.',
          ),
          const SizedBox(height: 20),
          _buildLegalHeader('3. User Submissions'),
          _buildLegalBody(
            'When you publish ratings, cook counts, or custom notes inside Recipely, you grant us a non-exclusive, worldwide, royalty-free license to display, modify, and distribute your content across our platform services.',
          ),
          const SizedBox(height: 20),
          _buildLegalHeader('4. Modifications'),
          _buildLegalBody(
            'We reserve the right to modify these terms at any time. Continued usage of the application indicates your active agreement to any updated regulations.',
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  // ── Data & Privacy sub-view ───────────────────────────────────────────────
  Widget _buildPrivacyView() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildLegalHeader('1. Information We Collect'),
          _buildLegalBody(
            'We collect details to personalize your experience, such as saved recipe booklists, dietary tags selected in searches, and completed step counters. Account identifiers are stored securely in local encryption storage.',
          ),
          const SizedBox(height: 20),
          _buildLegalHeader('2. Local Storage Usage'),
          _buildLegalBody(
            'We use secure storage mechanisms on your device to persist active login sessions, cache recent searches, and preserve cooking achievements level indicators so the app remains accessible offline.',
          ),
          const SizedBox(height: 20),
          _buildLegalHeader('3. Third-party APIs'),
          _buildLegalBody(
            'We do not sell or trade your data. Some network calls are routed through certified APIs (e.g., Supabase authentication) which comply with highest data encryption standard safety protocols.',
          ),
          const SizedBox(height: 20),
          _buildLegalHeader('4. Your Choices & Deletion'),
          _buildLegalBody(
            'You may clear cached preferences, modify cookies, or request complete account erasure by contacting support@recipely.com at any time.',
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  // ── About Recipely sub-view ───────────────────────────────────────────────
  Widget _buildAboutView() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 20),
          // App Logo Placeholder icon
          Container(
            width: 84,
            height: 84,
            decoration: BoxDecoration(
              color: const Color(0xFFFFF2D9),
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Icon(
              Icons.soup_kitchen_rounded,
              color: Color(0xFFF47B20),
              size: 44,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Recipely App',
            style: GoogleFonts.playfairDisplay(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1F1E1C),
            ),
          ),
          Text(
            'Version 1.0.0',
            style: GoogleFonts.poppins(
              fontSize: 12.5,
              color: const Color(0xFF8C8A87),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 32),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              'Recipely is a premium recipe app designed to elevate your home-cooking experience. Discover restaurant-grade culinary creations, toggle custom servings lists with strike-through checkboxes, and guide yourself step-by-step through elaborate cooking techniques with progress trackers.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 13.5,
                color: const Color(0xFF8C8A87),
                fontWeight: FontWeight.w400,
                height: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 40),
          const Divider(color: Color(0xFFEFEBE4), indent: 40, endIndent: 40),
          const SizedBox(height: 16),
          Text(
            '© 2026 Recipely Inc.',
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: const Color(0xFFB5B3B0),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegalHeader(String header) {
    return Text(
      header,
      style: GoogleFonts.playfairDisplay(
        fontSize: 16.5,
        fontWeight: FontWeight.w700,
        color: const Color(0xFF1F1E1C),
      ),
    );
  }

  Widget _buildLegalBody(String body) {
    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: Text(
        body,
        style: GoogleFonts.poppins(
          fontSize: 13.5,
          color: const Color(0xFF8C8A87),
          fontWeight: FontWeight.w400,
          height: 1.45,
        ),
      ),
    );
  }
}
