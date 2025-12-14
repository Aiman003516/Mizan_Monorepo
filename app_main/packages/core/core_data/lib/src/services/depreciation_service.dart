// FILE: packages/core/core_data/lib/src/services/depreciation_service.dart
// Purpose: Fixed asset depreciation calculations using methods from Accounting Principles textbook

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core_database/core_database.dart';
import 'package:drift/drift.dart';

/// Depreciation methods as taught in Accounting Principles 13e
enum DepreciationMethod {
  straightLine, // (Cost - Salvage) / Useful Life
  decliningBalance, // Book Value * Rate (often 2x straight-line rate)
  unitsOfActivity, // (Cost - Salvage) / Total Units * Units Used
  sumOfYearsDigits, // (Cost - Salvage) * (Remaining Years / SYD)
  depletion, // (Cost - Salvage) / Total Units * Units Extracted
}

/// Result of depreciation calculation
class DepreciationResult {
  final int annualDepreciation;
  final int monthlyDepreciation;
  final int accumulatedDepreciation;
  final int bookValue;
  final bool isFullyDepreciated;

  const DepreciationResult({
    required this.annualDepreciation,
    required this.monthlyDepreciation,
    required this.accumulatedDepreciation,
    required this.bookValue,
    required this.isFullyDepreciated,
  });
}

/// Service for managing fixed assets and depreciation
class DepreciationService {
  final AppDatabase _db;

  DepreciationService(this._db);

  /// Calculate depreciation using the Straight-Line method
  /// Formula: (Cost - Salvage Value) / Useful Life in Years
  /// From Accounting Principles 13e, Chapter 10
  DepreciationResult calculateStraightLine({
    required int acquisitionCost,
    required int salvageValue,
    required int usefulLifeMonths,
    required int totalDepreciationToDate,
  }) {
    final depreciableBase = acquisitionCost - salvageValue;
    final usefulLifeYears = usefulLifeMonths / 12;
    final annualDepreciation = (depreciableBase / usefulLifeYears).round();
    final monthlyDepreciation = (annualDepreciation / 12).round();

    final maxDepreciation = depreciableBase;
    final newAccumulatedDepreciation =
        (totalDepreciationToDate + annualDepreciation).clamp(
          0,
          maxDepreciation,
        );

    return DepreciationResult(
      annualDepreciation: annualDepreciation,
      monthlyDepreciation: monthlyDepreciation,
      accumulatedDepreciation: newAccumulatedDepreciation,
      bookValue: acquisitionCost - newAccumulatedDepreciation,
      isFullyDepreciated: newAccumulatedDepreciation >= maxDepreciation,
    );
  }

  /// Calculate depreciation using Declining Balance method
  /// Formula: Book Value * Rate (Rate often = 2 / Useful Life for Double-Declining)
  /// From Accounting Principles 13e, Chapter 10
  DepreciationResult calculateDecliningBalance({
    required int acquisitionCost,
    required int salvageValue,
    required int usefulLifeMonths,
    required int totalDepreciationToDate,
    double rate = 2.0, // 2.0 for double-declining balance
  }) {
    final bookValue = acquisitionCost - totalDepreciationToDate;
    final usefulLifeYears = usefulLifeMonths / 12;
    final depreciationRate = rate / usefulLifeYears;

    var annualDepreciation = (bookValue * depreciationRate).round();

    // Cannot depreciate below salvage value
    final maxDepreciation = acquisitionCost - salvageValue;
    if (totalDepreciationToDate + annualDepreciation > maxDepreciation) {
      annualDepreciation = maxDepreciation - totalDepreciationToDate;
    }

    final newAccumulatedDepreciation =
        totalDepreciationToDate + annualDepreciation;

    return DepreciationResult(
      annualDepreciation: annualDepreciation,
      monthlyDepreciation: (annualDepreciation / 12).round(),
      accumulatedDepreciation: newAccumulatedDepreciation,
      bookValue: acquisitionCost - newAccumulatedDepreciation,
      isFullyDepreciated: newAccumulatedDepreciation >= maxDepreciation,
    );
  }

