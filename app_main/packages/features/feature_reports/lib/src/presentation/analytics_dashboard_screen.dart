import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'analytics_providers.dart';

class AnalyticsDashboardScreen extends ConsumerWidget {
  const AnalyticsDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {

    return Scaffold(
      appBar: AppBar(title: const Text("Business Insights")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- SECTION 1: SALES TREND ---
            Text("Sales Trend (Last 30 Days)", style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 16),
            SizedBox(
              height: 250,
              child: _SalesLineChart(ref: ref),
            ),
            
            const SizedBox(height: 32),

            // --- SECTION 2: CATEGORY SHARE ---
            Text("Sales by Category", style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 16),
            SizedBox(
              height: 250,
              child: _CategoryPieChart(ref: ref),
            ),

            const SizedBox(height: 32),

            // --- SECTION 3: TOP PRODUCTS ---
            Text("Top 5 Products", style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 16),
            _TopProductsList(ref: ref),
          ],
        ),
      ),
    );
  }
}

// 📉 WIDGET: Line Chart
class _SalesLineChart extends ConsumerWidget {
  final WidgetRef ref;
  const _SalesLineChart({required this.ref});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dataAsync = ref.watch(dailySalesProvider);

    return dataAsync.when(
      data: (points) {
        if (points.isEmpty) return const Center(child: Text("No sales data yet."));
        
        // Normalize Data for Chart
        final spots = points.asMap().entries.map((e) {
          return FlSpot(e.key.toDouble(), e.value.amount);
        }).toList();

        final maxAmount = points.map((e) => e.amount).reduce((a, b) => a > b ? a : b);

        return LineChart(
          LineChartData(
            gridData: const FlGridData(show: false),
            titlesData: FlTitlesData(
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (value, meta) {
                    // Show date every 5 days roughly
                    final index = value.toInt();
                    if (index >= 0 && index < points.length && index % 5 == 0) {
                      return Text(DateFormat('MM/dd').format(points[index].date), style: const TextStyle(fontSize: 10));
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ),
              leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            ),
            borderData: FlBorderData(show: true, border: Border.all(color: Colors.grey.shade300)),
            lineBarsData: [
              LineChartBarData(
                spots: spots,
                isCurved: true,
                color: Colors.blue,
                barWidth: 3,
                dotData: const FlDotData(show: false),
                belowBarData: BarAreaData(show: true, color: Colors.blue.withOpacity(0.1)),
              ),
            ],
            maxY: maxAmount * 1.2, // Add headroom
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text("Error: $e")),
    );
  }
}

// 🥧 WIDGET: Pie Chart
class _CategoryPieChart extends ConsumerWidget {
  final WidgetRef ref;
  const _CategoryPieChart({required this.ref});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dataAsync = ref.watch(categorySalesProvider);

    return dataAsync.when(
      data: (categories) {
        if (categories.isEmpty) return const Center(child: Text("No category data."));

        final total = categories.fold(0.0, (sum, item) => sum + item.totalRevenue);

        return Row(
          children: [
            Expanded(
              child: PieChart(
                PieChartData(
                  sections: categories.asMap().entries.map((e) {
                    final index = e.key;
                    final item = e.value;
                    final isLarge = item.totalRevenue / total > 0.15;
                    
                    return PieChartSectionData(
                      color: Colors.primaries[index % Colors.primaries.length],
                      value: item.totalRevenue,
                      title: isLarge ? '${(item.totalRevenue / total * 100).toStringAsFixed(0)}%' : '',
                      radius: 50,
                      titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                    );
                  }).toList(),
                  centerSpaceRadius: 40,
                  sectionsSpace: 2,
                ),
              ),
            ),
            const SizedBox(width: 16),
            // Legend
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: categories.asMap().entries.map((e) {
                final index = e.key;
                final item = e.value;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      Container(width: 12, height: 12, color: Colors.primaries[index % Colors.primaries.length]),
                      const SizedBox(width: 8),
                      Text("${item.categoryName} (\$${item.totalRevenue.toStringAsFixed(0)})", style: const TextStyle(fontSize: 12)),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text("Error: $e")),
    );
  }
}

// 🏆 WIDGET: Top Products
class _TopProductsList extends ConsumerWidget {
  final WidgetRef ref;
  const _TopProductsList({required this.ref});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dataAsync = ref.watch(topProductsProvider);

    return dataAsync.when(
      data: (products) {
        if (products.isEmpty) return const Text("No sales data.");
        return Column(
          children: products.map((p) {
            return ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(
                backgroundColor: Colors.amber.shade100,
                child: const Icon(Icons.emoji_events, color: Colors.amber),
              ),
              title: Text(p.productName),
              trailing: Text("${p.quantitySold.toStringAsFixed(0)} sold", style: const TextStyle(fontWeight: FontWeight.bold)),
            );
          }).toList(),
        );
      },
      loading: () => const LinearProgressIndicator(),
      error: (e, _) => Text("Error: $e"),
    );
  }
}