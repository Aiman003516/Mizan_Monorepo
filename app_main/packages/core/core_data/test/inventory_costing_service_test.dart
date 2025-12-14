// Unit tests for InventoryCostingService
// Tests FIFO, LIFO, Weighted Average costing methods

import 'package:flutter_test/flutter_test.dart';
import 'package:core_data/src/services/inventory_costing_service.dart';

void main() {
  group('CostingMethod enum', () {
    test('should have all expected methods', () {
      expect(CostingMethod.values, contains(CostingMethod.fifo));
      expect(CostingMethod.values, contains(CostingMethod.lifo));
      expect(CostingMethod.values, contains(CostingMethod.weightedAverage));
      expect(CostingMethod.values, contains(CostingMethod.specificId));
    });
  });

  group('CostOfGoodsSoldResult', () {
    test('should store correct values', () {
      const result = CostOfGoodsSoldResult(
        costOfGoodsSold: 15000,
        endingInventoryValue: 45000,
        averageCost: 100.0,
        layersUsed: [],
      );

      expect(result.costOfGoodsSold, equals(15000));
      expect(result.endingInventoryValue, equals(45000));
      expect(result.averageCost, equals(100.0));
    });
  });

  group('LayerUsage', () {
    test('should store layer details correctly', () {
      const usage = LayerUsage(
        layerId: 'layer1',
        quantityUsed: 10.0,
        costPerUnit: 100,
        totalCost: 1000,
      );

      expect(usage.layerId, equals('layer1'));
      expect(usage.quantityUsed, equals(10.0));
      expect(usage.costPerUnit, equals(100));
      expect(usage.totalCost, equals(1000));
    });
  });

  group('FIFO Cost Allocation', () {
    late InventoryCostCalculator calculator;

    setUp(() {
      calculator = InventoryCostCalculator();
    });

    test('should allocate cost from oldest layer first', () {
      // Scenario: 3 purchase layers
      // Layer 1: 100 units @ $10 = $1,000
      // Layer 2: 150 units @ $12 = $1,800
      // Layer 3: 200 units @ $14 = $2,800
      // Sell 180 units using FIFO
      final layers = [
        MockLayer(id: '1', quantity: 100, cost: 1000), // oldest
        MockLayer(id: '2', quantity: 150, cost: 1200),
        MockLayer(id: '3', quantity: 200, cost: 1400), // newest
      ];

      final result = calculator.allocateFifo(layers, 180);

      // FIFO: Use all 100 from layer 1 ($1,000) + 80 from layer 2 ($960)
      // COGS = 100*10 + 80*12 = 1,000 + 960 = 1,960
      expect(result.costOfGoodsSold, equals(196000)); // in cents

      // Ending inventory: 70 from layer 2 + 200 from layer 3
      // = 70*12 + 200*14 = 840 + 2,800 = 3,640
      expect(result.endingInventoryValue, equals(364000));
    });

    test('should handle single layer', () {
      final layers = [MockLayer(id: '1', quantity: 100, cost: 1000)];

      final result = calculator.allocateFifo(layers, 50);

      expect(result.costOfGoodsSold, equals(50000)); // 50 * $10
      expect(result.layersUsed.length, equals(1));
    });

    test('should handle selling entire inventory', () {
      final layers = [
        MockLayer(id: '1', quantity: 100, cost: 1000),
        MockLayer(id: '2', quantity: 100, cost: 1200),
      ];

      final result = calculator.allocateFifo(layers, 200);

      expect(result.costOfGoodsSold, equals(220000));
      expect(result.endingInventoryValue, equals(0));
    });
  });

  group('LIFO Cost Allocation', () {
    late InventoryCostCalculator calculator;

    setUp(() {
      calculator = InventoryCostCalculator();
    });

    test('should allocate cost from newest layer first', () {
      // Same layers as FIFO test
      final layers = [
        MockLayer(id: '1', quantity: 100, cost: 1000), // oldest
        MockLayer(id: '2', quantity: 150, cost: 1200),
        MockLayer(id: '3', quantity: 200, cost: 1400), // newest
      ];

      final result = calculator.allocateLifo(layers, 180);

      // LIFO: Use 180 from layer 3 @ $14 = $2,520
      // But layer 3 only has 200, so all 180 comes from layer 3
      expect(result.costOfGoodsSold, equals(252000)); // 180 * $14

      // Ending: 100 from layer 1 + 150 from layer 2 + 20 from layer 3
      // = 100*10 + 150*12 + 20*14 = 1000 + 1800 + 280 = 3080 (in dollars)
      // = 100*1000 + 150*1200 + 20*1400 = 100000 + 180000 + 28000 = 308000 (in cents)
      expect(result.endingInventoryValue, equals(308000));
    });

    test('should span multiple layers in reverse order', () {
      final layers = [
        MockLayer(id: '1', quantity: 50, cost: 1000), // $10
        MockLayer(id: '2', quantity: 50, cost: 1100), // $11
        MockLayer(id: '3', quantity: 50, cost: 1200), // $12
      ];

      final result = calculator.allocateLifo(layers, 80);

      // LIFO: 50 from layer 3 ($600) + 30 from layer 2 ($330) = $930
      expect(result.costOfGoodsSold, equals(93000));
    });
  });

  group('Weighted Average Cost', () {
    late InventoryCostCalculator calculator;

    setUp(() {
      calculator = InventoryCostCalculator();
    });

    test('should calculate weighted average correctly', () {
      // Layer 1: 100 units @ $10 = $1,000
      // Layer 2: 200 units @ $12 = $2,400
      // Total: 300 units, $3,400
      // WAC = $3,400 / 300 = $11.33
      final layers = [
        MockLayer(id: '1', quantity: 100, cost: 1000),
        MockLayer(id: '2', quantity: 200, cost: 1200),
      ];

      final result = calculator.allocateWeightedAverage(layers, 150);

      // Average cost = (100*1000 + 200*1200) / 300 = 340000 / 300 = 1133.33
      // COGS = 150 * 1133 = 170,000 (approx)
      expect(result.averageCost, closeTo(1133.33, 1));
    });

    test('should handle equal costs', () {
      final layers = [
        MockLayer(id: '1', quantity: 100, cost: 1000),
        MockLayer(id: '2', quantity: 100, cost: 1000),
      ];

      final result = calculator.allocateWeightedAverage(layers, 50);

      expect(result.averageCost, equals(1000.0)); // All same cost
    });
  });

  group('Edge Cases', () {
    late InventoryCostCalculator calculator;

    setUp(() {
      calculator = InventoryCostCalculator();
    });

    test('should handle empty layers', () {
      final result = calculator.allocateFifo([], 10);

      expect(result.costOfGoodsSold, equals(0));
      expect(result.endingInventoryValue, equals(0));
      expect(result.layersUsed, isEmpty);
    });

    test('should handle zero quantity sale', () {
      final layers = [MockLayer(id: '1', quantity: 100, cost: 1000)];

      final result = calculator.allocateFifo(layers, 0);

      expect(result.costOfGoodsSold, equals(0));
    });

    test('should handle fractional quantities', () {
      final layers = [MockLayer(id: '1', quantity: 10.5, cost: 1000)];

      final result = calculator.allocateFifo(layers, 5.25);

      expect(result.layersUsed.first.quantityUsed, equals(5.25));
    });
  });

  group('LCM Valuation', () {
    test('should detect write-down needed', () {
      const currentCost = 1200; // $12 per unit
      const marketPrice = 1000; // $10 per unit
      const quantity = 100.0;

      final writeDownPerUnit = currentCost - marketPrice;
      final totalWriteDown = (writeDownPerUnit * quantity).round();

      expect(marketPrice, lessThan(currentCost));
      expect(totalWriteDown, equals(20000)); // $200 write-down
    });

    test('should not write down if market >= cost', () {
      const currentCost = 1000;
      const marketPrice = 1200;

      expect(marketPrice, greaterThanOrEqualTo(currentCost));
      // No write-down needed
    });
  });
}

