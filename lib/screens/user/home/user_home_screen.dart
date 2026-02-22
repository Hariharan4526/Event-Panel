import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/event_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/user/event_card.dart';
import '../../../widgets/common/loading_skeleton.dart';
import 'event_detail_screen.dart';

class UserHomeScreen extends StatefulWidget {
  const UserHomeScreen({super.key});

  @override
  State<UserHomeScreen> createState() => _UserHomeScreenState();
}

class _UserHomeScreenState extends State<UserHomeScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<EventProvider>().loadPublishedEvents();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final eventProvider = context.watch<EventProvider>();

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(AppTheme.spacing3),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Welcome back,',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: AppTheme.textSecondary,
                                ),
                          ),
                          Text(
                            authProvider.currentUser?.name ?? 'User',
                            style: Theme.of(context).textTheme.displaySmall,
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.notifications_outlined),
                        onPressed: () {
                          // TODO: Navigate to notifications
                        },
                      ),
                    ],
                  ),

                  const SizedBox(height: AppTheme.spacing3),

                  // Search Bar
                  TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search events...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear();
                                eventProvider.loadPublishedEvents();
                              },
                            )
                          : null,
                    ),
                    onSubmitted: (query) {
                      if (query.isNotEmpty) {
                        eventProvider.searchEvents(query);
                      }
                    },
                  ),

                  const SizedBox(height: AppTheme.spacing3),

                  // Category Filters
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _CategoryChip(
                          label: 'All',
                          isSelected: eventProvider.selectedCategory == 'all',
                          onTap: () => eventProvider.setCategory('all'),
                        ),
                        _CategoryChip(
                          label: 'Academic',
                          icon: '📚',
                          isSelected: eventProvider.selectedCategory == 'academic',
                          onTap: () => eventProvider.setCategory('academic'),
                        ),
                        _CategoryChip(
                          label: 'Social',
                          icon: '🎉',
                          isSelected: eventProvider.selectedCategory == 'social',
                          onTap: () => eventProvider.setCategory('social'),
                        ),
                        _CategoryChip(
                          label: 'Sport',
                          icon: '⚽',
                          isSelected: eventProvider.selectedCategory == 'sport',
                          onTap: () => eventProvider.setCategory('sport'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Events List
            Expanded(
              child: eventProvider.isLoading
                  ? ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacing3),
                      itemCount: 3,
                      itemBuilder: (context, index) => const EventCardSkeleton(),
                    )
                  : eventProvider.filteredEvents.isEmpty
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
                                'Check back later for new events',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: AppTheme.textSecondary,
                                    ),
                              ),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: () async {
                            await eventProvider.loadPublishedEvents();
                          },
                          child: ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacing3),
                            itemCount: eventProvider.filteredEvents.length,
                            itemBuilder: (context, index) {
                              final event = eventProvider.filteredEvents[index];
                              return EventCard(
                                event: event,
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => EventDetailScreen(event: event),
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final String label;
  final String? icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _CategoryChip({
    required this.label,
    this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: AppTheme.spacing1),
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.spacing2,
          vertical: 12,
        ),
        decoration: BoxDecoration(
          gradient: isSelected ? AppTheme.primaryGradient : null,
          color: isSelected ? null : AppTheme.darkCard,
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          border: Border.all(
            color: isSelected ? Colors.transparent : AppTheme.border,
          ),
        ),
        child: Row(
          children: [
            if (icon != null) ...[
              Text(icon!, style: const TextStyle(fontSize: 16)),
              const SizedBox(width: 8),
            ],
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : AppTheme.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

