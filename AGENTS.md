<!-- OPENSPEC:START -->
# OpenSpec Instructions

These instructions are for AI assistants working in this project.

Always open `@/openspec/AGENTS.md` when the request:
- Mentions planning or proposals (words like proposal, spec, change, plan)
- Introduces new capabilities, breaking changes, architecture shifts, or big performance/security work
- Sounds ambiguous and you need the authoritative spec before coding

Use `@/openspec/AGENTS.md` to learn:
- How to create and apply change proposals
- Spec format and conventions
- Project structure and guidelines

Keep this managed block so 'openspec update' can refresh the instructions.

<!-- OPENSPEC:END -->

# Development Commands

## Build & Type Checking
- `bun run build` - Build the project
- `bun run typecheck` - Run TypeScript type checking
- `tsc` - TypeScript compilation
- `tsgo --noEmit` - Type checking without emitting files

## Testing
No test framework currently configured.

# Code Style Guidelines

## Language & Runtime
- **Language**: JavaScript/TypeScript
- **Runtime**: Bun (package manager and execution)
- **Schema Validation**: Use Zod for all configurations

## Conventions
- **Minimalism**: Keep dependencies minimal (Void Linux principles)
- **Modular Design**: Simple, modular patterns for services and components
- **Schema-driven**: All configurations must use Zod validation
- **Plugin Architecture**: Extend functionality through plugins

## Import Style
- Use ES6 imports/exports
- Import Zod schemas for configuration validation

## Error Handling
- Use Zod for schema validation and error handling
- Validate all configuration files before use

## Naming
- Use kebab-case for file names and change IDs
- Use conventional commits: `feat(scope): description`, `fix(scope): description`
- Branch naming: `feature/`, `bugfix/`, `hotfix/`

## Git Workflow
- `main`: Stable production
- `develop`: Integration branch
- Create feature branches from `develop`
- Use conventional commits with types: feat, fix, docs, style, refactor, test, chore, config, iso