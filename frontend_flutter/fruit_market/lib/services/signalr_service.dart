import 'package:signalr_netcore/signalr_client.dart';
// import 'package:flutter/foundation.dart';
import '../models/real_time_update.dart';

class SignalRService {
  HubConnection? _hubConnection;
  bool _isConnected = false;
  final List<RealTimeUpdate> _notifications = [];

  bool get isConnected => _isConnected;
  List<RealTimeUpdate> get notifications => _notifications;

  // Callback để Provider lắng nghe
  Function(RealTimeUpdate)? onNotificationReceived;

  Future<void> connect(String token, String userId) async {
    if (_hubConnection?.state == HubConnectionState.Connected) return;

    // URL Hub của bạn
    const String hubUrl = "https://10.0.2.2:7262/orderHub";

    _hubConnection = HubConnectionBuilder()
        .withUrl(hubUrl, options: HttpConnectionOptions(
          accessTokenFactory: () async => token,
          transport: HttpTransportType.WebSockets,
          skipNegotiation: true,
        ))
        .withAutomaticReconnect()
        .build();

    _hubConnection!.on("ReceiveRealTimeUpdate", (arguments) {
      if (arguments != null && arguments.isNotEmpty) {
        final rawData = arguments[0] as Map<String, dynamic>;
        final update = RealTimeUpdate.fromJson(rawData);
        _handleIncoming(update);
      }
    });

    try {
      await _hubConnection!.start();
      _isConnected = true;
      // Gọi method JoinUserGroup trên Server (nếu Server yêu cầu)
      await _hubConnection!.invoke("JoinUserGroup", args: [userId]);
    } catch (e) {
      _isConnected = false;
      rethrow;
    }
  }

  void _handleIncoming(RealTimeUpdate update) {
    _notifications.insert(0, update);
    if (_notifications.length > 50) _notifications.removeLast();
    onNotificationReceived?.call(update);
  }

  // ĐỊNH NGHĨA HÀM NÀY ĐỂ PROVIDER GỌI ĐƯỢC
  Future<void> joinOrderGroup(int orderId) async {
    if (_hubConnection?.state == HubConnectionState.Connected) {
      await _hubConnection!.invoke("JoinOrderGroup", args: [orderId]);
    }
  }

  // ĐỊNH NGHĨA HÀM NÀY ĐỂ PROVIDER GỌI ĐƯỢC
  Future<void> leaveOrderGroup(int orderId) async {
    if (_hubConnection?.state == HubConnectionState.Connected) {
      await _hubConnection!.invoke("LeaveOrderGroup", args: [orderId]);
    }
  }

  Future<void> disconnect() async {
    if (_hubConnection != null) {
      await _hubConnection!.stop();
      _isConnected = false;
    }
  }

  // Hàm dispose của Service trả về void
  void dispose() {
    disconnect();
  }
}