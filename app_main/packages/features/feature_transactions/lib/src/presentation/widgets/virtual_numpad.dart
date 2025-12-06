// FILE: packages/features/feature_transactions/lib/src/presentation/widgets/virtual_numpad.dart

import 'package:flutter/material.dart';

class VirtualNumpad extends StatelessWidget {
  final Function(String) onKeyPressed;
  final VoidCallback onEnter;
  final VoidCallback onClear;
  final VoidCallback onBackspace;

  const VirtualNumpad({
    super.key,
    required this.onKeyPressed,
    required this.onEnter,
    required this.onClear,
    required this.onBackspace,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Calculate nice grid sizing
        return Column(
          children: [
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildKey('7'),
                  _buildKey('8'),
                  _buildKey('9'),
                ],
              ),
            ),
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildKey('4'),
                  _buildKey('5'),
                  _buildKey('6'),
                ],
              ),
            ),
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildKey('1'),
                  _buildKey('2'),
                  _buildKey('3'),
                ],
              ),
            ),
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildActionKey(Icons.backspace, Colors.red.shade100, onBackspace),
                  _buildKey('0'),
                  _buildActionKey(Icons.keyboard_return, Colors.green.shade100, onEnter),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildKey(String value) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(2.0),
        child: OutlinedButton(
          onPressed: () => onKeyPressed(value),
          style: OutlinedButton.styleFrom(
            shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(4))),
            textStyle: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          child: Text(value),
        ),
      ),
    );
  }

  Widget _buildActionKey(IconData icon, Color color, VoidCallback onTap) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(2.0),
        child: FilledButton(
          onPressed: onTap,
          style: FilledButton.styleFrom(
            backgroundColor: color,
            foregroundColor: Colors.black87,
            shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(4))),
          ),
          child: Icon(icon),
        ),
      ),
    );
  }
}