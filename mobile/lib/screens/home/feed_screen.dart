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
      backgroundColor: RikiaTheme.background,
      appBar: AppBar(
        title: ShaderMask(
          shaderCallback: (bounds) =>
              RikiaTheme.rainbowGradient.createShader(bounds),
          child: const Text(
            'RIKIA',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: 4,
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_box_outlined),
            onPressed: _showCreatePost,
          ),
        ],
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
                    style: TextStyle(color: RikiaTheme.textSecondary),
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
    showModalBottomSheet(
      context: context,
      backgroundColor: RikiaTheme.surface,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 16, right: 16, top: 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('New Post',
              style: TextStyle(
                color: RikiaTheme.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: captionController,
              autofocus: true,
              maxLines: 4,
              style: const TextStyle(color: RikiaTheme.textPrimary),
              decoration: const InputDecoration(
                hintText: "What's on your mind?",
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RikiaTheme.rainbowGradient,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ElevatedButton(
                  onPressed: () async {
                    if (captionController.text.isEmpty) return;
                    await ApiService.createPost(
                      caption: captionController.text,
                    );
                    if (!mounted) return;
                    Navigator.pop(context);
                    _loadFeed();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                  ),
                  child: const Text('Post',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
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
      margin: const EdgeInsets.only(bottom: 1),
      color: RikiaTheme.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // Avatar
                Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RikiaTheme.rainbowGradient,
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
                        color: RikiaTheme.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (post['location'] != null && post['location'] != '')
                      Text(
                        post['location'],
                        style: const TextStyle(
                          color: RikiaTheme.textSecondary,
                          fontSize: 12,
                        ),
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
                style: const TextStyle(color: RikiaTheme.textPrimary, fontSize: 15),
              ),
            ),
          // Image
          if (post['image_url'] != null && post['image_url'] != '')
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Image.network(
                post['image_url'],
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
          // Actions
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
                  style: const TextStyle(color: RikiaTheme.textSecondary),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.comment_outlined, color: RikiaTheme.textSecondary),
                const SizedBox(width: 4),
                Text(
                  '${post['comments_count'] ?? 0}',
                  style: const TextStyle(color: RikiaTheme.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
