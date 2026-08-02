import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import 'package:go_router/go_router.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();

  void _login() async {
    await ref.read(authProvider.notifier).loginOnline(
      _phoneController.text.trim(),
      _passwordController.text.trim(),
    );
    
    // Redirects handled by router based on state, but we can setup PIN here
    final authState = ref.read(authProvider);
    if (authState.status == AuthStatus.authenticated && mounted) {
      context.go('/pin_setup');
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Ramest Krishi',
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.green),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
              TextField(
                controller: _phoneController,
                decoration: const InputDecoration(labelText: 'Phone Number', border: OutlineInputBorder()),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passwordController,
                decoration: const InputDecoration(labelText: 'Password', border: OutlineInputBorder()),
                obscureText: true,
              ),
              const SizedBox(height: 24),
              if (authState.error != null)
                Text(authState.error!, style: const TextStyle(color: Colors.red)),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: authState.isLoading ? null : _login,
                style: ElevatedButton.styleFrom(padding: const EdgeInsets.all(16)),
                child: authState.isLoading
                    ? const CircularProgressIndicator()
                    : const Text('LOGIN'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
