import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static const String baseUrl = 'https://rikia-api.onrender.com/api/v1';

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', token);
  }

  static Future<void> saveUser(String userId, String username) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_id', userId);
    await prefs.setString('username', username);
  }

  static Future<String?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_id');
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  static Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null;
  }

  static Future<Map<String, dynamic>> get(String path) async {
    final token = await getToken();
    final response = await http.get(
      Uri.parse('$baseUrl$path'),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
    );
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> post(String path, {
    Map<String, dynamic>? body,
    bool requiresAuth = true,
  }) async {
    final token = requiresAuth ? await getToken() : null;
    final response = await http.post(
      Uri.parse('$baseUrl$path'),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
      body: body != null ? jsonEncode(body) : null,
    );
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> delete(String path) async {
    final token = await getToken();
    final response = await http.delete(
      Uri.parse('$baseUrl$path'),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
    );
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> register({
    required String username,
    required String email,
    required String password,
    String province = '',
  }) async {
    return post('/auth/register', body: {
      'username': username,
      'email': email,
      'password': password,
      'province': province,
    }, requiresAuth: false);
  }

  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    return post('/auth/login', body: {
      'email': email,
      'password': password,
    }, requiresAuth: false);
  }

  static Future<Map<String, dynamic>> getFeed() async => get('/feed');

  static Future<Map<String, dynamic>> createPost({
    required String caption,
    String imageUrl = '',
    String location = '',
  }) async {
    return post('/posts', body: {
      'caption': caption,
      'image_url': imageUrl,
      'location': location,
    });
  }

  static Future<Map<String, dynamic>> likePost(String postId) async =>
      post('/posts/$postId/like');

  static Future<Map<String, dynamic>> getComments(String postId) async =>
      get('/posts/$postId/comments');

  static Future<Map<String, dynamic>> addComment(String postId, String text) async =>
      post('/posts/$postId/comments', body: {'text': text});

  static Future<Map<String, dynamic>> getProfile(String userId) async =>
      get('/users/$userId');

  static Future<Map<String, dynamic>> followUser(String userId) async =>
      post('/users/$userId/follow');

  static Future<Map<String, dynamic>> getStories() async => get('/stories');

  static Future<Map<String, dynamic>> searchUsers(String query) async =>
      get('/search/users?q=$query');

  static Future<Map<String, dynamic>> getNotifications() async =>
      get('/notifications');

  static Future<String?> uploadImage(String base64Image) async {
    final result = await post('/upload', body: {'image': base64Image});
    return result['url'];
  }
}
