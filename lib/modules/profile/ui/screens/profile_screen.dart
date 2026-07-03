import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../router/routes.dart';
import '../../bloc/profile_bloc.dart';
import '../../bloc/profile_event.dart';
import '../../bloc/profile_state.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => ProfileBloc()..add(LoadProfilePage()),
      child: BlocListener<ProfileBloc, ProfileState>(
        listener: (context, state) {
          if (state.showHelpBottomSheet) {
            _showHelpCenterBottomSheet(context);
          }
        },
        child: BlocBuilder<ProfileBloc, ProfileState>(
          builder: (context, state) {
            return Scaffold(
              backgroundColor: const Color(0xFFFAF7F2), // Canvas background
              body: SafeArea(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
                  child: Column(
                    children: [
                      // ── Avatar & Name & Chef Badge ─────────────────────────
                      _buildHeaderAvatar(state),

                      const SizedBox(height: 24),

                      // ── Stats Card (Excluding Followers) ───────────────────
                      _buildStatsCard(state),

                      const SizedBox(height: 32),

                      // ── Achievements Row ───────────────────────────────────
                      _buildAchievementsSection(),

                      const SizedBox(height: 32),

                      // ── Actions Card ──────────────────────────────────────
                      _buildActionsCard(context),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeaderAvatar(ProfileState state) {
    return Column(
      children: [
        Center(
          child: Stack(
            children: [
              // Circular Photo
              Container(
                width: 110,
                height: 110,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 4.0),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF3A2818).withValues(alpha: 0.08),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipOval(
                  child: Image.asset(
                    state.imageUrl,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              // Floating Edit Pencil button
              Positioned(
                bottom: 2,
                right: 2,
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                    border: Border.all(color: const Color(0xFFEFEBE4), width: 1.0),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.edit_outlined,
                    color: Color(0xFF8C8A87),
                    size: 16,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Name
        Text(
          state.name,
          style: GoogleFonts.playfairDisplay(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF1F1E1C),
          ),
        ),
        const SizedBox(height: 8),

        // Chef level badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF2D9),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFFFE0A3), width: 1.0),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.soup_kitchen_outlined,
                color: Color(0xFFF47B20),
                size: 15,
              ),
              const SizedBox(width: 6),
              Text(
                state.level,
                style: GoogleFonts.poppins(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFFF47B20),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatsCard(ProfileState state) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
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
      child: Row(
        children: [
          // Saved Column
          Expanded(
            child: Column(
              children: [
                const Icon(Icons.bookmark_outline_rounded, color: Color(0xFFF47B20), size: 24),
                const SizedBox(height: 6),
                Text(
                  'Saved',
                  style: GoogleFonts.poppins(
                    fontSize: 12.5,
                    color: const Color(0xFF8C8A87),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${state.savedCount}',
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1F1E1C),
                  ),
                ),
              ],
            ),
          ),
          // Vertical Divider
          Container(
            width: 1.2,
            height: 52,
            color: const Color(0xFFEFEBE4),
          ),
          // Cooked Column
          Expanded(
            child: Column(
              children: [
                const Icon(Icons.soup_kitchen_outlined, color: Color(0xFF4CAF50), size: 24),
                const SizedBox(height: 6),
                Text(
                  'Cooked',
                  style: GoogleFonts.poppins(
                    fontSize: 12.5,
                    color: const Color(0xFF8C8A87),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${state.cookedCount}',
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1F1E1C),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAchievementsSection() {
    final achievements = [
      _AchievementItem('First Recipe', Icons.restaurant_rounded, 0xFFEAF5E3, 0xFF4CAF50),
      _AchievementItem('Home Cook', Icons.soup_kitchen_rounded, 0xFFFDECEB, 0xFFE91E63),
      _AchievementItem('Week Streak', Icons.military_tech_rounded, 0xFFFFF2D9, 0xFFF47B20, count: 3),
      _AchievementItem('Baking Star', Icons.cake_rounded, 0xFFFAF0F5, 0xFF9C27B0),
      _AchievementItem('Recipe Keeper', Icons.book_rounded, 0xFFE2F3E3, 0xFF2E7D32),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Achievements',
              style: GoogleFonts.playfairDisplay(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1F1E1C),
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'View all',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFFF47B20),
                  ),
                ),
                const SizedBox(width: 2),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: Color(0xFFF47B20),
                  size: 16,
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 94,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: achievements.length,
            separatorBuilder: (_, __) => const SizedBox(width: 14),
            itemBuilder: (context, index) {
              final ach = achievements[index];
              return Column(
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      // Badge Circle
                      Container(
                        width: 54,
                        height: 54,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(ach.bgHexColor),
                        ),
                        child: Icon(
                          ach.icon,
                          color: Color(ach.iconHexColor),
                          size: 24,
                        ),
                      ),
                      // Overlay Streak Count Badge
                      if (ach.count != null)
                        Positioned(
                          top: -2,
                          right: -2,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white,
                              boxShadow: [
                                BoxShadow(color: Colors.black12, blurRadius: 3),
                              ],
                            ),
                            constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                            child: Center(
                              child: Text(
                                '${ach.count}',
                                style: GoogleFonts.poppins(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFFF47B20),
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    ach.name,
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF8C8A87),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildActionsCard(BuildContext context) {
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
        children: [
          _buildActionItem(
            icon: Icons.menu_book_rounded,
            title: 'My Recipes',
            onTap: () {
              const ShoppingListRoute().push(context);
            },
          ),
          const Divider(color: Color(0xFFEFEBE4), height: 1),
          _buildActionItem(
            icon: Icons.settings_outlined,
            title: 'Settings',
            onTap: () {
              const SettingsRoute().push(context);
            },
          ),
          const Divider(color: Color(0xFFEFEBE4), height: 1),
          _buildActionItem(
            icon: Icons.help_outline_rounded,
            title: 'Help',
            onTap: () {
              context.read<ProfileBloc>().add(TriggerHelpCenter());
            },
          ),
        ],
      ),
    );
  }

  Widget _buildActionItem({
    required IconData icon,
    required String title,
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
      trailing: const Icon(
        Icons.chevron_right_rounded,
        color: Color(0xFFB5B3B0),
        size: 20,
      ),
      onTap: onTap,
    );
  }

  void _showHelpCenterBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Swipe Indicator
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFEBE4),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Title
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Help & Support',
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1F1E1C),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(0xFFF5F3EE),
                        ),
                        child: const Icon(Icons.close_rounded, color: Color(0xFF8C8A87), size: 16),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // FAQs Header
                Text(
                  'Frequently Asked Questions',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFFF47B20),
                  ),
                ),
                const SizedBox(height: 12),

                // FAQs list
                Flexible(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        _buildFaqItem(
                          'How do I add a recipe to favorites?',
                          'Simply tap the heart icon on any recipe thumbnail, or click the bookmark button inside the recipe detail page.',
                        ),
                        _buildFaqItem(
                          'What is the level status indicator?',
                          'Your Cooking Level increases as you prepare and complete meals via the interactive "Start Cooking" guide.',
                        ),
                        _buildFaqItem(
                          'Can I search recipes by specific diets?',
                          'Yes, navigate to the search page, tap the Diet dropdown chip, and select options like Vegan or Low Carb.',
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Contact Email button
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF47B20),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 0,
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Support email initialized to support@recipely.com'),
                          backgroundColor: Color(0xFFF47B20),
                        ),
                      );
                    },
                    child: Text(
                      'Email Support',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildFaqItem(String question, String answer) {
    return ExpansionTile(
      title: Text(
        question,
        style: GoogleFonts.poppins(
          fontSize: 13.5,
          fontWeight: FontWeight.w500,
          color: const Color(0xFF1F1E1C),
        ),
      ),
      iconColor: const Color(0xFFF47B20),
      collapsedIconColor: const Color(0xFF8C8A87),
      childrenPadding: const EdgeInsets.only(left: 16, right: 16, bottom: 12),
      expandedAlignment: Alignment.topLeft,
      expandedCrossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          answer,
          style: GoogleFonts.poppins(
            fontSize: 13,
            color: const Color(0xFF8C8A87),
            fontWeight: FontWeight.w400,
            height: 1.4,
          ),
        ),
      ],
    );
  }
}

class _AchievementItem {
  final String name;
  final IconData icon;
  final int bgHexColor;
  final int iconHexColor;
  final int? count;

  _AchievementItem(this.name, this.icon, this.bgHexColor, this.iconHexColor, {this.count});
}
