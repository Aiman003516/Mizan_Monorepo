// FILE: packages/features/feature_reports/lib/src/presentation/dynamic_report_screen.dart

import 'package:feature_reports/src/data/report_models.dart';
import 'package:feature_reports/src/data/report_templates_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:shared_ui/shared_ui.dart'; // For formatting utilities

class DynamicReportScreen extends ConsumerStatefulWidget {
  final ReportTemplate template;

  const DynamicReportScreen({super.key, required this.template});

  @override
  ConsumerState<DynamicReportScreen> createState() => _DynamicReportScreenState();
}

class _DynamicReportScreenState extends ConsumerState<DynamicReportScreen> {
  final Map<String, dynamic> _paramValues = {};
  List<Map<String, dynamic>>? _results;
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    // Initialize Defaults
    for (var param in widget.template.parameters) {
      if (param.type == 'date') {
        _paramValues[param.key] = DateTime.now();
      } else {
        _paramValues[param.key] = '';
      }
    }
  }

  Future<void> _runReport() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final data = await ref.read(reportTemplatesRepositoryProvider).runReportQuery(
        widget.template.sqlQuery,
        _paramValues,
      );
      setState(() {
        _results = data;
      });
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.template.title)),
      body: Column(
        children: [
          // 1. PARAMETERS SECTION
          if (widget.template.parameters.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.grey.shade100,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ...widget.template.parameters.map((param) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: _buildParamInput(param),
                    );
                  }),
                  ElevatedButton.icon(
                    onPressed: _isLoading ? null : _runReport,
                    icon: const Icon(Icons.play_arrow),
                    label: const Text("Run Report"),
                  ),
                ],
              ),
            ),

          // 2. RESULTS SECTION
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(child: Text("Error: $_error", style: const TextStyle(color: Colors.red)))
                    : _results == null
                        ? const Center(child: Text("Set parameters and run report."))
                        : _results!.isEmpty
                            ? const Center(child: Text("No data found for these criteria."))
                            : _buildDataTable(),
          ),
        ],
      ),
    );
  }

  Widget _buildParamInput(ReportParameter param) {
    if (param.type == 'date') {
      final date = _paramValues[param.key] as DateTime;
      return ListTile(
        title: Text(param.label),
        subtitle: Text(DateFormat.yMMMd().format(date)),
        trailing: const Icon(Icons.calendar_today),
        tileColor: Colors.white,
        onTap: () async {
          final picked = await showDatePicker(
            context: context,
            initialDate: date,
            firstDate: DateTime(2020),
            lastDate: DateTime(2030),
          );
          if (picked != null) {
            setState(() => _paramValues[param.key] = picked);
          }
        },
      );
    }
    // Fallback for Text
    return TextField(
      decoration: InputDecoration(
        labelText: param.label,
        filled: true,
        fillColor: Colors.white,
      ),
      onChanged: (v) => _paramValues[param.key] = v,
    );
  }

  Widget _buildDataTable() {
    return SingleChildScrollView(
      scrollDirection: Axis.vertical,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columns: widget.template.columns.map((col) {
            return DataColumn(label: Text(col.label));
          }).toList(),
          rows: _results!.map((row) {
            return DataRow(
              cells: widget.template.columns.map((col) {
                final rawVal = row[col.key];
                String displayVal = '$rawVal';

                // Format based on type
                if (rawVal != null) {
                  if (col.type == 'currency') {
                    // Try parsing if int/double
                     if (rawVal is num) {
                       // Simple format, normally use SharedUI formatter
                       displayVal = NumberFormat.simpleCurrency().format(rawVal / 100); 
                     }
                  } else if (col.type == 'date' && rawVal is int) {
                    // Drift stores dates as int (millis) sometimes
                    displayVal = DateFormat.yMMMd().format(DateTime.fromMillisecondsSinceEpoch(rawVal));
                  }
                }

                return DataCell(Text(displayVal));
              }).toList(),
            );
          }).toList(),
        ),
      ),
    );
  }
}