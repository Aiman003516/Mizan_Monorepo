# Mizan Accounting Engine - User Guide

A guide to the new accounting features in Mizan.

---

## New Features Overview

| Feature | Description | Access |
|---------|-------------|--------|
| Fixed Assets | Track equipment, vehicles, property | Settings → Fixed Assets |
| Depreciation | Calculate asset depreciation | Settings → Depreciation |
| Ghost Money | Reconcile rounding differences | Settings → Ghost Money |
| Multi-Currency | Foreign currency support | Settings → Currency Options |

---

## Fixed Assets Dashboard

The Fixed Assets screen provides a comprehensive view of your fixed asset portfolio.

### Dashboard Elements

**Summary Cards** (top section):
- **Net Book Value** - Total assets minus accumulated depreciation
- **Active** - Currently depreciating assets
- **Fully Depreciated** - Assets with zero remaining value
- **Disposed** - Sold or retired assets

**Tabs**:
1. **All Assets** - Complete list with depreciation progress
2. **By Category** - Grouped by depreciation method
3. **Schedule** - Upcoming depreciation with monthly amounts

### Adding an Asset

1. Tap the **+ Add Asset** button
2. Enter asset details:
   - Name and description
   - Acquisition cost and date
   - Salvage value (expected value at end of life)
   - Useful life in months
   - Depreciation method

### Asset Details

Tap any asset to view:
- Depreciation progress bar
- Value breakdown (cost, depreciation, book value)
- Depreciation settings
- Action buttons (Run Depreciation, Dispose)

---

## Depreciation Processing

Process depreciation for multiple assets at once.

### Running Batch Depreciation

1. Go to **Settings → Depreciation**
2. Set the **Period End Date**
3. Review the asset list with monthly amounts
4. Tap **Run All** to process all active assets

### Depreciation Methods

| Method | Calculation | Best For |
|--------|-------------|----------|
| Straight-Line | (Cost - Salvage) ÷ Useful Life | Most assets |
| Declining Balance | Book Value × Rate | Assets losing value quickly |
| Units of Activity | (Cost - Salvage) × (Units Used ÷ Total Units) | Equipment by usage |

---

## Ghost Money Reconciliation

Ghost money represents tiny rounding differences from:
- Splitting bills (e.g., $100 ÷ 3)
- Currency conversions
- Percentage calculations

### Viewing Ghost Money

1. Go to **Settings → Ghost Money**
2. View summary cards by currency
3. See individual entries with source and amount

### Reconciling

- **Individual**: Tap an entry to reconcile it
- **By Currency**: Tap a summary card → Reconcile all entries for that currency

---

## Chart of Accounts (Enhanced)

The Chart of Accounts now displays accounts in a hierarchical tree structure.

### Account Hierarchy

Accounts are organized by type:
- **Assets** (blue) - Cash, receivables, inventory, fixed assets
- **Liabilities** (red) - Payables, loans, accrued expenses
- **Equity** (purple) - Owner's capital, retained earnings
- **Revenue** (green) - Sales, service income
- **Expenses** (orange) - Operating expenses, COGS

### Expanding/Collapsing

- Tap the arrow (▶) to expand parent accounts
- Tap again (▼) to collapse
- Balances roll up to parent accounts

---

## Financial Reports Integration

New features are now integrated into financial reports.

### Balance Sheet

The Balance Sheet now includes:
- **Fixed Assets Summary** - Net book value of all fixed assets
- Accumulated depreciation totals

### Income Statement

Enhanced with:
- **Accruals Summary** - Prepaid expenses, accrued liabilities
- Depreciation expense by category

---

## Tips & Best Practices

### Fixed Assets
- ✅ Add salvage value for more accurate depreciation
- ✅ Use straight-line for simplicity
- ✅ Run monthly depreciation for accurate reports

### Ghost Money
- ✅ Reconcile periodically (monthly/quarterly)
- ✅ Small amounts are normal - typically a few cents
- ✅ Large amounts may indicate data issues

### Currency
- ✅ Set exchange rates before transactions
- ✅ Revalue foreign balances at period end
- ✅ Track exchange gains/losses separately

---

## Troubleshooting

| Issue | Solution |
|-------|----------|
| Asset not depreciating | Check status is 'Active' and useful life remaining |
| Ghost money growing | Reconcile more frequently |
| Balance Sheet imbalance | Run depreciation to update accumulated depreciation |
| Exchange rate missing | Add rate in Settings → Currency Options |

---

## Getting Help

For additional assistance:
1. Check the API Reference for technical details
2. Review unit tests for service examples
3. Contact support for accounting questions
