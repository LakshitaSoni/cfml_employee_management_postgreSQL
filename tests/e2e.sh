#!/usr/bin/env bash
# End-to-end tests for the Employee Management System.
# Drives the RUNNING app over HTTP with a real session (cookie jar), exactly like a browser.
#
#   BASE_URL=http://127.0.0.1:8510 bash tests/e2e.sh
#
# Requires: bash + curl (Git Bash on Windows is fine) and the sample data loaded
# (database/sample_data.sql). The tests create a few temporary employees and delete
# them again; they never touch other rows.

BASE_URL="${BASE_URL:-http://127.0.0.1:8510}"
JAR="$(mktemp)"
TMP="$(mktemp)"
trap 'rm -f "$JAR" "$TMP"' EXIT

PASS=0; FAIL=0; FAILED=()
STAMP="$(date +%s)"
EMAIL="e2e.$STAMP@example.com"

# ---- helpers ------------------------------------------------------------------
ok()   { PASS=$((PASS+1)); printf '  \033[32mPASS\033[0m %s\n' "$1"; }
bad()  { FAIL=$((FAIL+1)); FAILED+=("$1"); printf '  \033[31mFAIL\033[0m %s\n' "$1"; [ -n "$2" ] && printf '       %s\n' "$2"; }
section() { printf '\n\033[1m%s\033[0m\n' "$1"; }

get()  { curl -s -L -b "$JAR" -c "$JAR" "$BASE_URL$1"; }                       # follows redirects
code() { curl -s -o /dev/null -w '%{http_code}' -b "$JAR" -c "$JAR" "$BASE_URL$1"; }
# post <path> <curl --data-urlencode args...>   -> prints "status redirect_url"
post() { local p="$1"; shift; curl -s -o /dev/null -w '%{http_code} %{redirect_url}' -b "$JAR" -c "$JAR" -X POST "$BASE_URL$p" "$@"; }

assert_contains()     { if grep -qF -- "$2" <<<"$1"; then ok "$3"; else bad "$3" "expected to find: $2"; fi; }
assert_not_contains() { if grep -qF -- "$2" <<<"$1"; then bad "$3" "did not expect: $2"; else ok "$3"; fi; }
assert_eq()           { if [ "$1" = "$2" ]; then ok "$3"; else bad "$3" "expected '$2' got '$1'"; fi; }

token() { get "$1" | grep -o 'name="csrf_token" value="[a-f0-9]*"' | head -1 | sed 's/.*value="//; s/"//'; }
find_id() { get "/employees/index.cfm?q=$1" | grep -o 'view.cfm?id=[0-9]*' | head -1 | sed 's/.*id=//'; }

valid_fields=(--data-urlencode "name=Edgar Tester" --data-urlencode "email=$EMAIL" --data-urlencode "phone=+91 98765 00000"
              --data-urlencode "department=Quality Assurance" --data-urlencode "job_title=Test Engineer"
              --data-urlencode "salary=123456.50" --data-urlencode "joining_date=2024-03-15" --data-urlencode "status=Active")

# ---- 0. Reachability -------------------------------------------------------------
section "0. Application is up"
assert_eq "$(code /index.cfm)" "200" "dashboard responds 200"
[ "$(code /Application.cfc)" != "200" ] && ok "Application.cfc cannot be fetched (source not exposed)" || bad "Application.cfc cannot be fetched"
assert_eq "$(code /.env)" "404" ".env is not reachable over HTTP"
assert_eq "$(code /app/model/EmployeeDAO.cfc)" "404" "components are outside the web root"

# ---- 1. Dashboard -----------------------------------------------------------------
section "1. Dashboard"
DASH="$(get /index.cfm)"
assert_contains "$DASH" "Total employees"  "total employees card"
assert_contains "$DASH" "Active employees" "active employees card"
assert_contains "$DASH" "Departments"      "departments card"
assert_contains "$DASH" "Recent hires"     "recent hires card"
assert_contains "$DASH" "Latest hires"     "latest hires list"

# ---- 2. Directory: read / search / filter / sort / paginate -----------------------
section "2. Directory: read, search, filter, sort, paginate"
LIST="$(get /employees/index.cfm)"
assert_contains "$LIST" "Employee directory" "directory renders"
assert_contains "$LIST" "Aarav Mehta"        "sample data comes from the database"
assert_contains "$LIST" "Showing <strong>1</strong>&ndash;<strong>10</strong>" "first page shows rows 1-10"

