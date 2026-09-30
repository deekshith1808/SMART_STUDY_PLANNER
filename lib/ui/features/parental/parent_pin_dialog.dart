import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:smart_study_planner/ui/core/app_theme.dart';

class ParentPinDialog extends StatefulWidget {
  final bool Function(String pin) onVerify;
  final String title;
  final String subtitle;

  const ParentPinDialog({
    super.key,
    required this.onVerify,
    this.title = 'Parent Controller Access',
    this.subtitle = 'Enter 4-digit security PIN to access parental settings',
  });

  static Future<bool> show(
    BuildContext context, {
    required bool Function(String pin) onVerify,
    String title = 'Parent Controller Access',
    String subtitle = 'Enter 4-digit security PIN to access parental settings',
  }) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => ParentPinDialog(
        onVerify: onVerify,
        title: title,
        subtitle: subtitle,
      ),
    );
    return result ?? false;
  }

  @override
  State<ParentPinDialog> createState() => _ParentPinDialogState();
}

class _ParentPinDialogState extends State<ParentPinDialog> {
  final TextEditingController _pinController = TextEditingController();
  String _enteredPin = '';
  String? _errorMessage;

  void _onKeyPress(String val) {
    if (_enteredPin.length < 4) {
      setState(() {
        _enteredPin += val;
        _errorMessage = null;
      });
      if (_enteredPin.length == 4) {
        _validate();
      }
    }
  }

  void _onBackspace() {
    if (_enteredPin.isNotEmpty) {
      setState(() {
        _enteredPin = _enteredPin.substring(0, _enteredPin.length - 1);
        _errorMessage = null;
      });
    }
  }

  void _validate() {
    final success = widget.onVerify(_enteredPin);
    if (success) {
      Navigator.pop(context, true);
    } else {
      setState(() {
        _enteredPin = '';
        _errorMessage = 'Incorrect PIN. Default is 1234.';
      });
    }
  }

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dialogBg = isDark ? const Color(0xFF1F1D1B) : Colors.white;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: dialogBg,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Shield Icon
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF3C7),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFFDE68A), width: 2),
              ),
              child: const Icon(
                Icons.shield_rounded,
                size: 36,
                color: Color(0xFFD97706),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              widget.title,
              style: GoogleFonts.lora(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              widget.subtitle,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),

            // PIN Dots
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(4, (index) {
                final isFilled = index < _enteredPin.length;
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 10),
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isFilled ? AppColors.primary : Colors.transparent,
                    border: Border.all(
                      color: isFilled ? AppColors.primary : const Color(0xFFD6CBC0),
                      width: 2,
                    ),
                  ),
                );
              }),
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 12),
              Text(
                _errorMessage!,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.error,
                ),
              ),
            ],
            const SizedBox(height: 24),

            // Numeric Keypad
            _buildKeypad(),
            const SizedBox(height: 12),

            // Cancel Button
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(
                'Cancel',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKeypad() {
    return Column(
      children: [
        for (var row = 0; row < 3; row++)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                for (var col = 1; col <= 3; col++)
                  _buildKey('${row * 3 + col}'),
              ],
            ),
          ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            const SizedBox(width: 60, height: 60),
            _buildKey('0'),
            SizedBox(
              width: 60,
              height: 60,
              child: IconButton(
                onPressed: _onBackspace,
                icon: const Icon(Icons.backspace_outlined, size: 22),
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildKey(String value) {
    return SizedBox(
      width: 60,
      height: 60,
      child: Material(
        color: const Color(0xFFF4ECE1),
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: () => _onKeyPress(value),
          child: Center(
            child: Text(
              value,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
