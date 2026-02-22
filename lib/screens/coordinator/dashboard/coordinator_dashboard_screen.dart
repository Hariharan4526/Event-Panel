import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/event_provider.dart';
import '../../../services/event_service.dart';
import '../../../theme/app_theme.dart';
import '../../../utils/currency_formatter.dart';
import '../events/create_event_screen.dart';

class CoordinatorDashboardScreen extends StatefulWidget {
  const CoordinatorDashboardScreen({super.key});

  @override
  State<CoordinatorDashboardScreen> createState() => _CoordinatorDashboardScreenState();
}

class _CoordinatorDashboardScreenState extends State<CoordinatorDashboardScreen> {
  final EventService _eventService = EventService();
  Map<String, dynamic>? _analytics;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    final authProvider = context.read<AuthProvider>();
    final eventProvider = context.read<EventProvider>();

    setState(() {
      _isLoading = true;
    });

    await eventProvider.loadCoordinatorEvents(authProvider.currentUser!.id);

    // Calculate analytics
    final events = eventProvider.coordinatorEvents;
    double totalRevenue = 0;
    int totalRegistrations = 0;
    int activeEvents = events.where((e) => e.isPublished).length;

    for (var event in events) {
      final stats = await _eventService.getEventStats(event.id);
      totalRevenue += stats['total_revenue'] as double;
      totalRegistrations += stats['total_registrations'] as int;
    }

    setState(() {
      _analytics = {
        'total_events': events.length,
        'total_registrations': totalRegistrations,
        'total_revenue': totalRevenue,
        'active_events': activeEvents,
      };
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final eventProvider = context.watch<EventProvider>();

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadDashboardData,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppTheme.spacing3),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Good ${_getGreeting()},',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: AppTheme.textSecondary,
                              ),
                        ),
                        Text(
                          authProvider.currentUser?.name ?? 'Admin',
                          style: Theme.of(context).textTheme.displaySmall,
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.notifications_outlined),
                      onPressed: () {},
                    ),
                  ],
                ),

                const SizedBox(height: AppTheme.spacing4),

                // Analytics Cards
                if (_isLoading)
                  const Center(child: CircularProgressIndicator())
                else if (_analytics != null)
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    mainAxisSpacing: AppTheme.spacing2,
                    crossAxisSpacing: AppTheme.spacing2,
                    childAspectRatio: 1.3,
                    children: [
                      _AnalyticsCard(
                        icon: Icons.event,
                        iconColor: AppTheme.primaryBlue,
                        title: 'Total Events',
                        value: _analytics!['total_events'].toString(),
                        trend: '+12%',
                      ),
                      _AnalyticsCard(
                        icon: Icons.people,
                        iconColor: AppTheme.purple,
                        title: 'Registrations',
                        value: _formatNumber(_analytics!['total_registrations']),
                        trend: '+5%',
                      ),
                      _AnalyticsCard(
                        icon: Icons.bolt,
                        iconColor: AppTheme.warning,
                        title: 'Active Events',
                        value: _analytics!['active_events'].toString(),
                      ),
                      _AnalyticsCard(
                        icon: Icons.attach_money,
                        iconColor: AppTheme.success,
                        title: 'Revenue',
                        value: CurrencyFormatter.formatLarge(_analytics!['total_revenue']),
                        isLarge: true,
                      ),
                    ],
                  ),

                const SizedBox(height: AppTheme.spacing4),

                // Upcoming Events
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Upcoming Events',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    TextButton(
                      onPressed: () {
                        // Switch to events tab
                      },
                      child: const Text('View All'),
                    ),
                  ],
                ),

                const SizedBox(height: AppTheme.spacing2),

                // Events List
                if (eventProvider.coordinatorEvents.isEmpty)
                  Center(
                    child: Column(
                      children: [
                        const SizedBox(height: AppTheme.spacing4),
                        const Icon(
                          Icons.event_busy,
                          size: 64,
                          color: AppTheme.textSecondary,
                        ),
                        const SizedBox(height: AppTheme.spacing2),
                        Text(
                          'No events yet',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: AppTheme.spacing1),
                        Text(
                          'Create your first event to get started',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: AppTheme.textSecondary,
                              ),
                        ),
                      ],
                    ),
                  )
                else
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: eventProvider.coordinatorEvents.take(3).length,
                    itemBuilder: (context, index) {
                      final event = eventProvider.coordinatorEvents[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: AppTheme.spacing2),
                        padding: const EdgeInsets.all(AppTheme.spacing2),
                        decoration: BoxDecoration(
                          color: AppTheme.darkCard,
                          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                gradient: AppTheme.primaryGradient,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                event.categoryIcon,
                                style: const TextStyle(fontSize: 24),
                              ),
                            ),
                            const SizedBox(width: AppTheme.spacing2),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    event.title,
                                    style: Theme.of(context).textTheme.titleLarge,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Container(
                                        width: 8,
                                        height: 8,
                                        decoration: BoxDecoration(
                                          color: event.isPublished
                                              ? AppTheme.success
                                              : AppTheme.warning,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        event.status.toUpperCase(),
                                        style: Theme.of(context).textTheme.bodySmall,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const Icon(
                              Icons.chevron_right,
                              color: AppTheme.textSecondary,
                            ),
                          ],
                        ),
                      );
                    },
                  ),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const CreateEventScreen(),
            ),
          );
        },
        backgroundColor: AppTheme.primaryBlue,
        icon: const Icon(Icons.add),
        label: const Text('Create Event'),
      ),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Morning';
    if (hour < 17) return 'Afternoon';
    return 'Evening';
  }

  String _formatNumber(int number) {
    if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    }
    return number.toString();
  }
}

class _AnalyticsCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String value;
  final String? trend;
  final bool isLarge;

  const _AnalyticsCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.value,
    this.trend,
    this.isLarge = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacing2),
      decoration: BoxDecoration(
        color: AppTheme.darkCard,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
      ),
      constraints: const BoxConstraints(
        minHeight: 120,
        maxHeight: 160,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: iconColor, size: 20),
                ),
                if (trend != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.success.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      trend!,
                      style: const TextStyle(
                        color: AppTheme.success,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Flexible(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.bodySmall,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      value,
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

