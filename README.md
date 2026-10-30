# People Hub – Employee Management System

A complete, database-backed employee management application written in **CFML** for **Adobe ColdFusion 2023** (also uses only CF 2025-compatible features) and **MySQL**. Bootstrap 5 UI, no front-end build step, no hard-coded data.

| Area | What you get |
|---|---|
| **CRUD** | Create, read (searchable / sortable / filterable / paginated directory + profile page), update, delete-with-confirmation |
| **Dashboard** | Total / active employees, departments, recent hires, status split, top departments, latest hires |
| **UX** | Sidebar + top bar, avatars, status badges, toasts, loading states, empty states, live profile preview, responsive (desktop / tablet / mobile) |
| **Security** | Parameterized SQL only, server-side validation, output encoding, CSRF tokens, POST-only writes, CSP + security headers, generic error pages, credentials only from environment |

---

## 1. Project structure

```
cfml_employee_management_app/
├── public/                      ← THE WEB ROOT (only this folder is served)
│   ├── Application.cfc          bootstrap: mappings, datasource, session, headers, error handler
│   ├── index.cfm                dashboard
│   ├── employees/
│   │   ├── index.cfm            directory (search · filter · sort · paginate)
│   │   ├── form.cfm             add / edit form
│   │   ├── view.cfm             employee profile
│   │   ├── save.cfm             POST action: create / update
│   │   └── delete.cfm           POST action: delete
│   └── assets/                  css/app.css, js/app.js, vendor/ (Bootstrap 5.3.3 + Bootstrap Icons, local copies)
├── app/                         ← NOT web-accessible
│   ├── model/
│   │   ├── EmployeeDAO.cfc      all SQL (typed, parameterized)
│   │   ├── EmployeeService.cfc  validation, sanitising, business rules
│   │   ├── CsrfService.cfc      synchronizer-token CSRF protection
│   │   ├── FlashService.cfc     toasts + form state across redirects (PRG)
│   │   ├── ViewHelper.cfc       encoding, formatting, avatars, URL building
│   │   └── Settings.cfc         immutable app settings
│   └── views/                   init.cfm, layout/ (header, footer), partials/, error.cfm, setup_required.cfm
├── database/
│   ├── schema.sql               idempotent: creates OR upgrades the employees table
│   ├── alter_existing_table.sql plain ALTER TABLE version for phpMyAdmin (table `employee`)
│   └── sample_data.sql          27 fictional employees
├── tests/e2e.sh                 97 automated end-to-end checks (HTTP, real session)
├── docs/TEST_CHECKLIST.md       manual test checklist
├── .env.example                 configuration template (copy to .env – git-ignored)
├── server.json / box.json       CommandBox config (Adobe CF 2023, web root = public)
└── README.md
```

**Why `public/`?** Source, SQL and `.env` live outside the web root, so they cannot be downloaded over HTTP. Always point your web server / CF virtual host at `public/`, never at the repository root.

---

## 2. Database setup (MySQL 5.7+ / 8.x)

You already have `admin_employee_management.employees` with `id`, `name`, `email`, `department`. The app also needs `phone`, `job_title`, `salary`, `joining_date`, `status`, `created_at`, `updated_at`.

```bash
mysql -u root -p < database/schema.sql          # safe on your existing table – see below
mysql -u root -p < database/sample_data.sql     # optional: 27 sample employees
```

`schema.sql` is **idempotent and non-destructive**: it only *adds* missing columns and indexes, never drops or rewrites data. Existing rows get `status = 'Active'`; the new optional columns stay `NULL` until you edit the record. It adds a `UNIQUE` index on `email` – if your table already contains duplicate emails the script lists them and skips the index (fix the duplicates and re-run). The app's own validation enforces unique emails regardless.

**Using plain SQL / phpMyAdmin, or a table not called `employees`?** Use [database/alter_existing_table.sql](database/alter_existing_table.sql) (simple `ALTER TABLE` statements for a table named `employee`; rename as needed) and set `DB_TABLE=<your table name>` in `.env`. The default is `employees`.

Final table:

| Column | Type | Notes |
|---|---|---|
| id | INT(11) PK AUTO_INCREMENT | existing |
| name | VARCHAR(100) NOT NULL | existing |
| email | VARCHAR(254) NOT NULL, **UNIQUE** | existing + unique index |
| phone | VARCHAR(30) NULL | new |
| department | VARCHAR(100) NOT NULL | existing |
| job_title | VARCHAR(100) NULL | new |
| salary | DECIMAL(12,2) NULL | new |
| joining_date | DATE NULL | new |
| status | ENUM('Active','On Leave','Inactive') NOT NULL DEFAULT 'Active' | new |
| created_at / updated_at | DATETIME | new, maintained by MySQL |

Create a **least-privilege** MySQL user for the app (not `root`):

```sql
CREATE USER 'emp_app'@'localhost' IDENTIFIED BY 'a-strong-password';
GRANT SELECT, INSERT, UPDATE, DELETE ON admin_employee_management.* TO 'emp_app'@'localhost';
```

(`information_schema` reads for the start-up schema check need no extra grant.)

---

## 3. Configure the database connection (no credentials in source)

Pick **one** of the two options.

### Option A – environment variables / `.env` (default, works out of the box)

```bash
cp .env.example .env          # .env is git-ignored and lives outside the web root
```

Edit `.env`:

```ini
DB_HOST=127.0.0.1
DB_PORT=3306
DB_NAME=admin_employee_management
DB_USER=emp_app
DB_PASSWORD=your-password
APP_ENV=production            # "development" enables ?reinit=1
APP_CURRENCY=INR              # INR USD EUR GBP JPY AUD CAD AED
```

Real OS environment variables take precedence over `.env` (use these in production / containers). When `DB_HOST` and `DB_USER` are set, `Application.cfc` defines a per-application datasource named `admin_employee_management` from them using the MySQL driver bundled with ColdFusion. Values are read once per JVM – restart ColdFusion after changing them (or use `?reinit=1` with `APP_ENV=development`).

### Option B – datasource in the ColdFusion Administrator

Leave `DB_HOST`/`DB_USER` empty and create a datasource instead:

1. ColdFusion Administrator → **Data & Services → Data Sources**.
2. **Data Source Name:** `admin_employee_management` (must match exactly; override with `DB_DATASOURCE` if you prefer another name). **Driver:** *MySQL*. Click **Add**.
3. **Database:** `admin_employee_management` · **Server:** your host · **Port:** `3306` · **Username/Password:** the `emp_app` user.
4. *Advanced settings* → add `useUnicode=true&characterEncoding=UTF-8&serverTimezone=UTC` to *Connection String* options if needed.
5. **Submit** and confirm status **OK**.

If neither option is configured (or MySQL is down, or columns are missing) the app shows a clear *"Database setup required"* page (HTTP 503) – it never shows connection details. Technical detail goes to the `employee_app` ColdFusion log.

---

## 4. Run it locally

### With CommandBox (recommended)

Works with CommandBox 6.0 or newer.

```bash
cd cfml_employee_management_app
box server start          # uses server.json: adobe@2023, web root ./public, http://127.0.0.1:8510
```

The first start downloads ColdFusion 2023 and a JRE (several hundred MB). Open **http://127.0.0.1:8510/**. Change the port in `server.json` if 8510 is taken. Stop with `box server stop`. CommandBox's default CF Administrator password is `commandbox` – change it, and don't expose the admin outside localhost.

> **Moving to ColdFusion 2025 later:** the code is CF 2025-compatible but has only been tested on CF 2023. Adobe CF 2025 needs **CommandBox 6.2.0+** (it runs on Jakarta EE; older CommandBox fails with `NoClassDefFoundError: jakarta/servlet/Servlet`). Change `"cfengine"` in `server.json` to `adobe@2025` (and add `"jvm": {"javaVersion": "openjdk21_jre"}`), then re-run `tests/e2e.sh`.

### On an existing ColdFusion 2023 / 2025 install (IIS / Apache / Tomcat)

Create a site / virtual directory whose **document root is `<repo>/public`**, with ColdFusion handling `.cfm`/`.cfc`. Keep the rest of the repository *outside* any served folder. Set the environment variables at machine/service level (or put `.env` in the repository root) and restart the ColdFusion service. Nothing else is required – the `/app` mapping is created by `Application.cfc` relative to its own location.

