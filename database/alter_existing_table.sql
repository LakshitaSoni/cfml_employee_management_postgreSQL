-- =============================================================================
-- One-time upgrade of an EXISTING table that has only: id, name, email, department
-- Paste into phpMyAdmin > admin_employee_management > SQL tab (or run with the mysql client).
--
-- Table name used below: `employee`.  If your table is called `employees`, replace the
-- name in every statement.  Whatever the name is, set DB_TABLE=<name> in .env.
--
-- BEFORE YOU RUN:
--   1. Take a backup (phpMyAdmin > Export).
--   2. Run  SHOW COLUMNS FROM employee;  If any column below already exists, delete that
--      "ADD COLUMN" line from STEP 1 (otherwise MySQL answers "Duplicate column name").
--   3. Existing rows are NOT modified: they get status = 'Active' and NULL in the other new columns.
-- =============================================================================

-- STEP 1: add the new columns ------------------------------------------------
ALTER TABLE `employees`
    ADD COLUMN `phone`        VARCHAR(30)   NULL AFTER `email`,
    ADD COLUMN `job_title`    VARCHAR(100)  NULL AFTER `department`,
    ADD COLUMN `salary`       DECIMAL(12,2) NULL AFTER `job_title`,
    ADD COLUMN `joining_date` DATE          NULL AFTER `salary`,
    ADD COLUMN `status`       ENUM('Active','On Leave','Inactive') NOT NULL DEFAULT 'Active' AFTER `joining_date`,
    ADD COLUMN `created_at`   DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP AFTER `status`,
    ADD COLUMN `updated_at`   DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP AFTER `created_at`,
    ADD KEY `idx_department`   (`department`),
    ADD KEY `idx_status`       (`status`),
    ADD KEY `idx_joining_date` (`joining_date`);

-- STEP 2: check for duplicate emails (must return NO rows before step 3) ---------
SELECT `email`, COUNT(*) AS occurrences
FROM `employees`
GROUP BY `email`
HAVING COUNT(*) > 1;

-- STEP 3: enforce unique emails (skip if step 2 returned rows; fix those first) ----
ALTER TABLE `employees` ADD UNIQUE KEY `uq_employees_email` (`email`);

-- STEP 4: verify ------------------------------------------------------------------
SHOW COLUMNS FROM `employees`;
