import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../models/event_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../services/registration_service.dart';
import '../../../theme/app_theme.dart';
import '../../../utils/currency_formatter.dart';
import '../../../widgets/common/custom_buttons.dart';
import 'ticket_screen.dart';

class PaymentScreen extends StatefulWidget {
  final EventModel event;

  const PaymentScreen({super.key, required this.event});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final RegistrationService _registrationService = RegistrationService();
  String _selectedPaymentMethod = 'upi';
  bool _isProcessing = false;

  Future<void> _processPayment() async {
    setState(() {
      _isProcessing = true;
    });

    final authProvider = context.read<AuthProvider>();

    try {
      // No actual payment processing - just create registration
      final registration = await _registrationService.createRegistration(
        userId: authProvider.currentUser!.id,
        eventId: widget.event.id,
        amountPaid: widget.event.isFree ? 0.0 : widget.event.price,
      );

      // Mark as completed (no actual payment gateway)
      await _registrationService.updatePaymentStatus(
        registrationId: registration.id,
        status: 'completed',
      );

      if (!mounted) return;

      // Navigate to ticket screen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => TicketScreen(
            event: widget.event,
            qrToken: registration.qrToken,
            registrationId: registration.id,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isProcessing = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: AppTheme.error,
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final subtotal = widget.event.price;
    final serviceFee = widget.event.isFree ? 0.0 : 2.0;
    final tax = widget.event.isFree ? 0.0 : subtotal * 0.1;
    final total = subtotal + serviceFee + tax;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Checkout'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spacing3),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Event Summary
              Container(
                padding: const EdgeInsets.all(AppTheme.spacing2),
                decoration: BoxDecoration(
                  color: AppTheme.darkCard,
                  borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        gradient: AppTheme.primaryGradient,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          widget.event.categoryIcon,
                          style: const TextStyle(fontSize: 32),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppTheme.spacing2),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.event.title,
                            style: Theme.of(context).textTheme.titleLarge,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.event.venue,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppTheme.spacing4),

              // Payment Method
              Text(
                'Payment Method',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: AppTheme.spacing2),

              _PaymentMethodTile(
                icon: Icons.account_balance_wallet,
                title: 'Apple Pay / UPI',
                subtitle: 'Fastest checkout',
                value: 'upi',
                groupValue: _selectedPaymentMethod,
                onChanged: (value) {
                  setState(() {
                    _selectedPaymentMethod = value!;
                  });
                },
              ),

              const SizedBox(height: AppTheme.spacing1),

              _PaymentMethodTile(
                icon: Icons.credit_card,
                title: 'Visa **** 4242',
                subtitle: 'Expires 12/25',
                value: 'card',
                groupValue: _selectedPaymentMethod,
                onChanged: (value) {
                  setState(() {
                    _selectedPaymentMethod = value!;
                  });
                },
              ),

              const SizedBox(height: AppTheme.spacing1),

              _PaymentMethodTile(
                icon: Icons.account_balance,
                title: 'Net Banking',
                subtitle: 'View all banks',
                value: 'netbanking',
                groupValue: _selectedPaymentMethod,
                onChanged: (value) {
                  setState(() {
                    _selectedPaymentMethod = value!;
                  });
                },
              ),

              const SizedBox(height: AppTheme.spacing4),

              // Price Breakdown
              Container(
                padding: const EdgeInsets.all(AppTheme.spacing3),
                decoration: BoxDecoration(
                  color: AppTheme.darkCard,
                  borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                ),
                child: Column(
                  children: [
                    _PriceRow(
                      label: 'Subtotal',
                      value: CurrencyFormatter.format(subtotal),
                    ),
                    const SizedBox(height: AppTheme.spacing2),
                    _PriceRow(
                      label: 'Service Fee',
                      value: CurrencyFormatter.format(serviceFee),
                    ),
                    const SizedBox(height: AppTheme.spacing2),
                    _PriceRow(
                      label: 'Tax',
                      value: CurrencyFormatter.format(tax),
                    ),
                    const Divider(height: AppTheme.spacing3),
                    _PriceRow(
                      label: 'Total',
                      value: CurrencyFormatter.format(total),
                      isTotal: true,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppTheme.spacing1),

              // Security Notice
              const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.lock, size: 14, color: AppTheme.success),
                  SizedBox(width: 8),
                  Text(
                    '256-BIT SSL ENCRYPTED',
                    style: TextStyle(
                      color: AppTheme.success,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: AppTheme.spacing4),

              // Payment Button
              PrimaryButton(
                text: 'Confirm & Pay ${CurrencyFormatter.format(total)}',
                onPressed: _processPayment,
                isLoading: _isProcessing,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PaymentMethodTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String value;
  final String groupValue;
  final ValueChanged<String?> onChanged;

  const _PaymentMethodTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.groupValue,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = value == groupValue;

    return GestureDetector(
      onTap: () => onChanged(value),
      child: Container(
        padding: const EdgeInsets.all(AppTheme.spacing2),
        decoration: BoxDecoration(
          color: AppTheme.darkCard,
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          border: Border.all(
            color: isSelected ? AppTheme.primaryBlue : AppTheme.border,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.darkCardSecondary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: AppTheme.textPrimary),
            ),
            const SizedBox(width: AppTheme.spacing2),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            Radio<String>(
              value: value,
              groupValue: groupValue,
              onChanged: onChanged,
              activeColor: AppTheme.primaryBlue,
            ),
          ],
        ),
      ),
    );
  }
}

class _PriceRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isTotal;

  const _PriceRow({
    required this.label,
    required this.value,
    this.isTotal = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
                fontSize: isTotal ? 18 : 14,
              ),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
                fontSize: isTotal ? 18 : 14,
              ),
        ),
      ],
    );
  }
}

