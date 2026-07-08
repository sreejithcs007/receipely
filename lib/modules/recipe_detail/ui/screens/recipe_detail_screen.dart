import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import '../../../../shared/widgets/animations/confetti_celebration.dart';
import '../../../../shared/widgets/loader/shimmer_card.dart';
import '../../../../shared/core/constants/asset_constants.dart';
import '../../../../shared/di/service_locator.dart';
import '../../../../shared/data/repositories/recipe_repository.dart';
import '../../../../shared/data/repositories/user_repository.dart';
import '../../../../shared/services/haptic_service.dart';
import '../../../../shared/widgets/buttons/animated_favorite_button.dart';
import '../../../../shared/widgets/buttons/animated_press_button.dart';
import '../../../../shared/widgets/tabs/animated_tab_bar.dart';
import '../../../../shared/widgets/tiles/animated_ingredient_tile.dart';
import '../../../../shared/services/notification_service.dart';
import '../../bloc/recipe_detail_bloc.dart';
import '../../bloc/recipe_detail_event.dart';
import '../../bloc/recipe_detail_state.dart';

class RecipeDetailScreen extends StatefulWidget {
  final String recipeId;
  const RecipeDetailScreen({required this.recipeId, super.key});

  @override
  State<RecipeDetailScreen> createState() => _RecipeDetailScreenState();
}

class _RecipeDetailScreenState extends State<RecipeDetailScreen> {
  // Scroll controller drives the bottom CTA animation and app bar opacity
  final ScrollController _scrollController = ScrollController();

  /// True once the scroll position passes the image height threshold.
  bool _showFloatingTitle = false;

  PageController? _cookingPageController;
  bool _showConfetti = false;
  bool? _lastFavoriteState;

  // Image height used for SliverAppBar – slightly over-expanded for parallax
  static const double _kHeaderExpandedHeight = 340.0;
  // When scroll reaches this offset the floating title fades in
  static const double _kTitleFadeThreshold = 260.0;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    final offset = _scrollController.offset;

