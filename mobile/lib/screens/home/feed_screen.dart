import 'dart:convert';
import 'package:universal_html/html.dart' as html;
import 'package:flutter/material.dart';

import '../../services/api_service.dart';
import '../../theme/app_theme.dart';

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  List<dynamic> _posts = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadFeed();
  }

  Future<void> _loadFeed() async {
    setState(() => _loading = true);
    final data = await ApiService.getFeed();
    setState(() {
      _posts = data['posts'] ?? [];
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFAD1457),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreatePost(context),
        backgroundColor: RikiaTheme.purple,
        child: const Icon(Icons.add, color: const Color(0xFFAD1457)),
      ),
      body: _loading
        ? const Center(child: CircularProgressIndicator())
        : RefreshIndicator(
            onRefresh: _loadFeed,
            child: _posts.isEmpty
              ? const Center(
                  child: Text(
                    'No posts yet.\nFollow people to see their posts!',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Color(0xFF6B7280)),
                  ),
                )
              : Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 600),
                    child: ListView.builder(
                      itemCount: _posts.length,
                      itemBuilder: (context, index) {
                        return _PostCard(post: _posts[index], onRefresh: _loadFeed);
                      },
                    ),
                  ),
                ),
          ),
    );
  }

  void _showCreatePost(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFFAD1457),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => const _CreatePostSheet(),
    ).then((_) => _loadFeed());
  }
}

class _CreatePostSheet extends StatefulWidget {
  const _CreatePostSheet();

  @override
  State<_CreatePostSheet> createState() => _CreatePostSheetState();
}

class _CreatePostSheetState extends State<_CreatePostSheet> {
  final _captionController = TextEditingController();
  final _locationController = TextEditingController();
  int _selectedTab = 0;
  String? _pickedImageBase64;
  bool _posting = false;

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

    if (mounted) Navigator.pop(context);
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
              const Text('Create Post',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Tab selector
          Row(
            children: [
              _tab(0, '📝 Text'),
              const SizedBox(width: 8),
              _tab(1, '🖼 Photo'),
              const SizedBox(width: 8),
              _tab(2, '🎬 Video'),
            ],
          ),
          const SizedBox(height: 16),
          // Caption
          TextField(
            controller: _captionController,
            maxLines: 3,
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
          // Photo picker
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
          // Location
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
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
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
}

class _PostCard extends StatelessWidget {
  final Map<String, dynamic> post;
  final VoidCallback onRefresh;

  const _PostCard({required this.post, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFAD1457),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RikiaTheme.mainGradient,
                  ),
                  child: Center(
                    child: Text(
                      (post['username'] ?? '?')[0].toUpperCase(),
                      style: const TextStyle(
                        color: const Color(0xFFAD1457),
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(post['username'] ?? '',
                      style: const TextStyle(
                        color: Color(0xFF1A1A2E),
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    if (post['location'] != null && post['location'] != '')
                      Row(
                        children: [
                          const Icon(Icons.location_on,
                            size: 12, color: Color(0xFF6B7280)),
                          Text(post['location'],
                            style: const TextStyle(
                              color: Color(0xFF6B7280), fontSize: 12)),
                        ],
                      ),
                  ],
                ),
              ],
            ),
          ),
          if (post['caption'] != null && post['caption'] != '')
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(post['caption'],
                style: const TextStyle(
                  color: Color(0xFF1A1A2E), fontSize: 15)),
            ),
          if (post['image_url'] != null && post['image_url'] != '')
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(16)),
                child: Image.network(
                  post['image_url'],
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const SizedBox(),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.favorite_border,
                    color: RikiaTheme.red),
                  onPressed: () async {
                    await ApiService.likePost(post['id']);
                    onRefresh();
                  },
                ),
                Text('${post['likes_count'] ?? 0}',
                  style: const TextStyle(
                    color: Color(0xFF6B7280), fontSize: 13)),
                const SizedBox(width: 12),
                const Icon(Icons.comment_outlined,
                  color: Color(0xFF6B7280), size: 22),
                const SizedBox(width: 4),
                Text('${post['comments_count'] ?? 0}',
                  style: const TextStyle(
                    color: Color(0xFF6B7280), fontSize: 13)),
                const Spacer(),
                const Icon(Icons.share_outlined,
                  color: Color(0xFF6B7280), size: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
