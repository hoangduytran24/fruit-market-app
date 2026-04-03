import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // Đảm bảo bạn có dùng Provider
import '../services/signalr_service.dart';

class NotificationHandler extends StatelessWidget {
  final Widget child;

  const NotificationHandler({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    // Lắng nghe sự kiện từ SignalRService
    final signalR = Provider.of<SignalRService>(context, listen: false);
    
    signalR.onNotificationReceived = (update) {
      // Hiện thông báo dạng Snack-bar (màu xanh theo brand GreenFruit Market)
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(update.eventType, style: const TextStyle(fontWeight: FontWeight.bold)),
              Text(update.message),
            ],
          ),
          backgroundColor: Colors.green[700],
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 4),
        ),
      );
    };

    return child;
  }
}