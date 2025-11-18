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

### Validation Requirements
**IMPORTANT**: Before declaring any implementation complete or "ready", you MUST:
1. Build the project using `xcodebuild` to verify compilation
2. Ensure the build succeeds without errors
3. Only after successful build can you state the implementation is ready
4. Command: `cd .. && xcodebuild -project Waypoint.xcodeproj -scheme Waypoint -configuration Debug build`

This validation step is mandatory for all code changes, no matter how small.

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

### SwiftData Schema Versioning & Migrations

**CRITICAL**: Waypoint uses a versioned schema migration system. All schema changes MUST follow these guidelines to avoid crashes and data loss.

#### Current Schema Version
- **Latest Version**: SchemaV6 (defined in `Models/ProjectMigration.swift`)
- **Models**: Project, Issue, Item, Tag, Space, Resource, ProjectUpdate, Milestone, ContentBlock

#### When Migrations Are Required
You MUST create a new schema version when:
- Adding a new property to a model
- Removing a property from a model
- Changing a property type
- Modifying relationship configurations
- Renaming a model or property

#### How to Create a Schema Migration

**Step 1: Identify Affected Models**
When modifying a model (e.g., adding a field to Space), identify ALL models with direct relationships to it:
- Models that reference it (e.g., Project.space, Tag.space)
- Models it references (e.g., Space.projects, Space.tags)

**Step 2: Create Versioned Models for Previous Schema**
```swift
// Example: Before adding 'sort' field to Space
enum SchemaV5: VersionedSchema {
    static var versionIdentifier = Schema.Version(5, 0, 0)

    static var models: [any PersistentModel.Type] {
        [ProjectV5.self, TagV5.self, SpaceV5.self, /* other models */]
    }

    @Model
    final class SpaceV5 {
        // OLD schema without new field
        var id: UUID
        var name: String
        // ... other existing fields, NO new field

        @Relationship(deleteRule: .nullify, inverse: \ProjectV5.space)
        var projects: [ProjectV5] = []
    }

    @Model
    final class ProjectV5 {
        // ... fields
        var space: SpaceV5?  // References SpaceV5, not Space
    }
}
```

**Step 3: Create New Schema Version**
```swift
enum SchemaV6: VersionedSchema {
    static var versionIdentifier = Schema.Version(6, 0, 0)

    static var models: [any PersistentModel.Type] {
        [Project.self, Tag.self, Space.self, /* other current models */]
    }
    // Uses current model definitions with new fields
}
```

**Step 4: Create Migration Stage**
```swift
static let migrateV5toV6 = MigrationStage.custom(
    fromVersion: SchemaV5.self,
    toVersion: SchemaV6.self,
    willMigrate: { context in
        // Fetch old data
        let v5Spaces = try context.fetch(FetchDescriptor<SchemaV5.SpaceV5>())

        // Store data in temporary structure
        var spacesData: [(id: UUID, name: String, /* ... */)] = []
        for old in v5Spaces {
            spacesData.append((id: old.id, name: old.name))
        }

        // Delete old entities
        for old in v5Spaces { context.delete(old) }
        try context.save()

        // Create new entities with new schema
        for data in spacesData {
            let new = Space(name: data.name /* ... */)
            new.id = data.id  // Preserve IDs
            context.insert(new)
        }
        try context.save()
    },
    didMigrate: nil
)
```

**Step 5: Update Migration Plan**
```swift
enum WaypointMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] {
        [SchemaV1.self, SchemaV2.self, /* ... */, SchemaV6.self]  // Add new version
    }

    static var stages: [MigrationStage] {
        [migrateV1toV2, /* ... */, migrateV5toV6]  // Add new stage
    }
}
```

#### Critical Rules to Avoid "Duplicate Checksum" Errors

1. **NEVER modify an existing schema version** once it's been released/used
   - Don't add fields to SchemaV5 models after SchemaV5 is defined
   - Don't change SchemaV5 after the database has been created with it

2. **Version ALL related models** together
   - If Space changes, version Project and Tag too (they reference Space)
   - Use versioned types in relationships (SpaceV5, not Space)

3. **Use custom migrations for complex changes**
   - Custom migrations give you full control over data transformation
   - Lightweight migrations only work for simple additive changes

4. **Preserve entity IDs during migration**
   - Always copy the `id` field from old to new entities
   - Maintains relationships and user data continuity

5. **Test migrations thoroughly**
   - Cannot easily roll back migrations once run
   - Consider using the database reset code in WaypointApp.swift for testing

#### Database Reset (Testing Only)
In `WaypointApp.swift`, there's commented code to reset the database:
```swift
// Uncomment to delete database for testing fresh schema
// NEVER ship with this uncommented - will delete user data!
```

#### Migration History
- **V1**: Initial schema
- **V2**: Added Project.status field
- **V3**: Added Resources, Updates, Milestones
- **V4**: Added ContentBlock for block editor
- **V5**: Added ContentBlock.indentLevel
- **V6**: Added Space.sort for manual ordering (Current)

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
