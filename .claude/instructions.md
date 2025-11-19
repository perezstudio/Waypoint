# AI Assistant Instructions for Waypoint

This file contains important guidelines for AI assistants working on the Waypoint project.

## Critical Rules

### SwiftData Schema Migrations

**⚠️ MANDATORY**: Before making ANY changes to `@Model` classes, you MUST:

1. **Read the migration guide**: `.claude/swiftdata-migration-guide.md`
2. **Follow the step-by-step process** outlined in that guide
3. **Never modify model files directly** without proper versioning

#### Files That Require Migration:

If you're modifying ANY of these files, a schema migration is required:
- `Models/Project.swift`
- `Models/Issue.swift`
- `Models/ContentBlock.swift`
- `Models/Tag.swift`
- `Models/Space.swift`
- `Models/Resource.swift`
- `Models/ProjectUpdate.swift`
- `Models/Milestone.swift`
- `Models/ProjectIssuesViewSettings.swift`

Or if you're adding a new `@Model` class.

#### The Migration Pattern

**Golden Rule**: Latest schema = current models. Historical schemas = frozen versioned copies.

```
V1 (current)  → Uses: Project, Issue, Space (no suffix)
      ↓
When adding V2:
      ↓
V1 (frozen)   → Uses: ProjectV1, IssueV1, SpaceV1 (V1 suffix added)
      ↓
V2 (current)  → Uses: Project, Issue, Space (no suffix)
```

#### Quick Checklist

Before making model changes:
- [ ] Read `.claude/swiftdata-migration-guide.md`
- [ ] Freeze current schema with versioned models
- [ ] Create new schema using current models
- [ ] Make changes in `Models/` directory
- [ ] Update migration plan
- [ ] Build and test
- [ ] Update schema history in the guide

#### Common Errors to Avoid

❌ **NEVER** share model classes between schemas
❌ **NEVER** modify historical schema definitions
❌ **NEVER** skip versioning all models
❌ **NEVER** make model changes without following the migration guide

---

## Project-Specific Guidelines

### Code Style

- Use tabs for indentation (project convention)
- Follow existing naming conventions
- Keep models in `Models/` directory
- Keep views in `Views/` directory

### Testing

- Always build after making changes: `xcodebuild -scheme Waypoint -destination 'platform=macOS' build`
- Test with real data when possible
- Verify app functionality after migrations

### Documentation

- Update relevant documentation when making significant changes
- Keep migration history up to date in `.claude/swiftdata-migration-guide.md`
- Document breaking changes

---

## Resources

- **Migration Guide**: `.claude/swiftdata-migration-guide.md` - Read this before ANY model changes
- **Project Repository**: Current directory
- **Models**: `Models/` directory
- **Views**: `Views/` directory

---

## Summary

**Most Important Rule**: Any time you touch a `@Model` class, read and follow `.claude/swiftdata-migration-guide.md` completely. No exceptions.
