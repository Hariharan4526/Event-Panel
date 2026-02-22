import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../providers/auth_provider.dart';
import '../../../services/registration_service.dart';
import '../../../models/registration_model.dart';
import '../../../theme/app_theme.dart';
import '../../../utils/date_formatter.dart';
import '../../../utils/currency_formatter.dart';
import '../../../widgets/common/loading_skeleton.dart';

class MyEventsScreen extends StatefulWidget {
  const MyEventsScreen({super.key});

  @override
  State<MyEventsScreen> createState() => _MyEventsScreenState();
}

class _MyEventsScreenState extends State<MyEventsScreen> {
  final RegistrationService _registrationService = RegistrationService();
  List<RegistrationModel> _registrations = [];
  bool _isLoading = true;
  String _filter = 'all'; // all, upcoming, past

  @override
  void initState() {
    super.initState();
    _loadRegistrations();
  }

  Future<void> _loadRegistrations() async {
    setState(() {
      _isLoading = true;
    });

    final authProvider = context.read<AuthProvider>();
    if (authProvider.currentUser != null) {
      final registrations = await _registrationService.getUserRegistrations(
        authProvider.currentUser!.id,
      );

      setState(() {
        _registrations = registrations;
        _isLoading = false;
      });
    }
  }

  List<RegistrationModel> get _filteredRegistrations {
    final now = DateTime.now();

    return _registrations.where((reg) {
      if (_filter == 'upcoming') {
        return reg.eventStartDate != null && reg.eventStartDate!.isAfter(now);
      } else if (_filter == 'past') {
        return reg.eventStartDate != null && reg.eventStartDate!.isBefore(now);
      }
      return true;
    }).toList();
  }

