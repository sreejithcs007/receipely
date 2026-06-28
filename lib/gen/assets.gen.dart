/// GENERATED CODE - DO NOT MODIFY BY HAND
/// *****************************************************
///  FlutterGen
/// *****************************************************

// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: directives_ordering,unnecessary_import,implicit_dynamic_list_literal,deprecated_member_use

import 'package:flutter/widgets.dart';

class $AssetsIconsGen {
  const $AssetsIconsGen();

  /// File path: assets/icons/.gitkeep
  String get gitkeep => 'assets/icons/.gitkeep';

  /// List of all assets
  List<String> get values => [gitkeep];
}

class $AssetsImagesGen {
  const $AssetsImagesGen();

  /// File path: assets/images/.gitkeep
  String get gitkeep => 'assets/images/.gitkeep';

  $AssetsImagesAvatarsGen get avatars => const $AssetsImagesAvatarsGen();
  $AssetsImagesCategoriesGen get categories =>
      const $AssetsImagesCategoriesGen();
  $AssetsImagesEmptyStatesGen get emptyStates =>
      const $AssetsImagesEmptyStatesGen();
  $AssetsImagesHomeGen get home => const $AssetsImagesHomeGen();
  $AssetsImagesOnboardingGen get onboarding =>
      const $AssetsImagesOnboardingGen();
  $AssetsImagesRecipesGen get recipes => const $AssetsImagesRecipesGen();
  $AssetsImagesSplashGen get splash => const $AssetsImagesSplashGen();

  /// List of all assets
  List<String> get values => [gitkeep];
}

class $AssetsLottieGen {
  const $AssetsLottieGen();

  /// File path: assets/lottie/.gitkeep
  String get gitkeep => 'assets/lottie/.gitkeep';

  /// List of all assets
  List<String> get values => [gitkeep];
}

class $AssetsImagesAvatarsGen {
  const $AssetsImagesAvatarsGen();

  /// File path: assets/images/avatars/chef_avatar.png
  AssetGenImage get chefAvatar =>
      const AssetGenImage('assets/images/avatars/chef_avatar.png');

  /// List of all assets
  List<AssetGenImage> get values => [chefAvatar];
}

class $AssetsImagesCategoriesGen {
  const $AssetsImagesCategoriesGen();

  /// File path: assets/images/categories/category_beverage.png
  AssetGenImage get categoryBeverage =>
      const AssetGenImage('assets/images/categories/category_beverage.png');

  /// File path: assets/images/categories/category_breakfast.png
  AssetGenImage get categoryBreakfast =>
      const AssetGenImage('assets/images/categories/category_breakfast.png');

  /// File path: assets/images/categories/category_dessert.png
  AssetGenImage get categoryDessert =>
      const AssetGenImage('assets/images/categories/category_dessert.png');

  /// File path: assets/images/categories/category_dinner.png
  AssetGenImage get categoryDinner =>
      const AssetGenImage('assets/images/categories/category_dinner.png');

  /// File path: assets/images/categories/category_lunch.png
  AssetGenImage get categoryLunch =>
      const AssetGenImage('assets/images/categories/category_lunch.png');

  /// List of all assets
  List<AssetGenImage> get values => [
        categoryBeverage,
        categoryBreakfast,
        categoryDessert,
        categoryDinner,
        categoryLunch
      ];
}

class $AssetsImagesEmptyStatesGen {
  const $AssetsImagesEmptyStatesGen();

  /// File path: assets/images/empty_states/empty_favorites.png
  AssetGenImage get emptyFavorites =>
      const AssetGenImage('assets/images/empty_states/empty_favorites.png');

  /// File path: assets/images/empty_states/empty_search.png
  AssetGenImage get emptySearch =>
      const AssetGenImage('assets/images/empty_states/empty_search.png');

  /// List of all assets
  List<AssetGenImage> get values => [emptyFavorites, emptySearch];
}

class $AssetsImagesHomeGen {
  const $AssetsImagesHomeGen();

  /// File path: assets/images/home/hero_banner.png
  AssetGenImage get heroBanner =>
      const AssetGenImage('assets/images/home/hero_banner.png');

  /// List of all assets
  List<AssetGenImage> get values => [heroBanner];
}

class $AssetsImagesOnboardingGen {
  const $AssetsImagesOnboardingGen();