  /// Calculate depreciation using Units-of-Activity method
  /// Formula: ((Cost - Salvage) / Total Units) * Units Used This Period
  /// From Accounting Principles 13e, Chapter 10
  DepreciationResult calculateUnitsOfActivity({
    required int acquisitionCost,
    required int salvageValue,
    required int totalUnitCapacity,
    required int unitsUsedThisPeriod,
    required int totalDepreciationToDate,
  }) {
    final depreciableBase = acquisitionCost - salvageValue;
    final depreciationPerUnit = depreciableBase / totalUnitCapacity;
    var periodDepreciation = (depreciationPerUnit * unitsUsedThisPeriod)
        .round();

    // Cannot depreciate beyond depreciable base
    final maxDepreciation = depreciableBase;
    if (totalDepreciationToDate + periodDepreciation > maxDepreciation) {
      periodDepreciation = maxDepreciation - totalDepreciationToDate;
    }

    final newAccumulatedDepreciation =
        totalDepreciationToDate + periodDepreciation;

    return DepreciationResult(
      annualDepreciation:
          periodDepreciation, // For units-of-activity, this is period depreciation
      monthlyDepreciation: periodDepreciation,
      accumulatedDepreciation: newAccumulatedDepreciation,
      bookValue: acquisitionCost - newAccumulatedDepreciation,
      isFullyDepreciated: newAccumulatedDepreciation >= maxDepreciation,
    );
  }

  /// Calculate depreciation using Sum-of-Years-Digits method
  /// Formula: (Cost - Salvage) × (Remaining Years / Sum of Years Digits)
  /// SYD = n(n+1)/2 where n = useful life in years
  /// Accelerated method that front-loads depreciation
  /// From Accounting Principles 13e, Chapter 10
  DepreciationResult calculateSumOfYearsDigits({
    required int acquisitionCost,
    required int salvageValue,
    required int usefulLifeYears,
    required int currentYear, // Year 1, 2, 3, etc.
    required int totalDepreciationToDate,
  }) {
    final depreciableBase = acquisitionCost - salvageValue;

    // Sum of years digits = n(n+1)/2
    final syd = (usefulLifeYears * (usefulLifeYears + 1)) / 2;

    // Remaining years (at beginning of current year)
    final remainingYears = usefulLifeYears - currentYear + 1;

    // This year's fraction
    final fraction = remainingYears / syd;

    var annualDepreciation = (depreciableBase * fraction).round();

    // Cannot depreciate beyond depreciable base
    final maxDepreciation = depreciableBase;
    if (totalDepreciationToDate + annualDepreciation > maxDepreciation) {
      annualDepreciation = maxDepreciation - totalDepreciationToDate;
    }

    final newAccumulatedDepreciation =
        totalDepreciationToDate + annualDepreciation;

    return DepreciationResult(
      annualDepreciation: annualDepreciation,
      monthlyDepreciation: (annualDepreciation / 12).round(),
      accumulatedDepreciation: newAccumulatedDepreciation,
      bookValue: acquisitionCost - newAccumulatedDepreciation,
      isFullyDepreciated: newAccumulatedDepreciation >= maxDepreciation,
    );
  }

  /// Calculate depletion for natural resources
  /// Formula: ((Cost - Salvage) / Total Estimated Units) × Units Extracted
  /// Used for oil, gas, minerals, timber, etc.
  /// From Accounting Principles 13e, Chapter 10
  DepreciationResult calculateDepletion({
    required int totalCost,
    required int salvageValue,
    required int estimatedTotalUnits,
    required int unitsExtractedThisPeriod,
    required int totalDepletionToDate,
  }) {
    final depletableBase = totalCost - salvageValue;

    // Depletion rate per unit
    final depletionPerUnit = depletableBase / estimatedTotalUnits;

    var periodDepletion = (depletionPerUnit * unitsExtractedThisPeriod).round();

    // Cannot deplete beyond depletable base
    final maxDepletion = depletableBase;
    if (totalDepletionToDate + periodDepletion > maxDepletion) {
      periodDepletion = maxDepletion - totalDepletionToDate;
    }

    final newAccumulatedDepletion = totalDepletionToDate + periodDepletion;

    return DepreciationResult(
      annualDepreciation: periodDepletion, // Period depletion
      monthlyDepreciation: periodDepletion, // Same for depletion
      accumulatedDepreciation: newAccumulatedDepletion,
      bookValue: totalCost - newAccumulatedDepletion,
      isFullyDepreciated: newAccumulatedDepletion >= maxDepletion,
    );
  }