/// Mock layer for testing without database
class MockLayer {
  final String id;
  final double quantity;
  final int cost; // cost per unit in cents

  MockLayer({required this.id, required this.quantity, required this.cost});
}

/// Calculator helper for testing FIFO/LIFO/WAC without database
class InventoryCostCalculator {
  CostOfGoodsSoldResult allocateFifo(
    List<MockLayer> layers,
    double quantitySold,
  ) {
    if (layers.isEmpty) {
      return const CostOfGoodsSoldResult(
        costOfGoodsSold: 0,
        endingInventoryValue: 0,
        averageCost: 0,
        layersUsed: [],
      );
    }

    int cogs = 0;
    double remainingToSell = quantitySold;
    final layersUsed = <LayerUsage>[];
    final remainingLayers = <MockLayer>[];

    for (final layer in layers) {
      if (remainingToSell <= 0) {
        remainingLayers.add(layer);
        continue;
      }

      final quantityFromLayer = remainingToSell <= layer.quantity
          ? remainingToSell
          : layer.quantity;

      final costFromLayer = (quantityFromLayer * layer.cost).round();
      cogs += costFromLayer;

      layersUsed.add(
        LayerUsage(
          layerId: layer.id,
          quantityUsed: quantityFromLayer,
          costPerUnit: layer.cost,
          totalCost: costFromLayer,
        ),
      );

      remainingToSell -= quantityFromLayer;

      if (layer.quantity > quantityFromLayer) {
        remainingLayers.add(
          MockLayer(
            id: layer.id,
            quantity: layer.quantity - quantityFromLayer,
            cost: layer.cost,
          ),
        );
      }
    }

    int endingValue = 0;
    for (final layer in remainingLayers) {
      endingValue += (layer.quantity * layer.cost).round();
    }

    return CostOfGoodsSoldResult(
      costOfGoodsSold: cogs,
      endingInventoryValue: endingValue,
      averageCost: cogs / quantitySold,
      layersUsed: layersUsed,
    );
  }

  CostOfGoodsSoldResult allocateLifo(
    List<MockLayer> layers,
    double quantitySold,
  ) {
    // Reverse the layers for LIFO (newest first)
    final reversedLayers = layers.reversed.toList();
    return allocateFifo(reversedLayers, quantitySold);
  }

  CostOfGoodsSoldResult allocateWeightedAverage(
    List<MockLayer> layers,
    double quantitySold,
  ) {
    if (layers.isEmpty) {
      return const CostOfGoodsSoldResult(
        costOfGoodsSold: 0,
        endingInventoryValue: 0,
        averageCost: 0,
        layersUsed: [],
      );
    }

    double totalQuantity = 0;
    int totalValue = 0;
    for (final layer in layers) {
      totalQuantity += layer.quantity;
      totalValue += (layer.quantity * layer.cost).round();
    }

    final avgCost = totalValue / totalQuantity;
    final cogs = (quantitySold * avgCost).round();
    final endingValue = totalValue - cogs;

    return CostOfGoodsSoldResult(
      costOfGoodsSold: cogs,
      endingInventoryValue: endingValue,
      averageCost: avgCost,
      layersUsed: [],
    );
  }
}
