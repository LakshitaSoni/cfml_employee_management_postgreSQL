-- =============================================================================
-- Sample employees for testing. Run AFTER schema.sql.
--   pgAdmin: select the admin_employee_management database > Query Tool > paste > F5
--   psql:    psql -U postgres -h 127.0.0.1 -d admin_employee_management -f database/sample_data.sql
--
-- Uses ON CONFLICT DO NOTHING: rows whose email already exists are skipped, so
-- the script can be re-run. Joining dates are relative to today so the dashboard's
-- "recent hires" widgets always have data. All people/emails are fictional.
-- =============================================================================

INSERT INTO employees
    (name, email, phone, department, job_title, salary, joining_date, status)
VALUES
    ('Aarav Mehta',      'aarav.mehta@example.com',      '+91 98765 43210', 'Engineering',      'Senior Software Engineer',  1850000.00, CURRENT_DATE - 2,    'Active'),
    ('Priya Sharma',     'priya.sharma@example.com',     '+91 98765 43211', 'Human Resources',  'HR Business Partner',        1200000.00, CURRENT_DATE - 6,    'Active'),
    ('Rohan Verma',      'rohan.verma@example.com',      '+91 98765 43212', 'Sales',            'Account Executive',           950000.00, CURRENT_DATE - 12,   'Active'),
    ('Ananya Iyer',      'ananya.iyer@example.com',      '+91 98765 43213', 'Design',           'Product Designer',           1400000.00, CURRENT_DATE - 20,   'Active'),
    ('Karthik Nair',     'karthik.nair@example.com',     '+91 98765 43214', 'Engineering',      'DevOps Engineer',            1650000.00, CURRENT_DATE - 27,   'Active'),
    ('Sneha Kulkarni',   'sneha.kulkarni@example.com',   '+91 98765 43215', 'Finance',          'Financial Analyst',          1100000.00, CURRENT_DATE - 45,   'Active'),
    ('Vikram Singh',     'vikram.singh@example.com',     '+91 98765 43216', 'Operations',       'Operations Manager',         1750000.00, CURRENT_DATE - 80,   'Active'),
    ('Meera Reddy',      'meera.reddy@example.com',      '+91 98765 43217', 'Marketing',        'Content Strategist',          900000.00, CURRENT_DATE - 110,  'Active'),
    ('Arjun Kapoor',     'arjun.kapoor@example.com',     '+91 98765 43218', 'Engineering',      'Backend Developer',          1500000.00, CURRENT_DATE - 150,  'On Leave'),
    ('Divya Pillai',     'divya.pillai@example.com',     '+91 98765 43219', 'Customer Support', 'Support Team Lead',           850000.00, CURRENT_DATE - 200,  'Active'),
    ('Rahul Desai',      'rahul.desai@example.com',      '+91 98765 43220', 'Sales',            'Sales Manager',              1600000.00, CURRENT_DATE - 260,  'Active'),
    ('Neha Gupta',       'neha.gupta@example.com',       '+91 98765 43221', 'Finance',          'Accounts Manager',           1300000.00, CURRENT_DATE - 320,  'Active'),
    ('Siddharth Rao',    'siddharth.rao@example.com',    '+91 98765 43222', 'Engineering',      'QA Engineer',                1000000.00, CURRENT_DATE - 400,  'Active'),
    ('Pooja Bhatt',      'pooja.bhatt@example.com',      '+91 98765 43223', 'Human Resources',  'Talent Acquisition Lead',    1150000.00, CURRENT_DATE - 450,  'On Leave'),
    ('Manish Joshi',     'manish.joshi@example.com',     '+91 98765 43224', 'Operations',       'Logistics Coordinator',       720000.00, CURRENT_DATE - 520,  'Active'),
    ('Isha Malhotra',    'isha.malhotra@example.com',    '+91 98765 43225', 'Marketing',        'Marketing Director',         2200000.00, CURRENT_DATE - 600,  'Active'),
    ('Nikhil Chawla',    'nikhil.chawla@example.com',    '+91 98765 43226', 'Engineering',      'Engineering Manager',        2800000.00, CURRENT_DATE - 700,  'Active'),
    ('Tanvi Menon',      'tanvi.menon@example.com',      '+91 98765 43227', 'Design',           'UX Researcher',              1050000.00, CURRENT_DATE - 760,  'Inactive'),
    ('Harsh Agarwal',    'harsh.agarwal@example.com',    '+91 98765 43228', 'Customer Support', 'Support Specialist',          560000.00, CURRENT_DATE - 830,  'Inactive'),
    ('Kavya Subramanian','kavya.subramanian@example.com','+91 98765 43229', 'Finance',          'Chief Financial Officer',    4500000.00, CURRENT_DATE - 1500, 'Active'),
    ('Dev Patel',        'dev.patel@example.com',        NULL,              'Sales',            'Business Development Rep',    640000.00, CURRENT_DATE - 900,  'Inactive'),
    ('Zoya Khan',        'zoya.khan@example.com',        '+91 98765 43231', 'Legal',            'Corporate Counsel',          2000000.00, CURRENT_DATE - 1100, 'Active'),
    ('Aditya Bose',      'aditya.bose@example.com',      '+91 98765 43232', 'Engineering',      'Frontend Developer',         1350000.00, CURRENT_DATE - 33,   'Active'),
    ('Riya Banerjee',    'riya.banerjee@example.com',    '+91 98765 43233', 'Legal',            'Compliance Officer',         1450000.00, CURRENT_DATE - 15,   'Active'),
    ('Samuel D''Souza',  'samuel.dsouza@example.com',    '+91 98765 43234', 'Operations',       'Facilities Supervisor',       680000.00, CURRENT_DATE - 1300, 'On Leave')
ON CONFLICT (email) DO NOTHING;

SELECT status, COUNT(*) AS employees FROM employees GROUP BY status;
