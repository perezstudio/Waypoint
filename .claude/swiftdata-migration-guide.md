# SwiftData Migration Guide for Waypoint

## 🤖 AI Assistant Instructions

**IMPORTANT**: Whenever you need to make changes to any `@Model` class in the `Models/` directory, you MUST follow this migration guide. This includes:

- Adding/removing properties
- Changing property types
- Renaming properties
- Adding/removing relationships
- Adding new model classes
- Changing relationship types or delete rules

**Before making ANY model changes**, read this entire guide and follow the step-by-step process.

**Key Rule**: The latest schema version ALWAYS uses the current, unversioned models from `Models/`. Historical schemas contain frozen, versioned copies.

---

## Critical Principles

### 1. The Current-Models Pattern

✅ **CORRECT PATTERN:**
```
┌─────────────────────────────────────────┐
│ V1 (Current)                            │
│ Uses: Project, Issue, Space             │
│ Location: Models/*.swift                │
│ Note: No version suffix                 │
└─────────────────────────────────────────┘

When you need to add V2:

┌─────────────────────────────────────────┐
│ V1 (Historical - FROZEN)                │
│ Uses: ProjectV1, IssueV1, SpaceV1       │
│ Location: Inside SchemaV1 enum          │
│ Note: Exact copies of V1 models         │
└─────────────────────────────────────────┘
              ↓ Migration
┌─────────────────────────────────────────┐
│ V2 (Current)                            │
│ Uses: Project, Issue, Space             │
│ Location: Models/*.swift                │
│ Note: Contains your new changes         │
└─────────────────────────────────────────┘
```

### 2. Why This Pattern?

- **Latest schema = Current models**: Your app's `@Query` statements don't need updates
- **Historical schemas = Versioned copies**: Frozen in time for migration purposes
- **Each schema must be unique**: SwiftData uses checksums to differentiate schemas
- **Never share models between schemas**: Causes "Duplicate version checksums" crash

---

## Step-by-Step Migration Process

### Step 1: Identify That Migration Is Needed

You need a migration if you're changing ANY of these files:
- `Models/Project.swift`
- `Models/Issue.swift`
- `Models/ContentBlock.swift`
- `Models/Tag.swift`
- `Models/Space.swift`
- `Models/Resource.swift`
- `Models/ProjectUpdate.swift`
- `Models/Milestone.swift`
- `Models/ProjectIssuesViewSettings.swift`

Or adding a new `@Model` class.

### Step 2: Freeze the Current Schema

Open `Models/ProjectMigration.swift` and find the current schema (e.g., `SchemaV1`).

**BEFORE** (V1 uses current models):
```swift
enum SchemaV1: VersionedSchema {
    static var versionIdentifier = Schema.Version(1, 0, 0)

    static var models: [any PersistentModel.Type] {
        [
            Project.self,      // Current models
            Issue.self,
            ContentBlock.self,
            // ... etc
        ]
    }

    // Note: V1 uses the current, unversioned models from Models/
}
```

**AFTER** (V1 frozen with versioned models):
```swift
enum SchemaV1: VersionedSchema {
    static var versionIdentifier = Schema.Version(1, 0, 0)

    static var models: [any PersistentModel.Type] {
        [
            ProjectV1.self,      // NOW using versioned models
            IssueV1.self,
            ContentBlockV1.self,
            TagV1.self,
            SpaceV1.self,
            ResourceV1.self,
            ProjectUpdateV1.self,
            MilestoneV1.self,
            ProjectIssuesViewSettingsV1.self
        ]
    }

    // MARK: - V1 Models (Frozen Copies)

    @Model
    final class ProjectV1 {
        // Copy EXACTLY from Models/Project.swift
        var id: UUID
        var name: String
        var icon: String
        var color: String
        var status: Status
        var projectDescription: String?
        var createdAt: Date
        var updatedAt: Date
        var favorite: Bool = false

        @Relationship(deleteRule: .cascade, inverse: \IssueV1.project)
        var issues: [IssueV1] = []

        @Relationship(deleteRule: .cascade, inverse: \ResourceV1.project)
        var resources: [ResourceV1] = []

        @Relationship(deleteRule: .cascade, inverse: \ProjectUpdateV1.project)
        var updates: [ProjectUpdateV1] = []

        @Relationship(deleteRule: .cascade, inverse: \MilestoneV1.project)
        var milestones: [MilestoneV1] = []

        @Relationship(deleteRule: .cascade, inverse: \ContentBlockV1.project)
        var contentBlocks: [ContentBlockV1] = []

        @Relationship(deleteRule: .cascade, inverse: \ProjectIssuesViewSettingsV1.project)
        var viewSettings: ProjectIssuesViewSettingsV1?

        var space: SpaceV1?

        init(name: String, icon: String = "folder.fill", color: String = "#007AFF", status: Status = .inProgress, space: SpaceV1? = nil) {
            self.id = UUID()
            self.name = name
            self.icon = icon
            self.color = color
            self.status = status
            self.createdAt = Date()
            self.updatedAt = Date()
            self.favorite = false
            self.space = space
            self.viewSettings = ProjectIssuesViewSettingsV1(project: nil)
        }
    }

    @Model
    final class IssueV1 {
        // Copy EXACTLY from Models/Issue.swift
        // ... all properties and relationships ...
    }

    // ... Copy ALL other models with V1 suffix ...
}
```