R="$(get '/employees/index.cfm?q=aarav')"
assert_contains     "$R" "Aarav Mehta" "search finds a match"
assert_not_contains "$R" "Priya Sharma" "search excludes non-matches"
R="$(get '/employees/index.cfm?q=priya.sharma%40example')"
assert_contains "$R" "Priya Sharma" "search matches email"

R="$(get '/employees/index.cfm?department=Finance&pageSize=50')"
assert_contains     "$R" "Neha Gupta"   "department filter includes members"
assert_not_contains "$R" "Aarav Mehta"  "department filter excludes others"

R="$(get '/employees/index.cfm?status=Inactive&pageSize=50')"
assert_contains     "$R" "Tanvi Menon"  "status filter includes Inactive"
assert_not_contains "$R" "Aarav Mehta"  "status filter excludes Active"

R="$(get '/employees/index.cfm?sort=salary&dir=desc')"
first="$(grep -o 'person-name">[^<]*' <<<"$R" | head -1 | sed 's/person-name">//')"
assert_eq "$first" "Kavya Subramanian" "sort by salary desc puts highest salary first"
R="$(get '/employees/index.cfm?sort=name&dir=asc')"
first="$(grep -o 'person-name">[^<]*' <<<"$R" | head -1 | sed 's/person-name">//')"
assert_eq "$first" "Aarav Mehta" "sort by name asc"
R="$(get '/employees/index.cfm?sort=name&dir=desc')"
first="$(grep -o 'person-name">[^<]*' <<<"$R" | head -1 | sed 's/person-name">//')"
assert_eq "$first" "Zoya Khan" "sort by name desc"

R="$(get '/employees/index.cfm?page=2')"
assert_contains "$R" "Showing <strong>11</strong>" "page 2 starts at row 11"
R="$(get '/employees/index.cfm?pageSize=25&page=99')"
assert_contains "$R" "Showing" "out-of-range page is clamped, not an error"
R="$(get '/employees/index.cfm?q=zzzz-no-such-person')"
assert_contains "$R" "No employees match your filters" "empty state for no matches"

R="$(get '/employees/index.cfm?q=50%25')"
assert_contains "$R" "No employees match" "LIKE wildcards in search are treated literally"

# ---- 3. Create ---------------------------------------------------------------------
section "3. Create"
assert_eq "$(code /employees/form.cfm)" "200" "add form renders"
TOKEN="$(token /employees/form.cfm)"
[ -n "$TOKEN" ] && ok "form carries a CSRF token" || bad "form carries a CSRF token"

out="$(post /employees/save.cfm --data-urlencode "csrf_token=$TOKEN" --data-urlencode "id=0" "${valid_fields[@]}")"
NEWID="$(sed -n 's/.*view.cfm?id=\([0-9]*\).*/\1/p' <<<"$out")"
[ -n "$NEWID" ] && ok "valid create redirects to the new profile (id $NEWID)" || bad "valid create redirects to profile" "$out"

PROFILE="$(get "/employees/view.cfm?id=$NEWID")"
assert_contains "$PROFILE" "Edgar Tester"        "profile shows name"
assert_contains "$PROFILE" "e2e.$STAMP"      "profile shows email"
assert_contains "$PROFILE" "Quality Assurance" "profile shows department"
assert_contains "$PROFILE" "Test Engineer"     "profile shows job title"
assert_contains "$PROFILE" "123,456.50"        "profile shows formatted salary"
assert_contains "$PROFILE" "March 15, 2024"    "profile shows joining date"
assert_contains "$PROFILE" "was added to the directory" "success notification shown after create"

# ---- 4. Validation & unique email ----------------------------------------------------
section "4. Validation and unique email"
TOKEN="$(token /employees/form.cfm)"
out="$(post /employees/save.cfm --data-urlencode "csrf_token=$TOKEN" --data-urlencode "id=0" "${valid_fields[@]}")"
assert_contains "$out" "form.cfm" "duplicate email is rejected (redirect back to form)"
FORM="$(get /employees/form.cfm)"
assert_contains "$FORM" "already exists" "duplicate email message is shown"
assert_contains "$FORM" "Edgar Tester"     "entered values are preserved after an error"