  /// Record a new fixed asset
  Future<FixedAsset> recordAsset({
    required String name,
    String? description,
    required String assetAccountId,
    required String accumulatedDepreciationAccountId,
    required String depreciationExpenseAccountId,
    required int acquisitionCost,
    required int salvageValue,
    required DateTime acquisitionDate,
    required int usefulLifeMonths,
    required DepreciationMethod method,
    double decliningBalanceRate = 2.0,
    int? usefulLifeUnits,
  }) async {
    return await _db
        .into(_db.fixedAssets)
        .insertReturning(
          FixedAssetsCompanion.insert(
            name: name,
            description: Value(description),
            assetAccountId: assetAccountId,
            accumulatedDepreciationAccountId: accumulatedDepreciationAccountId,
            depreciationExpenseAccountId: depreciationExpenseAccountId,
            acquisitionCost: acquisitionCost,
            salvageValue: salvageValue,
            acquisitionDate: acquisitionDate,
            usefulLifeMonths: usefulLifeMonths,
            depreciationMethod: method.name.toUpperCase(),
            decliningBalanceRate: Value(decliningBalanceRate),
            usefulLifeUnits: Value(usefulLifeUnits),
          ),
        );
  }

  /// Process depreciation for a single asset and record journal entry
  Future<DepreciationResult> processDepreciation({
    required String assetId,
    required DateTime periodEndDate,
    int? unitsUsedThisPeriod, // Required for units-of-activity
  }) async {
    final asset = await (_db.select(
      _db.fixedAssets,
    )..where((t) => t.id.equals(assetId))).getSingle();

    if (asset.status != 'ACTIVE') {
      throw StateError('Asset is not active: ${asset.status}');
    }

    // Calculate depreciation based on method
    DepreciationResult result;
    switch (asset.depreciationMethod) {
      case 'STRAIGHT_LINE':
        result = calculateStraightLine(
          acquisitionCost: asset.acquisitionCost,
          salvageValue: asset.salvageValue,
          usefulLifeMonths: asset.usefulLifeMonths,
          totalDepreciationToDate: asset.totalDepreciation,
        );
        break;
      case 'DECLINING_BALANCE':
        result = calculateDecliningBalance(
          acquisitionCost: asset.acquisitionCost,
          salvageValue: asset.salvageValue,
          usefulLifeMonths: asset.usefulLifeMonths,
          totalDepreciationToDate: asset.totalDepreciation,
          rate: asset.decliningBalanceRate ?? 2.0,
        );
        break;
      case 'UNITS_OF_ACTIVITY':
        if (unitsUsedThisPeriod == null) {
          throw ArgumentError(
            'Units used is required for units-of-activity method',
          );
        }
        result = calculateUnitsOfActivity(
          acquisitionCost: asset.acquisitionCost,
          salvageValue: asset.salvageValue,
          totalUnitCapacity: asset.usefulLifeUnits ?? 1,
          unitsUsedThisPeriod: unitsUsedThisPeriod,
          totalDepreciationToDate: asset.totalDepreciation,
        );
        break;
      default:
        throw ArgumentError(
          'Unknown depreciation method: ${asset.depreciationMethod}',
        );
    }

    // Create journal entry: Debit Depreciation Expense, Credit Accumulated Depreciation
    final transaction = await _db
        .into(_db.transactions)
        .insertReturning(
          TransactionsCompanion.insert(
            description: 'Depreciation: ${asset.name}',
            transactionDate: periodEndDate,
            isAdjustment: const Value(true),
          ),
        );

    // Debit Depreciation Expense
    await _db
        .into(_db.transactionEntries)
        .insert(
          TransactionEntriesCompanion.insert(
            transactionId: transaction.id,
            accountId: asset.depreciationExpenseAccountId,
            amount: result.annualDepreciation,
          ),
        );

    // Credit Accumulated Depreciation
    await _db
        .into(_db.transactionEntries)
        .insert(
          TransactionEntriesCompanion.insert(
            transactionId: transaction.id,
            accountId: asset.accumulatedDepreciationAccountId,
            amount: -result.annualDepreciation,
          ),
        );

    // Update asset record
    await (_db.update(
      _db.fixedAssets,
    )..where((t) => t.id.equals(assetId))).write(
      FixedAssetsCompanion(
        totalDepreciation: Value(result.accumulatedDepreciation),
        currentPeriodDepreciation: Value(result.annualDepreciation),
        unitsUsed: Value(asset.unitsUsed + (unitsUsedThisPeriod ?? 0)),
        status: Value(
          result.isFullyDepreciated ? 'FULLY_DEPRECIATED' : 'ACTIVE',
        ),
        lastUpdated: Value(DateTime.now()),
      ),
    );

    return result;
  }

