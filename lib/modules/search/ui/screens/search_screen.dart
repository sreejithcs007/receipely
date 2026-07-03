import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../router/routes.dart';
import '../../bloc/search_bloc.dart';
import '../../bloc/search_event.dart';
import '../../bloc/search_state.dart';

class SearchScreen extends StatefulWidget {
  final String? query;
  final String? category;

  const SearchScreen({this.query, this.category, super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.query != null) {
      _searchController.text = widget.query!;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => SearchBloc()..add(LoadSearchPage()),
      child: Builder(
        builder: (context) {
          // Initialize state if initial query is passed via routing
          if (widget.query != null && widget.query!.isNotEmpty) {
            context.read<SearchBloc>().add(SearchQueryChanged(widget.query!));
          }

          return Scaffold(
            backgroundColor: const Color(0xFFFAF7F2), // Premium Canvas Background
            body: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Search Input Header ───────────────────────────────────
                    _buildSearchInput(context),

                    const SizedBox(height: 24),

                    // ── Main Content Area ──────────────────────────────────────
                    Expanded(
                      child: BlocBuilder<SearchBloc, SearchState>(
                        builder: (context, state) {
                          return SingleChildScrollView(
                            physics: const BouncingScrollPhysics(),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Recent Searches
                                if (state.recentSearches.isNotEmpty) ...[
                                  _buildRecentSearchesHeader(context),
                                  const SizedBox(height: 12),
                                  _buildRecentSearchesList(context, state),
                                  const SizedBox(height: 24),
                                ],

                                // Trending Section
                                _buildTrendingHeader(),
                                const SizedBox(height: 12),
                                _buildTrendingList(context),
                                const SizedBox(height: 24),

                                // Filter Row Dropdowns
                                _buildFiltersRow(context, state),
                                const SizedBox(height: 24),

                                // Grid Section Header
                                Text(
                                  state.query.isEmpty &&
                                          state.cuisineFilter == null &&
                                          state.dietFilter == null &&
                                          state.timeFilter == null
                                      ? 'Popular Recipes'
                                      : 'Search Results (${state.results.length})',
                                  style: GoogleFonts.playfairDisplay(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF1F1E1C),
                                  ),
                                ),
                                const SizedBox(height: 16),

                                // Grid Items
                                if (state.results.isEmpty)
                                  _buildEmptyState()
                                else
                                  _buildRecipesGrid(context, state),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSearchInput(BuildContext context) {
    return Container(
      height: 52,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEFEBE4), width: 1.2),
      ),
      child: Row(
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0),
            child: Icon(Icons.search_rounded, color: Color(0xFF8C8A87), size: 22),
          ),
          Expanded(
            child: TextField(
              controller: _searchController,
              onChanged: (val) {
                context.read<SearchBloc>().add(SearchQueryChanged(val));
              },
              onSubmitted: (val) {
                context.read<SearchBloc>().add(AddRecentSearch(val));
              },
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: const Color(0xFF1F1E1C),
                fontWeight: FontWeight.w400,
              ),
              decoration: InputDecoration(
                hintText: 'Search recipes, ingredients...',
                hintStyle: GoogleFonts.poppins(
                  fontSize: 14,
                  color: const Color(0xFFB5B3B0),
                  fontWeight: FontWeight.w400,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
          // Voice mic circle container
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: Container(
              width: 36,
              height: 36,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFFF5F3EE),
              ),
              child: const Icon(
                Icons.mic_none_rounded,
                color: Color(0xFF8C8A87),
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentSearchesHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Recent Searches',
          style: GoogleFonts.poppins(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF1F1E1C),
          ),
        ),
        GestureDetector(
          onTap: () {
            context.read<SearchBloc>().add(ClearRecentSearches());
          },
          child: Text(
            'Clear',
            style: GoogleFonts.poppins(
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
              color: const Color(0xFFF47B20),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRecentSearchesList(BuildContext context, SearchState state) {
    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: state.recentSearches.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final query = state.recentSearches[index];
          return Container(
            padding: const EdgeInsets.only(left: 12, right: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F3EE),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFEFEBE4), width: 1.0),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.access_time_rounded, color: Color(0xFF8C8A87), size: 14),
                const SizedBox(width: 6),
                GestureDetector(
                  onTap: () {
                    _searchController.text = query;
                    context.read<SearchBloc>().add(SearchQueryChanged(query));
                  },
                  child: Text(
                    query,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF1F1E1C),
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                GestureDetector(
                  onTap: () {
                    context.read<SearchBloc>().add(RemoveRecentSearch(query));
                  },
                  child: const Padding(
                    padding: EdgeInsets.all(4.0),
                    child: Icon(Icons.close, color: Color(0xFF8C8A87), size: 12),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildTrendingHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Trending',
          style: GoogleFonts.poppins(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF1F1E1C),
          ),
        ),
        Text(
          'See all',
          style: GoogleFonts.poppins(
            fontSize: 13.5,
            fontWeight: FontWeight.w600,
            color: const Color(0xFFF47B20),
          ),
        ),
      ],
    );
  }

  Widget _buildTrendingList(BuildContext context) {
    final trending = ['high protein', '30 minute meals', 'one pot meals'];
    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: trending.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final query = trending[index];
          return GestureDetector(
            onTap: () {
              _searchController.text = query;
              context.read<SearchBloc>().add(SearchQueryChanged(query));
              context.read<SearchBloc>().add(AddRecentSearch(query));
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF2D9), // Light warm yellow/peach
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFFFE0A3), width: 1.0),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.trending_up_rounded, color: Color(0xFFF47B20), size: 14),
                  const SizedBox(width: 6),
                  Text(
                    query,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFFF47B20),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFiltersRow(BuildContext context, SearchState state) {
    return Row(
      children: [
        _buildFilterChip(
          context,
          label: state.cuisineFilter ?? 'Cuisine',
          icon: Icons.language_rounded,
          isActive: state.cuisineFilter != null,
          onTap: () => _showFilterMenu(
            context,
            filterType: 'cuisine',
            options: ['Italian', 'Greek', 'Indian', 'American'],
            selectedValue: state.cuisineFilter,
          ),
        ),
        const SizedBox(width: 8),
        _buildFilterChip(
          context,
          label: state.dietFilter ?? 'Diet',
          icon: Icons.eco_outlined,
          isActive: state.dietFilter != null,
          onTap: () => _showFilterMenu(
            context,
            filterType: 'diet',
            options: ['Vegan', 'Vegetarian', 'Low Carb'],
            selectedValue: state.dietFilter,
          ),
        ),
        const SizedBox(width: 8),
        _buildFilterChip(
          context,
          label: state.timeFilter ?? 'Time',
          icon: Icons.access_time_rounded,
          isActive: state.timeFilter != null,
          onTap: () => _showFilterMenu(
            context,
            filterType: 'time',
            options: ['Under 15 min', 'Under 30 min'],
            selectedValue: state.timeFilter,
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChip(
    BuildContext context, {
    required String label,
    required IconData icon,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isActive ? const Color(0xFFF47B20) : const Color(0xFFEFEBE4),
              width: 1.2,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: isActive ? const Color(0xFFF47B20) : const Color(0xFF8C8A87),
                size: 15,
              ),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                    color: isActive ? const Color(0xFFF47B20) : const Color(0xFF1F1E1C),
                  ),
                ),
              ),
              const SizedBox(width: 2),
              Icon(
                Icons.keyboard_arrow_down_rounded,
                color: isActive ? const Color(0xFFF47B20) : const Color(0xFF8C8A87),
                size: 14,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showFilterMenu(
    BuildContext context, {
    required String filterType,
    required List<String> options,
    required String? selectedValue,
  }) {
    final searchBloc = context.read<SearchBloc>();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFEFEBE4),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Select ${filterType.substring(0, 1).toUpperCase()}${filterType.substring(1)}',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF1F1E1C),
                      ),
                    ),
                    if (selectedValue != null)
                      GestureDetector(
                        onTap: () {
                          searchBloc.add(SelectFilter(filterType, null));
                          Navigator.pop(context);
                        },
                        child: Text(
                          'Reset',
                          style: GoogleFonts.poppins(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFFF47B20),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const Divider(color: Color(0xFFEFEBE4)),
              ...options.map((opt) {
                final isSelected = opt == selectedValue;
                return ListTile(
                  title: Text(
                    opt,
                    style: GoogleFonts.poppins(
                      fontSize: 14.5,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                      color: isSelected ? const Color(0xFFF47B20) : const Color(0xFF1F1E1C),
                    ),
                  ),
                  trailing: isSelected
                      ? const Icon(Icons.check_rounded, color: Color(0xFFF47B20))
                      : null,
                  onTap: () {
                    searchBloc.add(SelectFilter(filterType, opt));
                    Navigator.pop(context);
                  },
                );
              }),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.only(top: 40.0),
        child: Column(
          children: [
            const Icon(Icons.search_off_rounded, size: 64, color: Color(0xFFB5B3B0)),
            const SizedBox(height: 16),
            Text(
              'No recipes found',
              style: GoogleFonts.playfairDisplay(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1F1E1C),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Try checking spelling or adjusting filters',
              style: GoogleFonts.poppins(
                fontSize: 13.5,
                color: const Color(0xFF8C8A87),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecipesGrid(BuildContext context, SearchState state) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        mainAxisExtent: 220,
      ),
      itemCount: state.results.length,
      itemBuilder: (context, index) {
        final item = state.results[index];
        return GestureDetector(
          onTap: () {
            // Push to detail screen
            RecipeDetailRoute(recipeId: item.id).push(context);
          },
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF3A2818).withValues(alpha: 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top image stack
                SizedBox(
                  height: 120,
                  width: double.infinity,
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: ClipRRect(
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(20),
                          ),
                          child: Image.asset(
                            item.imageUrl,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      // Bookmark/favorite overlay button (white circle with heart)
                      Positioned(
                        top: 10,
                        right: 10,
                        child: Container(
                          width: 28,
                          height: 28,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                          ),
                          child: const Icon(
                            Icons.favorite_border_rounded,
                            color: Color(0xFF8C8A87),
                            size: 15,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Card details
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF1F1E1C),
                          height: 1.25,
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Cook time
                      Row(
                        children: [
                          const Icon(
                            Icons.access_time_rounded,
                            color: Color(0xFF8C8A87),
                            size: 14,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            item.cookTime,
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF8C8A87),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
