# Automata POS System

A comprehensive, desktop-first Point of Sale (POS) application built with Flutter, designed for retail and service businesses.

## 🚀 Features

### 1. Dashboard
- **Real-time Overview**: View total revenue, invoice count, active memberships, and low stock alerts at a glance.
- **Sales Charts**: Interactive weekly and monthly revenue visualizations.
- **Recent Activity**: Quickly access the latest 5 transactions.

### 2. Billing & Invoicing
- **Multi-Mode Support**:
  - **Product Invoice**: Standard retail billing with barcode/SKU support.
  - **Service Invoice**: Billing for labor/services.
  - **Membership Invoice**: Sell and track membership plans.
  - **Advance Payment**: Record partial or full advance payments.
- **Flexible Statuses**: Active (Unpaid), Paid, Partial, Hold, and Cancelled.
- **Tax Management**: Automated GST (CGST/SGST/IGST) calculation based on HSN codes and branch/customer state configurations.
- **Thermal Printing**: Industry-standard 80mm thermal receipt format generation.

### 3. Inventory Management
- **Product Tracking**: SKU, Barcode, Stock Quantity, and Unit management.
- **Services**: Manage service offerings and rates.
- **HSN Master**: Configuring tax rates (GST/Cess) by HSN code.
- **Low Stock Alerts**: Automatic red-flagging of items below threshold (10 units).

### 4. Customer CRM
- **Profiles**: Track customer details, contact info, and "Member Since" data.
- **History**: View complete purchase history and transaction logs per customer.
- **Membership Management**: Track plan expiry and active status.
- **Activity Reports**: Analyze visit frequency and average basket size.

### 5. Reporting & Analytics
- **Sales Summary**: Revenue breakdown by tax, discount, and date range.
- **Customer Activity**: Detailed insight into individual customer behavior.
- **Inventory Status**: Stock valuation and low-stock reports.
- **Responsive UI**: Reports adapt to screen size for optimal viewing.

### 6. Administration
- **Branch Management**: Multi-branch support with distinct GSTIN and address details.
- **User Management**: Role-based access (Admin/POS User) with secure login.
- **Data Export**: Export invoices and reports to PDF/Excel (future).

---

## 🛠️ Technical Architecture

### Tech Stack
- **Framework**: Flutter (Dart)
- **Target Platform**: Windows / Linux
- **State Management**: Provider
- **Database**: SQflite (SQLite FFI for Desktop)
- **PDF Engine**: `pdf` package for receipt generation
- **Security**: `bcrypt` for password hashing

### Database Schema (Key Tables)
The application uses a local SQLite database (`automata.db`).

| Table | Description |
|-------|-------------|
| `invoices` | Core transaction record (Number, Amount, Status, Customer/Branch ID). |
| `invoice_items` | Line items for each invoice (Product/Service ID, Rate, Tax). |
| `products` | Inventory catalog with Stock and Price. |
| `customers` | Client database including Membership info. |
| `hsn_master` | Tax configuration (GST/Cess rates) linked by HSN code. |
| `users` | Auth table with hashed passwords and roles. |
| `branches` | Store locations configuration. |

---

## 💻 Getting Started

### Prerequisites
- Flutter SDK (Latest Stable)
- Visual Studio (with C++ Desktop development workload) for Windows build.

### Installation
1. **Clone the repository**:
   ```bash
   git clone <repo-url>
   cd automata-application
   ```

2. **Install dependencies**:
   ```bash
   flutter pub get
   ```

3. **Run the application**:
   ```bash
   flutter run -d windows
   ```

### Default Credentials
On first launch, a default admin account is created:
- **Username**: `admin`
- **Password**: `admin123`

---

## 📁 Project Structure

```
lib/
├── core/            # Configuration, Themes, DatabaseHelper
├── models/          # Data Models (Invoice, Product, Customer, etc.)
├── providers/       # State Management (POSProvider, AuthProvider)
├── screens/         # UI Screens (Dashboard, POS, Reports, etc.)
│   ├── create_invoices/ # Invoice generation screens
│   ├── reports/         # Analytics and Report wizards
├── services/        # External services (PDF Export, Print)
└── widgets/         # Reusable UI Components
```
