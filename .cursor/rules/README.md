# Cursor Rules for LookML Project

This directory contains Cursor AI rules that help maintain code quality and consistency across the LookML project.

## Rules Overview

### 1. `developer-preferences.mdc` ⚡ (Always Applied)
**Purpose**: Communication style and project scope guardrails
- Detailed explanations for new developers (explain WHY, WHAT, HOW)
- Professional documentation standards (no tool references)
- Project scope limitations (this repo and Looker project only)
- Educational approach with examples and glossary
- Safety-first approach to changes
- Read-only database reminders

### 2. `lookml-best-practices.mdc` ⚡ (Always Applied)
**Purpose**: Core principles and conventions for the entire project
- Project identity and location
- Project structure overview
- Naming conventions (snake_case, is_ prefix for booleans)
- Group label organization (numbered groups)
- Read-only database access reminders
- Refinement pattern usage

### 3. `lookml-view-standards.mdc` 📊
**Applies to**: `*.view.lkml` files
- File organization structure (parameters → derived_table → dimensions → measures)
- Dimension standards (primary keys, group labels, types)
- Measure standards (formatting, filtered measures, ratio calculations)
- CASE statement best practices
- Hidden dimension guidelines

### 4. `lookml-model-standards.mdc` 🏗️
**Applies to**: `*.model.lkml` and `*.ref.lkml` files
- Model file structure (connection, includes, explores)
- Refinement file patterns using `+` prefix
- Include statement best practices
- When and how to use refinements for extending views

### 5. `lookml-sql-patterns.mdc` 🔍
**Applies to**: `*.view.lkml` files
- Field reference syntax (`${TABLE}`, `${field}`)
- NULL handling and division by zero prevention
- String normalization with `upperUTF8(trim())`
- Derived table patterns with parameters
- JSON extraction patterns
- Performance considerations

### 6. `clickhouse-patterns.mdc` ⚙️
**Applies to**: `*.view.lkml` files
- ClickHouse-specific functions (`JSONExtractString`, `upperUTF8`)
- Query optimization for ClickHouse
- Data type considerations
- Date filtering with parameters
- Performance tips for column-oriented database

### 7. `documentation-standards.mdc` 📝
**Applies to**: `*.md` files
- Documentation directory structure
- Code review checklist and format (with timestamp: YYYY-MM-DD_HH_MM_SS)
- Review document templates
- Markdown best practices

### 8. `git-workflow.mdc` 🔄 (Always Applied)
**Purpose**: Version control and change management
- Branch naming conventions
- Commit message guidelines (professional, tool-agnostic)
- Pre-commit checklist for LookML files
- File change review process
- No references to automation tools in commits

## How Rules Work

### Always Applied
Rules marked with ⚡ are automatically included in every AI interaction:
- `developer-preferences.mdc` (NEW - explains detailed AI behavior)
- `lookml-best-practices.mdc`
- `git-workflow.mdc`

### File-Specific Rules
Rules with glob patterns are automatically applied when working with matching files:
- Working on a view file? → `lookml-view-standards.mdc`, `lookml-sql-patterns.mdc`, and `clickhouse-patterns.mdc` are loaded
- Working on a model file? → `lookml-model-standards.mdc` is loaded
- Writing documentation? → `documentation-standards.mdc` is loaded

### Manual Application
Rules without `alwaysApply: true` or `globs` can be manually referenced when needed.

## Usage Tips

1. **For New Views**: Reference `lookml-view-standards.mdc` to ensure proper structure
2. **For SQL Issues**: Check `lookml-sql-patterns.mdc` and `clickhouse-patterns.mdc`
3. **For Code Reviews**: Follow the checklist in `documentation-standards.mdc`
4. **For Extends/Refinements**: See examples in `lookml-model-standards.mdc`

## Maintenance

These rules should be updated when:
- New patterns emerge in the codebase
- Team standards change
- New ClickHouse functions are used
- New documentation requirements are added

## Related Files

- [content_integration_search.view.lkml](mdc:views/content_integration_search.view.lkml) - Main view example
- [content_integration_search.ref.lkml](mdc:models/content_integration_search.ref.lkml) - Refinement example
- [code_review.md](mdc:docs/commands/code_review.md) - Code review workflow

