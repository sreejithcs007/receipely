import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../router/routes.dart';
import '../../../../shared/core/constants/asset_constants.dart';
import '../../../../shared/di/service_locator.dart';
import '../../../../shared/data/repositories/recipe_repository.dart';
import '../../../../shared/data/repositories/user_repository.dart';
import '../../../../shared/data/models/recipe_model.dart';
import '../../../../shared/widgets/loader/shimmer_card.dart';
import '../../../../shared/services/storage_service.dart';
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
      create: (context) => ProfileBloc(
        getIt<RecipeRepository>(),
        getIt<UserRepository>(),
      )..add(LoadProfilePage()),
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
                  child: state.isLoading
                      ? _buildProfileShimmer(context)
                      : Column(
                          children: [
                            // ── Avatar & Name & Chef Badge ─────────────────────────
                            _buildHeaderAvatar(state),

                            const SizedBox(height: 24),

                            // ── Stats Card (Excluding Followers) ───────────────────
                            _buildStatsCard(context, state),

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
                  child: () {
                    final hasPhoto = state.imageUrl.isNotEmpty &&
                        !state.imageUrl.contains('default.png') &&
                        !state.imageUrl.contains('chef_avatar.png');

                    if (!hasPhoto) {
                      return _buildInitialsPlaceholder(state.name);
                    }

                    String resolvedUrl = state.imageUrl;
                    final isAsset = resolvedUrl.startsWith('assets/');
                    if (resolvedUrl.isNotEmpty && !resolvedUrl.startsWith('http') && !isAsset) {
                      try {
                        final parts = resolvedUrl.split('/');
                        if (parts.length >= 2) {
                          final bucket = parts[0];
                          final path = parts.sublist(1).join('/');
                          resolvedUrl = Supabase.instance.client.storage.from(bucket).getPublicUrl(path);
                        }
                      } catch (_) {}
                    }

                    return !isAsset && resolvedUrl.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: resolvedUrl,
                            memCacheWidth: 800,
                            memCacheHeight: 800,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(
                              color: const Color(0xFFEFEBE4),
                              child: const Center(
                                child: SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Color(0xFFF47B20),
                                  ),
                                ),
                              ),
                            ),
                            errorWidget: (context, url, error) => _buildInitialsPlaceholder(state.name),
                          )
                        : Image.asset(
                            resolvedUrl.isNotEmpty ? resolvedUrl : AppImages.chefAvatar,
                            fit: BoxFit.cover,
                          );
                  }(),
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

  Widget _buildStatsCard(BuildContext context, ProfileState state) {
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
          Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => _showSavedRecipesBottomSheet(context),
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
          ),
          // Vertical Divider
          Container(
            width: 1.2,
            height: 52,
            color: const Color(0xFFEFEBE4),
          ),
          Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => _showCookedRecipesBottomSheet(context),
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
          ),
        ],
      ),
    );
  }

  Future<List<RecipeModel>> _loadLocalSavedRecipes() async {
    try {
      final storage = getIt<StorageService>();
      final savedIdsStr = await storage.read('saved_recipe_ids') ?? '';
      final savedIds =
          savedIdsStr.split(',').where((id) => id.isNotEmpty).toList();
      if (savedIds.isEmpty) return [];

      final recipes = await getIt<RecipeRepository>().getRecipes();
      return recipes.where((r) => savedIds.contains(r.id)).toList();
    } catch (_) {
      return [];
    }
  }

  void _showSavedRecipesBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.75,
          decoration: const BoxDecoration(
            color: Color(0xFFFAF7F2),
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Bottom sheet drag handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFEBE4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Saved Recipes',
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1F1E1C),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0xFFEFEBE4),
                      ),
                      child: const Icon(Icons.close_rounded,
                          size: 16, color: Color(0xFF8C8A87)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Expanded(
                child: FutureBuilder<List<RecipeModel>>(
                  future: _loadLocalSavedRecipes(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFFF47B20),
                        ),
                      );
                    }
                    if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.bookmark_outline_rounded,
                              size: 48,
                              color: Color(0xFFB5B3B0),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              "No saved recipes yet",
                              style: GoogleFonts.poppins(
                                  fontSize: 15,
                                  color: const Color(0xFF8C8A87),
                                  fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    final savedList = snapshot.data!;
                    return ListView.builder(
                      itemCount: savedList.length,
                      itemBuilder: (context, index) {
                        final recipe = savedList[index];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFEFEBE4), width: 1),
                          ),
                          child: Material(
                            color: Colors.transparent,
                            clipBehavior: Clip.antiAlias,
                            borderRadius: BorderRadius.circular(16),
                            child: ListTile(
                              contentPadding: const EdgeInsets.all(8),
                              leading: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: SizedBox(
                                  width: 56,
                                  height: 56,
                                  child: recipe.imageUrl.startsWith('http')
                                      ? CachedNetworkImage(
                                          imageUrl: recipe.imageUrl,
                                          memCacheWidth: 200,
                                          memCacheHeight: 200,
                                          fit: BoxFit.cover,
                                          placeholder: (context, url) => Container(
                                            color: const Color(0xFFEFEBE4),
                                          ),
                                          errorWidget: (context, url, error) => Image.asset(
                                            AppImages.recipeRamen,
                                            fit: BoxFit.cover,
                                          ),
                                        )
                                      : Image.asset(
                                          recipe.imageUrl.isNotEmpty
                                              ? recipe.imageUrl
                                              : AppImages.recipeRamen,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) => Image.asset(
                                            AppImages.recipeRamen,
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                ),
                              ),
                              title: Text(
                                recipe.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.poppins(
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF1F1E1C),
                                ),
                              ),
                              subtitle: Row(
                                children: [
                                  const Icon(Icons.schedule_rounded, size: 14, color: Color(0xFF8C8A87)),
                                  const SizedBox(width: 4),
                                  Text(
                                    recipe.cookTime,
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      color: const Color(0xFF8C8A87),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  const Icon(Icons.bolt_rounded, size: 14, color: Color(0xFF8C8A87)),
                                  const SizedBox(width: 2),
                                  Text(
                                    recipe.calories,
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      color: const Color(0xFF8C8A87),
                                    ),
                                  ),
                                ],
                              ),
                              trailing: const Icon(
                                Icons.arrow_forward_ios_rounded,
                                size: 14,
                                color: Color(0xFF8C8A87),
                              ),
                              onTap: () {
                                RecipeDetailRoute(recipeId: recipe.id).push(context);
                              },
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    ).then((_) {
      if (context.mounted) {
        context.read<ProfileBloc>().add(LoadProfilePage());
      }
    });
  }

  void _showCookedRecipesBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final user = getIt<UserRepository>().getCurrentUser();
        return Container(
          height: MediaQuery.of(context).size.height * 0.75,
          decoration: const BoxDecoration(
            color: Color(0xFFFAF7F2),
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Bottom sheet drag handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFEBE4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Cooked Recipes',
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1F1E1C),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0xFFEFEBE4),
                      ),
                      child: const Icon(Icons.close_rounded, size: 16, color: Color(0xFF8C8A87)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Expanded(
                child: FutureBuilder<List<RecipeModel>>(
                  future: user != null
                      ? getIt<UserRepository>().getCookedRecipes(user.id)
                      : Future.value([]),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFFF47B20),
                        ),
                      );
                    }
                    if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.soup_kitchen_rounded,
                              size: 48,
                              color: Color(0xFFB5B3B0),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              "No cooked recipes yet",
                              style: GoogleFonts.poppins(
                                fontSize: 15,
                                color: const Color(0xFF8C8A87),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "Start cooking and tap Finish to save!",
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                color: const Color(0xFFB5B3B0),
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    final cookedList = snapshot.data!;
                    return ListView.builder(
                      itemCount: cookedList.length,
                      itemBuilder: (context, index) {
                        final recipe = cookedList[index];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFEFEBE4), width: 1),
                          ),
                          child: Material(
                            color: Colors.transparent,
                            clipBehavior: Clip.antiAlias,
                            borderRadius: BorderRadius.circular(16),
                            child: ListTile(
                              contentPadding: const EdgeInsets.all(8),
                              leading: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: SizedBox(
                                  width: 56,
                                  height: 56,
                                  child: recipe.imageUrl.startsWith('http')
                                      ? CachedNetworkImage(
                                          imageUrl: recipe.imageUrl,
                                          memCacheWidth: 200,
                                          memCacheHeight: 200,
                                          fit: BoxFit.cover,
                                          placeholder: (context, url) => Container(
                                            color: const Color(0xFFEFEBE4),
                                          ),
                                          errorWidget: (context, url, error) => Image.asset(
                                            AppImages.recipeRamen,
                                            fit: BoxFit.cover,
                                          ),
                                        )
                                      : Image.asset(
                                          recipe.imageUrl.isNotEmpty
                                              ? recipe.imageUrl
                                              : AppImages.recipeRamen,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) => Image.asset(
                                            AppImages.recipeRamen,
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                ),
                              ),
                              title: Text(
                                recipe.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.poppins(
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF1F1E1C),
                                ),
                              ),
                              subtitle: Row(
                                children: [
                                  const Icon(Icons.schedule_rounded, size: 14, color: Color(0xFF8C8A87)),
                                  const SizedBox(width: 4),
                                  Text(
                                    recipe.cookTime,
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      color: const Color(0xFF8C8A87),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  const Icon(Icons.bolt_rounded, size: 14, color: Color(0xFF8C8A87)),
                                  const SizedBox(width: 2),
                                  Text(
                                    recipe.calories,
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      color: const Color(0xFF8C8A87),
                                    ),
                                  ),
                                ],
                              ),
                              trailing: const Icon(
                                Icons.arrow_forward_ios_rounded,
                                size: 14,
                                color: Color(0xFF8C8A87),
                              ),
                              onTap: () {
                                RecipeDetailRoute(recipeId: recipe.id).push(context);
                              },
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    ).then((_) {
      if (context.mounted) {
        context.read<ProfileBloc>().add(LoadProfilePage());
      }
    });
  }

  Widget _buildBadge(_AchievementItem ach, {double size = 54.0}) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Color(ach.bgHexColor),
            border: Border.all(
              color: ach.isLocked ? const Color(0xFFE5E2DC) : const Color(0xFFFFF2D9),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF3A2818).withValues(alpha: ach.isLocked ? 0.02 : 0.06),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Icon(
            ach.icon,
            color: Color(ach.iconHexColor),
            size: size * 0.45,
          ),
        ),
        if (ach.isLocked)
          Positioned(
            right: -2,
            bottom: -2,
            child: Container(
              padding: const EdgeInsets.all(3),
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFF8C8A87),
              ),
              child: const Icon(
                Icons.lock_rounded,
                color: Colors.white,
                size: 10,
              ),
            ),
          )
        else
          Positioned(
            right: -2,
            bottom: -2,
            child: Container(
              padding: const EdgeInsets.all(3),
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFF4CAF50),
              ),
              child: const Icon(
                Icons.check_rounded,
                color: Colors.white,
                size: 10,
              ),
            ),
          ),
      ],
    );
  }

  void _showAllAchievementsBottomSheet(BuildContext context, List<_AchievementItem> achievements) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (dialogContext) {
        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFFFAF7F2),
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(28),
              topRight: Radius.circular(28),
            ),
          ),
          padding: const EdgeInsets.only(left: 24, right: 24, top: 20, bottom: 30),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 5,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFEBE4),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'All Achievements',
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1F1E1C),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF2D9),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '1 Unlocked',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFFF47B20),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: achievements.length,
                  separatorBuilder: (_, __) => const Divider(color: Color(0xFFEFEBE4), height: 24),
                  itemBuilder: (ctx, idx) {
                    final ach = achievements[idx];
                    return Row(
                      children: [
                        _buildBadge(ach, size: 48),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                ach.name,
                                style: GoogleFonts.poppins(
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w600,
                                  color: ach.isLocked ? const Color(0xFF8C8A87) : const Color(0xFF1F1E1C),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                ach.description,
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w400,
                                  color: const Color(0xFFB5B3B0),
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (ach.isLocked)
                          Text(
                            'Locked',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFFB5B3B0),
                            ),
                          )
                        else
                          Text(
                            'Unlocked',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF4CAF50),
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAchievementsSection() {
    final achievements = [
      _AchievementItem(
        'Home Cook',
        Icons.soup_kitchen_rounded,
        0xFFFFF2D9,
        0xFFF47B20,
        isLocked: false,
        description: 'Cooked your first recipe successfully!',
      ),
      _AchievementItem(
        'Master Chef',
        Icons.restaurant_menu_rounded,
        0xFFF2F0EC,
        0xFF8C8A87,
        isLocked: true,
        description: 'Cook 10 featured recipes to unlock.',
      ),
      _AchievementItem(
        'Flavor Finder',
        Icons.explore_outlined,
        0xFFF2F0EC,
        0xFF8C8A87,
        isLocked: true,
        description: 'Save recipes from 5 different categories.',
      ),
      _AchievementItem(
        'Spice Master',
        Icons.local_fire_department_outlined,
        0xFFF2F0EC,
        0xFF8C8A87,
        isLocked: true,
        description: 'Generate 5 custom AI recipes.',
      ),
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFEFEBE4), width: 1.0),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF3A2818).withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
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
              GestureDetector(
                onTap: () => _showAllAchievementsBottomSheet(context, achievements),
                child: Row(
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
                    _buildBadge(ach),
                    const SizedBox(height: 8),
                    Text(
                      ach.name,
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: ach.isLocked ? const Color(0xFFB5B3B0) : const Color(0xFF1F1E1C),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionsCard(BuildContext context) {
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
          children: [
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

  Widget _buildInitialsPlaceholder(String name) {
    final initials = name.trim().isNotEmpty ? name.trim()[0].toUpperCase() : 'S';
    return Container(
      color: const Color(0xFFFFF2D9),
      alignment: Alignment.center,
      child: Text(
        initials,
        style: GoogleFonts.playfairDisplay(
          fontSize: 48,
          fontWeight: FontWeight.w700,
          color: const Color(0xFFF47B20),
        ),
      ),
    );
  }

  Widget _buildProfileShimmer(BuildContext context) {
    return Column(
      children: [
        // Avatar circle
        const Center(
          child: CustomShimmer(
            width: 110,
            height: 110,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(height: 16),
        // Name placeholder
        CustomShimmer(width: 180, height: 22, borderRadius: BorderRadius.circular(6)),
        const SizedBox(height: 6),
        // Level placeholder
        CustomShimmer(width: 100, height: 14, borderRadius: BorderRadius.circular(4)),
        const SizedBox(height: 24),
        
        // Stats Card
        CustomShimmer(
          height: 80,
          width: double.infinity,
          borderRadius: BorderRadius.circular(20),
        ),
        const SizedBox(height: 32),
        
        // Achievements Title
        Align(
          alignment: Alignment.centerLeft,
          child: CustomShimmer(width: 140, height: 20, borderRadius: BorderRadius.circular(6)),
        ),
        const SizedBox(height: 16),
        // Achievements Row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(3, (index) => CustomShimmer(
            width: 80,
            height: 100,
            borderRadius: BorderRadius.circular(16),
          )),
        ),
        const SizedBox(height: 32),
        
        // Actions Card Placeholder
        CustomShimmer(
          height: 180,
          width: double.infinity,
          borderRadius: BorderRadius.circular(24),
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
  final bool isLocked;
  final String description;

  _AchievementItem(
    this.name,
    this.icon,
    this.bgHexColor,
    this.iconHexColor, {
    this.isLocked = false,
    this.description = '',
  });
}