  /// Dispose of an asset (sale, retirement, etc.)
  Future<void> disposeAsset({
    required String assetId,
    required DateTime disposalDate,
    required int proceedsFromSale,
    required String cashAccountId,
    required String gainLossAccountId,
  }) async {
    final asset = await (_db.select(
      _db.fixedAssets,
    )..where((t) => t.id.equals(assetId))).getSingle();

    final bookValue = asset.acquisitionCost - asset.totalDepreciation;
    final gainOrLoss = proceedsFromSale - bookValue;

    // Create disposal journal entry
    final transaction = await _db
        .into(_db.transactions)
        .insertReturning(
          TransactionsCompanion.insert(
            description: 'Disposal: ${asset.name}',
            transactionDate: disposalDate,
          ),
        );

    // Debit Cash for proceeds
    await _db
        .into(_db.transactionEntries)
        .insert(
          TransactionEntriesCompanion.insert(
            transactionId: transaction.id,
            accountId: cashAccountId,
            amount: proceedsFromSale,
          ),
        );

    // Debit Accumulated Depreciation (remove balance)
    await _db
        .into(_db.transactionEntries)
        .insert(
          TransactionEntriesCompanion.insert(
            transactionId: transaction.id,
            accountId: asset.accumulatedDepreciationAccountId,
            amount: asset.totalDepreciation,
          ),
        );

    // Credit Asset Account (remove from books)
    await _db
        .into(_db.transactionEntries)
        .insert(
          TransactionEntriesCompanion.insert(
            transactionId: transaction.id,
            accountId: asset.assetAccountId,
            amount: -asset.acquisitionCost,
          ),
        );

    // Record gain or loss
    await _db
        .into(_db.transactionEntries)
        .insert(
          TransactionEntriesCompanion.insert(
            transactionId: transaction.id,
            accountId: gainLossAccountId,
            amount: -gainOrLoss, // Credit for gain, Debit for loss
          ),
        );

    // Update asset status
    await (_db.update(
      _db.fixedAssets,
    )..where((t) => t.id.equals(assetId))).write(
      FixedAssetsCompanion(
        status: const Value('DISPOSED'),
        disposalDate: Value(disposalDate),
        lastUpdated: Value(DateTime.now()),
      ),
    );
  }

  /// Get all active fixed assets
  Future<List<FixedAsset>> getActiveAssets() async {
    return await (_db.select(
      _db.fixedAssets,
    )..where((t) => t.status.equals('ACTIVE'))).get();
  }

  /// Get asset depreciation schedule (projected depreciation over useful life)
  List<DepreciationResult> getDepreciationSchedule(FixedAsset asset) {
    final schedule = <DepreciationResult>[];
    int accumulated = 0;
    final usefulLifeYears = (asset.usefulLifeMonths / 12).ceil();

    for (var year = 0; year < usefulLifeYears; year++) {
      DepreciationResult result;

      switch (asset.depreciationMethod) {
        case 'STRAIGHT_LINE':
          result = calculateStraightLine(
            acquisitionCost: asset.acquisitionCost,
            salvageValue: asset.salvageValue,
            usefulLifeMonths: asset.usefulLifeMonths,
            totalDepreciationToDate: accumulated,
          );
          break;
        case 'DECLINING_BALANCE':
          result = calculateDecliningBalance(
            acquisitionCost: asset.acquisitionCost,
            salvageValue: asset.salvageValue,
            usefulLifeMonths: asset.usefulLifeMonths,
            totalDepreciationToDate: accumulated,
            rate: asset.decliningBalanceRate ?? 2.0,
          );
          break;
        default:
          continue; // Units-of-activity requires actual usage data
      }

      schedule.add(result);
      accumulated = result.accumulatedDepreciation;

      if (result.isFullyDepreciated) break;
    }

    return schedule;
  }
}

/// Provider for DepreciationService
final depreciationServiceProvider = Provider<DepreciationService>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return DepreciationService(db);
});
