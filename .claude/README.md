# .claude Directory

This directory contains documentation and guidelines for AI assistants (like Claude) working on the Waypoint project.

## Files

### `instructions.md`
Main instructions for AI assistants. Read this first when starting work on the project.

**Key content:**
- Critical rules for the project
- When to use specific guides
- Project-specific conventions

### `swiftdata-migration-guide.md`
Comprehensive guide for handling SwiftData schema migrations.

**When to use:**
- Before making ANY changes to `@Model` classes
- When adding/removing properties from models
- When changing relationships between models
- When adding new model classes

**This is mandatory reading before touching any model files!**

---

## For AI Assistants

1. **Start here**: Read `instructions.md` when beginning work
2. **Before model changes**: Read `swiftdata-migration-guide.md` completely
3. **Follow the guides**: They contain hard-earned lessons from debugging migration issues

## For Developers

These guides are useful for:
- Understanding the project's migration strategy
- Learning SwiftData migration best practices
- Onboarding new team members
- Reference when schema changes are needed

---

**Remember**: The migration guide exists because we encountered every error in the book. Follow it closely to avoid data loss and migration crashes!
