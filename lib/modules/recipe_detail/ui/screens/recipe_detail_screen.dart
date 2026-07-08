import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/cupertino.dart';
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
import '../../../../shared/services/wake_lock_helper.dart';
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

  // Shimmer timer to prevent loading skeleton flash
  Timer? _shimmerTimer;
  bool _showShimmer = false;

  // Bottom action bar scroll-driven reveal state
  bool _showBottomBar = true;
  double _lastOffset = 0.0;

  // Interactive step timer variables for immersive cooking mode
  Timer? _stepTimer;
  int _secondsRemaining = 0;
  int _totalDurationSeconds = 0;
  bool _isTimerRunning = false;

  // Image height used for SliverAppBar – slightly over-expanded for parallax
  static const double _kHeaderExpandedHeight = 340.0;
  // When scroll reaches this offset the floating title fades in
  static const double _kTitleFadeThreshold = 260.0;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _shimmerTimer = Timer(const Duration(milliseconds: 150), () {
      if (mounted) {
        setState(() => _showShimmer = true);
      }
    });
  }

  void _onScroll() {
    final offset = _scrollController.offset;

    // Floating title: fade in after the image scrolls away
    final shouldShowTitle = offset > _kTitleFadeThreshold;
    if (shouldShowTitle != _showFloatingTitle) {
      setState(() => _showFloatingTitle = shouldShowTitle);
    }

    // Scroll reveal bottom bar: hide when scrolling down, show when scrolling up
    if (offset > _lastOffset && offset > 120 && _showBottomBar) {
      setState(() => _showBottomBar = false);
    } else if (offset < _lastOffset && !_showBottomBar) {
      setState(() => _showBottomBar = true);
    }
    _lastOffset = offset;
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


  void _initTimerForStep(String stepText) {
    _stepTimer?.cancel();
    _isTimerRunning = false;

    // Matches numbers followed by min, minute, mins, etc.
    final regExp = RegExp(r'(\d+)\s*(?:min|minute|mins)');
    final match = regExp.firstMatch(stepText.toLowerCase());

    if (match != null) {
      final minutes = int.tryParse(match.group(1) ?? '0') ?? 0;
      if (minutes > 0) {
        setState(() {
          _secondsRemaining = minutes * 60;
          _totalDurationSeconds = minutes * 60;
        });
        return;
      }
    }

    setState(() {
      _secondsRemaining = 0;
      _totalDurationSeconds = 0;
    });
  }

  void _toggleStepTimer() {
    HapticService.selection();
    if (_isTimerRunning) {
      _stepTimer?.cancel();
      setState(() => _isTimerRunning = false);
    } else {
      if (_secondsRemaining <= 0) return;
      setState(() => _isTimerRunning = true);
      _stepTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (!mounted) {
          timer.cancel();
          return;
        }
        if (_secondsRemaining <= 1) {
          timer.cancel();
          HapticService.heavy();
          setState(() {
            _secondsRemaining = 0;
            _isTimerRunning = false;
          });
          OverlayNotification.show(
            context,
            message: 'Step timer complete! 🔔',
            type: NotificationType.success,
          );
        } else {
          setState(() {
            _secondsRemaining--;
          });
        }
      });
    }
  }

  @override
  void dispose() {
    _stepTimer?.cancel();
    releaseWakeLock();
    _shimmerTimer?.cancel();
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
            previous.currentCookingStep != current.currentCookingStep,
        listener: (context, state) {
          if (!state.isCooking) {
            _cookingPageController?.dispose();
            _cookingPageController = null;
            releaseWakeLock();
          } else {
            requestWakeLock();
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
        },
        child: BlocBuilder<RecipeDetailBloc, RecipeDetailState>(
          builder: (context, state) {
          if (state.title == 'Loading...') {
            return Scaffold(
              backgroundColor: const Color(0xFFFAF7F2),
              body: Stack(
                children: [
                  if (_showShimmer)
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
                  physics: const AlwaysScrollableScrollPhysics(
                    parent: BouncingScrollPhysics(),
                  ),
                  slivers: [
                    CupertinoSliverRefreshControl(
                      refreshTriggerPullDistance: 90.0,
                      refreshIndicatorExtent: 60.0,
                      onRefresh: () async {
                        final bloc = context.read<RecipeDetailBloc>();
                        final future = bloc.stream.first;
                        bloc.add(LoadRecipeDetail(widget.recipeId));
                        await future
                            .timeout(const Duration(seconds: 4))
                            .catchError((_) => bloc.state);
                      },
                      builder: (context, refreshState, pulledExtent,
                          refreshTriggerPullDistance, refreshIndicatorExtent) {
                        return PremiumRefreshIndicator(
                          mode: refreshState,
                          pulledExtent: pulledExtent,
                          refreshTriggerPullDistance: refreshTriggerPullDistance,
                          refreshIndicatorExtent: refreshIndicatorExtent,
                        );
                      },
                    ),
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
                  child: AnimatedSlide(
                    offset: _showBottomBar ? Offset.zero : const Offset(0.0, 1.0),
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOutCubic,
                    child: AnimatedOpacity(
                      opacity: _showBottomBar ? 1.0 : 0.0,
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeInOutCubic,
                      child: _buildBottomBar(context, state),
                    ),
                  ),
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
                          useBookmarkIcon: false,
                          activeColor: const Color(0xFFEA4335),
                          size: 20,
                          onToggle: () {
                            final nextState = !state.isFavorite;
                            context.read<RecipeDetailBloc>().add(ToggleFavorite());
                            OverlayNotification.show(
                              context,
                              message: nextState
                                  ? 'Added "${state.title}" to favorites! ❤️'
                                  : 'Removed "${state.title}" from favorites 💔',
                              type: nextState
                                  ? NotificationType.success
                                  : NotificationType.warning,
                            );
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
          child: AnimatedBuilder(
            animation: _scrollController,
            builder: (context, child) {
              double scrollY = 0.0;
              if (_scrollController.hasClients) {
                scrollY = _scrollController.offset;
              }
              // Parallax factor
              double parallaxOffset = scrollY > 0 ? scrollY * 0.45 : 0.0;
              return Transform.translate(
                offset: Offset(0, parallaxOffset),
                child: child,
              );
            },
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
            return StaggeredFadeSlide(
              delay: Duration(milliseconds: index * 70),
              child: Row(
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
              ),
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
                    color: state.isSaved
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
                  final nextState = !state.isSaved;
                  context.read<RecipeDetailBloc>().add(ToggleSave());
                  OverlayNotification.show(
                    context,
                    message: nextState
                        ? 'Saved "${state.title}" for later! 📌'
                        : 'Removed "${state.title}" from saved recipes 💔',
                    type: nextState
                        ? NotificationType.success
                        : NotificationType.warning,
                  );
                },
                child: Row(
                  children: [
                    AnimatedFavoriteButton(
                      isFavorite: state.isSaved,
                      useBookmarkIcon: true,
                      size: 20,
                      onToggle: () {}, // Handled by outer OutlinedButton
                    ),
                    const SizedBox(width: 8),
                    AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 200),
                      style: GoogleFonts.poppins(
                        color: state.isSaved
                            ? const Color(0xFFF47B20)
                            : const Color(0xFF1F1E1C),
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                      child: Text(state.isSaved ? 'Saved' : 'Save'),
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
      color: const Color(0xFFFAF7F2), // Immersive clean solid background
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            // Header bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
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
                        size: 18,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Progress Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 6,
                  backgroundColor: const Color(0xFFF5F3EE),
                  valueColor:
                      const AlwaysStoppedAnimation<Color>(Color(0xFFF47B20)),
                ),
              ),
            ),

            // Step PageView
            Expanded(
              child: PageView.builder(
                controller: _cookingPageController,
                itemCount: totalSteps,
                onPageChanged: (index) {
                  context.read<RecipeDetailBloc>().add(GoToStep(index));
                  HapticService.selection();
                  _initTimerForStep(state.steps[index]);
                },
                itemBuilder: (context, index) {
                  final stepText = state.steps[index];
                  // Extract step-specific ingredients
                  final stepIngredients = state.ingredients.where((ing) {
                    final cleanIng = ing.toLowerCase();
                    // Split ingredient text into words, filter out short stop words
                    final words = cleanIng
                        .split(RegExp(r'[^a-zA-Z]'))
                        .where((w) => w.length > 3)
                        .toList();
                    if (words.isEmpty) return cleanIng.contains(stepText);
                    return words.any((w) => stepText.toLowerCase().contains(w));
                  }).toList();

                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Step number circular card
                        Container(
                          width: 64,
                          height: 64,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Color(0xFFFFF2D9),
                          ),
                          child: Center(
                            child: Text(
                              '${index + 1}',
                              style: GoogleFonts.playfairDisplay(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFFF47B20),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 28),

                        // Instruction Text (large and readable)
                        Text(
                          stepText,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(
                            fontSize: 20,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF1F1E1C),
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 32),

                        // Countdown Timer Widget if parsed from step
                        if (_totalDurationSeconds > 0) ...[
                          GestureDetector(
                            onTap: _toggleStepTimer,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFF2D9),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                    color: const Color(0xFFFFE4B3),
                                    width: 1.0),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      SizedBox(
                                        width: 32,
                                        height: 32,
                                        child: CircularProgressIndicator(
                                          value: _totalDurationSeconds > 0
                                              ? _secondsRemaining /
                                                  _totalDurationSeconds
                                              : 0.0,
                                          strokeWidth: 3,
                                          backgroundColor:
                                              const Color(0xFFFFE4B3),
                                          valueColor:
                                              const AlwaysStoppedAnimation<
                                                  Color>(Color(0xFFF47B20)),
                                        ),
                                      ),
                                      Icon(
                                        _isTimerRunning
                                            ? Icons.pause_rounded
                                            : Icons.play_arrow_rounded,
                                        size: 16,
                                        color: const Color(0xFFF47B20),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    '${(_secondsRemaining ~/ 60).toString().padLeft(2, '0')}:${(_secondsRemaining % 60).toString().padLeft(2, '0')}',
                                    style: GoogleFonts.poppins(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      color: const Color(0xFFF47B20),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    _isTimerRunning ? 'Pause' : 'Start Timer',
                                    style: GoogleFonts.poppins(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFFF47B20),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 32),
                        ],

                        // Step-specific ingredients Checklist
                        if (stepIngredients.isNotEmpty) ...[
                          Text(
                            'INGREDIENTS NEEDED',
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF8C8A87),
                              letterSpacing: 1.2,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            alignment: WrapAlignment.center,
                            children: stepIngredients.map((ing) {
                              final ingIndex = state.ingredients.indexOf(ing);
                              final isChecked =
                                  state.checkedIngredients[ingIndex];
                              return ChoiceChip(
                                label: Text(ing),
                                selected: isChecked,
                                onSelected: (_) {
                                  context.read<RecipeDetailBloc>().add(
                                      ToggleIngredientCheck(ingIndex));
                                  HapticService.light();
                                },
                                selectedColor: const Color(0xFFFFF2D9),
                                backgroundColor: Colors.white,
                                checkmarkColor: const Color(0xFFF47B20),
                                labelStyle: GoogleFonts.poppins(
                                  fontSize: 12,
                                  fontWeight: isChecked
                                      ? FontWeight.w600
                                      : FontWeight.w500,
                                  color: isChecked
                                      ? const Color(0xFFF47B20)
                                      : const Color(0xFF1F1E1C),
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  side: BorderSide(
                                    color: isChecked
                                        ? const Color(0xFFF47B20)
                                        : const Color(0xFFEFEBE4),
                                    width: 1.0,
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ],
                    ),
                  );
                },
              ),
            ),

            // Controls bottom button bar
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Row(
                children: [
                  // Previous button
                  Expanded(
                    child: SizedBox(
                      height: 52,
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(
                              color: Color(0xFFEFEBE4), width: 1.5),
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
                            color: stepIndex > 0
                                ? const Color(0xFF1F1E1C)
                                : const Color(0xFFB5B3B0),
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Next Step / Finish button
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
                            context
                                .read<RecipeDetailBloc>()
                                .add(CompleteCooking());
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
            ),
          ],
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

class PremiumRefreshIndicator extends StatefulWidget {
  final RefreshIndicatorMode mode;
  final double pulledExtent;
  final double refreshTriggerPullDistance;
  final double refreshIndicatorExtent;

  const PremiumRefreshIndicator({
    required this.mode,
    required this.pulledExtent,
    required this.refreshTriggerPullDistance,
    required this.refreshIndicatorExtent,
    super.key,
  });

  @override
  State<PremiumRefreshIndicator> createState() =>
      _PremiumRefreshIndicatorState();
}

class _PremiumRefreshIndicatorState extends State<PremiumRefreshIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _rotationController;
  RefreshIndicatorMode? _lastMode;
  bool _hapticTriggered = false;

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat();
  }

  @override
  void dispose() {
    _rotationController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant PremiumRefreshIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.mode != _lastMode) {
      if (widget.mode == RefreshIndicatorMode.armed && !_hapticTriggered) {
        HapticService.medium();
        _hapticTriggered = true;
      }
      if (widget.mode == RefreshIndicatorMode.refresh) {
        _hapticTriggered = false;
      }
      if (widget.mode == RefreshIndicatorMode.done) {
        HapticService.medium();
        WidgetsBinding.instance.addPostFrameCallback((_) {
          OverlayNotification.show(
            context,
            message: 'Recipes Updated',
            type: NotificationType.success,
          );
        });
      }
      _lastMode = widget.mode;
    }
  }

  @override
  Widget build(BuildContext context) {
    final double dragPercentage =
        (widget.pulledExtent / widget.refreshTriggerPullDistance)
            .clamp(0.0, 1.0);

    return Container(
      height: widget.pulledExtent,
      alignment: Alignment.center,
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (widget.mode == RefreshIndicatorMode.drag ||
              widget.mode == RefreshIndicatorMode.armed)
            Transform.rotate(
              angle: dragPercentage * 3.1415926535 * 2,
              child: Transform.scale(
                scale: 0.8 + (dragPercentage * 0.4),
                child: const Icon(
                  Icons.soup_kitchen_rounded,
                  color: Color(0xFFF47B20),
                  size: 28,
                ),
              ),
            ),
          if (widget.mode == RefreshIndicatorMode.refresh)
            RotationTransition(
              turns: _rotationController,
              child: const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFF47B20)),
                ),
              ),
            ),
          if (widget.mode == RefreshIndicatorMode.done)
            TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 300),
              curve: Curves.elasticOut,
              builder: (context, val, child) {
                return Transform.scale(
                  scale: val,
                  child: const Icon(
                    Icons.check_circle_rounded,
                    color: Color(0xFF4CAF50),
                    size: 28,
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}

class StaggeredFadeSlide extends StatefulWidget {
  final Widget child;
  final Duration delay;

  const StaggeredFadeSlide({
    required this.child,
    required this.delay,
    super.key,
  });

  @override
  State<StaggeredFadeSlide> createState() => _StaggeredFadeSlideState();
}

class _StaggeredFadeSlideState extends State<StaggeredFadeSlide>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;
  late final Animation<Offset> _slide;
  bool _triggered = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _opacity = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0.0, 0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_triggered) {
      _triggered = true;
      final disableAnimations =
          MediaQuery.maybeOf(context)?.disableAnimations == true;
      if (disableAnimations) {
        _controller.value = 1.0;
      } else {
        Future.delayed(widget.delay, () {
          if (mounted) _controller.forward();
        });
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: SlideTransition(
        position: _slide,
        child: widget.child,
      ),
    );
  }
}
