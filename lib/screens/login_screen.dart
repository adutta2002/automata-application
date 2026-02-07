import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart'; // Ensure this is available or use standard TextStyles
import '../providers/auth_provider.dart';
import '../core/app_theme.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _rememberMe = false;
  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final authProvider = context.read<AuthProvider>();
    final error = await authProvider.login(
      _usernameController.text.trim(),
      _passwordController.text,
      rememberMe: _rememberMe,
    );

    if (mounted) {
      if (error != null) {
        setState(() {
          _isLoading = false;
          _errorMessage = error;
        });
      } else {
         // Login successful, navigation is usually handled by the wrapper or router 
         // monitoring the auth state. If not, we might need manual navigation here 
         // but usually AuthProvider notifies listeners.
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isDesktop = screenSize.width > 900;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Row(
        children: [
          // Left Side - Branding (Desktop Only)
          if (isDesktop)
            Expanded(
              flex: 5,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.primaryColor,
                      AppTheme.primaryColor.withAlpha(200), // Slightly lighter
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(50), // Semi-transparent
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.storefront_rounded,
                        size: 80,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 32),
                    Text(
                      'Welcome to\nAutomata POS',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.outfit( // Using Outfit or primary font
                        fontSize: 42,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Seamless Point of Sale Experience\nfor Modern Retail',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.white.withAlpha(200),
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          
          // Right Side - Login Form
          Expanded(
            flex: 4,
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(32),
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 480),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Mobile Logo/Title (Visible only on small screens)
                        if (!isDesktop) ...[
                           const Icon(
                            Icons.storefront_rounded,
                            size: 64,
                            color: AppTheme.primaryColor,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Automata POS',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.outfit(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                          const SizedBox(height: 32),
                        ],

                        // Form Headers
                        Text(
                          'Welcome Back',
                          style: GoogleFonts.outfit(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textColor,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Please sign in to access your dashboard.',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 32),

                        // Error Message
                        if (_errorMessage != null)
                          Container(
                            padding: const EdgeInsets.all(12),
                            margin: const EdgeInsets.only(bottom: 24),
                            decoration: BoxDecoration(
                              color: Colors.red.shade50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.red.shade200),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.error_outline, color: Colors.red.shade700, size: 20),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    _errorMessage!,
                                    style: TextStyle(color: Colors.red.shade800, fontSize: 14),
                                  ),
                                ),
                              ],
                            ),
                          ),

                        // Username
                        _buildLabel('Username'),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _usernameController,
                          decoration: _inputDecoration('Enter your username', Icons.person_outline),
                          validator: (val) {
                             if (val == null || val.isEmpty) return 'Username is required';
                             return null;
                          },
                          onFieldSubmitted: (_) => _handleLogin(),
                        ),
                        const SizedBox(height: 24),

                        // Password
                        _buildLabel('Password'),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          decoration: _inputDecoration('Enter your password', Icons.lock_outline).copyWith(
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                                color: Colors.grey.shade500,
                              ),
                              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                            ),
                          ),
                          validator: (val) {
                             if (val == null || val.isEmpty) return 'Password is required';
                             return null;
                          },
                          onFieldSubmitted: (_) => _handleLogin(),
                        ),
                        const SizedBox(height: 8),

                        // Remember Me
                        Row(
                          children: [
                            Checkbox(
                              value: _rememberMe,
                              activeColor: AppTheme.primaryColor,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                              onChanged: (val) => setState(() => _rememberMe = val ?? false),
                            ),
                            const Text('Remember me', style: TextStyle(fontWeight: FontWeight.w500)),
                            const Spacer(),
                           // TextButton(
                           //   onPressed: () {}, 
                           //   child: const Text('Forgot Password?')
                           // ),
                          ],
                        ),

                        const SizedBox(height: 32),

                        // Login Button
                        SizedBox(
                          height: 56,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _handleLogin,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryColor,
                              foregroundColor: Colors.white,
                              elevation: 4,
                              shadowColor: AppTheme.primaryColor.withAlpha(100), // ~0.4 opacity
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    height: 24,
                                    width: 24,
                                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.4),
                                  )
                                : const Text(
                                    'Sign In',
                                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                  ),
                          ),
                        ),

                        const SizedBox(height: 48),

                        // Default Credentials (Dev only)
                         Container(
                          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.blue.shade50,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(Icons.lock_open, size: 16, color: Colors.blue.shade700),
                              ),
                              const SizedBox(width: 16),
                               Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Default Access', style: TextStyle(color: Colors.grey.shade800, fontWeight: FontWeight.bold, fontSize: 13)),
                                  const SizedBox(height: 2),
                                  Text('admin / admin123', style: TextStyle(color: Colors.grey.shade600, fontSize: 13, fontFamily: 'monospace')),
                                ],
                              ),
                            ],
                          ),
                        ),
                        
                        const SizedBox(height: 24),
                        Center(
                          child: Text(
                            '© 2026 Automata POS. All rights reserved.',
                            style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
        fontWeight: FontWeight.w600,
        fontSize: 14,
        color: AppTheme.textColor,
      ),
    );
  }

  InputDecoration _inputDecoration(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.grey.shade400),
      prefixIcon: Icon(icon, color: Colors.grey.shade400, size: 20),
      filled: true,
      fillColor: Colors.grey.shade50, // Subtle grey bg for fields
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppTheme.primaryColor, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.red.shade200),
      ),
    );
  }
}
