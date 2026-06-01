import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<dynamic> _notifications = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final data = await ApiService.getNotifications();
    setState(() {
      _notifications = data['notifications'] ?? [];
      _loading = false;
    });
  }

  IconData _getIcon(String type) {
    switch (type) {
      case 'like': return Icons.favorite;
      case 'comment': return Icons.comment;
      case 'follow': return Icons.person_add;
      default: return Icons.notifications;
    }
  }

  Color _getColor(String type) {
    switch (type) {
      case 'like': return RikiaTheme.red;
      case 'comment': return RikiaTheme.blue;
      case 'follow': return RikiaTheme.green;
      default: return RikiaTheme.violet;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFAD1457),
      appBar: AppBar(title: const Text('Notifications')),
      body: _loading
        ? const Center(child: CircularProgressIndicator())
        : _notifications.isEmpty
          ? const Center(
              child: Text(
                'No notifications yet',
                style: TextStyle(color: const Color(0xFF1976D2)),
              ),
            )
          : ListView.builder(
              itemCount: _notifications.length,
              itemBuilder: (context, index) {
                final n = _notifications[index];
                final type = n['type'] ?? '';
                return ListTile(
                  leading: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _getColor(type).withOpacity(0.2),
                    ),
                    child: Icon(_getIcon(type), color: _getColor(type), size: 20),
                  ),
                  title: RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: '${n['username']} ',
                          style: const TextStyle(
                            color: const Color(0xFF1565C0),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        TextSpan(
                          text: n['message'] ?? '',
                          style: const TextStyle(color: const Color(0xFF1976D2)),
                        ),
                      ],
                    ),
                  ),
                  tileColor: n['is_read'] == false
                    ? RikiaTheme.violet.withOpacity(0.05)
                    : null,
                );
              },
            ),
    );
  }
}
