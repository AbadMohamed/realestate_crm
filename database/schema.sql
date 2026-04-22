-- ============================================================
-- Real Estate CRM Database Schema
-- MySQL 8.0+
-- ============================================================

CREATE DATABASE IF NOT EXISTS realestate_crm CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE realestate_crm;

-- ============================================================
-- USERS
-- ============================================================
CREATE TABLE users (
  id          INT AUTO_INCREMENT PRIMARY KEY,
  username    VARCHAR(100) NOT NULL UNIQUE,
  email       VARCHAR(150) NOT NULL UNIQUE,
  password    VARCHAR(255) NOT NULL,         -- bcrypt hash
  full_name   VARCHAR(200) NOT NULL,
  role        ENUM('admin','staff') NOT NULL DEFAULT 'staff',
  is_active   TINYINT(1) NOT NULL DEFAULT 1,
  created_at  DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at  DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

-- ============================================================
-- PROJECTS
-- ============================================================
CREATE TABLE projects (
  id          INT AUTO_INCREMENT PRIMARY KEY,
  name        VARCHAR(200) NOT NULL UNIQUE,
  location    VARCHAR(300),
  description TEXT,
  start_date  DATE,
  status      ENUM('active','completed','on_hold') NOT NULL DEFAULT 'active',
  created_by  INT,
  created_at  DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at  DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  FOREIGN KEY (created_by) REFERENCES users(id) ON DELETE SET NULL
);

-- ============================================================
-- PLOTS
-- ============================================================
CREATE TABLE plots (
  id                   INT AUTO_INCREMENT PRIMARY KEY,
  project_id           INT NOT NULL,
  plot_number          VARCHAR(100) NOT NULL,
  size_sqm             DECIMAL(10,2),
  cash_price           DECIMAL(15,2) NOT NULL,
  installment_price    DECIMAL(15,2) NOT NULL,
  installment_duration INT NOT NULL COMMENT 'months',
  monthly_installment  DECIMAL(15,2) NOT NULL,
  status               ENUM('available','reserved','sold') NOT NULL DEFAULT 'available',
  notes                TEXT,
  created_at           DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at           DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY uq_project_plot (project_id, plot_number),
  FOREIGN KEY (project_id) REFERENCES projects(id) ON DELETE RESTRICT
);

-- ============================================================
-- CLIENTS
-- ============================================================
CREATE TABLE clients (
  id          INT AUTO_INCREMENT PRIMARY KEY,
  full_name   VARCHAR(200) NOT NULL,
  phone       VARCHAR(20)  NOT NULL UNIQUE,
  nida        VARCHAR(50)  UNIQUE,
  address     TEXT,
  email       VARCHAR(150),
  notes       TEXT,
  created_by  INT,
  created_at  DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at  DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  FOREIGN KEY (created_by) REFERENCES users(id) ON DELETE SET NULL
);

-- ============================================================
-- SALES
-- ============================================================
CREATE TABLE sales (
  id            INT AUTO_INCREMENT PRIMARY KEY,
  client_id     INT NOT NULL,
  plot_id       INT NOT NULL UNIQUE,          -- one plot → one sale only
  payment_type  ENUM('cash','installment') NOT NULL,
  sale_date     DATE NOT NULL,
  total_amount  DECIMAL(15,2) NOT NULL,
  created_by    INT,
  created_at    DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (client_id)  REFERENCES clients(id) ON DELETE RESTRICT,
  FOREIGN KEY (plot_id)    REFERENCES plots(id)   ON DELETE RESTRICT,
  FOREIGN KEY (created_by) REFERENCES users(id)   ON DELETE SET NULL
);

-- ============================================================
-- INVOICES
-- ============================================================
CREATE TABLE invoices (
  id              INT AUTO_INCREMENT PRIMARY KEY,
  invoice_number  VARCHAR(50) NOT NULL UNIQUE,
  sale_id         INT NOT NULL UNIQUE,
  client_id       INT NOT NULL,
  payment_type    ENUM('cash','installment') NOT NULL,
  total_amount    DECIMAL(15,2) NOT NULL,
  paid_amount     DECIMAL(15,2) NOT NULL DEFAULT 0,
  balance         DECIMAL(15,2) GENERATED ALWAYS AS (total_amount - paid_amount) STORED,
  payment_status  ENUM('unpaid','partial','paid') NOT NULL DEFAULT 'unpaid',
  issued_date     DATE NOT NULL,
  due_date        DATE,
  notes           TEXT,
  created_at      DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at      DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  FOREIGN KEY (sale_id)   REFERENCES sales(id)   ON DELETE RESTRICT,
  FOREIGN KEY (client_id) REFERENCES clients(id) ON DELETE RESTRICT
);

-- ============================================================
-- PAYMENTS
-- ============================================================
CREATE TABLE payments (
  id             INT AUTO_INCREMENT PRIMARY KEY,
  invoice_id     INT NOT NULL,
  client_id      INT NOT NULL,
  amount         DECIMAL(15,2) NOT NULL,
  payment_date   DATE NOT NULL,
  receipt_number VARCHAR(100),
  method         ENUM('cash','bank_transfer','mobile_money','cheque') DEFAULT 'cash',
  notes          TEXT,
  recorded_by    INT,
  created_at     DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (invoice_id)   REFERENCES invoices(id) ON DELETE RESTRICT,
  FOREIGN KEY (client_id)    REFERENCES clients(id)  ON DELETE RESTRICT,
  FOREIGN KEY (recorded_by)  REFERENCES users(id)    ON DELETE SET NULL
);

-- ============================================================
-- INSTALLMENT SCHEDULE
-- ============================================================
CREATE TABLE installment_schedule (
  id              INT AUTO_INCREMENT PRIMARY KEY,
  sale_id         INT NOT NULL,
  invoice_id      INT NOT NULL,
  month_number    INT NOT NULL,
  due_date        DATE NOT NULL,
  expected_amount DECIMAL(15,2) NOT NULL,
  paid_amount     DECIMAL(15,2) NOT NULL DEFAULT 0,
  status          ENUM('pending','partial','paid','overdue','advance') NOT NULL DEFAULT 'pending',
  updated_at      DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  FOREIGN KEY (sale_id)    REFERENCES sales(id)    ON DELETE CASCADE,
  FOREIGN KEY (invoice_id) REFERENCES invoices(id) ON DELETE CASCADE
);

-- ============================================================
-- INDEXES for performance
-- ============================================================
CREATE INDEX idx_plots_project   ON plots(project_id, status);
CREATE INDEX idx_sales_client    ON sales(client_id);
CREATE INDEX idx_invoices_client ON invoices(client_id, payment_status);
CREATE INDEX idx_payments_invoice ON payments(invoice_id);
CREATE INDEX idx_installments_due ON installment_schedule(due_date, status);

-- ============================================================
-- SEED: default admin user  (password: Admin@1234)
-- ============================================================
INSERT INTO users (username, email, password, full_name, role) VALUES
('admin', 'admin@realestate.com',
 '$2b$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi',
 'System Administrator', 'admin');
