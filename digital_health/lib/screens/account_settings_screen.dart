import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/auth_controller.dart';

class AccountSettingsScreen extends StatefulWidget {
  const AccountSettingsScreen({super.key});

  @override
  State<AccountSettingsScreen> createState() => _AccountSettingsScreenState();
}

class _AccountSettingsScreenState extends State<AccountSettingsScreen> {
  final _nameController = TextEditingController();
  bool _savingName = false;
  bool _sendingReset = false;

  User? get _user => FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    _nameController.text = _user?.displayName ?? '';
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  String get _provider {
    final providers = _user?.providerData.map((p) => p.providerId).toList() ?? [];
    if (providers.contains('google.com')) return 'Google';
    if (providers.contains('password')) return 'Email & Password';
    return 'Unknown';
  }

  Future<void> _saveName() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;
    setState(() => _savingName = true);
    try {
      await _user?.updateDisplayName(name);
      await _user?.reload();
      Get.snackbar('Updated', 'Display name saved.',
          snackPosition: SnackPosition.BOTTOM);
    } catch (e) {
      Get.snackbar('Error', 'Could not update name.',
          snackPosition: SnackPosition.BOTTOM);
    } finally {
      setState(() => _savingName = false);
    }
  }

  Future<void> _sendPasswordReset() async {
    final email = _user?.email;
    if (email == null) return;
    setState(() => _sendingReset = true);
    try {
      await Get.find<AuthController>().resetPassword(email);
    } finally {
      setState(() => _sendingReset = false);
    }
  }

  void _confirmDeleteAccount() {
    Get.defaultDialog(
      title: 'Delete Account',
      titleStyle: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
      middleText:
          'This will permanently delete your account and all health data. This cannot be undone.',
      textConfirm: 'Delete',
      textCancel: 'Cancel',
      confirmTextColor: Colors.white,
      buttonColor: Colors.red,
      onConfirm: () async {
        Get.back();
        try {
          await FirebaseAuth.instance.currentUser?.delete();
          Get.offAllNamed('/login');
        } on FirebaseAuthException catch (e) {
          if (e.code == 'requires-recent-login') {
            Get.snackbar('Re-login Required',
                'Please sign out and sign in again before deleting your account.',
                snackPosition: SnackPosition.BOTTOM);
          } else {
            Get.snackbar('Error', e.message ?? 'Could not delete account.',
                snackPosition: SnackPosition.BOTTOM);
          }
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final email = _user?.email ?? 'Unknown';
    final initial = (_user?.displayName?.isNotEmpty == true)
        ? _user!.displayName![0].toUpperCase()
        : (email.isNotEmpty ? email[0].toUpperCase() : '?');

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: const Text('Account Settings')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Avatar + email header
            Center(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: theme.primaryColor.withOpacity(0.1),
                    child: Text(initial,
                        style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: theme.primaryColor)),
                  ),
                  const SizedBox(height: 12),
                  Text(email,
                      style: const TextStyle(fontSize: 16, color: Colors.grey)),
                  const SizedBox(height: 4),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: theme.primaryColor.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text('Signed in with $_provider',
                        style: TextStyle(
                            fontSize: 13, color: theme.primaryColor)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 36),

            // Update display name
            const Text('Display Name',
                style:
                    TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            TextField(
              controller: _nameController,
              style: const TextStyle(fontSize: 18),
              decoration: InputDecoration(
                hintText: 'Your name',
                hintStyle:
                    const TextStyle(fontSize: 18, color: Colors.grey),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15)),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _savingName ? null : _saveName,
                child: _savingName
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Text('Save Name'),
              ),
            ),

            const SizedBox(height: 32),
            const Divider(),
            const SizedBox(height: 24),

            // Password reset
            const Text('Password',
                style:
                    TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(
              _provider == 'Google'
                  ? 'Your account uses Google Sign-In. Password changes are managed through your Google account.'
                  : 'A reset link will be sent to $email.',
              style: const TextStyle(fontSize: 15, color: Colors.grey),
            ),
            const SizedBox(height: 12),
            if (_provider != 'Google')
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.lock_reset_rounded),
                  label: _sendingReset
                      ? const Text('Sending…')
                      : const Text('Send Password Reset Email'),
                  onPressed: _sendingReset ? null : _sendPasswordReset,
                ),
              ),

            const SizedBox(height: 32),
            const Divider(),
            const SizedBox(height: 24),

            // Danger zone
            const Text('Danger Zone',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.red)),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.delete_forever_rounded,
                    color: Colors.red),
                label: const Text('Delete Account',
                    style: TextStyle(color: Colors.red)),
                style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.red)),
                onPressed: _confirmDeleteAccount,
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
