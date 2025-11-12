# Waypoint - Project Requirements & Planning Document

## Executive Summary

Waypoint is a native macOS project management application designed for individual developers, combining the best aspects of Jira and Linear with a native Mac experience. Built using Objective-C for custom window management and SwiftUI for views, with SwiftData for persistence and CloudKit sync for seamless iCloud backup.

---

## Technical Architecture

### Technology Stack

**Core Technologies:**
- **UI Framework**: SwiftUI for views, Objective-C AppKit APIs for custom window chrome and layouts
- **Data Layer**: SwiftData for local persistence
- **Sync**: CloudKit integration via SwiftData's built-in sync capabilities
- **Language**: Swift 5.9+ with Objective-C interop for window management
- **Minimum OS**: macOS 14.0 (Sonoma) for full SwiftData features

**Architecture Pattern:**
- MVVM (Model-View-ViewModel) for SwiftUI views
- Repository pattern for data access abstraction
- Service layer for business logic
- Protocol-oriented design for future API extensibility

---

## Data Model

### Core Entities

#### 1. **Team**
```swift
@Model
class Team {
    var id: UUID
    var name: String
    var createdAt: Date
    var isDefault: Bool
    
    // Relationships
    var projects: [Project]
    var issues: [Issue]
    var labels: [Label]
    var statuses: [Status]
}
```

