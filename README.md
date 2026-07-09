# Recipely

### A hands-free, interactive cooking companion designed for the kitchen environment.

Recipely helps users discover recipes and prepare meals with step-by-step guidance. It replaces static lists with contextual tools that respond to cooking progress and keep screens active when hands are busy.

---

## Why Recipely?

- **Hands-Free Utility**: Keeps the mobile display active during preparation steps to avoid touching the screen with dirty hands.
- **Offline-First Synchronization**: Ensures recipe data is cached and available instantly even with spotty kitchen Wi-Fi.
- **Fluid Motion**: Built with highly responsive, frame-rate optimized scrolling and interface transitions.
- **Enterprise-Grade Foundation**: Structured using Clean Architecture rules for testability, scalability, and clean boundaries.

---

## Features

### 🍽 Discovery
- **Adaptive Carousel**: An infinite-loop recipe slider that pauses on tap and slides naturally to nearby options.
- **Search & Filters**: A predictive matching system that filters recipes instantly as you type.

### 👨🍳 Cooking Experience
- **Step-by-Step Cards**: A fullscreen guide that isolates each instruction step to reduce kitchen distractions.
- **Contextual Active Timers**: In-app timers that extract instruction durations and run countdowns on the step cards.
- **Active Step Ingredients**: Displays checkboxes showing only the ingredients needed for the active step.
- **Screen Wake Lock**: Programmatically prevents mobile device screen dimming or sleeping during active cooking.

### ❤️ Personalization
- **Backend Sync Bookmarks**: Instantly marks favorites and synchronizes saved selections with a cloud backend.
- **Secondary Bookmarks**: Saves secondary recipe cards locally for quick retrieval.

### ⚡ Performance
- **Zero-Flicker Preloaders**: Display shimmers with a 150ms delay to hide layout shifts and placeholder flashes on fast networks.
- **Scroll-Reveal CTAs**: Automatically translates the actions bar downwards during scrolls to focus on instruction content.

### ♿ Accessibility
- **Reduced Motion Settings**: Disables motion and scales layout transitions instantly if reduced motion is enabled on the device.
- **Legible Contrast & Sizing**: High contrast text ratios and large tap targets designed to be readable at arm's length.

---

## Tech Stack

| Category | Technology |
| --- | --- |
| **Frontend** | Flutter SDK (Dart) |
| **Architecture** | Clean Architecture (Data, Domain, Presentation) |
| **State Management** | flutter_bloc |
| **Backend** | Supabase API |
| **Database** | PostgreSQL (Supabase) |
| **Routing** | GoRouter (Typed Routing) |
| **Local Storage** | Shared Preferences & Custom Key-Value Caching |
| **Utilities** | get_it, google_fonts, share_plus, shimmer |
| **Testing** | flutter_test |

---

## Screenshots

| Home & Carousel | Detail & Parallax | Cooking Mode & Timers |
| --- | --- | --- |
| `[Placeholder: Home UI]` | `[Placeholder: Detail UI]` | `[Placeholder: Cooking UI]` |

---

## Architecture

Recipely uses Clean Architecture separated into Presentation, Domain, and Data layers. It implements the Repository Pattern to decouple backend database implementations from core business logic. Organised following a feature-first folder structure, the app handles dependency injection with a central service locator and uses highly modular, reusable widget tokens. This structure guarantees that features can be scaled, tested, and updated independently.

---

## Performance

✔ Consistent 60 FPS animations

✔ Smooth, non-blocking scroll mechanics

✔ Minimal widget rebuild cycles

✔ Cached network image structures

✔ Lazy-loaded lists and grids

✔ Reduced motion fallback support

✔ Multi-device responsive screen layouts

---

## Engineering Highlights

- **BLoC State Management**: Implements strict unidirectional data flow, mapping synchronous UI inputs to state transitions.
- **RepaintBoundary Insulation**: Isolates high-frequency paint widgets (like scroll parallax headers and custom pull-to-refresh loaders) to bypass main layout passes.
- **BlocSelector Optimization**: Prevents parent-level widget rebuilds by building children only when target properties change.
- **Image Memory Constraints**: Controls cache sizes via `memCacheWidth`/`memCacheHeight` on CachedNetworkImage to prevent out-of-memory errors.
- **Typed GoRouter**: Leverages code-generated declarative routing to ensure type-safe navigation and deep linking.
- **Wake Lock Interop**: Conditionally calls Web and VM JS/stub interfaces to keep screen awake without platform crashes.
- **Staggered Animations**: Manages delay offsets on custom slide-and-fade tiles to create structured list entry flows.
- **Pull-to-Refresh Controls**: Builds custom Cupertino refreshers with spoon rotation metrics and elastic done checkmarks.
- **Accessibility Fallbacks**: Detects media query settings to bypass motion animations dynamically under reduced motion profiles.

---

## Folder Structure

```
lib/
├── core/                  # Color tokens, themes, global assets, and configurations
├── router/                # Declared type-safe GoRouter route coordinates
├── modules/               # Feature-specific modules
│   └── [feature]/
│       ├── bloc/          # Presentation managers, event streams, and states
│       └── ui/            # Responsive screen views and local widgets
└── shared/                # Cross-cutting layers and reusable components
    ├── data/              # Database entities, repositories, and models
    ├── services/          # Storage, haptics, notification, and wake lock helpers
    └── widgets/           # Global design system buttons, loaders, empty states, and tiles
```

---

## Getting Started

### 1. Supabase Configuration
Execute [full_schema.sql](file:///d:/New%20folder/receipe_flutter/full_schema.sql) in your Supabase SQL Editor.
Add a `.env` file to the project root:
```env
SUPABASE_URL=https://your-project-ref.supabase.co
SUPABASE_ANON_KEY=your-anon-key
```

### 2. Run Commands
```bash
# Fetch dependencies
flutter pub get

# Generate type-safe routes
flutter pub run build_runner build --delete-conflicting-outputs

# Compile and run the application
flutter run
```

---

## Future Improvements

- 🧠 **AI Recipe Recommendations**: On-device machine learning recommendations based on cooking history.
- 🛒 **Smart Grocery List**: Automatic grocery list aggregation from checked ingredients.
- 📅 **Interactive Meal Planner**: Drag-and-drop weekly meal schedule with nutrition calculator metrics.
- 🎙️ **Voice Cooking Assistant**: Hands-free navigation between steps using speech commands.
- ⌚ **Wear OS Support**: Step checklist and timers synced directly to smartwatches.

---

## About the Developer

* 💼 **LinkedIn**: [LinkedIn Professional Profile](https://linkedin.com)
* 📁 **GitHub**: [GitHub Developer Profile](https://github.com)
* 🌐 **Portfolio**: [Portfolio Website](https://example.com)
* ✉️ **Contact**: [Email Contact Link](mailto:example@example.com)
