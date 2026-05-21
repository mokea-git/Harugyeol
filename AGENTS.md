# Repository Guidelines

## Project Structure & Module Organization
This repository is a small monorepo with two active apps:
- `haru_app/`: Flutter client (`lib/core` for shared infra, `lib/features` for feature modules, `test/` for widget tests).
- `harugyeol-server/`: Fastify + TypeScript API (`src/routes`, `src/middleware`, `src/lib`).
- `docs/`: product and architecture context (`docs/harugyeol_context.md`).
- `assets/`: shared design assets.

Keep feature-specific code inside each app’s feature folder; avoid cross-app imports.

## Build, Test, and Development Commands
Run commands from each subproject directory.

Client (`haru_app`):
- `flutter pub get`: install dependencies.
- `flutter run`: launch app in debug.
- `flutter analyze`: static analysis with `flutter_lints`.
- `flutter test`: run widget/unit tests.

Server (`harugyeol-server`):
- `npm ci`: install dependencies from lockfile.
- `npm run dev`: run Fastify with `ts-node-dev`.
- `npm run build`: compile TypeScript to `dist/`.
- `npm run start`: run compiled server.

## Coding Style & Naming Conventions
- Dart: follow `flutter_lints`; 2-space indentation; `snake_case.dart` filenames; `PascalCase` widget/class names.
- TypeScript: strict mode enabled; 2-space indentation; `camelCase` variables/functions; `PascalCase` types; keep route handlers thin and move shared logic to `src/lib`.
- Prefer small, single-purpose modules (for example, one route domain per file in `src/routes`).
- Authentication policy: use Supabase only for OAuth sign-in/token verification. Do not add product/user data writes to Supabase DB.
- Data policy: store user profile fields (image, name, email) in server-side SQLite managed by `harugyeol-server`.

## Testing Guidelines
- Flutter uses `flutter_test`; place tests under `haru_app/test` with `*_test.dart` naming.
- Add or update tests when changing UI state, routing, or API integration behavior.
- Server currently has no formal test suite; at minimum, validate changes via `npm run build`, then smoke-test endpoints (`/health`, modified routes).

## Commit & Pull Request Guidelines
Recent history follows Conventional Commits (`feat:`, `fix:`, `chore:`), often with Korean summaries. Keep this format.

PRs should include:
- concise change summary and scope,
- linked issue/task,
- test evidence (command output or screenshots for UI),
- notes for env/config changes (`.env`, Supabase OAuth keys, SQLite path/migrations, API keys).

## Security & Configuration Tips
- Never commit real secrets; use `harugyeol-server/.env.example` as the template.
- Use Supabase credentials for OAuth only; avoid using Supabase DB/service-role for application data.
- Keep OAuth and API keys server-only; do not expose them to Flutter client code.
