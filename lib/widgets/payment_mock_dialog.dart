import 'package:flutter/material.dart';

class PaymentMockDialog extends StatefulWidget {
  const PaymentMockDialog({super.key});

  @override
  State<PaymentMockDialog> createState() => _PaymentMockDialogState();
}

class _PaymentMockDialogState extends State<PaymentMockDialog> {
  bool _isProcessing = false;

  Future<void> _processPayment() async {
    setState(() {
      _isProcessing = true;
    });

    // Simulate payment processing
    await Future.delayed(const Duration(seconds: 2));

    if (mounted) {
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Payment'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('This is a mock payment portal'),
          const SizedBox(height: 16),
          const Text('Amount: \$100.00'),
          const SizedBox(height: 16),
          if (_isProcessing)
            const CircularProgressIndicator()
          else
            ElevatedButton(
              onPressed: _processPayment,
              child: const Text('Pay Now'),
            ),
        ],
      ),
    );
  }
}

