import 'package:flutter/material.dart';
import '../services/api_client.dart';
import '../theme/app_theme.dart';
import '../widgets/cat_mark.dart';
import 'home_screen.dart';

class AuthScreen extends StatefulWidget {
  final ApiClient api;
  const AuthScreen({super.key, required this.api});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool _isRegister = false;
  bool _loading = false;
  String? _error;

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  Future<void> _submit() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      if (_isRegister) {
        await widget.api.register(_nameController.text.trim(), _emailController.text.trim(), _passwordController.text);
      } else {
        await widget.api.login(_emailController.text.trim(), _passwordController.text);
      }
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => HomeScreen(api: widget.api)),
      );
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Center(child: CatMark(size: 56)),
                  const SizedBox(height: 12),
                  Text(
                    _isRegister ? 'Create your account' : 'Welcome back',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Shared expenses, without the awkward maths.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.ink, fontSize: 13),
                  ),
                  const SizedBox(height: 24),
                  if (_isRegister) ...[
                    TextField(
                      controller: _nameController,
                      decoration: const InputDecoration(labelText: 'Name'),
                    ),
                    const SizedBox(height: 12),
                  ],
                  TextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(labelText: 'Email'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: const InputDecoration(labelText: 'Password'),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Text(_error!, style: const TextStyle(color: AppColors.coral, fontSize: 13)),
                  ],
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _loading ? null : _submit,
                    child: Text(_loading ? 'Please wait...' : (_isRegister ? 'Sign up' : 'Log in')),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () => setState(() => _isRegister = !_isRegister),
                    child: Text(_isRegister ? 'Already have an account? Log in' : "New here? Create an account"),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
