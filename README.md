<img width="1536" height="1024" alt="ChatGPT Image Jul 9, 2026, 02_32_50 PM" src="https://github.com/user-attachments/assets/6adf37e4-d525-41a7-9f73-7b27e4ef1f67" />


# 🍛 Recipely

### Modern Recipe Discovery Built with Flutter

Recipely is a beautifully crafted recipe application built with **Flutter**, **BLoC**, **Clean Architecture**, **Hive**, and **Supabase**. It helps users discover recipes, save favorites, and enjoy an immersive step-by-step cooking experience with a clean, responsive interface.

> **Flutter • Clean Architecture • BLoC • Hive • Supabase**

---

# ✨ Why Recipely?

- 🍽 Discover curated recipes through an intuitive browsing experience.
- ❤️ Save and organize your favorite recipes with cloud synchronization.
- 📖 Follow recipes with an immersive guided cooking interface.
- 💾 Fast local caching powered by Hive for a responsive experience.
- 🏗 Built with Clean Architecture for scalability and maintainability.

---

# 🚀 Features

## 🍽 Discovery

- Infinite featured recipe carousel
- Smart search with instant filtering
- Curated recipe collections
- Beautiful recipe browsing experience

## 👨‍🍳 Cooking Experience

- Immersive step-by-step cooking interface
- Interactive ingredient checklist
- Large, readable cooking instructions
- Wake Lock support to keep the screen awake while cooking

## ❤️ Personalization

- Favorite recipes synchronization with Supabase
- Save recipes for quick access
- Personalized cooking experience

## ⚡ Performance

- Smooth scrolling experience
- Cached network images
- Shimmer loading placeholders
- Optimized widget rebuilds
- Responsive layouts

## ♿ Accessibility

- Reduced Motion support
- Large touch targets
- High contrast interface
- Accessible typography

---

# 🛠 Tech Stack

| Category | Technology |
|-----------|------------|
| **Framework** | Flutter & Dart |
| **Architecture** | Clean Architecture |
| **State Management** | flutter_bloc |
| **Backend** | Supabase |
| **Database** | PostgreSQL |
| **Routing** | GoRouter |
| **Local Storage** | Hive |
| **Dependency Injection** | get_it |
| **UI Libraries** | CachedNetworkImage, Shimmer |



# 🏗 Architecture

Recipely follows **Clean Architecture**, separating the application into **Presentation**, **Domain**, and **Data** layers.

The project is organized using a **feature-first structure**, powered by **BLoC** for predictable state management, **Repository Pattern** for data abstraction, and **Dependency Injection** using `get_it`.

This architecture keeps the codebase modular, testable, and easy to scale.

---

# ⚡ Performance Highlights

- ✅ Optimized widget rebuilds
- ✅ Cached network images
- ✅ Smooth 60 FPS animations
- ✅ Shimmer loading placeholders
- ✅ Lazy-loaded content
- ✅ Responsive layouts
- ✅ Reduced Motion accessibility support

---

# 🔬 Engineering Highlights

- Feature-first project structure
- Clean Architecture implementation
- BLoC state management
- Repository Pattern
- Typed GoRouter navigation
- Cached image optimization
- RepaintBoundary optimization
- BlocSelector rebuild optimization
- Staggered animations
- Custom pull-to-refresh interactions
- Wake Lock integration
- Accessibility-aware animations

---

# 📂 Folder Structure

```text
lib/
├── core/
├── router/
├── modules/
│   └── feature/
│       ├── bloc/
│       └── ui/
├── shared/
│   ├── data/
│   ├── services/
│   └── widgets/
└── main.dart
```

---

# 🚀 Getting Started

### Clone the repository

```bash
git clone <repository-url>
```

### Install dependencies

```bash
flutter pub get
```

### Generate routes

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

### Configure Supabase

Create a `.env` file:

```env
SUPABASE_URL=your_supabase_url
SUPABASE_ANON_KEY=your_supabase_key
```

Import the provided SQL schema into your Supabase project.

### Run

```bash
flutter run
```

---

# 🛣 Roadmap

- 🤖 AI recipe recommendations
- 🛒 Grocery list generation
- 📅 Weekly meal planner
- 🎙 Voice-assisted cooking
- ⌚ Wear OS companion

---


## ⭐ Support

If you enjoyed this project or found it useful, consider giving the repository a ⭐.

Contributions, suggestions, and feedback are always welcome.
