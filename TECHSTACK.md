# 🏗️ EchoWave Technical Stack Overview

This document provides an in-depth look at **EchoWave's** technology stack across Web, Mobile, and Backend layers. If you plan to build or extend a similar product, this serves as a blueprint of the exact tools, libraries, and architectural decisions in use today (✱ versions reflect the current `package.json` / `Podfile.lock` / `gradle` manifests at commit-time and may advance over time).

---

## 1. Web (Next.js App)

| Layer | Tech / Library | Version | Purpose |
|-------|----------------|---------|---------|
| Runtime | **Node.js** (LTS) | 20.x | Executes the Next.js server (dev / build) |
| Framework | **Next.js** | **15.3.4** | React meta-framework, routing, server actions, Turbopack bundler |
| Language | **TypeScript** | **5.x** | Static typing across all TS/TSX files |
| UI Library | **React** | **19** | Component model / hooks |
| Styling | **Tailwind CSS** | **4.x** | Utility-first styling with `globals.css`, JIT build via Tailwind v4 + PostCSS |
| Icons | **Lucide-React** | 0.522.0 | Feather-style icon components |
| Charts | `recharts` | 3.0.2 | Data-viz for insights dashboards |
| Drag-and-Drop | `@hello-pangea/dnd` | latest | Kanban board interactions |
| QR Generation | `qrcode`, `react-qr-code` | 1.5.x / 2.0.x | Shareable survey QR images |
| Search | `fuse.js` | 7.1.0 | Fuzzy question-bank search |
| YAML | `js-yaml` | 4.1.0 | Parsing survey templates (`/templates`) |
| Date Utils | `date-fns` | 4.1.0 | Formatting & calculations |
| State / Data | **Supabase JS** | 2.50.2 | Database & Auth client (SSR wrapper `@supabase/ssr` 0.6.1) |
| AI | **OpenAI SDK** | 4.73.1 | AI suggestions / insights endpoints |
| Linting | **ESLint** | 9.x | Code quality (`eslint-config-next`) |
| Bundler | **Turbopack** (Next default) | – | Rust-based incremental bundling |
| CSS Tooling | **PostCSS** | Tailwind plugin | Transforms Tailwind utilities |

### Key Web Directories

```text
web/
  ├─ src/
  │   ├─ app/               # Next.js app-router pages & API routes
  │   ├─ components/        # Reusable UI—SurveysKanbanBoard, AuthModal, etc.
  │   ├─ lib/               # Supabase client, auth helpers, webhook utils
  │   ├─ templates/         # YAML survey templates (loaded at runtime)
  │   ├─ types/             # Shared TS interfaces (Survey, User, …)
  │   └─ utils/             # Non-component helpers (templateLoader)
  ├─ public/                # Static assets & SVG icons
  └─ eslint.config.mjs      # Central linter rules
```

---

## 2. Backend (Supabase-as-a-Service)

| Area | Detail |
|------|--------|
| **Database** | Postgres 15 (managed by Supabase) |
| **Schema Management** | SQL migrations in `supabase/migrations/*.sql` run via Supabase CLI / GitHub CI |
| **Auth** | Supabase Auth (JWT) – email+password & 3rd party (can expand) |
| **Row-Level Security** | Enabled on every table, policies in migrations |
| **Edge Functions** | (Deno) optional – e.g., `/functions/...`, invoked by webhooks |
| **Storage** | Supabase Storage buckets (not yet used for surveys) |
| **Realtime** | Supabase Realtime for live updates (optional) |
| **AI-Assisted SQL** | Custom PL/pgSQL functions like `survey_accepts_responses`, `complete_survey` |
| **Scheduled Jobs** | Cron hitting RPC `scheduled_survey_maintenance()` to auto-expire surveys |

### Migration Highlights
- **20241227_000000_initial_schema.sql** – core tables (`surveys`, `responses`, etc.)
- **…_add_completed_status.sql** – `status = 'completed'`, `expiration_date`
- **…_ai_insights_system.sql** – caching AI-generated insights
- **…_webhooks_and_integrations.sql** – outbound webhooks infra

---

## 3. Mobile (Capacitor + SwiftUI / Android Kotlin)

Although optional for web-only deployments, EchoWave ships first-party mobile apps.

| Layer | iOS | Android |
|-------|-----|---------|
| Wrapper | **Capacitor 7.4** | Same |
| Native UI | **SwiftUI** (`ios/EchoWave`) | Jetpack Compose (future) |
| Shared Logic | Re-uses Supabase JS via Capacitor's WebView bridge |

The mobile app consumes the exact same REST/Realtime endpoints exposed via Next.js or directly via Supabase, enabling code reuse of core survey logic.

---

## 4. Tooling & Dev Experience

- **Monorepo Structure** – Top-level repo with `web/`, `ios/`, `android/`, `supabase/`
- **VS Code / Cursor** – Recommended editor (ESLint + Tailwind CSS IntelliSense)
- **Next.js Dev** – `npm run dev` (inside `web/`) spins up Turbopack & hot reloads
- **Supabase CLI** – `supabase start` for local Postgres or `supabase db push` to deploy migrations
- **Testing** – Jest / React Testing Library (planned), Supabase SQL tests (pgTAP)
- **CI/CD** – GitHub Actions: lint → test → deploy (Vercel) → run `supabase db push`

---

## 5. Architectural Principles

1. **Serverless-first** – Rely on Supabase for auth, DB, edge functions → minimal backend maintenance.
2. **Typed End-to-End** – Shared TypeScript interfaces between DB types (`supabase.ts` generated types) and React components to eliminate runtime mismatches.
3. **Utility-First UI** – Tailwind CSS ensures rapid styling with consistent design tokens.
4. **Feature-Flag-Driven** – New capabilities (AI insights, webhooks, conditional logic) live behind feature flags and can be toggled per environment.
5. **Offline-Friendly** – Mobile Capacitor app caches surveys locally (room for PWA offline caching).

---

## 6. How to Re-use This Stack

1. **Fork / Clone** the repo
2. Install Node / npm, then `cd web && npm install`
3. Create a new Supabase project → copy `supabase/config.toml` → `supabase link --project-ref <id>`
4. Run `supabase db push` to apply migrations
5. Set environment vars (SUPABASE_URL, SUPABASE_ANON_KEY, OPENAI_API_KEY) in `.env.local`
6. `npm run dev` inside `web/` → launch at `http://localhost:3000`
7. (Optional) `npx capacitor add ios/android` to scaffold mobile shells

---

## 7. Future Considerations / Alternatives

| Concern | Current Choice | Alternative Thoughts |
|---------|----------------|----------------------|
| Bundler | Turbopack | Vite, Webpack 5 |
| Auth Flows | Supabase Auth | Clerk, Auth0, custom JWT server |
| Drag-and-Drop | `@hello-pangea/dnd` | `dnd-kit` (lighter) |
| Data Layer | Supabase RPC + Realtime | GraphQL (Hasura, PostGraphile) |
| Styling | Tailwind CSS | Chakra UI, MUI, Vanilla Extract |

---

## 8. Credits

- **╰┈➤** Built with 💚 by the EchoWave team & OSS community.
- **Icons** by Lucide (MIT).
- **Supabase** for the generous open-source platform.

> **Happy building!** Re-use, fork, and extend this stack to accelerate your next product. 