DUPCASE="$(tr 'a-z' 'A-Z' <<<"$EMAIL")"
TOKEN="$(token /employees/form.cfm)"
post /employees/save.cfm --data-urlencode "csrf_token=$TOKEN" --data-urlencode "id=0" --data-urlencode "name=Case Dup" --data-urlencode "email=$DUPCASE" \
     --data-urlencode "department=QA" --data-urlencode "job_title=Tester" --data-urlencode "joining_date=2024-03-15" --data-urlencode "status=Active" >/dev/null
assert_contains "$(get /employees/form.cfm)" "already exists" "duplicate email check is case-insensitive"

TOKEN="$(token /employees/form.cfm)"
post /employees/save.cfm --data-urlencode "csrf_token=$TOKEN" --data-urlencode "id=0" --data-urlencode "name=" --data-urlencode "email=not-an-email" \
     --data-urlencode "phone=abc" --data-urlencode "department=" --data-urlencode "job_title=" --data-urlencode "salary=-5" \
     --data-urlencode "joining_date=2024-02-30" --data-urlencode "status=Bogus" >/dev/null
FORM="$(get /employees/form.cfm)"
assert_contains "$FORM" "Full name is required."        "required: name"
assert_contains "$FORM" "Enter a valid email address"   "invalid email"
assert_contains "$FORM" "Enter a valid phone number"    "invalid phone"
assert_contains "$FORM" "Department is required."       "required: department"
assert_contains "$FORM" "Job title is required."        "required: job title"
assert_contains "$FORM" "Salary must be a positive number" "invalid salary"
assert_contains "$FORM" "Enter a valid date."           "impossible date (Feb 30) rejected"
assert_contains "$FORM" "Choose a valid employment status." "invalid status"

TOKEN="$(token /employees/form.cfm)"
post /employees/save.cfm --data-urlencode "csrf_token=$TOKEN" --data-urlencode "id=0" --data-urlencode "name=<script>alert(1)</script>" --data-urlencode "email=x$STAMP@example.com" \
     --data-urlencode "department=<b>Ops</b>" --data-urlencode "job_title=Tester" --data-urlencode "joining_date=2024-03-15" --data-urlencode "status=Active" >/dev/null
FORM="$(get /employees/form.cfm)"
assert_contains     "$FORM" "Name may contain letters" "HTML in name is rejected"
assert_contains     "$FORM" "Department contains invalid characters" "HTML in department is rejected"
assert_not_contains "$FORM" "<script>alert(1)</script>" "rejected input is never echoed unescaped"

TOKEN="$(token /employees/form.cfm)"
post /employees/save.cfm --data-urlencode "csrf_token=$TOKEN" --data-urlencode "id=0" --data-urlencode "name=Far Future" --data-urlencode "email=ff$STAMP@example.com" \
     --data-urlencode "department=QA" --data-urlencode "job_title=Tester" --data-urlencode "joining_date=2099-01-01" --data-urlencode "status=Active" >/dev/null
assert_contains "$(get /employees/form.cfm)" "more than a year in the future" "far-future joining date rejected"

TOKEN="$(token /employees/form.cfm)"
LONG="$(printf 'a%.0s' $(seq 1 101))"
post /employees/save.cfm --data-urlencode "csrf_token=$TOKEN" --data-urlencode "id=0" --data-urlencode "name=$LONG" --data-urlencode "email=ln$STAMP@example.com" \
     --data-urlencode "department=QA" --data-urlencode "job_title=Tester" --data-urlencode "joining_date=2024-03-15" --data-urlencode "status=Active" >/dev/null
assert_contains "$(get /employees/form.cfm)" "between 2 and 100 characters" "over-length name rejected"

assert_eq "$(find_id "Case%20Dup")" "" "no rejected record was persisted"

# ---- 5. CSRF and HTTP method protection ----------------------------------------------
section "5. CSRF and POST-only enforcement"
out="$(post /employees/save.cfm --data-urlencode "id=0" "${valid_fields[@]}" --data-urlencode "email=csrf$STAMP@example.com")"
assert_contains "$(get /employees/form.cfm)" "could not be verified" "POST without CSRF token is rejected"
assert_eq "$(find_id "csrf$STAMP")" "" "record was NOT created without a CSRF token"

