# Waypoint - macOS Project Management App

## Project Overview
Waypoint is a macOS application built with SwiftUI for managing projects, tasks, and labels. The app features a three-pane interface similar to modern productivity apps with a sidebar, main detail view, and inspector panel.

## Technology Stack
- **Language**: Swift
- **Framework**: SwiftUI (macOS)
- **Data Persistence**: SwiftData
- **Minimum macOS Version**: macOS 14.0+ (Sonoma)
- **Architecture**: SwiftUI MVVM pattern

## Project Structure
```
Waypoint/
├── WaypointApp.swift        # App entry point with SwiftData configuration
├── ContentView.swift        # Main container view (three-pane layout)
├── Item.swift              # SwiftData model
└── Views/
    ├── SidebarView.swift   # Left sidebar navigation
    ├── DetailView.swift    # Center detail/main content view
    ├── InspectorView.swift # Right inspector panel
    └── MenuItemView.swift  # Reusable menu item component
```

## App Architecture

### Layout Structure
The app uses a three-pane HStack layout:
1. **SidebarView** (left, max width 300pt) - Navigation and favorites
2. **DetailView** (center, flexible width) - Main content area
3. **InspectorView** (right) - Contextual information panel

### Window Configuration
- Hidden title bar (`.windowStyle(.hiddenTitleBar)`)
- Thin material background (`.containerBackground(.thinMaterial, for: .window)`)

## Coding Standards

### SwiftUI Conventions
- Use `struct` for all views conforming to `View` protocol
- Include `#Preview` macros for all view files
- Use `@Environment(\.modelContext)` for SwiftData context access
- Use `@Query` for SwiftData queries

### File Organization
- All view files go in the `Views/` directory
- Data models at the root level
- Use consistent file headers with creation date and author

### Naming Conventions
- Views: `{Purpose}View.swift` (e.g., `SidebarView.swift`)
- Models: `{Entity}.swift` (e.g., `Item.swift`)
- Use descriptive, clear names that indicate purpose

### SwiftData Best Practices
- Define models with `@Model` macro
- Use `ModelContainer` with proper schema configuration
- Handle errors with meaningful messages when creating `ModelContainer`
- Use `inMemory: true` for previews to avoid affecting production data

### View Composition
- Break down complex views into smaller, reusable components
- Use view modifiers consistently (padding, spacing, etc.)
- Keep view bodies clean and readable
- Extract complex logic into private methods or separate view models

### Layout Guidelines
- Use `Spacer()` for flexible spacing
- Apply `.padding()` at the appropriate view level
- Use `HStack`, `VStack`, `ZStack` for layout composition
- Set explicit frame constraints where needed (`.frame(maxWidth:)`)

## Common Patterns

### Adding New Views
1. Create file in `Views/` directory with proper naming
2. Import `SwiftUI` and `SwiftData` if needed
3. Add file header comment with creation info
4. Implement view conforming to `View` protocol
5. Add `#Preview` macro for development

### Working with SwiftData
- Query data with `@Query private var items: [Entity]`
- Access context with `@Environment(\.modelContext) private var modelContext`
- Insert: `modelContext.insert(newItem)`
- Delete: `modelContext.delete(item)`
- Wrap mutations in `withAnimation` for smooth transitions

## Design Patterns
- Sidebar contains navigation, favorites, and quick actions
- Detail view shows tabbed interface for different content types (Overview, Status, Issues)
- Inspector provides contextual information about selected items
- Use SF Symbols for icons throughout the app

## Development Notes
- The app is in early development with placeholder content
- Current focus is on establishing the core layout structure
- SwiftData models need to be expanded beyond the basic `Item` model
- UI components like `MenuItemView` are currently placeholders

## Future Considerations
- Implement proper data models for projects, tasks, and labels
- Add state management for navigation and selection
- Implement sidebar toggle functionality
- Add proper tab navigation in DetailView
- Expand inspector with contextual property editors