  /// File path: assets/images/onboarding/onboarding_ai.png
  AssetGenImage get onboardingAi =>
      const AssetGenImage('assets/images/onboarding/onboarding_ai.png');

  /// File path: assets/images/onboarding/onboarding_discover.png
  AssetGenImage get onboardingDiscover =>
      const AssetGenImage('assets/images/onboarding/onboarding_discover.png');

  /// File path: assets/images/onboarding/onboarding_plan.png
  AssetGenImage get onboardingPlan =>
      const AssetGenImage('assets/images/onboarding/onboarding_plan.png');

  /// List of all assets
  List<AssetGenImage> get values =>
      [onboardingAi, onboardingDiscover, onboardingPlan];
}

class $AssetsImagesRecipesGen {
  const $AssetsImagesRecipesGen();

  /// File path: assets/images/recipes/recipe_avocado_toast.png
  AssetGenImage get recipeAvocadoToast =>
      const AssetGenImage('assets/images/recipes/recipe_avocado_toast.png');

  /// File path: assets/images/recipes/recipe_ramen.png
  AssetGenImage get recipeRamen =>
      const AssetGenImage('assets/images/recipes/recipe_ramen.png');

  /// File path: assets/images/recipes/recipe_salmon.png
  AssetGenImage get recipeSalmon =>
      const AssetGenImage('assets/images/recipes/recipe_salmon.png');

  /// List of all assets
  List<AssetGenImage> get values =>
      [recipeAvocadoToast, recipeRamen, recipeSalmon];
}

class $AssetsImagesSplashGen {
  const $AssetsImagesSplashGen();

  /// File path: assets/images/splash/splash_bg.png
  AssetGenImage get splashBg =>
      const AssetGenImage('assets/images/splash/splash_bg.png');

  /// File path: assets/images/splash/splash_logo.png
  AssetGenImage get splashLogo =>
      const AssetGenImage('assets/images/splash/splash_logo.png');

  /// List of all assets
  List<AssetGenImage> get values => [splashBg, splashLogo];
}

class Assets {
  Assets._();

  static const $AssetsIconsGen icons = $AssetsIconsGen();
  static const $AssetsImagesGen images = $AssetsImagesGen();
  static const $AssetsLottieGen lottie = $AssetsLottieGen();
}

class AssetGenImage {
  const AssetGenImage(this._assetName);

  final String _assetName;

  Image image({
    Key? key,
    AssetBundle? bundle,
    ImageFrameBuilder? frameBuilder,
    ImageErrorWidgetBuilder? errorBuilder,
    String? semanticLabel,
    bool excludeFromSemantics = false,
    double? scale,
    double? width,
    double? height,
    Color? color,
    Animation<double>? opacity,
    BlendMode? colorBlendMode,
    BoxFit? fit,
    AlignmentGeometry alignment = Alignment.center,
    ImageRepeat repeat = ImageRepeat.noRepeat,
    Rect? centerSlice,
    bool matchTextDirection = false,
    bool gaplessPlayback = false,
    bool isAntiAlias = false,
    String? package,
    FilterQuality filterQuality = FilterQuality.low,
    int? cacheWidth,
    int? cacheHeight,
  }) {
    return Image.asset(
      _assetName,
      key: key,
      bundle: bundle,
      frameBuilder: frameBuilder,
      errorBuilder: errorBuilder,
      semanticLabel: semanticLabel,
      excludeFromSemantics: excludeFromSemantics,
      scale: scale,
      width: width,
      height: height,
      color: color,
      opacity: opacity,
      colorBlendMode: colorBlendMode,
      fit: fit,
      alignment: alignment,
      repeat: repeat,
      centerSlice: centerSlice,
      matchTextDirection: matchTextDirection,
      gaplessPlayback: gaplessPlayback,
      isAntiAlias: isAntiAlias,
      package: package,
      filterQuality: filterQuality,
      cacheWidth: cacheWidth,
      cacheHeight: cacheHeight,
    );
  }

  ImageProvider provider({
    AssetBundle? bundle,
    String? package,
  }) {
    return AssetImage(
      _assetName,
      bundle: bundle,
      package: package,
    );
  }

  String get path => _assetName;

  String get keyName => _assetName;
}