out="$(post /employees/save.cfm --data-urlencode "csrf_token=deadbeef" --data-urlencode "id=0" "${valid_fields[@]}" --data-urlencode "email=csrf2$STAMP@example.com")"
assert_eq "$(find_id "csrf2$STAMP")" "" "POST with a forged CSRF token is rejected"

get "/employees/save.cfm?name=GetCreate&email=get$STAMP@example.com&department=QA&job_title=T&joining_date=2024-01-01&status=Active" >/dev/null
assert_eq "$(find_id "get$STAMP")" "" "GET cannot create an employee"

# a second client (no session) cannot reuse a token from another session
OTHER_JAR="$(mktemp)"
out="$(curl -s -o /dev/null -w '%{http_code}' -b "$OTHER_JAR" -c "$OTHER_JAR" -X POST "$BASE_URL/employees/save.cfm" --data-urlencode "csrf_token=$TOKEN" --data-urlencode "id=0" "${valid_fields[@]}" --data-urlencode "email=other$STAMP@example.com")"
rm -f "$OTHER_JAR"
assert_eq "$(find_id "other$STAMP")" "" "a token from another session is rejected"

# ---- 6. Update -------------------------------------------------------------------------
section "6. Update"
EDIT="$(get "/employees/form.cfm?id=$NEWID")"
assert_contains "$EDIT" "Edit employee"        "edit form renders"
assert_contains "$EDIT" "Edgar Tester"           "edit form is pre-filled from the database"
assert_contains "$EDIT" "value=\"2024-03-15\"" "edit form pre-fills the date"
TOKEN="$(token "/employees/form.cfm?id=$NEWID")"
out="$(post /employees/save.cfm --data-urlencode "csrf_token=$TOKEN" --data-urlencode "id=$NEWID" --data-urlencode "name=Edgar Tester Updated" --data-urlencode "email=$EMAIL" \
     --data-urlencode "phone=" --data-urlencode "department=Quality Assurance" --data-urlencode "job_title=Lead Test Engineer" --data-urlencode "salary=150000" \
     --data-urlencode "joining_date=2024-03-15" --data-urlencode "status=On Leave")"
assert_contains "$out" "view.cfm?id=$NEWID" "valid update redirects to the profile"
PROFILE="$(get "/employees/view.cfm?id=$NEWID")"
assert_contains "$PROFILE" "Edgar Tester Updated"  "updated name persisted"
assert_contains "$PROFILE" "Lead Test Engineer"  "updated job title persisted"
assert_contains "$PROFILE" "On Leave"            "updated status persisted"
assert_contains "$PROFILE" "150,000.00"          "updated salary persisted"
assert_contains "$PROFILE" "was updated successfully" "success notification shown after update"

TOKEN="$(token "/employees/form.cfm?id=$NEWID")"
post /employees/save.cfm --data-urlencode "csrf_token=$TOKEN" --data-urlencode "id=$NEWID" --data-urlencode "name=Edgar Tester Updated" --data-urlencode "email=priya.sharma@example.com" \
     --data-urlencode "department=QA" --data-urlencode "job_title=Tester" --data-urlencode "joining_date=2024-03-15" --data-urlencode "status=Active" >/dev/null
assert_contains "$(get "/employees/form.cfm?id=$NEWID")" "already exists" "update cannot steal another employee's email"
TOKEN="$(token "/employees/form.cfm?id=$NEWID")"
out="$(post /employees/save.cfm --data-urlencode "csrf_token=$TOKEN" --data-urlencode "id=$NEWID" --data-urlencode "name=Edgar Tester Updated" --data-urlencode "email=$EMAIL" \
     --data-urlencode "department=Quality Assurance" --data-urlencode "job_title=Lead Test Engineer" --data-urlencode "joining_date=2024-03-15" --data-urlencode "status=Active")"
assert_contains "$out" "view.cfm?id=$NEWID" "saving an employee with their own unchanged email is allowed"

assert_contains "$(get '/employees/form.cfm?id=99999999')" "could not be found" "editing a non-existent employee is handled"
assert_contains "$(get '/employees/view.cfm?id=99999999')" "could not be found" "viewing a non-existent employee is handled"

