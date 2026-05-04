import 'package:flutter/material.dart';
import '../../shared/theme/app_theme.dart';

class ZakatCalculatorScreen extends StatefulWidget {
  const ZakatCalculatorScreen({super.key});

  @override
  State<ZakatCalculatorScreen> createState() => _ZakatCalculatorScreenState();
}

class _ZakatCalculatorScreenState extends State<ZakatCalculatorScreen> {
  final _assetsCtrl = TextEditingController();
  final _liabilitiesCtrl = TextEditingController();
  final _nisabCtrl = TextEditingController(text: '595');

  String _currency = 'USD';
  String? _resultText;
  String? _breakdownText;
  String? _nisabStatus;
  bool _aboveNisab = false;

  final List<String> _currencies = ['USD', 'GBP', 'EUR', 'SAR', 'AED', 'MYR', 'NGN'];

  static const double _zakatRate = 0.025;

  void _calculate() {
    final assets = double.tryParse(_assetsCtrl.text.replaceAll(',', '')) ?? 0;
    final liabilities = double.tryParse(_liabilitiesCtrl.text.replaceAll(',', '')) ?? 0;
    final nisab = double.tryParse(_nisabCtrl.text.replaceAll(',', '')) ?? 0;
    final net = assets - liabilities;
    _aboveNisab = net >= nisab;

    if (!_aboveNisab) {
      setState(() {
        _nisabStatus = 'Your net wealth ($_currency ${net.toStringAsFixed(2)}) is below the Nisab threshold. Zakat is not obligatory.';
        _resultText = null;
        _breakdownText = null;
      });
      return;
    }

    final zakat = net * _zakatRate;
    setState(() {
      _nisabStatus = 'Your net wealth is above the Nisab threshold. Zakat is obligatory.';
      _resultText = 'Zakat Due: $_currency ${zakat.toStringAsFixed(2)}';
      _breakdownText = 'Total Assets: $_currency ${assets.toStringAsFixed(2)}\n'
          'Total Liabilities: $_currency ${liabilities.toStringAsFixed(2)}\n'
          'Net Wealth: $_currency ${net.toStringAsFixed(2)}\n'
          'Nisab: $_currency ${nisab.toStringAsFixed(2)}\n'
          'Zakat Rate: 2.5%\n'
          'Zakat Payable: $_currency ${zakat.toStringAsFixed(2)}';
    });
  }

  @override
  void dispose() {
    _assetsCtrl.dispose();
    _liabilitiesCtrl.dispose();
    _nisabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Zakat Calculator'),
        backgroundColor: AppTheme.primaryRed,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Currency
            Card(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: DropdownButtonFormField<String>(
                  value: _currency,
                  decoration: const InputDecoration(
                    labelText: 'Currency',
                    border: InputBorder.none,
                  ),
                  items: _currencies
                      .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
                  onChanged: (v) => setState(() => _currency = v!),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Total assets
            _buildField(_assetsCtrl, 'Total Assets ($_currency)',
                'Enter total assets value', Icons.account_balance_wallet_rounded),
            const SizedBox(height: 12),

            // Total liabilities
            _buildField(_liabilitiesCtrl, 'Total Liabilities ($_currency)',
                'Enter total liabilities', Icons.money_off_rounded),
            const SizedBox(height: 12),

            // Nisab
            _buildField(_nisabCtrl, 'Nisab Value ($_currency)',
                'Enter nisab threshold', Icons.balance_rounded),
            const SizedBox(height: 8),
            const Text(
              'Nisab is approximately 595g of silver or 85g of gold equivalent in your local currency.',
              style: TextStyle(fontSize: 12, color: AppTheme.subTextColor),
            ),
            const SizedBox(height: 20),

            // Calculate button
            _AnimatedButton(
              label: 'Calculate Zakat',
              onTap: _calculate,
            ),
            const SizedBox(height: 20),

            // Results
            if (_nisabStatus != null)
              _ResultCard(
                color: _aboveNisab
                    ? Colors.green.shade50
                    : Colors.orange.shade50,
                borderColor: _aboveNisab ? Colors.green : Colors.orange,
                icon: _aboveNisab
                    ? Icons.check_circle_rounded
                    : Icons.info_rounded,
                iconColor: _aboveNisab ? Colors.green : Colors.orange,
                text: _nisabStatus!,
              ),

            if (_resultText != null) ...[
              const SizedBox(height: 12),
              _ResultCard(
                color: AppTheme.primaryRed.withOpacity(0.07),
                borderColor: AppTheme.primaryRed,
                icon: Icons.calculate_rounded,
                iconColor: AppTheme.primaryRed,
                text: _resultText!,
                isLarge: true,
              ),
            ],

            if (_breakdownText != null) ...[
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Breakdown',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      const SizedBox(height: 8),
                      Text(_breakdownText!,
                          style: const TextStyle(
                              fontSize: 14, height: 1.6, color: Colors.black87)),
                    ],
                  ),
                ),
              ),
            ],

            const SizedBox(height: 24),
            const Text(
              'Note: This calculator provides an estimate. Please consult a qualified Islamic scholar for precise Zakat calculation.',
              style: TextStyle(fontSize: 12, color: AppTheme.subTextColor),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildField(
      TextEditingController ctrl, String label, String hint, IconData icon) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: TextField(
          controller: ctrl,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            labelText: label,
            hintText: hint,
            prefixIcon: Icon(icon, color: AppTheme.primaryRed),
            border: InputBorder.none,
          ),
        ),
      ),
    );
  }
}

class _ResultCard extends StatelessWidget {
  final Color color;
  final Color borderColor;
  final IconData icon;
  final Color iconColor;
  final String text;
  final bool isLarge;

  const _ResultCard({
    required this.color,
    required this.borderColor,
    required this.icon,
    required this.iconColor,
    required this.text,
    this.isLarge = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Icon(icon, color: iconColor),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: isLarge ? 16 : 14,
                fontWeight: isLarge ? FontWeight.bold : FontWeight.normal,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AnimatedButton extends StatefulWidget {
  final String label;
  final VoidCallback onTap;

  const _AnimatedButton({required this.label, required this.onTap});

  @override
  State<_AnimatedButton> createState() => _AnimatedButtonState();
}

class _AnimatedButtonState extends State<_AnimatedButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
      lowerBound: 0.95,
      upperBound: 1.0,
      value: 1.0,
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _ctrl.reverse(),
      onTapUp: (_) {
        _ctrl.forward();
        widget.onTap();
      },
      onTapCancel: () => _ctrl.forward(),
      child: ScaleTransition(
        scale: _ctrl,
        child: Container(
          height: 52,
          decoration: BoxDecoration(
            color: AppTheme.primaryRed,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryRed.withOpacity(0.4),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: Text(
            widget.label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}