---

## 5. Tests

**Automated (97 checks)** – drives the running app over HTTP with a real session, exactly like a browser. Needs Bash + curl (Git Bash on Windows) and the sample data loaded:

```bash
BASE_URL=http://127.0.0.1:8510 bash tests/e2e.sh
```

It covers dashboard, search/filter/sort/pagination, create, read, update, delete, every validation rule, duplicate emails (including case-insensitive and "update steals email"), CSRF (missing / forged / other-session token), POST-only enforcement, SQL-injection and XSS probes, security headers, source/`.env` not downloadable, and error pages without leaks. It creates temporary employees and removes them again.

**Manual** – see [docs/TEST_CHECKLIST.md](docs/TEST_CHECKLIST.md).

### Verification status

| Check | Engine | Result |
|---|---|---|
| Schema script on a legacy 4-column table, twice (idempotent) | MySQL 8.4 | ✅ |
| 97 end-to-end checks | **Adobe CF 2023** (the target engine) + MySQL 8.4 | ✅ 97/97 |
| UI at 1440 px and 390 px | Edge headless | ✅ |
| DB-down → generic 500; recovery without restart | Adobe CF 2023 | ✅ |
| **Adobe CF 2025** | – | ⚠️ **Not run in the authoring environment** (it only had CommandBox 6.0.0, which cannot start CF 2025). The code uses only CFML features available identically in CF 2023/2025 – please run `tests/e2e.sh` on your CF 2025 server as the final acceptance step. |

---

## 6. Security design

| Concern | Implementation |
|---|---|
| SQL injection | Every value bound via typed `queryExecute` params. The only interpolated SQL (ORDER BY column/direction) comes from fixed whitelists. LIKE wildcards in search are escaped. |
| XSS | All output through `encodeForHTML` / `encodeForHTMLAttribute` (`h()` / `ha()`); `<` `>` rejected in text fields on input; strict CSP (`script-src 'self'`, no inline scripts). |
| CSRF | Per-session 256-bit token in every form, verified in constant time on every POST; `SameSite=Lax` + `HttpOnly` session cookie (`Secure` automatically on HTTPS). |
| HTTP methods | `save.cfm` / `delete.cfm` reject anything but POST; GET never changes data. |
| Validation | Server-side for every field (required, length, format, strict real-date check, numeric ranges, status whitelist, unique email – checked in the app *and* by the DB unique index; a race that trips the index is reported as a friendly field error). Client-side HTML5 validation is only a convenience. |
| Errors | `onError` logs the real error to `employee_app` and shows a generic page with a reference id. No stack traces, SQL or config reach the browser. |
| Secrets | Only from OS env / git-ignored `.env` outside the web root (or the CF Administrator). Nothing sensitive in source control. |
| Delete | Bootstrap confirmation dialog → POST + CSRF token. |

### Known limitation – no login screen

The brief did not ask for authentication, so none is included: **anyone who can reach the site can manage employees.** Run it on a trusted network or behind your SSO / reverse-proxy authentication before exposing it, and consider adding roles + audit logging as a next step. Salary data is sensitive.

---

## 7. Troubleshooting

| Symptom | Fix |
|---|---|
| "Database setup required – could not connect" | MySQL running? `DB_*` values right? Look in the `employee_app` log (CF Administrator → Debugging & Logging → Log Files). |
| "…missing columns" | Run `database/schema.sql`. |
| `NoClassDefFoundError: jakarta/servlet/Servlet` on `box server start` | You switched `server.json` to CF 2025 on a CommandBox older than 6.2 – upgrade CommandBox or use `adobe@2023`. |
| MySQL 8 "Public Key Retrieval is not allowed" | Add `allowPublicKeyRetrieval=true` (dev only) or enable SSL via `DB_PARAMS`. |
| Changed `.env` but nothing happened | Env is cached per JVM – restart CF, or open any page with `?reinit=1` when `APP_ENV=development`. |
| Port 8510 in use | Change `web.http.port` in `server.json`. |
