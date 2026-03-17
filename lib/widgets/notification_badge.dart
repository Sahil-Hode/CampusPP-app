import 'package:flutter/material.dart';
import 'package:badges/badges.dart' as badges;
import 'package:provider/provider.dart';
import '../providers/notification_provider.dart';

class NotificationBadge extends StatelessWidget {
  const NotificationBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<NotificationProvider>(
      builder: (context, provider, child) {
        return badges.Badge(
          position: badges.BadgePosition.topEnd(top: 0, end: 3),
          showBadge: provider.unreadCount > 0,
          badgeContent: Text(
            provider.unreadCount > 99 ? '99+' : provider.unreadCount.toString(),
            style: const TextStyle(color: Colors.white, fontSize: 10),
          ),
          badgeStyle: badges.BadgeStyle(
            shape: badges.BadgeShape.circle,
            badgeColor: Colors.red,
            padding: const EdgeInsets.all(4),
          ),
          child: IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {
              Navigator.pushNamed(context, '/notifications');
            },
          ),
        );
      },
    );
  }
}
