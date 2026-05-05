import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/auth_controller.dart';
import '../controllers/settings_controller.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final AuthController authController = Get.find<AuthController>();
  final SettingsController _settings = Get.find<SettingsController>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  bool _isRegisterMode = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  void _submit() {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final name = _nameController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      authController.errorMessage.value = 'auth.error.fill_fields'.tr;
      return;
    }
    if (_isRegisterMode && name.isEmpty) {
      authController.errorMessage.value = 'auth.error.enter_name'.tr;
      return;
    }

    if (_isRegisterMode) {
      authController.registerWithEmail(name, email, password);
    } else {
      authController.loginWithEmail(email, password);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0066CC), Color(0xFF003D7A)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // ── Logo & Title ──
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.local_hospital_rounded,
                        size: 60, color: Colors.white),
                  ),
                  const SizedBox(height: 20),
                  Text('app.title'.tr,
                      style: const TextStyle(
                          fontSize: 34,
                          fontWeight: FontWeight.bold,
                          color: Colors.white)),
                  const SizedBox(height: 6),
                  Text(
                    _isRegisterMode
                        ? 'auth.subtitle.register'.tr
                        : 'auth.subtitle.login'.tr,
                    style: const TextStyle(fontSize: 17, color: Colors.white70),
                  ),
                  const SizedBox(height: 40),

                  // ── Form Card ──
                  Container(
                    padding: const EdgeInsets.all(28),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black.withOpacity(0.15),
                            blurRadius: 30,
                            offset: const Offset(0, 10)),
                      ],
                    ),
                    child: Column(
                      children: [
                        // Name field (Register only)
                        if (_isRegisterMode) ...[
                          TextField(
                            controller: _nameController,
                            style: const TextStyle(fontSize: 18),
                            decoration: InputDecoration(
                              labelText: 'auth.field.name'.tr,
                              prefixIcon: const Icon(Icons.person_outline),
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16)),
                            ),
                          ),
                          const SizedBox(height: 18),
                        ],

                        // Email
                        TextField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          style: const TextStyle(fontSize: 18),
                          decoration: InputDecoration(
                            labelText: 'auth.field.email'.tr,
                            prefixIcon: const Icon(Icons.email_outlined),
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16)),
                          ),
                        ),
                        const SizedBox(height: 18),

                        // Password
                        TextField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          style: const TextStyle(fontSize: 18),
                          decoration: InputDecoration(
                            labelText: 'auth.field.password'.tr,
                            prefixIcon: const Icon(Icons.lock_outline),
                            suffixIcon: IconButton(
                              icon: Icon(_obscurePassword
                                  ? Icons.visibility_off
                                  : Icons.visibility),
                              onPressed: () => setState(
                                  () => _obscurePassword = !_obscurePassword),
                            ),
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16)),
                          ),
                          onSubmitted: (_) => _submit(),
                        ),

                        // Forgot password (Login only)
                        if (!_isRegisterMode) ...[
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: () {
                                final email = _emailController.text.trim();
                                if (email.isEmpty) {
                                  Get.snackbar('snackbar.info'.tr,
                                      'auth.error.enter_email_first'.tr,
                                      snackPosition: SnackPosition.BOTTOM);
                                } else {
                                  authController.resetPassword(email);
                                }
                              },
                              child: Text('auth.btn.forgot'.tr,
                                  style: const TextStyle(fontSize: 15)),
                            ),
                          ),
                        ] else
                          const SizedBox(height: 20),

                        // Error message
                        Obx(() {
                          if (authController.errorMessage.value.isNotEmpty) {
                            return Container(
                              width: double.infinity,
                              margin: const EdgeInsets.only(bottom: 15),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.red.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                    color: Colors.red.withOpacity(0.3)),
                              ),
                              child: Text(
                                authController.errorMessage.value,
                                style: const TextStyle(
                                    color: Colors.red, fontSize: 15),
                                textAlign: TextAlign.center,
                              ),
                            );
                          }
                          return const SizedBox.shrink();
                        }),

                        // Submit button
                        Obx(() => SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: authController.isLoading.value
                                    ? null
                                    : _submit,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF0066CC),
                                  foregroundColor: Colors.white,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 18),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16)),
                                ),
                                child: authController.isLoading.value
                                    ? const SizedBox(
                                        height: 22,
                                        width: 22,
                                        child: CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 2.5))
                                    : Text(
                                        _isRegisterMode
                                            ? 'auth.btn.create_account'.tr
                                            : 'auth.btn.signin'.tr,
                                        style: const TextStyle(fontSize: 20)),
                              ),
                            )),

                        const SizedBox(height: 20),

                        // Divider
                        Row(
                          children: [
                            const Expanded(child: Divider()),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 15),
                              child: Text('auth.divider.or'.tr,
                                  style: const TextStyle(
                                      color: Colors.grey, fontSize: 15)),
                            ),
                            const Expanded(child: Divider()),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // Google Sign-In
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: authController.signInWithGoogle,
                            icon: const Icon(Icons.g_mobiledata_rounded,
                                size: 30),
                            label: Text('auth.btn.google'.tr,
                                style: const TextStyle(fontSize: 18)),
                            style: OutlinedButton.styleFrom(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16)),
                              side: const BorderSide(color: Color(0xFFDDDDDD)),
                            ),
                          ),
                        ),

                        const SizedBox(height: 15),

                        // Demo mode
                        TextButton(
                          onPressed: () => Get.offAllNamed('/'),
                          child: Text('auth.btn.demo'.tr,
                              style: const TextStyle(
                                  fontSize: 15, color: Colors.grey)),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 25),

                  // Toggle Login / Register
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _isRegisterMode
                            ? 'auth.toggle.have_account'.tr
                            : 'auth.toggle.no_account'.tr,
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 16),
                      ),
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _isRegisterMode = !_isRegisterMode;
                            authController.errorMessage.value = '';
                          });
                        },
                        child: Text(
                          _isRegisterMode ? 'auth.btn.signin'.tr : 'auth.btn.register'.tr,
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 17,
                              decoration: TextDecoration.underline),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),
                  Text('app.privacy'.tr,
                      style: const TextStyle(color: Colors.white38, fontSize: 13)),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ),
      ),
          // ── Language toggle button ──
          SafeArea(
            child: Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Obx(() {
                  final isSv = _settings.localeCode.value == 'sv';
                  return GestureDetector(
                    onTap: _settings.toggleLocale,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: Colors.white.withOpacity(0.4)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.language,
                              color: Colors.white, size: 16),
                          const SizedBox(width: 6),
                          Text(
                            isSv ? 'EN' : 'SV',
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
