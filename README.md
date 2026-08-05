# Shop Admin — Local-Only E-Commerce App + Admin Dashboard

A single Flutter application containing **both** a customer shop and an admin
dashboard, 100% offline. All data lives in a local SQLite database — there is
no backend, no Firebase, no Supabase. The customer and admin share the domain
and data layers and are separated only by role-based navigation behind a local
PIN gate.

Built as a portfolio piece demonstrating production-grade **Clean
Architecture, BLoC/Cubit state management, and a serious local data layer**:
type-safe reactive persistence (drift), a `Result<T>` error boundary, sealed
state machines per feature, and a fully tested flow from UI to SQLite and back.

---

## Features

### Customer shop
- **Catalog** — categories, live search, sort (newest / name / price asc-desc),
  product detail with stock badges (out of stock / low stock), discount pricing.
- **Cart** — add / remove / quantity steppers, persisted in drift, live totals
  that react to admin price and stock edits, stock-cap enforcement, a live
  item-count badge on the shell.
- **Checkout** — validated shipping form, **Cash on Delivery only** (a mock
  payment decision: real gateways need server-held secrets, never client-side),
  inline success view with the order number.
- **Orders** — history with status chips, and a detail screen with snapshot
  items, totals, and the full **status timeline**.
- **Profile** — local customer profile (no real auth) that pre-fills checkout;
  reactive across writers (saving from checkout updates the profile tab live).

### Admin dashboard
- **PIN gate** — mock auth: a salted SHA-256 hash of a 4–6 digit PIN, stored
  on-device, guarding every `/admin/...` route via a router redirect. The
  single on-screen entry lives on the customer **Profile** tab.
- **Overview** — derived revenue, order counts by status, recent orders, and
  low-stock alerts, charted with `fl_chart`. No extra queries: every metric is
  recomputed in memory from the live watch streams.
- **Products** — full CRUD: name, price, discount, stock, category, and images
  picked from the gallery and stored in the app documents directory.
- **Categories** — CRUD with referential-integrity protection (a category with
  products cannot be deleted).
- **Orders** — filter by status, order detail, and status transitions
  (`pending → confirmed → shipped → delivered`, or cancel) enforced by the
  domain state machine, with a live-updating timeline.
- **Seed data** — a full demo catalog and six orders with complete status
  histories, so the app is demoable on first launch.

### Cross-cutting
- Explicit **Loading / Success / Error / Empty** states in every feature.
- **`Result<T>`** at every repository boundary — errors are caught in the data
  layer, never in widgets.
- Material 3 **light/dark theme** and constraint-based responsive layout
  (a `LayoutBuilder` picks `NavigationRail` vs `NavigationBar` — no device-type
  checks).

---

## Architecture

Feature-first **Clean Architecture** — dependencies point inward, and each
feature is a slice across the layers:

```
lib/
├── core/          # entities, money utils, Result<T>/errors, DI composition root
├── domain/        # repository interfaces, use cases, business rules (pure Dart)
├── data/          # drift database (tables, DAOs, migrations), mappers, repositories
└── presentation/  # Cubits (sealed states), screens, shared widgets, shells, router
```

**Data flow** — every screen is reactive end-to-end:

```
Widget → Cubit → UseCase → Repository → drift DAO → SQLite
                                  └────────── watch stream ──┐
Widget ←── BlocBuilder ←── Cubit state ←─────────────────────┘
```

Writes funnel through use cases (the business rules live here); reads are
reactive watch streams that re-emit the query on any change, so an admin's
edit reflects on the customer's screen on the next emission.

### Key decisions (all documented in code)
| Decision | Choice | Why |
| --- | --- | --- |
| Money | **Integer cents** everywhere | No floating-point rounding at boundaries |
| State | **Cubit + sealed `Equatable` states** per feature | Compiler-checked exhaustive state handling |
| Errors | **`Result<T>` at repository boundaries** | No silent failures; caught once, in the data layer |
| Business rules | **Thin use cases** (Decision A) | Rules live in the domain; repositories stay storage gates |
| Orders | **Snapshot aggregates** (items, totals, status history) | History survives later product edits/deletions (FK `SET NULL`) |
| Admin PIN | **Salted SHA-256 hash only** | Never the raw PIN on disk |
| Local DB | **drift (SQLite)** | Type-safe relational data with reactive streams + migrations |
| DI | **GetIt, manual registration** | No codegen for wiring |
| Routing | **GoRouter `StatefulShellRoute`** + admin redirect guard | Two shells, one router, a real route guard |

---

## Getting started

Requirements: Flutter 3.x / Dart 3.x (the app targets **Android** and
**Windows desktop**).

```bash
flutter pub get
flutter run            # pick a device (Android emulator/device or Windows desktop)
```

### First-run demo walkthrough

1. The app opens on the shop catalog — seeded products and categories are
   already there.
2. Add something to the cart → the shell badge updates live → **Checkout** →
   fill the shipping form → place the order. The order appears in **Orders**
   with its timeline, and the shipping details land in **Profile**.
3. Open the admin side — go to **Profile** and tap **Admin dashboard** (the
   one on-screen entry; every `/admin/...` route is otherwise locked): the
   first visit asks you to **set a 4–6 digit PIN**; afterwards it asks for
   the PIN.
4. In the admin **Overview**, revenue and the orders-by-status chart are
   seeded with demo data. Open **Orders**, pick the pending order
   (`ORD-000004`), and walk it through `confirmed → shipped → delivered` —
   the timeline, chip, and buttons refresh live.
5. Edit a product's stock below 5 in **Products** → it appears under the
   dashboard's **Low stock** alerts immediately (reactive streams again).

---

## Testing

```bash
flutter test
```

The suite covers every layer with the same stack the app ships with:

- **Data** — repositories and DAOs against an **in-memory drift database**
  (real queries, real migrations, no mocks).
- **Domain** — use cases with `mocktail` (validation, stock caps, the
  `canTransitionTo` state machine, profile best-effort saves).
- **Presentation** — Cubits with `bloc_test`, and **end-to-end widget flows**
  through the real DI graph + router against the in-memory database (seeded
  catalog → cart → checkout → orders → admin gate → dashboard → status
  transitions → profile).

219 tests, all green; `flutter analyze` is clean.

---

## Out of scope (deliberate)

Real payments, real authentication, any API/sync, push notifications,
localization, and native platform code. The app is local-only by design —
a standalone demonstration of what Flutter + Clean Architecture can do without
a server.