**Business Rules:**
- One default team per user (created with user's name)
- Team name must be unique per user
- Deleting a team cascades to all related entities

---

#### 2. **Project**
```swift
@Model
class Project {
    var id: UUID
    var name: String
    var description: String
    var status: ProjectStatus // enum
    var priority: Priority // enum
    var startDate: Date?
    var targetDate: Date?
    var isFavorite: Bool
    var planDocument: String // Markdown content
    var createdAt: Date
    var updatedAt: Date
    
    // Relationships
    var team: Team
    var issues: [Issue]
    var milestones: [Milestone]
    var labels: [Label]
    var links: [ProjectLink]
    var updates: [ProjectUpdate]
}

enum ProjectStatus: String, Codable {
    case backlog, planned, inProgress, completed, canceled
}

enum Priority: String, Codable {
    case urgent, high, medium, low, noPriority
}
```

**Features:**
- Markdown-based plan editor with Notion-like component generation
- Link management for external documentation
- Status and priority tracking
- Favoriting for quick access

---

#### 3. **Milestone**
```swift
@Model
class Milestone {
    var id: UUID
    var name: String
    var description: String
    var targetDate: Date?
    var createdAt: Date
    
    // Relationships
    var project: Project
    var issues: [Issue]
    
    // Computed properties (not stored)
    var totalIssues: Int // Count excluding canceled
    var completedIssues: Int // Count with completed status
    var completionPercentage: Double
}
```

**Business Rules:**
- Must belong to a project
- Only issues from the same project can be linked
- Canceled issues excluded from progress calculations

---

#### 4. **Issue**
```swift
@Model
class Issue {
    var id: UUID
    var title: String
    var description: String
    var status: Status
    var priority: Priority
    var dueDate: Date?
    var isInbox: Bool
    var createdAt: Date
    var updatedAt: Date
    
    // Relationships
    var team: Team
    var project: Project?
    var milestone: Milestone?
    var labels: [Label]
    var checklists: [Checklist]
    var comments: [Comment]
}
```

**Business Rules:**
- Issues without a project are inbox items (isInbox = true)
- Must belong to a team
- If assigned to milestone, must belong to milestone's project

---

#### 5. **Label**
```swift
@Model
class Label {
    var id: UUID
    var name: String
    var color: String // Hex color code
    var description: String
    var isFavorite: Bool
    var createdAt: Date
    
    // Relationships
    var team: Team
    var projects: [Project]
    var issues: [Issue]
}
```

---

#### 6. **Status**
```swift
@Model
class Status {
    var id: UUID
    var name: String
    var parentStatus: ParentStatus
    var sortOrder: Int
    var createdAt: Date
    
    // Relationships
    var team: Team
}

enum ParentStatus: String, Codable {
    case backlog, planned, inProgress, completed, canceled
}
```

**Business Rules:**
- Custom statuses grouped under parent categories
- Multiple statuses can exist under same parent (e.g., "In Review", "In Development" under In Progress)
- Default statuses created per team matching ParentStatus enum

---

#### 7. **Supporting Entities**

**Checklist**
```swift
@Model
class Checklist {
    var id: UUID
    var title: String
    var isCompleted: Bool
    var sortOrder: Int
    var createdAt: Date
    
    var issue: Issue
}
```

**Comment**
```swift
@Model
class Comment {
    var id: UUID
    var content: String
    var createdAt: Date
    var updatedAt: Date
    var editHistory: [CommentEdit]
    
    var issue: Issue
}

struct CommentEdit: Codable {
    var editedAt: Date
    var previousContent: String
}
```

**ProjectLink**
```swift
@Model
class ProjectLink {
    var id: UUID
    var title: String
    var url: String
    var sortOrder: Int
    var createdAt: Date
    
    var project: Project
}
```

**ProjectUpdate**
```swift
@Model
class ProjectUpdate {
    var id: UUID
    var content: String
    var healthStatus: ProjectHealth
    var createdAt: Date
    var updatedAt: Date
    var editHistory: [UpdateEdit]
    
    var project: Project
}

enum ProjectHealth: String, Codable {
    case onTrack, atRisk, offTrack
}

struct UpdateEdit: Codable {
    var editedAt: Date
    var previousContent: String
    var previousHealth: ProjectHealth
}
```

---

## User Interface Structure

### Window Architecture

**Main Window (Custom Objective-C Chrome)**
```
┌─────────────────────────────────────────────────────────┐
│  [Team Picker ▾]                    [macOS Traffic Lights]│
├─────────────┬──────────────────────┬────────────────────┤
│             │                      │                    │
│   Sidebar   │    Main Content      │   Details Panel   │
│   (250px)   │      (flexible)      │     (300px)       │
│             │                      │                    │
│             │                      │                    │
│             │                      │                    │
│             │                      │                    │
├─────────────┴──────────────────────┴────────────────────┤
│  [+] [Settings]                                         │
└─────────────────────────────────────────────────────────┘
```

**Features:**
- Three-column layout with resizable splitters
- Collapsible sidebar and details panel
- Custom window chrome using NSWindow subclass
- Toolbar items in title bar
- Native macOS appearance (supports light/dark mode)

---

### Sidebar Navigation

**Structure:**
```
┌─────────────────────────┐
│ [Team Picker ▾]         │
├─────────────────────────┤
│ 📥 Inbox          (12)  │
│ 📅 Today          (5)   │
│ 🗓️  Scheduled            │
│ 📋 All Issues     (47)  │
│ 📚 Logbook              │
│ 🗂️  Projects      (8)   │
├─────────────────────────┤
│ ⭐ Favorites            │
│   ▾ Mobile App          │
│   ▾ API Redesign        │
│   ▾ Documentation       │
├─────────────────────────┤
│ 🏷️  Labels               │
│   ▾ 🔴 Critical          │
│   ▾ 🟡 Bug               │
│   ▾ 🔵 Feature           │
├─────────────────────────┤
│ [+]            [⚙️]      │
└─────────────────────────┘
```

**Behavior:**
- Badge counts on relevant items
- Collapsible sections (Favorites, Labels)
- Drag-and-drop for reordering favorites
- Context menu on right-click
- Keyboard navigation (↑↓ to navigate, Enter to select, ⌘N for new)

---

### Main Content Views

#### 1. **Inbox View**
- Filtered list of issues where `isInbox = true`
- Group by: None, Priority, Labels
- Sort by: Created Date, Updated Date, Priority, Title
- Quick actions: Assign to project, Set due date, Complete

#### 2. **Today View**
- Issues due today or overdue
- Grouped by: Overdue / Today
- Prioritized sorting
- Visual indicators for overdue items

#### 3. **Scheduled View**
- Calendar interface (month/week/day views)
- Issues displayed on due dates
- Drag-and-drop to reschedule
- Mini calendar sidebar for quick navigation

#### 4. **All Issues View**
- Master list of all open issues (not completed/canceled)
- Advanced filtering and grouping
- List and Board (Kanban) view options
- Multi-select for batch operations

#### 5. **Logbook View**
- Completed and canceled issues
- Grouped by completion date
- Filterable by date range
- Archive/restore functionality

#### 6. **Projects List View**
- Grid or list view of all projects
- Filter by status, priority, labels
- Sort by name, status, dates, priority
- Visual status indicators

---

### Project Detail Views

**Project View Tabs:**
```
┌──────────────────────────────────────────────────┐
│  [Overview] [Updates] [Issues]                   │
├──────────────────────────────────────────────────┤
│                                                  │
│  [Content area specific to selected tab]        │
│                                                  │
└──────────────────────────────────────────────────┘
```

#### **Overview Tab**
- Project metadata (name, description, dates, status, priority)
- Markdown plan editor with live preview
- Component-based editing (headings, lists, code blocks, etc.)
- Links list with add/edit/delete functionality
- Milestones summary with progress indicators

#### **Updates Tab**
- Chronological feed of project updates
- Add update form with rich text editor
- Health status selector (On Track, At Risk, Off Track)
- Visual timeline with health indicators
- Edit history tracking
- Filter by health status

#### **Issues Tab**
- List or Board view toggle
- Advanced filtering panel
- Group by: Status, Priority, Milestone, Label, Assignee (future)
- Sort by: Any field
- Inline issue creation
- Drag-and-drop between groups (Board view)

---

### Issue Detail View (Right Panel)

**Layout:**
```
┌────────────────────────┐
│ Issue Title            │
│ [Edit] [Delete]        │
├────────────────────────┤
│ Status:    [Dropdown]  │
│ Priority:  [Dropdown]  │
│ Project:   [Dropdown]  │
│ Milestone: [Dropdown]  │
│ Due Date:  [Picker]    │
│ Labels:    [Tags]      │
├────────────────────────┤
│ Description            │
│ [Rich text editor]     │
├────────────────────────┤
│ Checklists             │
│ ☐ Task 1              │
│ ☑ Task 2              │
│ [+ Add checklist]      │
├────────────────────────┤
│ Comments               │
│ [Comment thread]       │
│ [Add comment]          │
├────────────────────────┤
│ Created: Date          │
│ Updated: Date          │
└────────────────────────┘
```

**Features:**
- Inline editing for all fields
- Auto-save on change
- Keyboard shortcuts for common actions
- Expandable/collapsible sections

---

### Settings Window

**Sections:**

1. **General**
   - User name (for default team)
   - Theme preferences
   - Default views
   - Keyboard shortcuts reference

2. **Teams**
   - List of teams
   - Create/edit/delete teams
   - Set default team

3. **Statuses**
   - Organized by parent status
   - Create custom statuses
   - Reorder statuses (drag-and-drop)
   - Set default status per parent category

4. **Labels**
   - Master label list
   - Create/edit/delete labels
   - Color picker
   - Preview labels

5. **Data & Sync**
   - CloudKit sync status
   - Data export
   - Clear cache
   - Debug options

6. **Advanced**
   - Feature flags for API (future)
   - Performance settings
   - Backup/restore

---

## Keyboard Navigation & Shortcuts

### Global Shortcuts
- `⌘N`: New issue (from anywhere)
- `⌘⇧N`: New project
- `⌘K`: Command palette (quick search/actions)
- `⌘/`: Focus search
- `⌘,`: Open settings
- `⌘1-6`: Navigate sidebar sections
- `⌘←/→`: Previous/next view

### List Navigation
- `↑/↓`: Navigate items
- `Enter`: Open selected item
- `Space`: Quick preview
- `⌘⌫`: Delete selected item
- `⌘E`: Edit selected item
- `Tab`: Focus next field
- `⇧Tab`: Focus previous field

### Issue Shortcuts
- `⌘Enter`: Save and close
- `Esc`: Cancel/close
- `⌘⇧L`: Add label
- `⌘⇧M`: Set milestone
- `⌘D`: Set due date

---

## Feature Requirements

### Phase 1: Core MVP (Current Scope)

**Must Have:**
1. Complete data model with SwiftData persistence
2. CloudKit sync setup
3. Custom window architecture (Objective-C)
4. Sidebar navigation
5. All main views (Inbox, Today, Scheduled, All Issues, Logbook, Projects)
6. Project CRUD with all three tabs
7. Issue CRUD with all properties
8. Label management
9. Milestone management with progress tracking
10. Markdown plan editor
11. Settings window with team/status/label management
12. Keyboard navigation throughout
13. Light/dark mode support

**Should Have:**
1. Drag-and-drop reordering
2. Batch operations
3. Advanced filtering
4. Board view for issues
5. Calendar view for scheduled items
6. Quick actions/context menus

**Could Have:**
1. Keyboard shortcuts customization
2. Export functionality
3. Templates for projects/issues
4. Quick switcher (⌘K)

---

### Phase 2: API & Collaboration (Future)

**Planned Features:**
1. REST API for external integrations
2. Multi-user team support
3. Real-time collaboration
4. User roles and permissions
5. Activity feeds
6. @mentions and notifications
7. File attachments
8. Time tracking
9. Issue relationships (blocks, depends on)
10. Custom fields

**Architecture Considerations:**
- RESTful API design
- JWT authentication
- WebSocket for real-time updates
- Role-based access control (RBAC)
- Audit logging
- Rate limiting

---

## Technical Specifications

### Custom Window Implementation (Objective-C)

**NSWindow Subclass:**
```objc
@interface WaypointWindow : NSWindow
@property (nonatomic, assign) BOOL showsSidebar;
@property (nonatomic, assign) BOOL showsDetailsPanel;
@property (nonatomic, assign) CGFloat sidebarWidth;
@property (nonatomic, assign) CGFloat detailsPanelWidth;
- (void)toggleSidebar;
- (void)toggleDetailsPanel;
@end
```

**Features:**
- Custom title bar with team picker
- Three-column layout management
- Resizable split views with constraints
- State restoration
- Full-screen support

---

### SwiftData Configuration

**ModelContainer Setup:**
```swift
import SwiftData

@main
struct WaypointApp: App {
    let container: ModelContainer
    
    init() {
        let schema = Schema([
            Team.self,
            Project.self,
            Issue.self,
            Milestone.self,
            Label.self,
            Status.self,
            // ... other models
        ])
        
        let config = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            cloudKitDatabase: .private("iCloud.com.waypoint.app")
        )
        
        container = try! ModelContainer(
            for: schema,
            configurations: config
        )
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(container)
    }
}
```

---

### Markdown Editor Implementation

**Plan Editor Architecture:**
- Use `Markdown` framework for parsing
- Component-based rendering (each heading/list/block is a discrete SwiftUI view)
- Real-time preview
- Syntax highlighting
- Keyboard shortcuts for formatting
- Export to HTML/PDF

**Component Types:**
1. Headings (H1-H6)
2. Paragraphs
3. Lists (ordered, unordered, tasks)
4. Code blocks with syntax highlighting
5. Blockquotes
6. Horizontal rules
7. Tables
8. Links and images (preview)

---

## Data Validation Rules

### Team
- Name: Required, 1-100 characters
- One default team per installation

### Project
- Name: Required, 1-200 characters
- Description: Optional, max 5000 characters
- Start date: Must be before or equal to target date
- Target date: Optional

### Issue
- Title: Required, 1-500 characters
- Description: Optional, max 10,000 characters
- If milestone assigned, must belong to milestone's project

### Milestone
- Name: Required, 1-200 characters
- Must belong to a project
- Target date: Optional

### Label
- Name: Required, 1-50 characters, unique per team
- Color: Valid hex color code

### Status
- Name: Required, 1-50 characters, unique per parent status per team
- Parent status: Required

---

## Performance Considerations

1. **Lazy Loading**: List views paginate large datasets
2. **Indexing**: SwiftData indexes on frequently queried fields (status, priority, dates)
3. **Caching**: Cache computed properties (milestone progress)
4. **Debouncing**: Search and filter inputs debounced (300ms)
5. **Image Optimization**: Future file attachments compressed
6. **Background Sync**: CloudKit sync operates on background queue

---

## Accessibility Requirements

1. **VoiceOver**: Full support for all UI elements
2. **Keyboard Navigation**: 100% keyboard accessible
3. **Dynamic Type**: Support all system text sizes
4. **High Contrast**: Respect system accessibility settings
5. **Reduced Motion**: Disable animations when requested
6. **Color Blind Modes**: Status indicators use shapes + colors

---

## Testing Strategy

### Unit Tests
- Data model validation
- Business logic (milestone progress, filtering, sorting)
- Markdown parsing
- Status state transitions

### Integration Tests
- SwiftData CRUD operations
- CloudKit sync
- Window state management

### UI Tests
- Navigation flows
- Keyboard shortcuts
- Form validation
- Drag-and-drop

### Manual Testing
- CloudKit sync across devices
- Performance with large datasets (10k+ issues)
- Accessibility compliance
- Cross-OS version compatibility (macOS 14+)

---

## Deployment Requirements

1. **Code Signing**: Valid Apple Developer certificate
2. **Notarization**: App notarized for distribution outside Mac App Store
3. **Sandbox**: Full App Sandbox compliance for Mac App Store
4. **Entitlements**:
   - CloudKit
   - Network access (future API)
   - User-selected file access (export)
5. **Privacy**: Include usage descriptions in Info.plist

---

## Success Metrics

### Phase 1 (MVP)
- App launches without crashes
- CloudKit sync functional across devices
- All CRUD operations working
- Keyboard navigation complete
- Performance: <100ms response for all UI interactions

### Future
- API response time: <200ms p95
- Sync conflict resolution: <1% data loss
- User retention: Track via analytics (post-API launch)

---

## Timeline Estimate

**Phase 1 (MVP):**
- Week 1-2: Data model + SwiftData setup
- Week 3-4: Custom window architecture (Objective-C)
- Week 5-7: Core views (Sidebar, Issues, Projects)
- Week 8-9: Project detail tabs + Markdown editor
- Week 10-11: Settings, keyboard navigation, polish
- Week 12: Testing, bug fixes, documentation

**Total: ~3 months for single developer**

---

## Risk Assessment

| Risk | Impact | Mitigation |
|------|--------|------------|
| CloudKit sync conflicts | High | Implement robust conflict resolution, last-write-wins with merge strategies |
| Objective-C/SwiftUI bridge complexity | Medium | Start with proven examples, incremental integration |
| Markdown editor performance | Medium | Component virtualization, limit document size |
| Large dataset performance | High | Implement pagination, indexing, lazy loading early |
| Keyboard navigation coverage | Low | Test-driven development for accessibility |

---

## Open Questions for Discussion

1. **User Accounts**: Should users authenticate with Apple ID for CloudKit, or support email/password for future API?
2. **Data Limits**: Should we impose limits on projects/issues per team?
3. **Offline Mode**: How long should app function without CloudKit sync? Conflict resolution strategy?
4. **Export Formats**: Priority order for export formats (JSON, CSV, Markdown)?
5. **Theming**: Allow custom themes beyond light/dark in Phase 1?
6. **Mobile**: Plans for iOS companion app timeline?

---

## Next Steps

1. **Review & Approve**: Stakeholder review of this requirements document
2. **Design Mockups**: Create high-fidelity UI mockups in Figma/Sketch
3. **Technical Spike**: Prototype Objective-C window + SwiftUI integration
4. **Data Model Validation**: Implement SwiftData models, test CloudKit sync
5. **Sprint Planning**: Break down Phase 1 into 2-week sprints

---

## Appendix

### Glossary
- **Inbox**: Temporary holding area for issues not yet assigned to projects
- **Logbook**: Archive of completed/canceled issues
- **Parent Status**: Top-level status categories that cannot be customized
- **Custom Status**: User-defined statuses within parent categories
- **Plan**: Markdown-based project documentation with notion-like editing

### References
- Apple SwiftData Documentation
- CloudKit Sync Best Practices
- macOS Human Interface Guidelines
- AppKit Window Programming Guide

---

**Document Version**: 1.0  
**Last Updated**: November 11, 2025  
**Status**: Draft for Review
