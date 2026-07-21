# Mizan App Architecture & Developer Map

This file serves as a comprehensive map of the Mizan monorepo to help developers and AI assistants navigate the codebase efficiently without scanning every folder.

## High-Level Architecture Graph

```mermaid
graph TD
    App[Mizan App Main\napp_main/apps/lib] --> Features
    
    subgraph "Feature Packages (app_main/packages/features)"
        Features --> feature_accounts["feature_accounts (AR/AP)"]
        Features --> feature_contacts["feature_contacts (Suppliers/Customers)"]
        Features --> feature_transactions["feature_transactions"]
        Features --> feature_dashboard["feature_dashboard"]
        Features --> feature_sync["feature_sync (Cloud Backup)"]
        Features --> feature_products["feature_products"]
        Features --> feature_reports["feature_reports"]
        Features --> feature_settings["feature_settings"]
        Features --> feature_auth["feature_auth"]
        Features --> feature_data_import["feature_data_import"]
    end
    
    subgraph "Shared Packages (app_main/packages/shared)"
        feature_accounts --> shared_ui["shared_ui (Common Widgets)"]
        feature_contacts --> shared_ui
        feature_accounts --> shared_services["shared_services (Cross-Feature Logic)"]
    end
    
    subgraph "Core Packages (app_main/packages/core)"
        shared_ui --> core_ui["core_ui (Themes, Colors, Design System)"]
        shared_services --> core_database["core_database (Drift/SQLite Setup)"]
        shared_services --> core_l10n["core_l10n (Translations/Currencies)"]
        shared_services --> core_data["core_data (Base Models)"]
    end
```

## Directory Breakdown

### 1. `app_main/apps/`
* **Purpose:** The main Flutter application entry point. 
* **Key Files:** `lib/main.dart` handles the main routing, bottom navigation bar, and tab structure. It glues all the independent feature packages together.

### 2. `app_main/packages/features/`
Independent feature modules. They should rarely depend on each other directly. If they need to communicate (e.g., Accounts needing to read Contacts), they should do so via `shared_services` or shared data models.
* **`feature_accounts`**: Handles Accounts Receivable (AR) and Accounts Payable (AP), ledgers, and invoice tracking.
* **`feature_contacts`**: Handles Customers and Suppliers.
* **`feature_sync`**: Handles Google Drive/Cloud syncing of the SQLite database.

### 3. `app_main/packages/shared/`
Code that is shared across multiple features.
* **`shared_ui`**: Generic components like custom DataTables, specific dialogs, or dropdowns used by multiple features.
* **`shared_services`**: Business logic or state management that spans multiple features.

### 4. `app_main/packages/core/`
The foundational layer of the app. It does not know about any specific feature.
* **`core_database`**: The SQLite (Drift) schema and database connection setup.
* **`core_ui`**: The pure design system (Colors, Typography, Themes).
* **`core_l10n`**: Localization and currency formatting logic.

## Core Flows
* **Database Access**: Features access the database via repositories provided by `core_database`. 
* **Currencies**: Currencies are handled dynamically using `core_l10n` and the Dart `intl` package. Hardcoded currency symbols (like `$`) should be avoided.
* **UI/UX Guidelines**: Mizan aims for a premium, highly responsive UI. Avoid generic widgets. Use responsive tables (`SingleChildScrollView` with horizontal scrolling) and dynamic bottom sheets/dropdowns.