# ---- 7. Security: injection and output encoding -------------------------------------
section "7. SQL injection and XSS"
R="$(get "/employees/index.cfm?q=%27%20OR%20%271%27%3D%271")"
assert_contains "$R" "No employees match" "SQL injection in search returns nothing (parameterised)"
R="$(get "/employees/index.cfm?q=x%27%3B%20DROP%20TABLE%20employees%3B%20--")"
assert_contains "$(get /employees/index.cfm)" "Aarav Mehta" "table still intact after injection attempt"
R="$(get "/employees/index.cfm?department=Finance%27%20OR%20%271%27%3D%271")"
assert_contains "$R" "No employees match" "SQL injection in department filter is inert"
R="$(get "/employees/index.cfm?sort=name%3B%20DROP%20TABLE%20employees&dir=asc%3Bx")"
assert_contains "$R" "Aarav Mehta" "sort/dir values are whitelisted"
R="$(get "/employees/view.cfm?id=1%20OR%201%3D1")"
assert_contains "$R" "could not be found" "non-numeric id is not interpreted as SQL"

R="$(get '/employees/index.cfm?q=%3Cscript%3Ealert(1)%3C/script%3E')"
assert_not_contains "$R" "<script>alert(1)" "reflected search term is HTML-encoded"
assert_contains     "$R" "&lt;"  "angle brackets appear HTML-encoded in the page"
R="$(get '/employees/index.cfm?q=%22%20onfocus%3D%22alert(1)')"
assert_not_contains "$R" 'value="" onfocus="alert(1)"' "attribute injection is blocked"

# ---- 8. Headers ------------------------------------------------------------------------
section "8. Security headers and error handling"
HDR="$(curl -s -D - -o /dev/null "$BASE_URL/index.cfm")"
assert_contains "$HDR" "Content-Security-Policy" "CSP header present"
assert_contains "$HDR" "X-Frame-Options: DENY"   "clickjacking protection"
assert_contains "$HDR" "X-Content-Type-Options: nosniff" "nosniff"
assert_contains "$(tr 'A-Z' 'a-z' <<<"$HDR")" "httponly" "session cookie is HttpOnly"
assert_contains "$(tr 'A-Z' 'a-z' <<<"$HDR")" "samesite=lax" "session cookie is SameSite=Lax"
body="$(curl -s "$BASE_URL/employees/view.cfm?id=abc")"
assert_not_contains "$body" "coldfusion.runtime" "no stack traces leak"
assert_not_contains "$body" "password"            "no credentials leak"

# ---- 9. Delete ----------------------------------------------------------------------------
section "9. Delete (confirmation, CSRF, POST-only)"
LIST="$(get "/employees/index.cfm?q=Edgar+Tester")"
assert_contains "$LIST" 'id="deleteModal"'            "confirmation dialog is part of the page"
assert_contains "$LIST" "Yes, delete"                 "confirmation dialog has an explicit confirm button"
assert_contains "$LIST" "data-employee-id=\"$NEWID\"" "delete buttons carry the employee id"

get "/employees/delete.cfm?id=$NEWID" >/dev/null
assert_eq "$(code "/employees/view.cfm?id=$NEWID")" "200" "GET delete does nothing"
post /employees/delete.cfm --data-urlencode "id=$NEWID" >/dev/null
assert_eq "$(code "/employees/view.cfm?id=$NEWID")" "200" "POST delete without CSRF token does nothing"

TOKEN="$(token "/employees/view.cfm?id=$NEWID")"
out="$(post /employees/delete.cfm --data-urlencode "csrf_token=$TOKEN" --data-urlencode "id=$NEWID")"
assert_contains "$out" "employees/index.cfm" "confirmed delete redirects to the directory"
assert_contains "$(get "/employees/index.cfm")" "was deleted" "success notification shown after delete"
assert_contains "$(get "/employees/view.cfm?id=$NEWID")" "could not be found" "deleted employee no longer exists"
assert_eq "$(find_id "$STAMP")" "" "deleted employee is gone from the directory"

TOKEN="$(token /employees/index.cfm)"
post /employees/delete.cfm --data-urlencode "csrf_token=$TOKEN" --data-urlencode "id=99999999" >/dev/null
assert_contains "$(get /employees/index.cfm)" "no longer exists" "deleting a missing employee is handled gracefully"

# ---- Summary ----------------------------------------------------------------------------------
printf '\n\033[1mResult: %d passed, %d failed\033[0m\n' "$PASS" "$FAIL"
if [ "$FAIL" -gt 0 ]; then printf ' - %s\n' "${FAILED[@]}"; exit 1; fi
