import 'package:flutter/material.dart';
import 'package:multando_sdk/multando_sdk.dart';
import 'package:multando_sdk/src/widgets/multando_provider.dart';
import 'package:multando_sdk/src/widgets/report_form.dart';

void main() {
  runApp(const MultandoExampleApp());
}

class MultandoExampleApp extends StatelessWidget {
  const MultandoExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Multando Example',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: const Color(0xFF3B5EEF),
        useMaterial3: true,
      ),
      home: const LoginPage(),
    );
  }
}

/// A simple login form that initializes the MultandoClient, authenticates,
/// then navigates to the report creation screen.
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController(text: 'demo@multando.io');
  final _passwordController = TextEditingController(text: 'password123');
  final _client = MultandoClient();
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initSdk();
  }

  Future<void> _initSdk() async {
    await _client.initialize(
      const MultandoConfig(
        baseUrl: 'https://api.multando.io',
        apiKey: 'example-api-key',
        locale: 'en',
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _client.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await _client.auth.login(
        LoginRequest(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        ),
      );

      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => ReportPage(client: _client),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.shield_outlined,
                  size: 64,
                  color: Color(0xFF3B5EEF),
                ),
                const SizedBox(height: 12),
                Text(
                  'Multando',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF3B5EEF),
                      ),
                ),
                const SizedBox(height: 32),
                TextField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _passwordController,
                  decoration: const InputDecoration(
                    labelText: 'Password',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.lock_outlined),
                  ),
                  obscureText: true,
                ),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    _error!,
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                ],
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: FilledButton(
                    onPressed: _loading ? null : _login,
                    child: _loading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Sign In'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Shows the ReportForm widget wrapped in a MultandoProvider.
class ReportPage extends StatelessWidget {
  const ReportPage({super.key, required this.client});

  final MultandoClient client;

  @override
  Widget build(BuildContext context) {
    return MultandoProvider(
      client: client,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Create Report'),
          backgroundColor: const Color(0xFF3B5EEF),
          foregroundColor: Colors.white,
        ),
        body: ReportForm(
          client: client,
          onReportCreated: (report) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Report created: ${report.id}'),
                backgroundColor: const Color(0xFF10B981),
              ),
            );
            Navigator.of(context).pop();
          },
        ),
      ),
    );
  }
}
