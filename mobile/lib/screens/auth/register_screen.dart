import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../home/home_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String _province = 'Malaita';
  bool _loading = false;
  String _error = '';

  final List<String> _provinces = [
    'Malaita', 'Guadalcanal', 'Western', 'Choiseul',
    'Isabel', 'Makira', 'Temotu', 'Rennell and Bellona',
    'Central', 'Honiara'
  ];

  Future<void> _register() async {
    setState(() { _loading = true; _error = ''; });
    try {
      final data = await ApiService.register(
        username: _usernameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text,
        province: _province,
      );
      if (data['token'] != null) {
        await ApiService.saveToken(data['token']);
        await ApiService.saveUser(data['user_id'], data['username']);
        if (!mounted) return;
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const HomeScreen()),
          (route) => false,
        );
      } else {
        setState(() { _error = data['error'] ?? 'Registration failed'; });
      }
    } catch (e) {
      setState(() { _error = 'Network error'; });
    }
    setState(() { _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: const Color(0xFF1A1A2E)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ShaderMask(
                shaderCallback: (bounds) =>
                    RikiaTheme.rainbowGradient.createShader(bounds),
                child: const Text(
                  'Join Rikia',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Create your account',
                style: TextStyle(color: const Color(0xFF6B7280), fontSize: 16),
              ),
              const SizedBox(height: 32),
              _buildLabel('USERNAME'),
              TextField(
                controller: _usernameController,
                autocorrect: false,
                style: const TextStyle(color: const Color(0xFF1A1A2E)),
                decoration: const InputDecoration(
                  hintText: 'your_username',
                  prefixIcon: Icon(Icons.person_outline, color: const Color(0xFF6B7280)),
                ),
              ),
              const SizedBox(height: 16),
              _buildLabel('EMAIL'),
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                autocorrect: false,
                style: const TextStyle(color: const Color(0xFF1A1A2E)),
                decoration: const InputDecoration(
                  hintText: 'your@email.com',
                  prefixIcon: Icon(Icons.email_outlined, color: const Color(0xFF6B7280)),
                ),
              ),
              const SizedBox(height: 16),
              _buildLabel('PASSWORD'),
              TextField(
                controller: _passwordController,
                obscureText: true,
                style: const TextStyle(color: const Color(0xFF1A1A2E)),
                decoration: const InputDecoration(
                  hintText: '••••••••',
                  prefixIcon: Icon(Icons.lock_outline, color: const Color(0xFF6B7280)),
                ),
              ),
              const SizedBox(height: 16),
              _buildLabel('PROVINCE'),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.whiteLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _province,
                    dropdownColor: Colors.whiteLight,
                    isExpanded: true,
                    style: const TextStyle(color: const Color(0xFF1A1A2E)),
                    items: _provinces.map((p) => DropdownMenuItem(
                      value: p,
                      child: Text(p),
                    )).toList(),
                    onChanged: (v) => setState(() => _province = v!),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              if (_error.isNotEmpty)
                Text(_error, style: const TextStyle(color: RikiaTheme.red)),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RikiaTheme.rainbowGradient,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ElevatedButton(
                    onPressed: _loading ? null : _register,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _loading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'Create Account',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(
          color: const Color(0xFF6B7280),
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.5,
        ),
      ),
    );
  }
}
