import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
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
      backgroundColor: Colors.white,
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreatePost,
        backgroundColor: RikiaTheme.purple,
        child: const Icon(Icons.add, color: Colors.white),
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
              : ListView.builder(
                  itemCount: _posts.length,
                  itemBuilder: (context, index) {
                    return _PostCard(post: _posts[index], onRefresh: _loadFeed);
                  },
                ),
          ),
    );
  }

  void _showCreatePost() {
    final captionController = TextEditingController();
    final imageUrlController = TextEditingController();
    final videoUrlController = TextEditingController();
    final locationController = TextEditingController();
    int _selectedTab = 0;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 16, right: 16, top: 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Create Post',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1A1A2E),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Media type selector
              Row(
                children: [
                  _mediaTab(0, '📝 Text', _selectedTab, (i) => setModalState(() => _selectedTab = i)),
                  const SizedBox(width: 8),
                  _mediaTab(1, '🖼 Photo', _selectedTab, (i) => setModalState(() => _selectedTab = i)),
                  const SizedBox(width: 8),
                  _mediaTab(2, '🎬 Video', _selectedTab, (i) => setModalState(() => _selectedTab = i)),
                ],
              ),
              const SizedBox(height: 16),

              // Caption
              TextField(
                controller: captionController,
                maxLines: 3,
                style: const TextStyle(color: Color(0xFF1A1A2E)),
                decoration: InputDecoration(
                  hintText: _selectedTab == 0
                    ? "What's on your mind?"
                    : _selectedTab == 1
                      ? 'Add a caption...'
                      : 'Describe your video...',
                  filled: true,
                  fillColor: const Color(0xFFF5F5F5),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Photo picker
              if (_selectedTab == 1)
                Column(
                  children: [
                    GestureDetector(
                      onTap: () async {
                        final picker = ImagePicker();
                        final picked = await picker.pickImage(
                          source: ImageSource.gallery,
                          imageQuality: 80,
                        );
                        if (picked != null) {
                          final bytes = await picked.readAsBytes();
                          final base64 = base64Encode(bytes);
                          imageUrlController.text = 'data:image/jpeg;base64,$base64';
                          setModalState(() {});
                        }
                      },
                      child: Container(
                        width: double.infinity,
                        height: 120,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF5F5F5),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE5E7EB)),
                        ),
                        child: imageUrlController.text.startsWith('data:')
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.memory(
                                base64Decode(imageUrlController.text.split(',')[1]),
                                fit: BoxFit.cover,
                              ),
                            )
                          : const Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.add_photo_alternate_outlined, size: 40, color: Color(0xFF6B7280)),
                                SizedBox(height: 8),
                                Text('Tap to pick from gallery', style: TextStyle(color: Color(0xFF6B7280))),
                              ],
                            ),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                ),

              // Video URL input
              if (_selectedTab == 2)
                TextField(
                  controller: videoUrlController,
                  style: const TextStyle(color: Color(0xFF1A1A2E)),
                  decoration: InputDecoration(
                    hintText: 'Paste video URL (YouTube, etc)...',
                    prefixIcon: const Icon(Icons.video_library_outlined, color: Color(0xFF6B7280)),
                    filled: true,
                    fillColor: const Color(0xFFF5F5F5),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),

              const SizedBox(height: 12),

              // Location
              TextField(
                controller: locationController,
                style: const TextStyle(color: Color(0xFF1A1A2E)),
                decoration: InputDecoration(
                  hintText: 'Add location (optional)',
                  prefixIcon: const Icon(Icons.location_on_outlined, color: Color(0xFF6B7280)),
                  filled: true,
                  fillColor: const Color(0xFFF5F5F5),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Post button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RikiaTheme.buttonGradient,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ElevatedButton(
                    onPressed: () async {
                      if (captionController.text.isEmpty &&
                          imageUrlController.text.isEmpty &&
                          videoUrlController.text.isEmpty) return;
                      await ApiService.createPost(
                        caption: captionController.text,
                        imageUrl: imageUrlController.text,
                        location: locationController.text,
                      );
                      if (!context.mounted) return;
                      Navigator.pop(context);
                      _loadFeed();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Post',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _mediaTab(int index, String label, int selected, Function(int) onTap) {
    final isSelected = index == selected;
    return GestureDetector(
      onTap: () => onTap(index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          gradient: isSelected ? RikiaTheme.buttonGradient : null,
          color: isSelected ? null : const Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : const Color(0xFF6B7280),
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
        color: Colors.white,
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
          // Header
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
                        color: Colors.white,
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
                    Text(
                      post['username'] ?? '',
                      style: const TextStyle(
                        color: Color(0xFF1A1A2E),
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    if (post['location'] != null && post['location'] != '')
                      Row(
                        children: [
                          const Icon(Icons.location_on, size: 12, color: Color(0xFF6B7280)),
                          Text(
                            post['location'],
                            style: const TextStyle(
                              color: Color(0xFF6B7280),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ],
            ),
          ),
          // Caption
          if (post['caption'] != null && post['caption'] != '')
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                post['caption'],
                style: const TextStyle(
                  color: Color(0xFF1A1A2E),
                  fontSize: 15,
                ),
              ),
            ),
          // Image
          if (post['image_url'] != null && post['image_url'] != '')
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
                child: Image.network(
                  post['image_url'],
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const SizedBox(),
                ),
              ),
            ),
          // Actions
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.favorite_border, color: RikiaTheme.red),
                  onPressed: () async {
                    await ApiService.likePost(post['id']);
                    onRefresh();
                  },
                ),
                Text(
                  '${post['likes_count'] ?? 0}',
                  style: const TextStyle(color: Color(0xFF6B7280), fontSize: 13),
                ),
                const SizedBox(width: 12),
                const Icon(Icons.comment_outlined, color: Color(0xFF6B7280), size: 22),
                const SizedBox(width: 4),
                Text(
                  '${post['comments_count'] ?? 0}',
                  style: const TextStyle(color: Color(0xFF6B7280), fontSize: 13),
                ),
                const Spacer(),
                const Icon(Icons.share_outlined, color: Color(0xFF6B7280), size: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