**IMPORTANT**: You must copy ALL models, even if they haven't changed. Update ALL relationship references to use V1 versions (e.g., `@Relationship(inverse: \IssueV1.tags)`).

### Step 3: Create the New Schema Version

Add a new schema AFTER the frozen one:

```swift
// MARK: - Schema V2 (Current - Your New Changes)

enum SchemaV2: VersionedSchema {
    static var versionIdentifier = Schema.Version(2, 0, 0)

    static var models: [any PersistentModel.Type] {
        [
            Project.self,      // Uses CURRENT models (no version suffix)
            Issue.self,
            ContentBlock.self,
            Tag.self,
            Space.self,
            Resource.self,
            ProjectUpdate.self,
            Milestone.self,
            ProjectIssuesViewSettings.self
        ]
    }

    // No model definitions here - uses current models from Models/ directory
    // Make your changes in Models/Issue.swift, Models/Project.swift, etc.
}
```

### Step 4: Make Your Changes in Models/

Now you can safely modify the model files in `Models/`:

```swift
// In Models/Issue.swift
@Model
final class Issue {
    var id: UUID
    var title: String
    var issueDescription: String?
    var status: Status
    var priority: IssuePriority
    var createdAt: Date
    var updatedAt: Date
    var dueDate: Date?

    // NEW PROPERTY - Always make new properties optional!
    var estimatedHours: Int? = nil

    // Or RENAME with @Attribute
    @Attribute(originalName: "issueDescription")
    var description: String?

    var project: Project?
    var tags: [Tag] = []

    @Relationship(deleteRule: .cascade, inverse: \ContentBlock.issue)
    var contentBlocks: [ContentBlock] = []

    init(title: String, status: Status = .todo, priority: IssuePriority = .medium, project: Project? = nil) {
        self.id = UUID()
        self.title = title
        self.status = status
        self.priority = priority
        self.createdAt = Date()
        self.updatedAt = Date()
        self.project = project
    }
}
```

### Step 5: Update the Migration Plan

Add the new schema and migration stage:

```swift
enum WaypointMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] {
        [SchemaV1.self, SchemaV2.self]  // Add V2
    }

    static var stages: [MigrationStage] {
        [migrateV1toV2]  // Add migration stage
    }

    // V1 -> V2 Migration
    static let migrateV1toV2 = MigrationStage.lightweight(
        fromVersion: SchemaV1.self,
        toVersion: SchemaV2.self
    )
}
```

### Step 6: NO Changes to WaypointApp.swift

✅ **WaypointApp.swift stays the same!** It continues using current models:

```swift
return try ModelContainer(
    for: Project.self,      // Still current models
    Issue.self,
    ContentBlock.self,
    Tag.self,
    Space.self,
    Resource.self,
    ProjectUpdate.self,
    Milestone.self,
    ProjectIssuesViewSettings.self,
    migrationPlan: WaypointMigrationPlan.self
)
```

### Step 7: Build and Test

```bash
xcodebuild -scheme Waypoint -destination 'platform=macOS' build
```

If you get errors like:
- "Duplicate version checksums" → Models are shared between schemas
- "Cannot find type in scope" → Forgot to add V1 suffix to a relationship

---

## Lightweight vs Custom Migrations

### Use Lightweight Migration (90% of cases)

Good for:
- ✅ Adding optional properties
- ✅ Removing properties
- ✅ Renaming properties with `@Attribute(originalName:)`
- ✅ Adding new model classes

```swift
static let migrateV1toV2 = MigrationStage.lightweight(
    fromVersion: SchemaV1.self,
    toVersion: SchemaV2.self
)
```

### Use Custom Migration (Complex cases)

Required for:
- ⚠️ Changing property types
- ⚠️ Making optional properties required
- ⚠️ Complex data transformations
- ⚠️ Setting default values for new required properties

```swift
static let migrateV1toV2 = MigrationStage.custom(
    fromVersion: SchemaV1.self,
    toVersion: SchemaV2.self,
    willMigrate: { context in
        // Runs BEFORE data transformation
        print("📦 Starting V1 → V2 migration")
    },
    didMigrate: { context in
        // Runs AFTER data transformation
        print("📦 Applying post-migration logic")

        let descriptor = FetchDescriptor<Issue>()
        let issues = try context.fetch(descriptor)

        for issue in issues {
            // Set defaults for new properties
            if issue.estimatedHours == nil {
                issue.estimatedHours = 0
            }
        }

        try context.save()
        print("✅ V1 → V2 migration complete")
    }
)
```

---

## Common Errors and Solutions

### Error: "Duplicate version checksums detected"

**Cause**: Two schemas are using the same model classes.

**Fix**: Ensure each schema uses different models:
- Historical schemas: Versioned models (ProjectV1, IssueV1)
- Latest schema: Current models (Project, Issue)

