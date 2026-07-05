import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../router/routes.dart';
import '../../../../shared/di/service_locator.dart';
import '../../../../shared/data/repositories/user_repository.dart';
import '../../bloc/settings_bloc.dart';
import '../../bloc/settings_event.dart';
import '../../bloc/settings_state.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  bool _isSavingProfile = false;
  bool _isUpdatingEmail = false;
  bool _isLoggingOut = false;

  @override
  void dispose() {
    _nameController.dispose();
    _titleController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => SettingsBloc(getIt<UserRepository>())..add(LoadSettings()),
      child: BlocListener<SettingsBloc, SettingsState>(
        listenWhen: (previous, current) => previous.activeSubSection != current.activeSubSection,
        listener: (context, state) {
          if (state.activeSubSection == 'profile_details') {
            _nameController.text = state.name;
            _titleController.text = state.title;
          } else if (state.activeSubSection == 'email_address') {
            _emailController.text = state.email;
          }
        },
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
      case 'profile_details':
        return 'Profile Details';
      case 'email_address':
        return 'Email Address';
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
      case 'profile_details':
        return _buildProfileDetailsView(context, state);
      case 'email_address':
        return _buildEmailAddressView(context, state);
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
              subtitle: '${state.name}, ${state.title}',
              onTap: () {
                context.read<SettingsBloc>().add(const SelectSubSection('profile_details'));
              },
            ),
            const Divider(color: Color(0xFFEFEBE4), height: 1),
            _buildSettingTile(
              icon: Icons.alternate_email_rounded,
              title: 'Email Address',
              subtitle: state.email,
              onTap: () {
                context.read<SettingsBloc>().add(const SelectSubSection('email_address'));
              },
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
                disabledBackgroundColor: const Color(0xFFFDECEB),
              ),
              onPressed: _isLoggingOut
                  ? null
                  : () async {
                      setState(() => _isLoggingOut = true);
                      try {
                        await getIt<UserRepository>().signOut();
                      } catch (_) {}
                      await Future.delayed(const Duration(milliseconds: 500));
                      if (!context.mounted) return;
                      const LoginRoute().go(context);
                    },
              child: _isLoggingOut
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.0,
                        color: Color(0xFFD32F2F),
                      ),
                    )
                  : Text(
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
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF3A2818).withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: children,
        ),
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
        return AppThemeDialog(
          onSelect: (theme) {
            context.read<SettingsBloc>().add(UpdateThemeMode(theme));
          },
        );
      },
    );
  }

  // ── Profile Details edit sub-view ─────────────────────────────────────────
  Widget _buildProfileDetailsView(BuildContext context, SettingsState state) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Stack(
              children: [
                Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3.0),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 12,
                      ),
                    ],
                  ),
                  child: const ClipOval(
                    child: Icon(
                      Icons.person_rounded,
                      color: Color(0xFF8C8A87),
                      size: 48,
                    ),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xFFF47B20),
                    ),
                    child: const Icon(
                      Icons.camera_alt_outlined,
                      color: Colors.white,
                      size: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // Name Input
          _buildInputLabel('Full Name'),
          const SizedBox(height: 8),
          _buildTextField(
            controller: _nameController,
            hint: 'Enter your full name',
            icon: Icons.person_outline_rounded,
          ),
          const SizedBox(height: 20),

          // Title Input
          _buildInputLabel('Job Title / Bio'),
          const SizedBox(height: 8),
          _buildTextField(
            controller: _titleController,
            hint: 'e.g., Home Chef',
            icon: Icons.work_outline_rounded,
          ),
          const SizedBox(height: 40),

          // Save Changes
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF47B20),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
                disabledBackgroundColor: const Color(0xFFF47B20).withValues(alpha: 0.6),
              ),
              onPressed: _isSavingProfile
                  ? null
                  : () async {
                      setState(() => _isSavingProfile = true);
                      context.read<SettingsBloc>().add(UpdateProfile(
                            name: _nameController.text.trim(),
                            title: _titleController.text.trim(),
                          ));
                      await Future.delayed(const Duration(milliseconds: 600));
                      if (!context.mounted) return;
                      setState(() => _isSavingProfile = false);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Profile details updated successfully!'),
                          backgroundColor: Color(0xFFF47B20),
                        ),
                      );
                    },
              child: _isSavingProfile
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.0,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      'Save Changes',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Email Address edit sub-view ───────────────────────────────────────────
  Widget _buildEmailAddressView(BuildContext context, SettingsState state) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Current Email Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFEFEBE4), width: 1.0),
            ),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFFFFF2D9),
                  ),
                  child: const Icon(
                    Icons.alternate_email_rounded,
                    color: Color(0xFFF47B20),
                    size: 18,
                  ),
                ),
                const SizedBox(width: 14),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Current Email Address',
                      style: GoogleFonts.poppins(
                        fontSize: 11.5,
                        color: const Color(0xFF8C8A87),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      state.email,
                      style: GoogleFonts.poppins(
                        fontSize: 14.5,
                        color: const Color(0xFF1F1E1C),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // New Email Input
          _buildInputLabel('New Email Address'),
          const SizedBox(height: 8),
          _buildTextField(
            controller: _emailController,
            hint: 'Enter your new email address',
            icon: Icons.mail_outline_rounded,
          ),
          const SizedBox(height: 40),

          // Update Email button
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF47B20),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
                disabledBackgroundColor: const Color(0xFFF47B20).withValues(alpha: 0.6),
              ),
              onPressed: _isUpdatingEmail
                  ? null
                  : () async {
                      final email = _emailController.text.trim();
                      if (email.isNotEmpty && email.contains('@')) {
                        setState(() => _isUpdatingEmail = true);
                        context.read<SettingsBloc>().add(UpdateEmail(email));
                        await Future.delayed(const Duration(milliseconds: 600));
                        if (!context.mounted) return;
                        setState(() => _isUpdatingEmail = false);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Email address updated successfully!'),
                            backgroundColor: Color(0xFFF47B20),
                          ),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Please enter a valid email address.'),
                            backgroundColor: Color(0xFFD32F2F),
                          ),
                        );
                      }
                    },
              child: _isUpdatingEmail
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.0,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      'Update Email',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(left: 4.0),
      child: Text(
        label,
        style: GoogleFonts.poppins(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: const Color(0xFF1F1E1C),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        style: GoogleFonts.poppins(
          fontSize: 14.5,
          color: const Color(0xFF1F1E1C),
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.poppins(
            fontSize: 13.5,
            color: const Color(0xFFB5B3B0),
          ),
          prefixIcon: Icon(icon, color: const Color(0xFF8C8A87), size: 20),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFFEFEBE4), width: 1.0),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFFEFEBE4), width: 1.0),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFFF47B20), width: 1.5),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
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

class AppThemeDialog extends StatelessWidget {
  final Function(String) onSelect;
  const AppThemeDialog({required this.onSelect, super.key});

  @override
  Widget build(BuildContext context) {
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
              onSelect('system');
              Navigator.pop(context);
            },
          ),
          ListTile(
            title: Text('Light Mode', style: GoogleFonts.poppins(fontSize: 14)),
            onTap: () {
              onSelect('light');
              Navigator.pop(context);
            },
          ),
          ListTile(
            title: Text('Dark Mode', style: GoogleFonts.poppins(fontSize: 14)),
            onTap: () {
              onSelect('dark');
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }
}
