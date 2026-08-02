import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';

class PinScreen extends ConsumerStatefulWidget {
  final bool isSetupMode;
  const PinScreen({super.key, this.isSetupMode = false});

  @override
  ConsumerState<PinScreen> createState() => _PinScreenState();
}

class _PinScreenState extends ConsumerState<PinScreen> {
  String _pin = '';

  void _onKeyPress(String value) {
    if (_pin.length < 4) {
      setState(() => _pin += value);
    }
    if (_pin.length == 4) {
      _submitPin();
    }
  }

  void _submitPin() async {
    final notifier = ref.read(authProvider.notifier);
    if (widget.isSetupMode) {
      await notifier.setupPin(_pin);
      // Let GoRouter redirect based on AuthStatus
    } else {
      final success = await notifier.verifyOfflinePin(_pin);
      if (!success) {
        setState(() => _pin = '');
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invalid PIN')));
      }
    }
  }

  void _triggerBiometric() {
    ref.read(authProvider.notifier).authenticateBiometric();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.read(authProvider).user;
    
    return Scaffold(
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              widget.isSetupMode ? 'Set up 4-Digit PIN' : 'Welcome back, ${user?.fullName ?? ""}',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Text(widget.isSetupMode ? 'Enter a PIN for fast offline access' : 'Enter your PIN'),
            const SizedBox(height: 48),
            
            // Basic representation of PIN dots
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(4, (index) {
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: index < _pin.length ? Colors.green : Colors.grey.shade300,
                  ),
                );
              }),
            ),
            
            const SizedBox(height: 64),
            // Custom Numpad (Simplified for brevity)
            Wrap(
              spacing: 24,
              runSpacing: 24,
              alignment: WrapAlignment.center,
              children: [
                for (var i = 1; i <= 9; i++)
                  _buildNumpadButton(i.toString()),
                _buildNumpadButton('clear', icon: Icons.backspace),
                _buildNumpadButton('0'),
                if (!widget.isSetupMode)
                  _buildNumpadButton('bio', icon: Icons.fingerprint),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildNumpadButton(String value, {IconData? icon}) {
    return InkWell(
      onTap: () {
        if (value == 'clear' && _pin.isNotEmpty) {
          setState(() => _pin = _pin.substring(0, _pin.length - 1));
        } else if (value == 'bio') {
          _triggerBiometric();
        } else if (value != 'clear' && value != 'bio') {
          _onKeyPress(value);
        }
      },
      child: Container(
        width: 70,
        height: 70,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.grey.shade100,
        ),
        child: Center(
          child: icon != null 
              ? Icon(icon, size: 32)
              : Text(value, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }
}