### Error: "The current model reference and the next model reference cannot be equal"

**Cause**: Same as above - schemas have identical checksums.

**Fix**: Properly version all models in historical schemas.

### Error: "Cannot find type 'ProjectV1' in scope"

**Cause**: You referenced a versioned model but didn't define it.

**Fix**: Make sure ALL models are copied and versioned in the historical schema.

### Error: Build succeeds but app crashes on launch

**Cause**: Model definitions in versioned schema don't match the actual data in the database.

**Fix**: Your versioned models must be EXACT copies of the models as they were in that version. Don't "fix" or "improve" them.

---

## Migration Checklist

When creating a new schema version:

- [ ] Identified all models that need versioning
- [ ] Created versioned copies (V1, V2, etc.) in the OLD schema
- [ ] Updated ALL relationship references to use versioned types
- [ ] Created new schema version using current models
- [ ] Made changes only in `Models/` directory files
- [ ] Updated migration plan with new schema
- [ ] Added migration stage (lightweight or custom)
- [ ] Build succeeds without errors
- [ ] Tested with existing data (if any)
- [ ] Verified data integrity after migration
- [ ] Tested app functionality with migrated data
- [ ] Updated this guide if you learned something new

---

## Quick Reference

### Current State

**Schema Version**: V1 (1.0.0)
**Models**: All 9 models with Issue-ContentBlock relationship
**File**: `Models/ProjectMigration.swift`

### Schema History

| Version | Date | Changes | Migration Type |
|---------|------|---------|----------------|
| V1 | Nov 19, 2025 | Initial baseline with Issue-ContentBlock relationship | - |

### When to Version

```
┌─────────────────────────────────────┐
│ Question: Do I need a migration?    │
└─────────────────────────────────────┘
                ↓
    Are you changing a @Model class?
                ↓
              ┌─┴─┐
             YES  NO → Just code changes, no migration
              │
              ↓
┌──────────────────────────────────────┐
│ Follow Step-by-Step Process Above   │
└──────────────────────────────────────┘
```

---

## Example: Complete Migration (V1 → V2)

Let's say we want to add `estimatedHours` to `Issue`.

### Before (Current State)

`Models/ProjectMigration.swift`:
```swift
enum SchemaV1: VersionedSchema {
    static var versionIdentifier = Schema.Version(1, 0, 0)
    static var models: [any PersistentModel.Type] {
        [Project.self, Issue.self, ...]  // Current models
    }
}

enum WaypointMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] {
        [SchemaV1.self]
    }
    static var stages: [MigrationStage] {
        []
    }
}
```

### After (With V2)

`Models/ProjectMigration.swift`:
```swift
enum SchemaV1: VersionedSchema {
    static var versionIdentifier = Schema.Version(1, 0, 0)
    static var models: [any PersistentModel.Type] {
        [ProjectV1.self, IssueV1.self, ...]  // FROZEN with V1 suffix
    }

    @Model
    final class ProjectV1 { /* exact copy */ }

    @Model
    final class IssueV1 { /* exact copy WITHOUT estimatedHours */ }

    // ... all other V1 models ...
}

enum SchemaV2: VersionedSchema {
    static var versionIdentifier = Schema.Version(2, 0, 0)
    static var models: [any PersistentModel.Type] {
        [Project.self, Issue.self, ...]  // Current models
    }
    // No definitions - uses Models/
}

enum WaypointMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] {
        [SchemaV1.self, SchemaV2.self]  // Added V2
    }

    static var stages: [MigrationStage] {
        [migrateV1toV2]  // Added stage
    }

    static let migrateV1toV2 = MigrationStage.lightweight(
        fromVersion: SchemaV1.self,
        toVersion: SchemaV2.self
    )
}
```

`Models/Issue.swift`:
```swift
@Model
final class Issue {
    // ... existing properties ...
    var estimatedHours: Int? = nil  // NEW!
    // ... rest of model ...
}
```

---

## Resources

- [Apple SwiftData Documentation](https://developer.apple.com/documentation/swiftdata)
- [Apple Migration Guide](https://developer.apple.com/documentation/swiftdata/migrating-your-app-s-data-model)
- [WWDC23: Model your schema with SwiftData](https://developer.apple.com/videos/play/wwdc2023/10195/)
- [Hacking with Swift - SwiftData Migrations](https://www.hackingwithswift.com/quick-start/swiftdata/how-to-migrate-swiftdata-schema-changes)

---

## Summary for AI Assistants

**When making model changes:**

1. ✅ Read this entire guide
2. ✅ Follow the step-by-step process
3. ✅ Freeze the current schema with versioned models
4. ✅ Create new schema using current models
5. ✅ Make changes in `Models/` directory
6. ✅ Update migration plan
7. ✅ Build and test
8. ✅ Update schema history table in this guide

**Never:**
- ❌ Share models between schemas
- ❌ Modify historical schema definitions
- ❌ Skip versioning all models
- ❌ Make changes without testing

**The golden rule**: Latest schema = current models. Historical schemas = frozen versioned copies.
