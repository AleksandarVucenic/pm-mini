# Project Management System — API

A REST API for managing projects and tasks across multiple teams, built with Ruby on Rails 8 (API-only mode).

Built as a take-home assignment for Productive.

---

## Table of Contents

- [Tech Stack](#tech-stack)
- [Setup](#setup)
- [Authentication](#authentication)
- [Rate limiting](#rate-limiting)
- [Response format](#response-format)
- [API Reference](#api-reference)
- [Authorization rules](#authorization-rules)
- [Business rule: max 5 open tasks](#business-rule-max-5-open-tasks-per-assignee-per-project)
- [Search & filtering](#search--filtering)
- [Performance notes](#performance-notes)
- [Postman collection](#postman-collection)
- [Testing](#testing)
- [Architecture notes](#architecture-notes)
- [Known limitations](#known-limitations)

---

## Tech Stack

- **Ruby** 3.4.10
- **Rails** 8.1 (API-only)
- **MySQL** (via `mysql2`)
- **Devise** + **devise-jwt** — token-based authentication with revocation support
- **Pundit** — authorization policies
- **jsonapi-serializer** — JSON:API-formatted responses
- **Pagy** (v43) — pagination
- **RSpec** + **FactoryBot** — testing

---

## Setup

```bash
bundle install
rails db:create
rails db:migrate
rails db:seed
rails server
```

The server runs on `http://localhost:3000` by default.

### Seeded data

`db/seeds.rb` creates 7 users and a small, deliberately-designed scenario so authorization rules are visible immediately without any manual setup:

| User | Email | Role on Enterprise Refit (project 1) | Role on Voyager Refit (project 2) |
|---|---|---|---|
| James Kirk | `kirk@enterprise.com` | **PM** | assignee (1 open task) |
| Spock | `spock@enterprise.com` | assignee (1 open, 1 closed task) | no relation |
| Montgomery Scott | `scotty@enterprise.com` | no relation | **PM** |
| Nyota Uhura | `uhura@enterprise.com` | no relation | assignee (1 open task) |
| Leonard McCoy | `mccoy@enterprise.com` | assignee (1 open task) | no relation |
| Hikaru Sulu | `sulu@enterprise.com` | no relation | no relation |
| Pavel Chekov | `chekov@enterprise.com` | no relation | no relation |

All passwords: `starfleet123`

Kirk is intentionally both a PM (on Enterprise Refit) and a plain assignee (on Voyager Refit) — this demonstrates that a user's role is derived per-project, not a fixed global attribute.

---

## Authentication

This API uses **JWT tokens** (via Devise + devise-jwt) rather than session cookies — a stateless, token-based mechanism is what's appropriate for API consumption, since there's no browser to manage a session cookie. It works identically from Postman, a mobile client, or another backend service.

### Log in

```
POST /api/v1/login
Content-Type: application/json
```

**Request body:**
```json
{ "user": { "email": "kirk@enterprise.com", "password": "starfleet123" } }
```

**Success response — `200 OK`.** The token is returned in the **`Authorization` response header** (standard `devise-jwt` behavior), not the JSON body:

```
Authorization: Bearer eyJhbGciOiJIUzI1NiJ9.eyJzdWIiOiIxIiwic2NwIjoi...
```

```json
{
  "data": {
    "id": "1",
    "type": "user",
    "attributes": { "name": "James Kirk", "email": "kirk@enterprise.com" }
  }
}
```

**Failure response — `401 Unauthorized`** (wrong password or non-existent email — deliberately identical in both cases, to avoid leaking which emails are registered):

```json
{ "errors": [{ "status": "401", "title": "Unauthorized", "detail": "Invalid Email or password." }] }
```

Copy the token from the response header and send it on every subsequent request:

```
Authorization: Bearer <token>
```

### Log out

```
DELETE /api/v1/logout
Authorization: Bearer <token>
```

**Success — `200 OK`.** This **revokes** the token via a denylist, so it can no longer be used even though it hasn't expired yet — unlike a naive JWT setup where "logout" is purely client-side and a stolen token would keep working until it expires on its own.

**No token provided — `401 Unauthorized`.**

---

## Rate limiting

Login (`POST /api/v1/login`) is rate-limited to **5 requests per 3 minutes per IP + email combination**. Exceeding the limit returns `429 Too Many Requests` with a JSON:API error body.

Rate limiting uses Rails 8's built-in `rate_limit` macro, which stores counters in `Rails.cache`. The cache backend differs by environment:

| Environment | Cache store | Behaviour |
|---|---|---|
| `development` | `:memory_store` | Per-process, resets on restart — fine for local dev |
| `test` | `:memory_store` | Per-process, isolated between test runs |
| `production` | `:solid_cache_store` | DB-backed (`pm_mini_production_cache`), shared across all Puma workers — counters are global and survive restarts |

**Production setup note:** the counters live in the separate `pm_mini_production_cache` database (configured in `config/database.yml`). A single `bin/rails db:prepare` creates every configured database and loads each one's schema — including the cache DB — so no manual per-database step is needed before deploying.

---

## Response format

Responses follow the **JSON:API** convention (`data` / `attributes` / `meta`).

```json
{
  "data": {
    "id": "1",
    "type": "project",
    "attributes": { "name": "Enterprise Refit", "open_tasks_count": 3, "closed_tasks_count": 1 },
    "relationships": { "pm": { "data": { "id": "1", "type": "user" } } }
  },
  "included": [
    { "id": "1", "type": "user", "attributes": { "name": "James Kirk", "email": "kirk@enterprise.com" } }
  ]
}
```

**Note on relationships:** both resource types use formal JSON:API `relationships` + `included` sideloading:

- **Projects** sideload `pm` in `included`. On the project list, multiple projects can share the same PM — sideloading ensures the user record appears exactly once in `included` regardless of how many projects reference them.
- **Tasks** sideload `project` (via `ProjectEmbedSerializer`) and `assignee`. A task list can return many tasks that share the same project or assignee — sideloading deduplicates them. The included project carries its own `pm` as a nested relationship, resolved from the same `included` array. If a user is both PM of a project and assignee on a task, they appear exactly once in `included`.

**Errors** follow the JSON:API error format:

```json
{ "errors": [{ "status": "422", "title": "Validation Error", "detail": "Title can't be blank" }] }
```

Multiple validation failures produce multiple error objects in the same array.

---

## API Reference

All endpoints below (except login) require an `Authorization: Bearer <token>` header. Omitting it, or sending an invalid/expired/revoked token, returns:

```json
{ "errors": [{ "status": "401", "title": "Unauthorized", "detail": "You need to sign in or sign up before continuing." }] }
```

### Users

#### `GET /api/v1/users`

Lists every user in the system. Any authenticated user can call this.

**Response — `200 OK`:**
```json
{
  "data": [
    { "id": "1", "type": "user", "attributes": { "name": "James Kirk", "email": "kirk@enterprise.com" } },
    { "id": "2", "type": "user", "attributes": { "name": "Spock", "email": "spock@enterprise.com" } }
  ],
  "meta": { "current_page": 1, "page_size": 20, "total_pages": 1, "total_count": 7 }
}
```

---

### Projects

#### `GET /api/v1/projects`

Lists all projects. **Every authenticated user sees every project**, regardless of whether they're the PM of any of them.

**Query parameters (all optional):**

| Param | Type | Description |
|---|---|---|
| `term` | string | Case-insensitive substring match against the project's `name` only. |
| `page` | integer | Page number, default `1`. |
| `per_page` | integer | Results per page, default `20`. |

**Response — `200 OK`:**
```json
{
  "data": [
    {
      "id": "1",
      "type": "project",
      "attributes": { "name": "Enterprise Refit", "open_tasks_count": 3, "closed_tasks_count": 1 },
      "relationships": { "pm": { "data": { "id": "1", "type": "user" } } }
    }
  ],
  "meta": { "current_page": 1, "page_size": 20, "total_pages": 1, "total_count": 2 },
  "included": [
    { "id": "1", "type": "user", "attributes": { "name": "James Kirk", "email": "kirk@enterprise.com" } }
  ]
}
```

#### `GET /api/v1/projects/:id`

Shows a single project. Same shape as one element of the `index` array above.

**Not found — `404 Not Found`:**
```json
{ "errors": [{ "status": "404", "title": "Not Found", "detail": "Couldn't find Project with 'id'=999" }] }
```

#### `POST /api/v1/projects`

Creates a project. **Any authenticated user can create one, and is automatically set as its PM.**

**Request body:**
```json
{ "project": { "name": "Enterprise Refit" } }
```

Note: if a `pm_id` is included in the body, it is silently ignored — the PM is always the currently authenticated user, derived server-side. This is enforced by strong parameters (`project_create_params` only permits `:name`) combined with building the record through `current_user.managed_projects.build(...)`, not by assigning `pm_id` from user input.

**Success — `201 Created`.** Same shape as `show`, with `open_tasks_count`/`closed_tasks_count` both `0`.

**Missing name — `422 Unprocessable Content`:**
```json
{ "errors": [{ "status": "422", "title": "Validation Error", "detail": "Name can't be blank" }] }
```

#### `PATCH /api/v1/projects/:id`

Updates a project. **PM-only** — any other authenticated user gets `403`.

**Request body:**
```json
{ "project": { "name": "Enterprise Refit (Refitted Again)" } }
```

**Success — `200 OK`.**

**Not the PM — `403 Forbidden`:**
```json
{ "errors": [{ "status": "403", "title": "Forbidden", "detail": "You are not authorized to perform this action" }] }
```

#### `DELETE /api/v1/projects/:id`

Deletes a project (and cascades to delete its tasks). **PM-only.**

**Success — `204 No Content`** (no response body, per HTTP/REST convention for DELETE).

**Not the PM — `403 Forbidden`** (same shape as above).

---

### Tasks

#### `GET /api/v1/tasks`

Lists tasks. **What you see depends on your relationship to each task's project:**
- If you're the **PM** of a task's project, you see **all** tasks in that project (assigned or not).
- Otherwise, you see **only** tasks assigned to you, in any project.

These two rules combine per-project — see the [Authorization rules](#authorization-rules) table and the Seeded data table above (Kirk is PM of one project and assignee on another, and sees the appropriate task set from both roles simultaneously).

**Query parameters (all optional, combinable):**

| Param | Type | Description |
|---|---|---|
| `closed` | `true` \| `false` | Filter by whether the task is closed. |
| `project_id` | integer | Restrict to a single project. |
| `term` | string | Case-insensitive substring match against the task's `title` **or** its project's `name`. |
| `page` / `per_page` | integer | Pagination, same defaults as Projects. |

Results are always ordered by `updated_at` **descending** (most recently updated first), regardless of filters.

**Response — `200 OK`:**
```json
{
  "data": [
    {
      "id": "1",
      "type": "task",
      "attributes": {
        "title": "Repair warp core",
        "description": "Warp core is running at 60% efficiency",
        "closed": false,
        "updated_at": "2026-07-04T10:15:00.000Z"
      },
      "relationships": {
        "project": { "data": { "type": "project", "id": "1" } },
        "assignee": { "data": { "type": "user", "id": "2" } }
      }
    }
  ],
  "included": [
    {
      "id": "1", "type": "project",
      "attributes": { "name": "Enterprise Refit" },
      "relationships": { "pm": { "data": { "type": "user", "id": "1" } } }
    },
    { "id": "1", "type": "user", "attributes": { "name": "James Kirk", "email": "kirk@enterprise.com" } },
    { "id": "2", "type": "user", "attributes": { "name": "Spock", "email": "spock@enterprise.com" } }
  ],
  "meta": { "current_page": 1, "page_size": 20, "total_pages": 1, "total_count": 4 }
}
```

An unassigned task has `"assignee": { "data": null }` in `relationships` and no corresponding entry in `included`.

#### `GET /api/v1/tasks/:id`

Shows a single task — same shape as one element from the list above (including `relationships` and `included`). Returns `404` if the task doesn't exist or is outside your scope (see [Authorization rules](#authorization-rules)).

#### `POST /api/v1/tasks`

Creates a task. **PM-only, and only for a project they manage** — being PM of *some* project does not grant permission to create tasks in a *different* project.

**Request body:**
```json
{
  "task": {
    "title": "Recalibrate deflector array",
    "description": "Optional",
    "project_id": 1,
    "assignee_id": 2
  }
}
```

Only `title` and `project_id` are required — `description`, `assignee_id`, and `closed` are all optional (`closed` defaults to `false`, `assignee_id` defaults to blank per the spec's "assignee can be blank").

**Success — `201 Created`.**

**Not the PM of that project — `403 Forbidden`.**

**Assignee already has 5 open tasks in this project — `422 Unprocessable Content`:**
```json
{ "errors": [{ "status": "422", "title": "Validation Error", "detail": "Assignee already has 5 open tasks in this project" }] }
```
See [Business rule](#business-rule-max-5-open-tasks-per-assignee-per-project) below for the exact semantics.

#### `PATCH /api/v1/tasks/:id`

Updates a task.
- The **PM** of the task's project can update **any field**.
- The **assignee** can update their own task (including closing it, i.e. `"closed": true`), but only if it's assigned to them.
- Anyone else gets `403`.

**Request body** (any subset of fields):
```json
{ "task": { "closed": true } }
```

**Success — `200 OK`.** **Not authorized — `403 Forbidden`.**

#### `DELETE /api/v1/tasks/:id`

Deletes a task. **PM-only** (of that task's project).

**Success — `204 No Content`.** **Not authorized — `403 Forbidden`.**

---

## Authorization rules

| Action | Any authenticated user | PM (of the relevant project) | Assignee |
|---|---|---|---|
| See all projects | Yes | Yes | Yes |
| Create a project (becomes its PM) | Yes | — | — |
| Update / delete a project | No | Yes | No |
| See all tasks in a project (assigned or not) | No | Yes | No |
| See own assigned tasks | Yes | Yes | Yes |
| Create / delete a task | No | Yes (own project only) | No |
| Update any field on any task in their project | No | Yes | No |
| Update / close their own assigned task | No | Yes (as PM, separately) | Yes |

A user's role (PM / assignee) is **not** a fixed attribute on the user record — it's derived per-project from `Project#pm_id` and per-task from `Task#assignee_id`. The same person can be a PM on one project and an ordinary assignee on another (see Kirk in the seed data).

Implemented with **Pundit**. `TaskPolicy::Scope` is the key piece — it's what `GET /tasks` uses to determine the visible task set: all tasks in projects the user manages, **plus** any task assigned to them, combined with `OR` in a single query (not two separate lookups).

**404 vs 403 on tasks:** `TaskPolicy::Scope` is restrictive — only PM's tasks and assigned tasks are visible. A task outside that scope returns `404 Not Found` on `show`, `update`, and `destroy`, not `403 Forbidden`. This prevents an authenticated user from enumerating IDs to discover which tasks exist. The only cases that return 403 are when a task is already in scope but the specific operation is disallowed (e.g. an assignee trying to delete their own task).

**403 on projects:** `ProjectPolicy::Scope` returns all projects — every authenticated user can see every project. Because no project is ever "outside scope", a non-PM who tries to `update` or `delete` a project they don't own will always get `403 Forbidden` (found in scope, operation denied), never 404.

---

## Business rule: max 5 open tasks per assignee per project

A user cannot have more than 5 **open** tasks within a **single project**. This is enforced as a model validation (`Task#assignee_open_task_limit`), checked whenever `assignee_id` or `closed` changes on save. The model is the last line of defence — the rule is enforced regardless of how the record is saved, not just through the service layer.

Specifics, each covered by a dedicated test:
- Exactly 5 open tasks for the same assignee in the same project is allowed; a 6th is rejected.
- **Closed** tasks don't count toward the limit — a 6th task is fine if it's closed.
- The limit is scoped per **project** — a 6th open task for the same assignee is fine if it's in a different project.
- The limit is scoped per **assignee** — a 6th open task in the same project is fine if it's assigned to someone else.
- Updating an existing task that's already one of an assignee's 5 open tasks doesn't falsely trip the limit against itself (the check excludes the record being saved from its own count).

**Concurrency:** the check-and-save is protected against race conditions via `Tasks::Base#persist!`, which wraps the save in a transaction with a pessimistic row lock (`SELECT ... FOR UPDATE` on the project row). This ensures two simultaneous requests for the same project cannot both pass the limit check and jointly create a 6th open task.

---

## Search & filtering

Search is implemented as a `term` query parameter on the existing `GET /projects` and `GET /tasks` endpoints, **rather than as a separate `/search` resource**.

This is a deliberate choice: search is just another filter alongside `closed`, `project_id`, etc. — keeping it on the same resource endpoint avoids an unnecessary extra route and keeps filtering logic centralized in one place.

- `?term=` on `/tasks` matches the task's `title` **or** its project's `name` (per spec).
- `?term=` on `/projects` matches the project's `name` only (per spec).
- Matching is case-insensitive (MySQL's default collation is case-insensitive for `LIKE`; verified with a dedicated test using an uppercase search term).
- Term search uses `LIKE '%term%'` (leading wildcard), which a standard B-tree index cannot serve — so no index is kept on `tasks.title` or `projects.name`; they would be pure write overhead with no read benefit. At this scale the substring match is a cheap full scan. For production scale, the right upgrade is a MySQL `FULLTEXT` index with `MATCH … AGAINST` (or a trigram index on Postgres), not a plain B-tree index.
- `?closed=` on `/tasks` accepts only `true` or `false`. An invalid value returns `400 Bad Request` — the validation is explicit in `TaskQuery` before the query runs.

---

## Performance notes

- `GET /projects` computes open/closed task counts via `ProjectTaskCountsQuery`, which issues **two grouped `COUNT` queries total** (one per status), regardless of how many projects are returned — not one query per project.
- `POST /projects`, `PATCH /projects/:id`, and `GET /projects/:id` use `ProjectTaskCountsQuery.for_project` which issues **a single `GROUP BY closed` query** to compute both open and closed counts at once — no redundant project reload from DB.
- `POST /tasks` and `PATCH /tasks/:id` reload the saved task with `.includes(project: :pm, assignee: [])` before serialization, ensuring the serializer never triggers lazy association queries.
- All `index` actions eager-load associations (`.includes`) to avoid N+1 queries when serializing `pm` / `assignee` / `project`.
- Both `GET /projects` and `GET /tasks` are paginated (default 20/page, `?per_page=` to override).
- Indexes exist on: `users.email` (unique), `tasks.updated_at` (used by the default `ORDER BY updated_at DESC` on every task list), the `project_id` / `assignee_id` / `pm_id` foreign keys, and a composite `(project_id, assignee_id)` index to keep the 5-open-tasks check fast (it's checked on every task create/update). No index is kept on the free-text search columns (`tasks.title`, `projects.name`) — see the search section for why a B-tree index wouldn't help a `LIKE '%term%'` query.

---

## Postman collection

A ready-to-import Postman collection lives at `postman/Productive_PM_System.postman_collection.json` — 61 requests across 7 numbered folders, covering every endpoint plus explicit tests for authorization rules and the 5-open-tasks business rule (each with real assertions, not just "check the status code").

**To use it:**
1. Run `rails db:reset && rails db:seed` first — the business-rule folder creates new tasks on every run, so a fresh seed keeps the numbers accurate.
2. Import the collection into Postman.
3. Use **Run collection** (not individual clicks) — folders are numbered and order matters: `1. Auth` logs in and stores tokens as collection variables that every later request depends on, and `7. Logout & Token Revocation` deliberately revokes a token, so it has to run last.

---

## Testing

```bash
bundle exec rspec
```

| Area | File(s) | What's covered |
|---|---|---|
| User model | `spec/models/user_spec.rb` | Validations, `assigned_tasks` nullify-on-delete |
| Project model | `spec/models/project_spec.rb` | Validations, `belongs_to :pm` presence |
| Task model | `spec/models/task_spec.rb` | Validations (presence, length), 5-task limit (new task, re-open blocked, title-only change skips check, closing always allowed) |
| Query objects | `spec/queries/` | `TaskQuery` and `ProjectTaskCountsQuery` tested in isolation — filtering, term search, `InvalidFilterError` on a bad `closed` value, `for_project` single-query path, pagination-safe counting |
| `ErrorSerializer` | `spec/lib/error_serializer_spec.rb` | JSON:API error shape generation |
| Auth | `spec/requests/api/v1/session_spec.rb` | Login (success/failure), logout, token revocation, protected-route access without a token |
| Projects API | `spec/requests/api/v1/project_spec.rb` | Full CRUD, `pm_id` spoofing is ignored, PM-only update/delete enforcement |
| Tasks API | `spec/requests/api/v1/task_spec.rb` | Full CRUD, PM vs. assignee visibility, PM full control (create/update/delete any task in their project), assignee limited to own task + restricted fields, 5-task limit, invalid filter, pagination, FK violation |
| Users API | `spec/requests/api/v1/users_spec.rb` | List all users, unauthorized without token, attribute shape, pagination |
| `Tasks::Create` | `spec/services/tasks/create_spec.rb` | Persist new task, invalid task raises, 5-task limit enforced |
| `Tasks::Update` | `spec/services/tasks/update_spec.rb` | Persist changes, invalid update raises, 5-task limit enforced on reassignment |
| Factories | `spec/factory_bot/factories_spec.rb` | Sanity check that every FactoryBot factory builds a valid record |

---

## Architecture notes

- **Query objects** (`app/queries/`) hold filtering/aggregation logic that would otherwise bloat controllers — e.g. `TaskQuery` composes closed/project/term filters and is reused identically by both the plain `tasks#index` listing and its `?term=` search behavior, since search is just another filter, not a separate code path.
- **Serializers** (`app/serializers/`) are `jsonapi-serializer` classes. Both project and task responses use formal `belongs_to` relationships with `included` sideloading. Projects sideload `pm` (`UserSerializer`). Tasks sideload `project` (`ProjectEmbedSerializer`, which itself sideloads `pm`) and `assignee` (`UserSerializer`) — shared resources are deduplicated across a task list so a project or user appearing on ten tasks is included exactly once.
- **Policies** (`app/policies/`) hold all authorization logic; controllers only call `authorize`/`policy_scope` and contain no role-checking conditionals of their own.
- **`ApiFailureApp`** (`app/lib/api_failure_app.rb`) is a custom Warden failure handler — without it, a failed login (wrong password) would return Devise's own default `{"error": "..."}` shape instead of matching this API's JSON:API error format everywhere else.
- **`Tasks::Create` / `Tasks::Update`** (`app/services/tasks/`) both inherit from `Tasks::Base`, which wraps persistence in a transaction with a pessimistic row lock on the project (`SELECT ... FOR UPDATE`), protecting the 5-open-tasks check against race conditions under concurrent requests. Each service has its own `call` entry point so create and update can diverge independently (notifications, audit log, etc.) without touching shared logic.
- Authentication uses Devise + devise-jwt rather than a hand-rolled JWT implementation, specifically for its battle-tested token revocation (denylist) support, which a minimal custom implementation wouldn't provide out of the box.

---

## Known limitations

- No user self-registration endpoint — users are provisioned via `db/seeds.rb`. The spec only requires that users *can log in*, not that they can register themselves; given the assignment's project-management context (a real system like this would more plausibly use an invite flow than open signup), seeding was chosen over building a registration flow that the spec doesn't actually ask for.