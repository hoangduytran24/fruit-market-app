import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/real_time_provider.dart';

class NotificationBadge extends StatelessWidget {
  final Widget child;
  
  const NotificationBadge({super.key, required this.child});
  
  @override
  Widget build(BuildContext context) {
    return Consumer<RealTimeProvider>(
      builder: (context, provider, _) {
        final count = provider.notifications.length;
        
        return Stack(
          clipBehavior: Clip.none,
          children: [
            child,
            if (count > 0)
              Positioned(
                right: -4,
                top: -4,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 18,
                    minHeight: 18,
                  ),
                  child: Text(
                    count > 99 ? '99+' : '$count',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}