// FILE: feature_data_import/lib/src/presentation/import_wizard_screen.dart
// Purpose: Step-by-step wizard for importing data

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';

import '../data/import_service.dart';
import '../data/field_mapper.dart';

/// Import Wizard Screen - 4 step process:
/// 1. Select file
/// 2. Choose target entity
/// 3. Map columns
/// 4. Preview & Import
class ImportWizardScreen extends ConsumerStatefulWidget {
  const ImportWizardScreen({super.key});

  @override
  ConsumerState<ImportWizardScreen> createState() => _ImportWizardScreenState();
}

class _ImportWizardScreenState extends ConsumerState<ImportWizardScreen> {
  int _currentStep = 0;
  File? _selectedFile;
  String _targetEntity = 'accounts';
  ImportPreview? _preview;
  List<FieldMapping> _mappings = [];
  ImportResult? _result;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Import Data'),
      ),
      body: Stepper(
        currentStep: _currentStep,
        onStepContinue: _onStepContinue,
        onStepCancel: _onStepCancel,
        controlsBuilder: (context, details) {
          return Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Row(
              children: [
                if (_currentStep < 3)
                  ElevatedButton(
                    onPressed: _isLoading ? null : details.onStepContinue,
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(_currentStep == 2 ? 'Import' : 'Continue'),
                  ),
                if (_currentStep > 0 && _currentStep < 3)
                  Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: TextButton(
                      onPressed: details.onStepCancel,
                      child: const Text('Back'),
                    ),
                  ),
                if (_currentStep == 3)
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(_result),
                    child: const Text('Done'),
                  ),
              ],
            ),
          );
        },
        steps: [
          Step(
            title: const Text('Select File'),
            subtitle: _selectedFile != null
                ? Text(_selectedFile!.path.split(Platform.pathSeparator).last)
                : null,
            content: _buildFileSelectionStep(),
            isActive: _currentStep >= 0,
            state: _currentStep > 0 ? StepState.complete : StepState.indexed,
          ),
          Step(
            title: const Text('Choose Data Type'),
            subtitle: _currentStep > 1 ? Text(_targetEntity) : null,
            content: _buildEntitySelectionStep(),
            isActive: _currentStep >= 1,
            state: _currentStep > 1 ? StepState.complete : StepState.indexed,
          ),
          Step(
            title: const Text('Map Columns'),
            subtitle: _preview != null
                ? Text('${_preview!.parsedData.rowCount} rows')
                : null,
            content: _buildMappingStep(),
            isActive: _currentStep >= 2,
            state: _currentStep > 2 ? StepState.complete : StepState.indexed,
          ),
          Step(
            title: const Text('Results'),
            content: _buildResultsStep(),
            isActive: _currentStep >= 3,
            state: _result != null ? StepState.complete : StepState.indexed,
          ),
        ],
      ),
    );
  }

  Widget _buildFileSelectionStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Select a CSV or Excel file to import.'),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          onPressed: _pickFile,
          icon: const Icon(Icons.upload_file),
          label: const Text('Choose File'),
        ),
        if (_selectedFile != null) ...[
          const SizedBox(height: 16),
          Card(
            child: ListTile(
              leading: const Icon(Icons.description),
              title:
                  Text(_selectedFile!.path.split(Platform.pathSeparator).last),
              trailing: IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => setState(() => _selectedFile = null),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildEntitySelectionStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('What type of data are you importing?'),
        const SizedBox(height: 16),
        ...EntityFieldDefinitions.entityNames
            .map((entity) => RadioListTile<String>.adaptive(
                  title: Text(_formatEntityName(entity)),
                  subtitle: Text(
                      '${EntityFieldDefinitions.getFieldsFor(entity).length} fields'),
                  value: entity,
                  groupValue: _targetEntity,
                  onChanged: (value) => setState(() => _targetEntity = value!),
                )),
      ],
    );
  }

  Widget _buildMappingStep() {
    if (_preview == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
            'Found ${_preview!.parsedData.rowCount} rows with ${_preview!.parsedData.columnCount} columns.'),
        const SizedBox(height: 16),
        const Text('Map each column to a field:',
            style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        ..._buildMappingRows(),
      ],
    );
  }

  List<Widget> _buildMappingRows() {
    final availableFields = EntityFieldDefinitions.getFieldsFor(_targetEntity);

    return _mappings.asMap().entries.map((entry) {
      final index = entry.key;
      final mapping = entry.value;

      return Card(
        margin: const EdgeInsets.only(bottom: 8),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                mapping.sourceColumn,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: mapping.isSkipped
                    ? 'skip'
                    : mapping.isExistingField
                        ? mapping.targetField
                        : 'custom:${mapping.customField?.name}',
                decoration: const InputDecoration(
                  labelText: 'Map to',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                items: [
                  const DropdownMenuItem(
                      value: 'skip', child: Text('(Skip this column)')),
                  ...availableFields.map((f) => DropdownMenuItem(
                        value: f.name,
                        child: Text('${f.label}${f.required ? ' *' : ''}'),
                      )),
                  DropdownMenuItem(
                    value:
                        'custom:${mapping.customField?.name ?? mapping.sourceColumn}',
                    child: const Text('+ Create Custom Field'),
                  ),
                ],
                onChanged: (value) {
                  setState(() {
                    if (value == 'skip') {
                      _mappings[index] =
                          FieldMapping.skipped(mapping.sourceColumn);
                    } else if (value?.startsWith('custom:') == true) {
                      _mappings[index] = FieldMapping.toCustomField(
                        sourceColumn: mapping.sourceColumn,
                        targetEntity: _targetEntity,
                        customField: CustomFieldDef(
                          name: FieldMapperService.autoSuggestMappings(
                                [mapping.sourceColumn],
                                _targetEntity,
                              ).first.customField?.name ??
                              mapping.sourceColumn.toLowerCase(),
                          type: 'text',
                          label: mapping.sourceColumn,
                        ),
                      );
                    } else {
                      _mappings[index] = FieldMapping.toExistingField(
                        sourceColumn: mapping.sourceColumn,
                        targetEntity: _targetEntity,
                        targetField: value!,
                      );
                    }
                  });
                },
              ),
            ],
          ),
        ),
      );
    }).toList();
  }

  Widget _buildResultsStep() {
    if (_result == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Card(
          color:
              _result!.hasErrors ? Colors.orange.shade50 : Colors.green.shade50,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Icon(
                  _result!.hasErrors ? Icons.warning : Icons.check_circle,
                  size: 48,
                  color: _result!.hasErrors ? Colors.orange : Colors.green,
                ),
                const SizedBox(height: 8),
                Text(
                  'Import Complete',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text('${_result!.successCount} records imported successfully'),
                if (_result!.hasErrors)
                  Text(
                    '${_result!.errorCount} errors',
                    style: const TextStyle(color: Colors.red),
                  ),
                Text('Duration: ${_result!.duration.inSeconds}s'),
              ],
            ),
          ),
        ),
        if (_result!.errors.isNotEmpty) ...[
          const SizedBox(height: 16),
          const Text('Errors:', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ...(_result!.errors.take(10).map((e) => Card(
                color: Colors.red.shade50,
                child: ListTile(
                  leading: const Icon(Icons.error, color: Colors.red),
                  title: Text('Row ${e.rowNumber}'),
                  subtitle: Text(e.message),
                ),
              ))),
          if (_result!.errors.length > 10)
            Text('... and ${_result!.errors.length - 10} more errors'),
        ],
      ],
    );
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv', 'xlsx', 'xls'],
    );

    if (result != null && result.files.single.path != null) {
      setState(() {
        _selectedFile = File(result.files.single.path!);
      });
    }
  }

  void _onStepContinue() async {
    switch (_currentStep) {
      case 0:
        if (_selectedFile == null) {
          _showError('Please select a file');
          return;
        }
        setState(() => _currentStep = 1);
        break;

      case 1:
        setState(() => _isLoading = true);
        try {
          final importService = ref.read(importServiceProvider);
          _preview = await importService.parseAndPreview(
              _selectedFile!, _targetEntity);
          _mappings = List.from(_preview!.suggestedMappings);
          setState(() {
            _currentStep = 2;
            _isLoading = false;
          });
        } catch (e) {
          _showError('Error parsing file: $e');
          setState(() => _isLoading = false);
        }
        break;

      case 2:
        setState(() => _isLoading = true);
        try {
          final importService = ref.read(importServiceProvider);
          _result = await importService.executeImport(
            parsedData: _preview!.parsedData,
            mappings: _mappings,
            targetEntity: _targetEntity,
          );
          setState(() {
            _currentStep = 3;
            _isLoading = false;
          });
        } catch (e) {
          _showError('Error importing: $e');
          setState(() => _isLoading = false);
        }
        break;
    }
  }

  void _onStepCancel() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  String _formatEntityName(String entity) {
    return entity[0].toUpperCase() + entity.substring(1);
  }
}
