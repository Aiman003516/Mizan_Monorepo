import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class InvitationCodeField extends StatefulWidget {
  const InvitationCodeField({
    super.key,
    required this.onChanged,
    required this.pasteLabel,
    required this.fieldLabel,
    this.initialCode = '',
    this.enabled = true,
  });

  final ValueChanged<String> onChanged;
  final String pasteLabel;
  final String fieldLabel;
  final String initialCode;
  final bool enabled;

  @override
  State<InvitationCodeField> createState() => _InvitationCodeFieldState();
}

class _InvitationCodeFieldState extends State<InvitationCodeField> {
  late final List<TextEditingController> _controllers;
  late final List<FocusNode> _focusNodes;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(6, (_) => TextEditingController());
    _focusNodes = List.generate(6, (_) => FocusNode());
    _applyCode(widget.initialCode, announce: false);
  }

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    for (final node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  String _digits(String value) => value.replaceAll(RegExp(r'[^0-9]'), '');

  String get _code => _controllers.map((controller) => controller.text).join();

  void _applyCode(String raw, {bool announce = true}) {
    final sanitized = _digits(raw);
    final code = sanitized.substring(
      0,
      sanitized.length > 6 ? 6 : sanitized.length,
    );
    for (var index = 0; index < 6; index++) {
      final value = index < code.length ? code[index] : '';
      _controllers[index].value = TextEditingValue(
        text: value,
        selection: TextSelection.collapsed(offset: value.length),
      );
    }
    if (announce) widget.onChanged(_code);
    if (code.length < 6 && widget.enabled) {
      _focusNodes[code.length].requestFocus();
    }
  }

  void _onChanged(int index, String value) {
    final sanitized = _digits(value);
    if (sanitized.length > 1) {
      _applyCode(sanitized);
      return;
    }
    if (sanitized.isEmpty) {
      if (index > 0) _focusNodes[index - 1].requestFocus();
    } else if (index < 5) {
      _focusNodes[index + 1].requestFocus();
    }
    widget.onChanged(_code);
  }

  Future<void> _paste() async {
    final clipboard = await Clipboard.getData(Clipboard.kTextPlain);
    final value = clipboard?.text;
    if (value == null || value.isEmpty) return;
    _applyCode(value);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      label: widget.fieldLabel,
      textField: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Directionality(
            textDirection: TextDirection.ltr,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(6, (index) {
                return Padding(
                  padding: EdgeInsetsDirectional.only(end: index == 5 ? 0 : 8),
                  child: SizedBox(
                    width: 42,
                    child: TextField(
                      controller: _controllers[index],
                      focusNode: _focusNodes[index],
                      enabled: widget.enabled,
                      autofocus: index == 0 && widget.enabled,
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      decoration: const InputDecoration(
                        counterText: '',
                        contentPadding: EdgeInsets.symmetric(vertical: 12),
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (value) => _onChanged(index, value),
                    ),
                  ),
                );
              }),
            ),
          ),
          Align(
            alignment: AlignmentDirectional.center,
            child: TextButton.icon(
              onPressed: widget.enabled ? _paste : null,
              icon: const Icon(Icons.content_paste_outlined, size: 18),
              label: Text(widget.pasteLabel),
            ),
          ),
        ],
      ),
    );
  }
}
