# Manual Test Checklist

Run `tests/e2e.sh` first (97 automated checks). This checklist covers what a person should eyeball in a browser.
Pre-conditions: `database/schema.sql` and `database/sample_data.sql` loaded, app running, start at the dashboard.

Legend: ☐ = to do · Expected results are in *italics*.

## A. Setup & configuration
- ☐ Start with MySQL stopped → open the site. *"Database setup required" page (HTTP 503), no host/user/password/stack trace shown.*
- ☐ Start MySQL, reload. *Dashboard appears without restarting ColdFusion.*
- ☐ Rename a column (e.g. `job_title`) on a copy of the DB → open the site. *Setup page lists the missing column.* Re-run `schema.sql`. *App works again.*
- ☐ Browse to `/Application.cfc`, `/.env`, `/app/model/EmployeeDAO.cfc`, `/database/schema.sql`. *None are downloadable.*

## B. Dashboard
- ☐ Cards show Total, Active, Departments, Recent hires. *Numbers match the directory.*
- ☐ Click a card / status legend / department row. *Directory opens pre-filtered.*
- ☐ Latest hires list links to the profile. *Opens the right employee.*
- ☐ Empty database. *Friendly empty state with "Add the first employee".*

## C. Directory (Read)
- ☐ Table shows avatar, name, email, department, title, joined, salary, status badge. *Values come from the DB.*
- ☐ Search `aarav`, an email fragment, a phone fragment, a department, a job title. *Matches are shown.*
- ☐ Search `50%` and `_`. *Treated literally (no match), no error.*
- ☐ Filter by department, by status, both together; clear with the reset button. *Counts and rows update; "clear filters" link works.*
- ☐ Click every sortable header twice. *Arrow flips, order changes, filters preserved.*
- ☐ Change "Rows" to 25 / 50; page through; jump to a far page via the URL (`?page=999`). *Pagination correct; out-of-range page is clamped.*
- ☐ Type in the search box and pause. *Loading overlay appears, results refresh automatically.*
- ☐ No match. *"No employees match your filters" empty state with a Clear button.*
- ☐ Browser back/forward after filtering. *State restored, no stuck spinner.*

## D. Profile
- ☐ Open several profiles. *Name, status badge, contact links (mailto/tel), salary formatted, joining date, tenure, record dates.*
- ☐ A legacy employee with no phone/title/salary/date. *Shows "Not provided", no errors.*
- ☐ `/employees/view.cfm?id=999999` and `?id=abc`. *Redirect to directory with "could not be found" toast.*

## E. Create
- ☐ Open "Add employee" from sidebar, top bar and directory. *Form opens with status Active and today's date.*
- ☐ Submit empty. *Browser validation highlights required fields (name, email, department, job title, joining date, status).*
- ☐ Type a name/title/department. *Profile preview card updates live.*
- ☐ Create a valid employee. *Redirect to the profile; green toast; employee visible in the directory and dashboard counts.*
- ☐ Disable JavaScript (or craft the POST) and submit bad data. *Server shows the same errors, values preserved.*
- ☐ Duplicate email (also with different letter case). *"An employee with this email address already exists."*
- ☐ Bad email, bad phone (`abc`), negative salary, `2024-02-30`, far-future date, 101-char name, `<b>` in name/department. *Each rejected with a clear message.*
- ☐ Optional fields blank (phone, salary). *Saved as empty; profile shows "Not provided".*
- ☐ Double-click the submit button. *Only one record is created (button shows spinner and disables).*

## F. Update
- ☐ Edit from the table, from the profile. *Form pre-filled incl. date and status.*
- ☐ Change every field; save. *Toast "updated"; profile and directory reflect it.*
- ☐ Save without changing the email. *Allowed (own email is not a duplicate).*
- ☐ Change email to another employee's. *Rejected as duplicate.*
- ☐ Clear a required field and save. *Rejected, other edits preserved.*
- ☐ Open an edit page, delete that employee in another tab, then save. *"No longer exists" message, no crash.*
- ☐ Cancel. *Returns without saving.*

## G. Delete
- ☐ Click the trash icon (table) and Delete (profile). *Confirmation dialog names the employee.*
- ☐ Cancel / close with Esc. *Nothing deleted.*
- ☐ Confirm. *Employee removed, toast shown, list keeps the active filters; deleting the last row of the last page lands on a valid page.*
- ☐ Delete an employee that no longer exists (stale page). *Friendly message, no crash.*

## H. Security & reliability
- ☐ Open DevTools → remove the `csrf_token` hidden field and submit create/update/delete. *Rejected with "could not be verified"; nothing changed.*
- ☐ Visit `/employees/save.cfm` and `/employees/delete.cfm` directly (GET). *Redirected; nothing changed.*
- ☐ Try `?q=<script>alert(1)</script>`, `?q=' OR '1'='1`, `?sort=name;DROP TABLE employees`. *No script runs, no extra rows, table intact.*
- ☐ Check response headers. *CSP, X-Frame-Options: DENY, nosniff; session cookie HttpOnly + SameSite=Lax.*
- ☐ Let the session expire (or clear cookies) and submit a form. *Rejected cleanly with a "session expired" message.*
- ☐ Stop MySQL mid-session and click around. *Generic error page with a reference id; nothing sensitive; the id appears in the `employee_app` log.*

## I. Responsive & accessibility
- ☐ Desktop ≥1200 px, tablet ~768 px, phone ~390 px. *No horizontal page scroll; sidebar becomes a slide-in menu on <992 px; table keeps view/edit/delete reachable.*
- ☐ Keyboard only: Tab through nav, filters, table actions, dialog. *Visible focus; dialog traps focus and Esc closes it.*
- ☐ Toasts are announced (role alert/status) and dismissible.
