import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../models/event_model.dart';
import '../../../theme/app_theme.dart';
import '../../../utils/date_formatter.dart';
import '../../../widgets/common/custom_buttons.dart';

class TicketScreen extends StatelessWidget {
  final EventModel event;
  final String qrToken;
  final String registrationId;

  const TicketScreen({
    super.key,
    required this.event,
    required this.qrToken,
    required this.registrationId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spacing3),
          child: Column(
            children: [
              // Success Icon
              Container(
                width: 80,
                height: 80,
                decoration: const BoxDecoration(
                  color: AppTheme.success,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check,
                  size: 48,
                  color: Colors.white,
                ),
              ),

              const SizedBox(height: AppTheme.spacing3),

              // Success Message
              Text(
                'Registration\nSuccessful!',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.displaySmall,
              ),

              const SizedBox(height: AppTheme.spacing1),

              Text(
                'You\'re all set for the event. A receipt\nhas been sent to your email.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.textSecondary,
                    ),
              ),

              const SizedBox(height: AppTheme.spacing4),

              // QR Code Ticket
              Expanded(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppTheme.spacing3),
                  decoration: BoxDecoration(
                    color: AppTheme.darkCard,
                    borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // QR Code
                      Container(
                        padding: const EdgeInsets.all(AppTheme.spacing3),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                        ),
                        child: QrImageView(
                          data: qrToken,
                          version: QrVersions.auto,
                          size: 200,
                        ),
                      ),

                      const SizedBox(height: AppTheme.spacing3),

                      // Event Details
                      Text(
                        event.title,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),

                      const SizedBox(height: AppTheme.spacing2),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.calendar_today_outlined,
                            size: 16,
                            color: AppTheme.textSecondary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            DateFormatter.formatDateTime(event.startDate),
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),

                      const SizedBox(height: AppTheme.spacing1),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.location_on_outlined,
                            size: 16,
                            color: AppTheme.textSecondary,
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              event.venue,
                              style: Theme.of(context).textTheme.bodySmall,
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: AppTheme.spacing3),

                      // Registration ID
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppTheme.spacing2,
                          vertical: AppTheme.spacing1,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.darkCardSecondary,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'ID: ${registrationId.substring(0, 8).toUpperCase()}',
                          style: const TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 12,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: AppTheme.spacing3),

              // Action Buttons
              PrimaryButton(
                text: 'Save Ticket',
                onPressed: () {
                  // TODO: Implement save ticket functionality
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Ticket saved to gallery'),
                      backgroundColor: AppTheme.success,
                    ),
                  );
                },
                icon: Icons.download,
              ),

              const SizedBox(height: AppTheme.spacing2),

              SecondaryButton(
                text: 'Add to Calendar',
                onPressed: () {
                  // TODO: Implement add to calendar
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Event added to calendar'),
                      backgroundColor: AppTheme.success,
                    ),
                  );
                },
                icon: Icons.calendar_month,
              ),

              const SizedBox(height: AppTheme.spacing2),

              TextButton(
                onPressed: () {
                  Navigator.popUntil(context, (route) => route.isFirst);
                },
                child: const Text('View My Events'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

