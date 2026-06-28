import 'package:flutter/material.dart';
import '../../../../router/routes.dart';
import '../../../../shared/core/constants/dimensions.dart';
import '../../../../shared/widgets/app_bar/app_appbar.dart';
import '../../../../shared/widgets/avatar/profile_avatar.dart';
import '../../../../shared/utils/extension/context_extension.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isDarkMode = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.white.c50,
      appBar: const AppAppBar(title: 'My Profile', showBackButton: false),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(
          horizontal: Dimensions.space24,
          vertical: Dimensions.space20,
        ),
        child: Column(
          children: [
            // User Header Profile info
            const ProfileAvatar(
              name: 'Chef John',
              imageUrl:
                  'https://images.unsplash.com/photo-1577219491135-ce391730fb2c?q=80&w=200',
              radius: 48.0,
            ),
            const SizedBox(height: Dimensions.space16),
            Text(
              'Chef John Doe',
              style: context.typography.textLg.bold.copyWith(
                color: context.grey.c900,
              ),
            ),
            const SizedBox(height: 2.0),
            Text(
              'Food Lover & Home Chef',
              style: context.typography.textSm.medium.copyWith(
                color: context.grey.c500,
              ),
            ),
            const SizedBox(height: Dimensions.space32),
            // User stats row
            Container(
              padding: const EdgeInsets.symmetric(vertical: Dimensions.space16),
              decoration: BoxDecoration(
                color: context.grey.c50,
                borderRadius: BorderRadius.circular(Dimensions.radiusLg),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildStatColumn('124', 'Saved'),
                  Container(
                    width: 1.0,
                    height: 32.0,
                    color: context.grey.c200,
                  ),
                  _buildStatColumn('48', 'Cooked'),
                  Container(
                    width: 1.0,
                    height: 32.0,
                    color: context.grey.c200,
                  ),
                  _buildStatColumn('12', 'Collections'),
                ],
              ),
            ),
            const SizedBox(height: Dimensions.space32),
            // XP progress indicator level
            Align(
              alignment: Alignment.centerLeft,
              child: Row(
                children: [
                  Text(
                    'Cooking Level 8',
                    style: context.typography.textSm.bold.copyWith(
                      color: context.grey.c800,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '320 / 500 XP',
                    style: context.typography.textXs.semibold.copyWith(
                      color: context.primary.c500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: Dimensions.space8),
            ClipRRect(
              borderRadius: BorderRadius.circular(Dimensions.radiusFull),
              child: LinearProgressIndicator(
                value: 0.64,
                minHeight: 8.0,
                backgroundColor: context.grey.c200,
                valueColor: AlwaysStoppedAnimation<Color>(context.primary.c500),
              ),
            ),
            const SizedBox(height: Dimensions.space40),
            // Settings menu options list
            _buildMenuTile(
              icon: Icons.notifications_none,
              title: 'Notifications',
              trailing: Icon(Icons.arrow_forward_ios, size: 16.0, color: context.grey.c400),
              onTap: () => const NotificationsRoute().push(context),
            ),
            const SizedBox(height: Dimensions.space12),
            _buildMenuTile(
              icon: Icons.dark_mode_outlined,
              title: 'Dark Mode',
              trailing: Switch(
                value: _isDarkMode,
                activeThumbColor: context.primary.c500,
                onChanged: (value) {
                  setState(() {
                    _isDarkMode = value;
                  });
                },
              ),
              onTap: () {},
            ),
            const SizedBox(height: Dimensions.space12),
            _buildMenuTile(
              icon: Icons.settings_outlined,
              title: 'Settings',
              trailing: Icon(Icons.arrow_forward_ios, size: 16.0, color: context.grey.c400),
              onTap: () => const SettingsRoute().push(context),
            ),
            const SizedBox(height: Dimensions.space12),
            _buildMenuTile(
              icon: Icons.logout,
              title: 'Log Out',
              titleColor: context.error.c500,
              trailing: Icon(Icons.arrow_forward_ios, size: 16.0, color: context.error.c200),
              onTap: () => const LoginRoute().go(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatColumn(String val, String title) {
    return Column(
      children: [
        Text(
          val,
          style: context.typography.textLg.bold.copyWith(
            color: context.grey.c900,
          ),
        ),
        const SizedBox(height: 2.0),
        Text(
          title,
          style: context.typography.textXs.regular.copyWith(
            color: context.grey.c500,
          ),
        ),
      ],
    );
  }

  Widget _buildMenuTile({
    required IconData icon,
    required String title,
    required Widget trailing,
    required VoidCallback onTap,
    Color? titleColor,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: Dimensions.space16,
          vertical: Dimensions.space12,
        ),
        decoration: BoxDecoration(
          color: context.grey.c50,
          borderRadius: BorderRadius.circular(Dimensions.radiusMd),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: titleColor ?? context.grey.c700,
              size: 22.0,
            ),
            const SizedBox(width: Dimensions.space16),
            Expanded(
              child: Text(
                title,
                style: context.typography.textSm.semibold.copyWith(
                  color: titleColor ?? context.grey.c800,
                ),
              ),
            ),
            trailing,
          ],
        ),
      ),
    );
  }
}
