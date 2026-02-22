import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../../../models/event_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../services/registration_service.dart';
import '../../../theme/app_theme.dart';
import '../../../utils/date_formatter.dart';
import '../../../utils/currency_formatter.dart';
import '../../../widgets/common/custom_buttons.dart';
import 'payment_screen.dart';

class EventDetailScreen extends StatefulWidget {
  final EventModel event;

  const EventDetailScreen({super.key, required this.event});

  @override
  State<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends State<EventDetailScreen> {
  final RegistrationService _registrationService = RegistrationService();
  bool _isRegistered = false;
  bool _isLoading = true;
  int _registrationCount = 0;

  @override
  void initState() {
    super.initState();
    _checkRegistrationStatus();
    _loadRegistrationCount();
  }

  Future<void> _checkRegistrationStatus() async {
    final authProvider = context.read<AuthProvider>();
    if (authProvider.currentUser != null) {
      final isRegistered = await _registrationService.isUserRegistered(
        userId: authProvider.currentUser!.id,
        eventId: widget.event.id,
      );
      setState(() {
        _isRegistered = isRegistered;
        _isLoading = false;
      });
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadRegistrationCount() async {
    final count = await _registrationService.getEventRegistrationCount(widget.event.id);
    setState(() {
      _registrationCount = count;
    });
  }

  void _navigateToPayment() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PaymentScreen(event: widget.event),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final seatsLeft = widget.event.maxCapacity - _registrationCount;
    final capacityPercentage = (_registrationCount / widget.event.maxCapacity * 100).clamp(0, 100);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // App Bar with Banner
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: widget.event.bannerUrl != null
                  ? CachedNetworkImage(
                      imageUrl: widget.event.bannerUrl!,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        color: AppTheme.darkCardSecondary,
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: AppTheme.darkCardSecondary,
                        child: const Icon(Icons.event, size: 64),
                      ),
                    )
                  : Container(
                      decoration: BoxDecoration(
                        gradient: AppTheme.cardGradient,
                      ),
                      child: Center(
                        child: Text(
                          widget.event.categoryIcon,
                          style: const TextStyle(fontSize: 100),
                        ),
                      ),
                    ),
            ),
          ),

          // Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(AppTheme.spacing3),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Category Badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryBlue.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      widget.event.category.toUpperCase(),
                      style: const TextStyle(
                        color: AppTheme.primaryBlue,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),

                  const SizedBox(height: AppTheme.spacing2),

                  // Title
                  Text(
                    widget.event.title,
                    style: Theme.of(context).textTheme.displaySmall,
                  ),

                  const SizedBox(height: AppTheme.spacing3),

                  // Date & Time
                  _InfoRow(
                    icon: Icons.calendar_today_outlined,
                    label: 'Date & Time',
                    value: DateFormatter.formatDateTime(widget.event.startDate),
                  ),

                  const SizedBox(height: AppTheme.spacing2),

                  // Venue
                  _InfoRow(
                    icon: Icons.location_on_outlined,
                    label: 'Venue',
                    value: widget.event.venue,
                  ),

                  const SizedBox(height: AppTheme.spacing3),

                  // Capacity
                  Container(
                    padding: const EdgeInsets.all(AppTheme.spacing2),
                    decoration: BoxDecoration(
                      color: AppTheme.darkCard,
                      borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Capacity',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            Text(
                              '$_registrationCount / ${widget.event.maxCapacity}',
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                    color: AppTheme.primaryBlue,
                                  ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppTheme.spacing1),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(
                            value: capacityPercentage / 100,
                            backgroundColor: AppTheme.darkCardSecondary,
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              AppTheme.primaryBlue,
                            ),
                            minHeight: 8,
                          ),
                        ),
                        const SizedBox(height: AppTheme.spacing1),
                        Text(
                          '$seatsLeft seats left',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: AppTheme.spacing3),

                  // Description
                  Text(
                    'About Event',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: AppTheme.spacing1),
                  Text(
                    widget.event.description,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppTheme.textSecondary,
                          height: 1.6,
                        ),
                  ),

                  const SizedBox(height: 100), // Space for bottom button
                ],
              ),
            ),
          ),
        ],
      ),

      // Bottom Action Button
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(AppTheme.spacing3),
        decoration: const BoxDecoration(
          color: AppTheme.darkBg,
          border: Border(
            top: BorderSide(color: AppTheme.border, width: 1),
          ),
        ),
        child: SafeArea(
          child: Row(
            children: [
              // Price
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Price',
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    widget.event.isFree
                        ? 'FREE'
                        : CurrencyFormatter.format(widget.event.price),
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: AppTheme.primaryBlue,
                        ),
                  ),
                ],
              ),

              const SizedBox(width: AppTheme.spacing3),

              // Register Button
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _isRegistered
                        ? SecondaryButton(
                            text: 'Already Registered',
                            onPressed: () {},
                            icon: Icons.check_circle,
                          )
                        : seatsLeft <= 0
                            ? SecondaryButton(
                                text: 'Event Full',
                                onPressed: () {},
                              )
                            : PrimaryButton(
                                text: 'Register Now',
                                onPressed: _navigateToPayment,
                                icon: Icons.arrow_forward,
                              ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacing2),
      decoration: BoxDecoration(
        color: AppTheme.darkCard,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.white),
          ),
          const SizedBox(width: AppTheme.spacing2),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                Text(
                  value,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

