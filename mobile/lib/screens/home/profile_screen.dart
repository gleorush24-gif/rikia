import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../auth/login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? _profile;
  List<dynamic> _posts = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final userId = await ApiService.getUserId();
    if (userId == null) return;
    final data = await ApiService.getProfile(userId);
    setState(() {
      _profile = data['profile'];
      _posts = data['posts'] ?? [];
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFAD1457),
      appBar: AppBar(
        title: Text(_profile?['username'] ?? 'Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await ApiService.logout();
              if (!mounted) return;
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (route) => false,
              );
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreatePost(context),
        backgroundColor: RikiaTheme.purple,
        child: const Icon(Icons.add, color: const Color(0xFFAD1457)),
      ),
      body: _loading
        ? const Center(child: CircularProgressIndicator())
        : RefreshIndicator(
            onRefresh: _load,
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // Profile header
                  Container(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        // Avatar
                        Container(
                          width: 80,
                          height: 80,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RikiaTheme.rainbowGradient,
                          ),
                          child: Center(
                            child: Text(
                              (_profile?['username'] ?? '?')[0].toUpperCase(),
                              style: const TextStyle(
                                color: const Color(0xFFAD1457),
                                fontWeight: FontWeight.w800,
                                fontSize: 32,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _profile?['username'] ?? '',
                          style: const TextStyle(
                            color: const Color(0xFF1565C0),
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        if (_profile?['province'] != null)
                          Text(
                            '📍 ${_profile!['province']}',
                            style: const TextStyle(
                              color: const Color(0xFF1976D2),
                              fontSize: 14,
                            ),
                          ),
                        const SizedBox(height: 16),
                        // Stats
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _stat('${_profile?['posts_count'] ?? 0}', 'Posts'),
                            _stat('${_profile?['followers_count'] ?? 0}', 'Followers'),
                            _stat('${_profile?['following_count'] ?? 0}', 'Following'),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const Divider(color: const Color(0xFFE5E7EB)),
                  // Posts grid
                  _posts.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.all(40),
                        child: Text(
                          'No posts yet',
                          style: TextStyle(color: const Color(0xFF1976D2)),
                        ),
                      )
                    : GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(4),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: 2,
                          mainAxisSpacing: 2,
                        ),
                        itemCount: _posts.length,
                        itemBuilder: (context, index) {
                          final post = _posts[index];
                          return ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: post['image_url'] != null && post['image_url'] != ''
                              ? Image.network(
                                  post['image_url'],
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => _textPostTile(post),
                                )
                              : _textPostTile(post),
                          );
                        },
                      ),
class _CreatePostSheet extends StatefulWidget {
  final VoidCallback onPosted;
  const _CreatePostSheet({required this.onPosted});

  @override
  State<_CreatePostSheet> createState() => _CreatePostSheetState();
}

class _CreatePostSheetState extends State<_CreatePostSheet> {
  final _captionController = TextEditingController();
  final _locationController = TextEditingController();
  String? _pickedImageBase64;
  bool _posting = false;
  int _selectedTab = 0;

  Future<void> _pickImage() async {
    final input = html.FileUploadInputElement()..accept = 'image/*';
    input.click();
    await input.onChange.first;
    if (input.files == null || input.files!.isEmpty) return;
    final file = input.files![0];
    final reader = html.FileReader();
    reader.readAsDataUrl(file);
    await reader.onLoad.first;
    setState(() {
      _pickedImageBase64 = reader.result as String;
    });
  }

  Future<void> _post() async {
    if (_captionController.text.isEmpty && _pickedImageBase64 == null) return;
    setState(() => _posting = true);
    String imageUrl = '';
    if (_pickedImageBase64 != null) {
      imageUrl = await ApiService.uploadImage(_pickedImageBase64!) ?? '';
    }
    await ApiService.createPost(
      caption: _captionController.text,
      imageUrl: imageUrl,
      location: _locationController.text,
    );
    if (mounted) {
      Navigator.pop(context);
      widget.onPosted();
    }
  }

  Widget _tab(int index, String label) {
    final isSelected = index == _selectedTab;
    return GestureDetector(
      onTap: () => setState(() => _selectedTab = index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          gradient: isSelected ? RikiaTheme.buttonGradient : null,
          color: isSelected ? null : const Color(0xFF880E4F),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(label,
          style: TextStyle(
            color: isSelected ? const Color(0xFFAD1457) : const Color(0xFF1976D2),
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16, right: 16, top: 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('New Post',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _tab(0, '📝 Text'),
              const SizedBox(width: 8),
              _tab(1, '🖼 Photo'),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _captionController,
            maxLines: 3,
            autofocus: true,
            decoration: InputDecoration(
              hintText: "What's on your mind?",
              filled: true,
              fillColor: const Color(0xFF880E4F),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 12),
          if (_selectedTab == 1)
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                width: double.infinity,
                height: 150,
                decoration: BoxDecoration(
                  color: const Color(0xFF880E4F),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: _pickedImageBase64 != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.memory(
                        base64Decode(_pickedImageBase64!.split(',')[1]),
                        fit: BoxFit.cover,
                      ),
                    )
                  : const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_photo_alternate_outlined,
                          size: 48, color: Color(0xFF6B7280)),
                        SizedBox(height: 8),
                        Text('Tap to pick from gallery',
                          style: TextStyle(color: Color(0xFF6B7280))),
                      ],
                    ),
              ),
            ),
          if (_selectedTab == 1) const SizedBox(height: 12),
          TextField(
            controller: _locationController,
            decoration: InputDecoration(
              hintText: 'Add location (optional)',
              prefixIcon: const Icon(Icons.location_on_outlined,
                color: Color(0xFF6B7280)),
              filled: true,
              fillColor: const Color(0xFF880E4F),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RikiaTheme.buttonGradient,
                borderRadius: BorderRadius.circular(12),
              ),
              child: ElevatedButton(
                onPressed: _posting ? null : _post,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                ),
                child: _posting
                  ? const CircularProgressIndicator(color: const Color(0xFFAD1457))
                  : const Text('Post',
                      style: TextStyle(color: const Color(0xFFAD1457),
                        fontWeight: FontWeight.w700, fontSize: 16)),
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
