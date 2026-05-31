import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _searchController = TextEditingController();
  List<dynamic> _users = [];
  bool _loading = false;

  Future<void> _search(String query) async {
    if (query.isEmpty) {
      setState(() => _users = []);
      return;
    }
    setState(() => _loading = true);
    final data = await ApiService.searchUsers(query);
    setState(() {
      _users = data['users'] ?? [];
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          autofocus: false,
          style: const TextStyle(color: const Color(0xFF1A1A2E)),
          decoration: InputDecoration(
            hintText: 'Search users...',
            hintStyle: const TextStyle(color: const Color(0xFF6B7280)),
            border: InputBorder.none,
            prefixIcon: const Icon(Icons.search, color: const Color(0xFF6B7280)),
            suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, color: const Color(0xFF6B7280)),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _users = []);
                  },
                )
              : null,
          ),
          onChanged: _search,
        ),
      ),
      body: _loading
        ? const Center(child: CircularProgressIndicator())
        : _users.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ShaderMask(
                    shaderCallback: (bounds) =>
                        RikiaTheme.rainbowGradient.createShader(bounds),
                    child: const Icon(Icons.search, size: 64, color: Colors.white),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Search for people on Rikia',
                    style: TextStyle(color: const Color(0xFF6B7280)),
                  ),
                ],
              ),
            )
          : ListView.builder(
              itemCount: _users.length,
              itemBuilder: (context, index) {
                final user = _users[index];
                return ListTile(
                  leading: Container(
                    width: 44,
                    height: 44,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RikiaTheme.rainbowGradient,
                    ),
                    child: Center(
                      child: Text(
                        (user['username'] ?? '?')[0].toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  title: Text(
                    user['username'] ?? '',
                    style: const TextStyle(
                      color: const Color(0xFF1A1A2E),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Text(
                    user['province'] ?? '',
                    style: const TextStyle(color: const Color(0xFF6B7280)),
                  ),
                  trailing: Text(
                    '${user['followers_count']} followers',
                    style: const TextStyle(
                      color: const Color(0xFF6B7280),
                      fontSize: 12,
                    ),
                  ),
                );
              },
            ),
    );
  }
}