    // Floating title: fade in after the image scrolls away
    final shouldShowTitle = offset > _kTitleFadeThreshold;
    if (shouldShowTitle != _showFloatingTitle) {
      setState(() => _showFloatingTitle = shouldShowTitle);
    }
  }

  /// Builds a rich share text and triggers the native OS share sheet.
  void _shareRecipe(RecipeDetailState state) {
    HapticService.medium();

    final ingredients = state.ingredients
        .asMap()
        .entries
        .map((e) => '  ${e.key + 1}. ${e.value}')
        .join('\n');

    final steps = state.steps
        .asMap()
        .entries
        .map((e) => '  Step ${e.key + 1}: ${e.value}')
        .join('\n');

    final shareText = '''
🍽️ ${state.title}

${state.description}

⭐ Rating: ${state.rating} (${state.reviews} reviews)
⏱️ Cook Time: ${state.cookTime}
🔥 Calories: ${state.calories}
👥 Servings: ${state.servings}

📋 Ingredients (${state.ingredients.length} items):
$ingredients

👨‍🍳 Steps:
$steps

✨ Found on Recipely — Your Premium Recipe App
    '''.trim();

    if (kIsWeb) {
      _copyToClipboard(context, shareText);
    } else {
      try {
        Share.share(
          shareText,
          subject: '${state.title} — Recipe from Recipely',
        );
      } catch (e) {
        _copyToClipboard(context, shareText);
      }
    }
  }

  void _copyToClipboard(BuildContext context, String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Recipe details copied to clipboard!'),
        duration: Duration(seconds: 2),
      ),
    );
  }


  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _cookingPageController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => RecipeDetailBloc(
        getIt<RecipeRepository>(),
        getIt<UserRepository>(),
      )..add(LoadRecipeDetail(widget.recipeId)),
      child: BlocListener<RecipeDetailBloc, RecipeDetailState>(
        listenWhen: (previous, current) =>
            previous.isCooking != current.isCooking ||
            previous.currentCookingStep != current.currentCookingStep ||
            previous.isFavorite != current.isFavorite,
        listener: (context, state) {
          if (!state.isCooking) {
            _cookingPageController?.dispose();
            _cookingPageController = null;
          } else {
            if (_cookingPageController == null) {
              _cookingPageController =
                  PageController(initialPage: state.currentCookingStep);
            } else if (_cookingPageController!.hasClients &&
                _cookingPageController!.page?.round() !=
                    state.currentCookingStep) {
              _cookingPageController!.animateToPage(
                state.currentCookingStep,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOutCubic,
              );
            }
          }

          if (state.title != 'Loading...') {
            if (_lastFavoriteState != null &&
                _lastFavoriteState != state.isFavorite) {
              OverlayNotification.show(
                context,
                message: state.isFavorite
                    ? 'Added "${state.title}" to your favorites! ❤️'
                    : 'Removed "${state.title}" from favorites 💔',
                type: state.isFavorite
                    ? NotificationType.success
                    : NotificationType.warning,
              );
            }
            _lastFavoriteState = state.isFavorite;
          }
        },
        child: BlocBuilder<RecipeDetailBloc, RecipeDetailState>(
          builder: (context, state) {
          if (state.title == 'Loading...') {
            return Scaffold(
              backgroundColor: const Color(0xFFFAF7F2),
              body: Stack(
                children: [
                  SafeArea(
                    top: false,
                    child: _buildDetailShimmer(context),
                  ),
                  Positioned(
                    top: MediaQuery.of(context).padding.top + 12,
                    left: 20,
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                        ),
                        child: const Icon(
                          Icons.chevron_left_rounded,
                          color: Color(0xFF1F1E1C),
                          size: 24,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }

          return Scaffold(
            backgroundColor: const Color(0xFFFAF7F2),
            // ── Floating transparent AppBar (title appears on scroll) ──────
            extendBodyBehindAppBar: true,
            appBar: _buildTransparentAppBar(context, state),
            body: Stack(
              children: [
                // ── Main Scroll View with Parallax Header ────────────────
                CustomScrollView(
                  controller: _scrollController,
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    // Parallax image header
                    _buildSliverHeader(context, state),

                    // All content as a single SliverToBoxAdapter
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(24.0, 20.0, 24.0, 0.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Title
                            Text(
                              state.title,
                              style: GoogleFonts.playfairDisplay(
                                fontSize: 28,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF1F1E1C),
                              ),
                            ),
                            const SizedBox(height: 8),

                            // Description
                            Text(
                              state.description,
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                color: const Color(0xFF8C8A87),
                                fontWeight: FontWeight.w400,
                                height: 1.4,
                              ),
                            ),
                            const SizedBox(height: 20),

                            // Stats Row
                            _buildStatsRow(state),
                            const SizedBox(height: 28),

                            // Animated Tab Bar
                            _buildCustomTabBar(context, state),
                            const SizedBox(height: 20),

                            // Tab Content
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 250),
                              switchInCurve: Curves.easeOutCubic,
                              switchOutCurve: Curves.easeInCubic,
                              transitionBuilder: (child, anim) => FadeTransition(
                                opacity: anim,
                                child: SlideTransition(
                                  position: Tween<Offset>(
                                    begin: const Offset(0, 0.03),
                                    end: Offset.zero,
                                  ).animate(anim),
                                  child: child,
                                ),
                              ),
                              child: KeyedSubtree(
                                key: ValueKey(state.selectedTabIndex),
                                child: state.selectedTabIndex == 0
                                    ? _buildIngredientsTab(context, state)
                                    : _buildStepsTab(state),
                              ),
                            ),

                            // Bottom padding so content clears the sticky bar
                            const SizedBox(height: 120),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                // ── Scroll-driven Sticky CTA Bottom Bar ──────────────────
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: _buildBottomBar(context, state),
                ),

                // ── Full-screen Cooking Guide Overlay ────────────────────
                if (state.isCooking)
                  _buildCookingOverlay(context, state),

                // ── Confetti Celebration ─────────────────────────────────
                if (_showConfetti)
                  Positioned.fill(
                    child: ConfettiCelebration(
                      onAnimationFinished: () {
                        setState(() => _showConfetti = false);
                      },
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    ),
  );
}

  /// Transparent AppBar that shows a frosted title after scrolling past image.
  PreferredSizeWidget _buildTransparentAppBar(
      BuildContext context, RecipeDetailState state) {
    return AppBar(
      backgroundColor: _showFloatingTitle
          ? Colors.white.withValues(alpha: 0.95)
          : Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      automaticallyImplyLeading: false,
      flexibleSpace: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        color: _showFloatingTitle
            ? Colors.white.withValues(alpha: 0.95)
            : Colors.transparent,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            child: Row(
              children: [
                // Back Button
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _showFloatingTitle
                          ? const Color(0xFFF5F3EE)
                          : Colors.white,
                      boxShadow: _showFloatingTitle
                          ? []
                          : [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.08),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                    ),
                    child: const Icon(
                      Icons.chevron_left_rounded,
                      color: Color(0xFF1F1E1C),
                      size: 24,
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Animated floating title
                Expanded(
                  child: AnimatedOpacity(
                    opacity: _showFloatingTitle ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 200),
                    child: Text(
                      state.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1F1E1C),
                      ),
                    ),
                  ),
                ),

                // Right action buttons
                Row(
                  children: [
                    // Bookmark
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _showFloatingTitle
                            ? const Color(0xFFF5F3EE)
                            : Colors.white,
                      ),
                      child: Center(
                        child: AnimatedFavoriteButton(
                          isFavorite: state.isFavorite,
                          useBookmarkIcon: true,
                          size: 20,
                          onToggle: () {
                            context.read<RecipeDetailBloc>().add(ToggleFavorite());
                          },
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Share
                    GestureDetector(
                      onTap: () => _shareRecipe(state),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _showFloatingTitle
                              ? const Color(0xFFF5F3EE)
                              : Colors.white,
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.share_outlined,
                            color: Color(0xFF1F1E1C),
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      toolbarHeight: MediaQuery.of(context).padding.top + 64,
    );
  }

  /// SliverAppBar with pinned back/actions and parallax stretch image.
  Widget _buildSliverHeader(BuildContext context, RecipeDetailState state) {
    return SliverAppBar(
      expandedHeight: _kHeaderExpandedHeight,
      pinned: false,
      floating: false,
      stretch: true,
      stretchTriggerOffset: 80,
      automaticallyImplyLeading: false,
      backgroundColor: Colors.transparent,
      flexibleSpace: FlexibleSpaceBar(
        stretchModes: const [
          StretchMode.zoomBackground,
          StretchMode.blurBackground,
        ],
        background: ClipRRect(
          borderRadius: const BorderRadius.vertical(bottom: Radius.circular(32)),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // ── Parallax Image ────────────────────────────────────────────
              state.imageUrl.startsWith('http')
                  ? Hero(
                      tag: state.imageUrl,
                      flightShuttleBuilder: (_, anim, __, ___, ____) => Material(
                        color: Colors.transparent,
                        child: ClipRRect(
                          borderRadius:
                              const BorderRadius.vertical(bottom: Radius.circular(32)),
                          child: CachedNetworkImage(
                            imageUrl: state.imageUrl,
                            memCacheWidth: 1000,
                            memCacheHeight: 1000,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      child: CachedNetworkImage(
                        imageUrl: state.imageUrl,
                        memCacheWidth: 1000,
                        memCacheHeight: 1000,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          color: const Color(0xFFEFEBE4),
                        ),
                        errorWidget: (context, url, error) => Image.asset(
                          AppImages.recipeRamen,
                          fit: BoxFit.cover,
                        ),
                      ),
                    )
                  : Image.asset(
                      state.imageUrl.isNotEmpty
                          ? state.imageUrl
                          : AppImages.recipeRamen,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Image.asset(
                        AppImages.recipeRamen,
                        fit: BoxFit.cover,
                      ),
                    ),

              // ── Gradient overlay top (for status bar readability) ─────────
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: const Alignment(0, 0.35),
                      colors: [
                        Colors.black.withValues(alpha: 0.35),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),

              // ── Gradient overlay bottom (vanishing into canvas color) ─────
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: const Alignment(0, 0.4),
                      colors: [
                        const Color(0xFFFAF7F2).withValues(alpha: 0.5),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }


  Widget _buildStatsRow(RecipeDetailState state) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEFEBE4), width: 1.0),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Rating
          Row(
            children: [
              const Icon(Icons.star_rounded, color: Color(0xFFF47B20), size: 18),
              const SizedBox(width: 4),
              Text(
                state.rating,
                style: GoogleFonts.poppins(fontSize: 12.5, fontWeight: FontWeight.w600, color: const Color(0xFF1F1E1C)),
              ),
              const SizedBox(width: 2),
              Text(
                '(${state.reviews})',
                style: GoogleFonts.poppins(fontSize: 11, color: const Color(0xFF8C8A87)),
              ),
            ],
          ),
          const SizedBox(height: 16, child: VerticalDivider(color: Color(0xFFEFEBE4), width: 1)),

          // Cook Time
          Row(
            children: [
              const Icon(Icons.access_time_rounded, color: Color(0xFFF47B20), size: 16),
              const SizedBox(width: 4),
              Text(
                state.cookTime,
                style: GoogleFonts.poppins(fontSize: 12.5, fontWeight: FontWeight.w600, color: const Color(0xFF1F1E1C)),
              ),
            ],
          ),
          const SizedBox(height: 16, child: VerticalDivider(color: Color(0xFFEFEBE4), width: 1)),

          // Calories
          Row(
            children: [
              const Icon(Icons.local_fire_department_rounded, color: Color(0xFFF47B20), size: 17),
              const SizedBox(width: 4),
              Text(
                state.calories,
                style: GoogleFonts.poppins(fontSize: 12.5, fontWeight: FontWeight.w600, color: const Color(0xFF1F1E1C)),
              ),
            ],
          ),
          const SizedBox(height: 16, child: VerticalDivider(color: Color(0xFFEFEBE4), width: 1)),

          // Servings
          Row(
            children: [
              const Icon(Icons.people_outline_rounded, color: Color(0xFFF47B20), size: 17),
              const SizedBox(width: 4),
              Text(
                state.servings,
                style: GoogleFonts.poppins(fontSize: 12.5, fontWeight: FontWeight.w600, color: const Color(0xFF1F1E1C)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCustomTabBar(BuildContext context, RecipeDetailState state) {
    return AnimatedTabBar(
      selectedIndex: state.selectedTabIndex,
      labels: const ['Ingredients', 'Steps'],
      onTabChanged: (index) {
        context.read<RecipeDetailBloc>().add(ChangeTab(index));
      },
    );
  }

  Widget _buildIngredientsTab(BuildContext context, RecipeDetailState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Ingredients',
              style: GoogleFonts.playfairDisplay(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1F1E1C),
              ),
            ),
            Text(
              '${state.ingredients.length} items',
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: const Color(0xFFF47B20),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Staggered animated ingredient list
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: ListView.separated(
            key: ValueKey(state.ingredients.length),
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: state.ingredients.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              return AnimatedIngredientTile(
                ingredient: state.ingredients[index],
                isChecked: state.checkedIngredients[index],
                entryDelay: Duration(milliseconds: index * 70),
                onToggle: () {
                  context.read<RecipeDetailBloc>().add(ToggleIngredientCheck(index));
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildStepsTab(RecipeDetailState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Cooking Instructions',
          style: GoogleFonts.playfairDisplay(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF1F1E1C),
          ),
        ),
        const SizedBox(height: 16),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: state.steps.length,
          separatorBuilder: (_, __) => const SizedBox(height: 16),
          itemBuilder: (context, index) {
            final step = state.steps[index];
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Step Badge
                Container(
                  width: 28,
                  height: 28,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFFFFF2D9),
                  ),
                  child: Center(
                    child: Text(
                      '${index + 1}',
                      style: GoogleFonts.poppins(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFFF47B20),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Instruction Text
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Text(
                      step,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: const Color(0xFF1F1E1C),
                        fontWeight: FontWeight.w400,
                        height: 1.45,
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildBottomBar(BuildContext context, RecipeDetailState state) {
    return Container(
      padding: const EdgeInsets.all(24.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            // ── Animated Save / Bookmark Button ──────────────────────────────
            SizedBox(
              height: 52,
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  side: BorderSide(
                    color: state.isFavorite
                        ? const Color(0xFFF47B20)
                        : const Color(0xFFEFEBE4),
                    width: 1.5,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                ),
                onPressed: () {
                  context.read<RecipeDetailBloc>().add(ToggleFavorite());
                },
                child: Row(
                  children: [
                    AnimatedFavoriteButton(
                      isFavorite: state.isFavorite,
                      useBookmarkIcon: true,
                      size: 20,
                      onToggle: () {
                        context.read<RecipeDetailBloc>().add(ToggleFavorite());
                      },
                    ),
                    const SizedBox(width: 8),
                    AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 200),
                      style: GoogleFonts.poppins(
                        color: state.isFavorite
                            ? const Color(0xFFF47B20)
                            : const Color(0xFF1F1E1C),
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                      child: Text(state.isFavorite ? 'Saved' : 'Save'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            // ── Animated Start Cooking Button ──────────────────────────────
            Expanded(
              child: StartCookingButton(
                onPressed: () {
                  context.read<RecipeDetailBloc>().add(StartCooking());
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCookingOverlay(BuildContext context, RecipeDetailState state) {
    final stepIndex = state.currentCookingStep;
    final totalSteps = state.steps.length;
    final progress = (stepIndex + 1) / totalSteps;
    final isLastStep = stepIndex == totalSteps - 1;

    return Container(
      color: Colors.black.withValues(alpha: 0.5), // Semi-transparent scrim
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Container(
          height: MediaQuery.of(context).size.height * 0.75,
          width: double.infinity,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Swipe/Drag handle helper visual
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFEBE4),
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Title and Close
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Step ${stepIndex + 1} of $totalSteps',
                    style: GoogleFonts.poppins(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFFF47B20),
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      context.read<RecipeDetailBloc>().add(CancelCooking());
                    },
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0xFFF5F3EE),
                      ),
                      child: const Icon(
                        Icons.close_rounded,
                        color: Color(0xFF8C8A87),
                        size: 16,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Progress Bar
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 6,
                  backgroundColor: const Color(0xFFF5F3EE),
                  valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFF47B20)),
                ),
              ),
              const SizedBox(height: 40),

              // Step Detail Card
              Expanded(
                child: PageView.builder(
                  controller: _cookingPageController,
                  itemCount: totalSteps,
                  onPageChanged: (index) {
                    context.read<RecipeDetailBloc>().add(GoToStep(index));
                    HapticService.selection();
                  },
                  itemBuilder: (context, index) {
                    return Center(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Giant illustration icon
                            Container(
                              width: 80,
                              height: 80,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Color(0xFFFFF2D9),
                              ),
                              child: const Icon(
                                Icons.restaurant_rounded,
                                color: Color(0xFFF47B20),
                                size: 40,
                              ),
                            ),
                            const SizedBox(height: 24),
                            // Instruction Text
                            Text(
                              state.steps[index],
                              textAlign: TextAlign.center,
                              style: GoogleFonts.poppins(
                                fontSize: 18,
                                fontWeight: FontWeight.w500,
                                color: const Color(0xFF1F1E1C),
                                height: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

              // Button controls
              Row(
                children: [
                  // Previous Step button
                  Expanded(
                    child: SizedBox(
                      height: 52,
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFFEFEBE4), width: 1.5),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        onPressed: stepIndex > 0
                            ? () {
                                context.read<RecipeDetailBloc>().add(PrevStep());
                              }
                            : null,
                        child: Text(
                          'Previous',
                          style: GoogleFonts.poppins(
                            color: stepIndex > 0 ? const Color(0xFF1F1E1C) : const Color(0xFFB5B3B0),
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Next Step button
                  Expanded(
                    child: SizedBox(
                      height: 52,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFF47B20),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                        ),
                        onPressed: () {
                          if (isLastStep) {
                            // Show beautiful success dialog and complete cooking state
                            context.read<RecipeDetailBloc>().add(CompleteCooking());
                            setState(() => _showConfetti = true);
                            _showSuccessDialog(context, state.title);
                          } else {
                            context.read<RecipeDetailBloc>().add(NextStep());
                          }
                        },
                        child: Text(
                          isLastStep ? 'Finish!' : 'Next Step',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSuccessDialog(BuildContext context, String recipeTitle) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              // Celebration Lottie/Icon
              Container(
                width: 80,
                height: 80,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFFEAF5E3),
                ),
                child: const Icon(
                  Icons.celebration_rounded,
                  color: Color(0xFF4CAF50),
                  size: 40,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Congratulations! 🎉',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1F1E1C),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'You successfully prepared $recipeTitle. Enjoy your delicious home-cooked meal!',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 13.5,
                  color: const Color(0xFF8C8A87),
                  fontWeight: FontWeight.w400,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 24),
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
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'Enjoy Meal',
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
        );
      },
    );
  }

  Widget _buildDetailShimmer(BuildContext context) {
    return const DetailShimmer();
  }
}
