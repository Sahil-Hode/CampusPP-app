import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/notification_provider.dart';
import '../widgets/notification_card.dart';

class NotificationListScreen extends StatefulWidget {
  const NotificationListScreen({super.key});

  @override
  State<NotificationListScreen> createState() => _NotificationListScreenState();
}

class _NotificationListScreenState extends State<NotificationListScreen> {
  final ScrollController _scrollController = ScrollController();
  final List<String> _filters = ['All', 'Unread', 'Critical', 'Warning', 'Info'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NotificationProvider>().fetchNotifications(refresh: true);
      context.read<NotificationProvider>().fetchUnreadCount();
    });

    _scrollController.addListener(() {
      if (_scrollController.position.pixels == _scrollController.position.maxScrollExtent) {
        context.read<NotificationProvider>().fetchNotifications();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          TextButton(
             onPressed: () {
                context.read<NotificationProvider>().markAllAsRead();
             },
             child: const Text('Mark all read'),
          ),
        ],
      ),
      body: Consumer<NotificationProvider>(
        builder: (context, provider, child) {
          return Column(
            children: [
              // Filters
              SizedBox(
                height: 50,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _filters.length,
                  itemBuilder: (context, index) {
                    final filter = _filters[index];
                    final isSelected = provider.currentFilter == filter;
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 8.0),
                      child: ChoiceChip(
                        label: Text(filter),
                        selected: isSelected,
                        onSelected: (selected) {
                          if (selected) {
                            provider.setFilter(filter);
                          }
                        },
                      ),
                    );
                  },
                ),
              ),

              // Loading State / Empty State / List
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () async {
                    await provider.fetchNotifications(refresh: true);
                  },
                  child: provider.isLoading && provider.notifications.isEmpty
                      ? const Center(child: CircularProgressIndicator())
                      : provider.notifications.isEmpty
                          ? ListView( // ListView needed for RefreshIndicator
                              children: [
                                SizedBox(height: MediaQuery.of(context).size.height * 0.3),
                                const Center(
                                    child: Text(
                                        'No notifications found.',
                                        style: TextStyle(fontSize: 16, color: Colors.grey)
                                    )
                                )
                              ],
                            )
                          : ListView.separated(
                              controller: _scrollController,
                              itemCount: provider.notifications.length + (provider.hasMore ? 1 : 0),
                              separatorBuilder: (context, index) => const Divider(height: 1),
                              itemBuilder: (context, index) {
                                if (index == provider.notifications.length) {
                                  return const Padding(
                                    padding: EdgeInsets.all(16.0),
                                    child: Center(child: CircularProgressIndicator()),
                                  );
                                }
                                final notification = provider.notifications[index];
                                return NotificationCard(notification: notification);
                              },
                            ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
