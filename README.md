# Waypoint

A modern, keyboard-first project and task management application for macOS built with SwiftUI and SwiftData.

## Features

### 🗂️ Flexible Organization

- **Projects & Issues**: Organize work into projects with detailed issue tracking
- **Spaces**: Group projects into logical workspaces (Engineering, Design, etc.)
- **Multiple Views**:
  - **Inbox** - Capture and triage new tasks
  - **Today** - Focus on what's due today
  - **Upcoming** - Plan ahead with upcoming tasks
  - **Completed** - Review finished work
  - **Projects** - Manage all projects in one place

### 📊 Powerful Visualization

- **Board View**: Kanban-style columns for visual workflow management
- **List View**: Dense list view for power users
- **Dynamic Grouping**: Group by status, priority, project, due date, or tags
- **Smart Sorting**: Sort by due date, priority, status, created date, or title
- **Color-Coded**: Visual indicators for status and priority

### ⌨️ Keyboard-First Design

- **Navigation Shortcuts**:
  - `⌘I` - Inbox
  - `⌘T` - Today
  - `⌘U` - Upcoming
  - `⌘D` - Completed
  - `⌘P` - Projects
- **View Mode Shortcuts**:
  - `⌘⇧1` - List View
  - `⌘⇧2` - Board View
- **Actions**:
  - `⌘⇧N` - Create New Issue
  - `Arrow Keys` - Navigate between items
  - `Enter` - Open/Activate selected item
  - `Esc` - Clear selection

### 🎯 Rich Task Management

- **Status Tracking**: To Do, In Progress, Review, Done
- **Priority Levels**: Urgent, High, Medium, Low
- **Due Dates**: Set and track deadlines
- **Tags**: Organize with custom tags
- **Descriptions**: Add detailed notes to issues
- **Projects**: Associate issues with projects

### 🎨 Customization

- **Project Icons**: Choose from 24+ SF Symbols
- **Color Themes**: 12 preset colors for projects and spaces
- **View Settings**: Customize grouping and sorting per view
- **Control Display Modes**: Icon only, Icon & Text, or Text only

### 💾 Modern Architecture

- **SwiftData**: Automatic persistence and iCloud sync support
- **Schema Migration**: Seamless database upgrades
- **Reactive UI**: Real-time updates across all views
- **Type-Safe**: Full Swift type safety with compile-time checks

## Requirements

- macOS 14.0 (Sonoma) or later
- Xcode 15.0 or later

## Installation

1. Clone the repository:
   ```bash
   git clone https://github.com/yourusername/Waypoint.git
   cd Waypoint
   ```

2. Open the project in Xcode:
   ```bash
   open Waypoint.xcodeproj
   ```

3. Build and run:
   - Select your target device (Mac)
   - Press `⌘R` or click the Run button

## Project Structure

```
Waypoint/
├── Models/               # SwiftData models
│   ├── Issue.swift      # Issue/task model
│   ├── Project.swift    # Project model
│   ├── Space.swift      # Workspace model
│   ├── Tag.swift        # Tag model
│   └── ViewSettings.swift # User preferences
├── Views/               # SwiftUI views
│   ├── InboxView.swift
│   ├── TodayView.swift
│   ├── ProjectsListView.swift
│   ├── GenericIssueViews.swift
│   ├── GenericProjectViews.swift
│   └── ...
├── Helpers/             # Utility functions
│   ├── IssueHelpers.swift
│   ├── ProjectGrouper.swift
│   └── ...
└── Stores/              # State management
    ├── ProjectStore.swift
    └── ViewSettingsStore.swift
```

## Technology Stack

- **SwiftUI** - Declarative UI framework
- **SwiftData** - Apple's persistence framework
- **Observation Framework** - Modern reactive state management
- **SF Symbols** - System icon library
- **Combine** - Reactive programming

## Key Concepts

### Issues
Individual tasks or work items with:
- Title and description
- Status (To Do, In Progress, Review, Done)
- Priority (Urgent, High, Medium, Low)
- Optional due date
- Tags and project association

### Projects
Collections of related issues with:
- Custom icon and color
- Status tracking
- Space association
- Issue count tracking

### Spaces
High-level organizational units for grouping projects:
- Custom icon and color
- Description
- Project grouping

### View Settings
Per-view customization:
- View mode (List or Board)
- Grouping preferences
- Sorting preferences
- Saved automatically via UserDefaults

## Database Schema

Waypoint uses SwiftData with automatic schema migration:

- **Schema V1**: Initial schema
- **Schema V2**: Added Project status field
- **Migration**: Automatic migration with data preservation

## Keyboard Navigation

Full keyboard support throughout the app:

- **Arrow Keys**: Navigate between items in board/list views
- **Tab/Shift+Tab**: Navigate form fields
- **Enter**: Activate focused item
- **Escape**: Clear focus/close dialogs
- **Number Keys (1-9)**: Quick selection in grids

## Contributing

This is a personal project, but suggestions and feedback are welcome! Feel free to:

- Report bugs via Issues
- Suggest features via Discussions
- Submit pull requests

## License

Copyright © 2025. All rights reserved.

## Acknowledgments

Built with ❤️ using Apple's latest frameworks and design patterns.

---

**Note**: This project is under active development. Features and APIs may change.