  void _showQRCode(RegistrationModel registration) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        padding: const EdgeInsets.all(AppTheme.spacing4),
        decoration: const BoxDecoration(
          color: AppTheme.darkCard,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppTheme.radiusXLarge),
          ),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.textSecondary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              const SizedBox(height: AppTheme.spacing3),

              // Title
              Text(
                'Your Event Ticket',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: AppTheme.spacing4),

              // QR Code Container
              Container(
                padding: const EdgeInsets.all(AppTheme.spacing4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: QrImageView(
                  data: registration.qrToken,
                  version: QrVersions.auto,
                  size: 280,
                ),
              ),

              const SizedBox(height: AppTheme.spacing4),

              // Event Details
              Container(
                padding: const EdgeInsets.all(AppTheme.spacing3),
                decoration: BoxDecoration(
                  color: AppTheme.darkCardSecondary,
                  borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Event Details',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: AppTheme.spacing2),

                    // Event Title
                    Text(
                      registration.eventTitle ?? 'Event',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: AppTheme.spacing2),

                    // Date and Time
                    if (registration.eventStartDate != null)
                      Row(
                        children: [
                          const Icon(
                            Icons.calendar_today_outlined,
                            size: 16,
                            color: AppTheme.textSecondary,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              DateFormatter.formatDateTime(registration.eventStartDate!),
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ),
                        ],
                      ),
                    const SizedBox(height: AppTheme.spacing2),

                    // Venue
                    if (registration.eventVenue != null)
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on_outlined,
                            size: 16,
                            color: AppTheme.textSecondary,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              registration.eventVenue!,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ),
                        ],
                      ),
                    const SizedBox(height: AppTheme.spacing2),

                    // Registration ID
                    Row(
                      children: [
                        const Icon(
                          Icons.confirmation_number_outlined,
                          size: 16,
                          color: AppTheme.textSecondary,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'ID: ${registration.id.substring(0, 8).toUpperCase()}',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontFamily: 'monospace',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppTheme.spacing3),

              // Instructions
              Container(
                padding: const EdgeInsets.all(AppTheme.spacing2),
                decoration: BoxDecoration(
                  color: AppTheme.primaryBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                  border: Border.all(
                    color: AppTheme.primaryBlue.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.info_outline,
                      size: 18,
                      color: AppTheme.primaryBlue,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Show this QR code to the coordinator at the event entrance for verification.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.primaryBlue,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppTheme.spacing4),

              // Close Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Events'),
      ),
      body: Column(
        children: [
          // Filter Tabs
          Padding(
            padding: const EdgeInsets.all(AppTheme.spacing3),
            child: Row(
              children: [
                Expanded(
                  child: _FilterButton(
                    label: 'All',
                    isSelected: _filter == 'all',
                    onTap: () => setState(() => _filter = 'all'),
                  ),
                ),
                const SizedBox(width: AppTheme.spacing1),
                Expanded(
                  child: _FilterButton(
                    label: 'Upcoming',
                    isSelected: _filter == 'upcoming',
                    onTap: () => setState(() => _filter = 'upcoming'),
                  ),
                ),
                const SizedBox(width: AppTheme.spacing1),
                Expanded(
                  child: _FilterButton(
                    label: 'Past',
                    isSelected: _filter == 'past',
                    onTap: () => setState(() => _filter = 'past'),
                  ),
                ),
              ],
            ),
          ),

          // Events List
          Expanded(
            child: _isLoading
                ? ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacing3),
                    itemCount: 3,
                    itemBuilder: (context, index) => const ListItemSkeleton(),
                  )
                : _filteredRegistrations.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.event_busy,
                              size: 64,
                              color: AppTheme.textSecondary,
                            ),
                            const SizedBox(height: AppTheme.spacing2),
                            Text(
                              'No events found',
                              style: Theme.of(context).textTheme.headlineSmall,
                            ),
                            const SizedBox(height: AppTheme.spacing1),
                            Text(
                              'Register for events to see them here',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: AppTheme.textSecondary,
                                  ),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadRegistrations,
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppTheme.spacing3,
                          ),
                          itemCount: _filteredRegistrations.length,
                          itemBuilder: (context, index) {
                            final registration = _filteredRegistrations[index];
                            return _EventRegistrationCard(
                              registration: registration,
                              onViewQR: () => _showQRCode(registration),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}

class _FilterButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          gradient: isSelected ? AppTheme.primaryGradient : null,
          color: isSelected ? null : AppTheme.darkCard,
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          border: Border.all(
            color: isSelected ? Colors.transparent : AppTheme.border,
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isSelected ? Colors.white : AppTheme.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _EventRegistrationCard extends StatelessWidget {
  final RegistrationModel registration;
  final VoidCallback onViewQR;

  const _EventRegistrationCard({
    required this.registration,
    required this.onViewQR,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onViewQR,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppTheme.spacing2),
        padding: const EdgeInsets.all(AppTheme.spacing2),
        decoration: BoxDecoration(
          color: AppTheme.darkCard,
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        registration.eventTitle ?? 'Event',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 4),
                      if (registration.eventStartDate != null)
                        Text(
                          DateFormatter.formatDateTime(registration.eventStartDate!),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                    ],
                  ),
                ),
                // Payment Status Badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: registration.isPaid
                        ? AppTheme.success.withOpacity(0.2)
                        : AppTheme.warning.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    registration.paymentStatus.toUpperCase(),
                    style: TextStyle(
                      color: registration.isPaid ? AppTheme.success : AppTheme.warning,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: AppTheme.spacing2),

            // Venue
            if (registration.eventVenue != null)
              Row(
                children: [
                  const Icon(
                    Icons.location_on_outlined,
                    size: 16,
                    color: AppTheme.textSecondary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      registration.eventVenue!,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ],
              ),

            const SizedBox(height: AppTheme.spacing2),

            // Amount and QR Button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  CurrencyFormatter.format(registration.amountPaid),
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: AppTheme.primaryBlue,
                      ),
                ),
                if (registration.isPaid)
                  Row(
                    children: [
                      const Icon(Icons.qr_code, size: 18, color: AppTheme.primaryBlue),
                      const SizedBox(width: 8),
                      Text(
                        'View Ticket',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.primaryBlue,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  )
                else
                  Text(
                    'Pending Payment',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.warning,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

