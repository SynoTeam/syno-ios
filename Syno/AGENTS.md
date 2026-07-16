# AGENTS.md

## Project Overview

Syno is an iOS-first personal AI memory app.

Syno lets users save screens, text, links, files, photos, voice notes, mail-related context, and other work memories. AI organizes those memories around people, companies, and projects so users can later retrieve them through search, summaries, and meeting briefings.

The initial product direction focuses on iOS first. Future expansion may include macOS capture workflows, but do not assume macOS is the primary target unless the user explicitly says so.

## Product Priorities

- Build local-first capture, organization, and retrieval flows.
- Prioritize user-initiated saving over automatic background collection.
- Keep original data and derived index data separate.
- Preserve useful derived metadata where appropriate, such as OCR text, summaries, people/project links, source, date, and follow-up actions.
- Treat sensitive information conservatively.
- Do not include Sensitive Vault data in default search, summaries, or briefings unless explicitly requested by the user.

## Platform And Stack

- Platform: iOS first, macOS later.
- UI: SwiftUI-first.
- Native APIs: UIKit or platform APIs are allowed when SwiftUI cannot reasonably cover a system feature.
- Architecture: MVVM + Clean Architecture.
- Storage: local-first.
- Sync: iCloud may be considered as an option.
- AI: use OCR/STT output for summaries, classification, people/company/project candidates, and follow-up action extraction.
- Search: prefer local database or local index search first; use AI answer generation only when it adds value.

## Architecture

Use MVVM + Clean Architecture.

Directory roles:

- `App`: app entry point, dependency injection, app-level setup, routing composition.
- `Presentation`: SwiftUI views, view models, screen state, feature UI.
- `Domain`: entities, use cases, repository protocols, core business rules.
- `Data`: DTOs, data sources, repository implementations, storage adapters, API clients.
- `DesignSystem`: reusable visual primitives, colors, typography, spacing, and domain-agnostic UI components.
- `Resources`: assets, localization, and app resources.

Dependency direction:

- `Presentation` may depend on `Domain`.
- `Data` may depend on `Domain`.
- `Domain` must not depend on `Presentation` or `Data`.
- `DesignSystem` must not depend on feature-specific domain concepts.

## MVVM Rules

- Keep SwiftUI views focused on layout, rendering, and forwarding user actions.
- Do not put file saving, DB access, AI calls, OCR/STT work, or business rules directly inside views.
- ViewModels manage screen state, handle user actions, and call UseCases.
- UseCases coordinate business operations.
- Repositories and services handle storage, file processing, OCR/STT, network, and AI-client dependencies.
- Root views must not contain business logic.

## Dependency Injection

- Do not create services, repositories, storage clients, or AI clients directly inside views.
- Use a DI container or SwiftUI Environment-based injection.
- Keep previews and tests possible by supporting mock implementations.
- Do not add unnecessary protocols, managers, helpers, or abstraction layers for simple one-off behavior.

## Data And Privacy

- Store original data locally or in iCloud by default.
- Do not design a flow that uploads every original file to a Syno server automatically.
- Early cloud usage should focus on lightweight metadata such as summaries, tags, links, search indexes, and follow-up actions.
- Separate originals from derived indexes and metadata.
- Minimize network dependency in MVP work.
- AI summary/classification calls may use a server or external AI API only when needed.
- Mask sensitive information or ask for user confirmation before sending sensitive content to AI services.
- Do not automatically save sensitive apps, password managers, OTP screens, payment screens, or similar private surfaces.

## MVP Boundaries

Do not implement these unless the user explicitly asks:

- Always-on screen recording.
- Automatic collection from every app or screen.
- KakaoTalk local DB parsing.
- iMessage automatic collection.
- Automatic collection from all messengers.
- Automatic full-file upload to a Syno server.

## MVP Navigation Flow

Use this flow as the product IA baseline for the current MVP work.

Primary screens:

- `Splash`: first launch surface. On app start, check local app state and route into `Home`.
- `Home` / `Contact People`: primary hub for people and contact-centered memory. This is the default post-splash screen.
- `Notes`: note and saved memory list/detail area.
- `Room`: conversation or person/project-focused room.
- `Global Search`: cross-app search over people, rooms, notes, and attachments.
- `Add Contact`: contact creation flow.
- `Settings`: app configuration and account/privacy controls.
- `Room Archive`: optional room archive and restore flow. Do not prioritize this unless explicitly requested.

Navigation rules:

- `Home` owns the main contact-oriented experience and should remain the central return point.
- The initial tab structure should start from `Home` and `Notes`. Add other tabs only when their screen behavior is clear.
- Search should be treated as a global action that can be entered from `Home`, `Notes`, `Room`, and `Settings`.
- Settings should be reachable from the main app shell, not buried inside a feature-specific view.
- Selecting a person from `Home` should navigate to `Room`.
- Creating a contact from `Add Contact` should prefer moving the user into the newly created `Room` after save.
- Cancelling `Add Contact` should return to `Home`.
- Back/cancel behavior from `Room`, `Notes`, `Global Search`, and `Settings` should preserve the user's expected previous context.
- Selecting a person, note, room, or attachment result from `Global Search` should navigate to the relevant destination.
- `Room Archive` is entered from `Room` through a secondary action such as more/archive, and can open or restore archived rooms.

Current branch scope:

- Implement the initial `TabView` app shell.
- Implement the initial `ContactView` / `Home` experience.
- Keep non-essential flows as placeholders when needed, especially search, settings, add contact, and archive.
- Keep routing simple until the first real screens establish concrete state and data requirements.

## Branch And Commit Rules

Branch naming:

- `main`: stable, releasable version.
- `develop`: integration branch.
- `feature/*`: feature development.
- `fix/*`: bug fixes.
- `refactor/*`: structure or internal improvements.
- `docs/*`: documentation changes.

Commit message examples:

- `feat: add quick capture flow`
- `fix: resolve memory card deletion issue`
- `refactor: split capture view model responsibilities`
- `docs: add codex guide`
- `chore: clean project settings`

## Codex Working Rules

- Respond in Korean by default.
- Keep code, type names, file names, function names, and commit messages in English.
- Before making substantial changes, explain the reason, expected impact, example shape, and verification plan.
- If the user asks directly to change, fix, add, create, move, or refactor something, proceed with implementation.
- If the user is asking for advice, design discussion, or comparison, do not edit files until they explicitly ask for changes.
- Read the relevant existing files before editing.
- Keep edits scoped to the user's request.
- Do not rewrite the whole architecture unless explicitly requested.
- Do not add third-party dependencies without asking first.
- Distinguish errors from warnings when reporting command results.

## Verification

After structural or Swift changes, run a build when feasible:

```bash
xcodebuild -project Syno.xcodeproj -scheme Syno -configuration Debug -sdk iphonesimulator -derivedDataPath /tmp/SynoDerivedData CODE_SIGNING_ALLOWED=NO build
```

If the sandbox blocks Xcode, Swift macros, CoreSimulator, or signing-related access, report that clearly and retry with scoped approval when build verification is important.
