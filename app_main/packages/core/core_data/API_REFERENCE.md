# Mizan Accounting Services - API Reference

This document provides API reference for all core accounting services in the Mizan accounting engine.

---

## Table of Contents
- [JournalEntryService](#journalentryservice)
- [DepreciationService](#depreciationservice)
- [CurrencyService](#currencyservice)
- [GhostMoneyService](#ghostmoneyservice)
- [InventoryCostingService](#inventorycostingservice)
- [AccrualsService](#accrualsservice)

---

## JournalEntryService

Handles compound and reversing journal entries with automatic validation.

### Provider
```dart
final journalEntryServiceProvider = Provider<JournalEntryService>((ref) => ...);
```

### Methods

#### `createCompoundEntry`
Creates a compound journal entry with multiple lines.

```dart
Future<JournalEntryResult> createCompoundEntry({
  required String description,
  required List<JournalLine> lines,
  DateTime? date,
  String? currencyCode,
})
```

**Parameters:**
| Name | Type | Required | Description |
|------|------|----------|-------------|
| description | String | ✓ | Entry description |
| lines | List<JournalLine> | ✓ | Debit/credit lines (must balance) |
| date | DateTime | ✗ | Transaction date (defaults to now) |
| currencyCode | String | ✗ | Currency code (defaults to 'Local') |

**Returns:** `JournalEntryResult` with transaction ID and validation status.

#### `createReversingEntry`
Creates a reversing entry that auto-reverses on the specified date.

```dart
Future<JournalEntryResult> createReversingEntry({
  required String description,
  required List<JournalLine> lines,
  required DateTime reversalDate,
})
```

---

## DepreciationService

Calculates and records depreciation using multiple methods.

### Provider
```dart
final depreciationServiceProvider = Provider<DepreciationService>((ref) => ...);
```

### Depreciation Methods
- `STRAIGHT_LINE` - Even distribution over useful life
- `DECLINING_BALANCE` - Accelerated depreciation using rate
- `UNITS_OF_ACTIVITY` - Based on usage/production

### Methods

#### `calculateDepreciation`
Calculates depreciation without recording.

```dart
DepreciationResult calculateDepreciation({
  required int acquisitionCost,
  required int salvageValue,
  required int usefulLifeMonths,
  required String method,
  int? currentPeriodUnits,
  int? totalLifetimeUnits,
  double? decliningBalanceRate,
})
```

**Returns:** `DepreciationResult` with:
- `annualDepreciation` - Yearly depreciation amount
- `monthlyDepreciation` - Monthly depreciation amount
- `accumulatedDepreciation` - Total depreciation to date

#### `processDepreciation`
Calculates and records depreciation for an asset.

```dart
Future<DepreciationResult> processDepreciation({
  required String assetId,
  required DateTime periodEndDate,
})
```

---

## CurrencyService

Multi-currency support with IFRS-compliant revaluation.

### Provider
```dart
final currencyServiceProvider = Provider<CurrencyService>((ref) => ...);
```

### Methods

#### `convertAmount`
Converts amount between currencies.

```dart
int convertAmount({
  required int amount,
  required double fromRate,
  required double toRate,
})
```

#### `revalueForeignBalance`
Revalues foreign currency balance at new exchange rate.

```dart
RevaluationResult revalueForeignBalance({
  required int foreignAmount,
  required double oldRate,
  required double newRate,
})
```

**Returns:** `RevaluationResult` with:
- `newLocalAmount` - Revalued amount in local currency
- `gainOrLoss` - Exchange gain (positive) or loss (negative)
- `isGain` - Boolean indicating gain vs loss

---

## GhostMoneyService

Tracks and reconciles rounding differences (ghost money).

### Provider
```dart
final ghostMoneyServiceProvider = Provider<GhostMoneyService>((ref) => ...);
```

### Source Types
- `TRANSACTION` - General transaction rounding
- `SPLIT` - Bill splitting rounding
- `EXCHANGE` - Currency exchange rounding
- `IMPORT` - Data import rounding

### Methods

#### `recordGhostMoney`
Records a rounding difference.

```dart
Future<void> recordGhostMoney({
  required String sourceType,
  required String sourceId,
  required int amount,
  required String currency,
  required String reason,
})
```

#### `reconcileEntries`
Reconciles ghost money entries by currency.

```dart
Future<int> reconcileEntries({
  required String currencyCode,
})
```

**Returns:** Number of entries reconciled.

---

## InventoryCostingService

Inventory valuation using FIFO, LIFO, and Weighted Average.

### Provider
```dart
final inventoryCostingServiceProvider = Provider<InventoryCostingService>((ref) => ...);
```

### Costing Methods
- `FIFO` - First In, First Out
- `LIFO` - Last In, First Out
- `WEIGHTED_AVERAGE` - Weighted average cost

### Methods

#### `calculateCostOfGoodsSold`
Calculates COGS for a sale.

```dart
CostingResult calculateCostOfGoodsSold({
  required List<InventoryLayer> layers,
  required double quantitySold,
  required String method,
})
```

**Returns:** `CostingResult` with:
- `costOfGoodsSold` - Total COGS amount
- `layerUsages` - Breakdown by layer
- `remainingLayers` - Updated inventory layers

#### `applyLowerOfCostOrMarket`
Applies LCM valuation rule.

```dart
LcmResult applyLowerOfCostOrMarket({
  required int carryingValue,
  required int marketValue,
})
```

---

## AccrualsService

Manages accruals and deferrals for matching principle compliance.

### Provider
```dart
final accrualsServiceProvider = Provider<AccrualsService>((ref) => ...);
```

### Accrual Types
- `PREPAID_EXPENSE` - Paid ahead, expense over time
- `ACCRUED_EXPENSE` - Incurred, paid later
- `DEFERRED_REVENUE` - Received ahead, earned over time
- `ACCRUED_REVENUE` - Earned, received later

### Methods

#### `calculatePrepaidAmortization`
Calculates amortization for prepaid expenses.

```dart
AmortizationResult calculatePrepaidAmortization({
  required int totalAmount,
  required DateTime startDate,
  required int periodMonths,
  required DateTime asOfDate,
})
```

**Returns:** `AmortizationResult` with:
- `amortizedAmount` - Amount expensed to date
- `remainingBalance` - Unexpired portion
- `monthsElapsed` - Periods completed

#### `calculateAccruedExpense`
Calculates accrued expense for a period.

```dart
int calculateAccruedExpense({
  required int annualAmount,
  required DateTime periodStart,
  required DateTime periodEnd,
})
```

---

## Data Models

### JournalLine
```dart
class JournalLine {
  final String accountId;
  final int amount;  // Positive = Debit, Negative = Credit
  final String? memo;
}
```

### InventoryLayer
```dart
class InventoryLayer {
  final DateTime date;
  final double quantity;
  final int unitCost;  // In cents
}
```

### DepreciationResult
```dart
class DepreciationResult {
  final int annualDepreciation;
  final int monthlyDepreciation;
  final int accumulatedDepreciation;
  final int netBookValue;
}
```

---

## Amount Handling

All monetary amounts are stored as **integers representing the smallest currency unit** (cents, fils, etc.) to avoid floating-point precision issues.

```dart
// Store $100.50 as 10050 cents
final amount = 10050;

// Display as formatted currency
final display = (amount / 100).toStringAsFixed(2);  // "100.50"
```

---

## Error Handling

All services throw descriptive exceptions for invalid operations:

```dart
try {
  await journalEntryService.createCompoundEntry(...);
} catch (e) {
  // Handle validation errors, database errors, etc.
  print('Error: $e');
}
```

Common exceptions:
- `UnbalancedEntryException` - Debits don't equal credits
- `InvalidAccountException` - Account not found
- `InsufficientInventoryException` - Not enough inventory for sale
