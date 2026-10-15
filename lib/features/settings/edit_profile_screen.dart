
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../services/user_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_card.dart';
import '../../widgets/app_text_field.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final UserService _userService = UserService();
  final TextEditingController _nameController = TextEditingController();

  bool _loading = true;
  bool _saving = false;
  bool _sendingResetEmail = false;

  String _email = '';
  String _originalName = '';
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    try {
      final user = await _userService.getUser();

      if (!mounted) return;

      if (user != null) {
        _nameController.text = user.name;
        _originalName = user.name;
        _email = user.email;
      }
    } catch (e) {
      debugPrint('Load profile error: $e');

      if (!mounted) return;
      _error = 'Could not load your profile.';
    }

    if (mounted) {
      setState(() => _loading = false);
    }
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();

    if (name.isEmpty) {
      setState(() => _error = 'Enter your name.');
      return;
    }

    setState(() {
      _error = null;
      _saving = true;
    });

    try {
      if (name != _originalName) {
        await _userService.updateName(name);
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile updated successfully.'),
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      debugPrint('Save profile error: $e');

      if (!mounted) return;

      setState(() {
        _saving = false;
        _error = 'Could not update your profile. Please try again.';
      });
    }
  }

  Future<void> _changePassword() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Change Password'),
        content: const Text(
          'A password reset link will be sent to your registered '
              'email address. Continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Send Email'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _sendingResetEmail = true);

    try {
      await _userService.sendPasswordResetToCurrentUser();

      debugPrint('Password reset email request completed.');

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'If an account exists for this email, a password reset '
                'email should arrive at $_email. Check your inbox and spam.',
          ),
          duration: const Duration(seconds: 5),
        ),
      );
    } on FirebaseAuthException catch (e) {
      debugPrint('Password reset error code: ${e.code}');
      debugPrint('Password reset error message: ${e.message}');

      if (!mounted) return;

      String message;

      switch (e.code) {
        case 'user-not-found':
          message = 'No signed-in account with an email was found.';
          break;
        case 'invalid-email':
          message = 'The account email address is invalid.';
          break;
        case 'too-many-requests':
          message = 'Too many attempts. Please try again later.';
          break;
        case 'network-request-failed':
          message = 'Network error. Check your internet connection.';
          break;
        case 'operation-not-allowed':
          message = 'Password reset is not enabled in Firebase.';
          break;
        default:
          message = 'Could not send the reset email (${e.code}).';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          duration: const Duration(seconds: 6),
        ),
      );
    } catch (e) {
      debugPrint('Unexpected password reset error: $e');

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Unexpected error. Check the terminal for details.',
          ),
          duration: Duration(seconds: 5),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _sendingResetEmail = false);
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = Theme.of(context).textTheme;

    if (_loading) {
      return Scaffold(
        body: Container(
          decoration: BoxDecoration(gradient: colors.gradient),
          child: const Center(
            child: CircularProgressIndicator(),
          ),
        ),
      );
    }

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: colors.gradient),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
            children: [
              Row(
                children: [
                  Material(
                    color: colors.surfaceAlt,
                    shape: const CircleBorder(),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: _saving || _sendingResetEmail
                          ? null
                          : () => Navigator.pop(context),
                      child: SizedBox(
                        width: 48,
                        height: 48,
                        child: Icon(
                          Icons.chevron_left,
                          color: colors.text,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      'Edit Profile',
                      style: text.headlineLarge,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Update your account information',
                style: text.bodySmall,
              ),
              const SizedBox(height: 28),
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'PERSONAL INFORMATION',
                      style: text.labelSmall,
                    ),
                    const SizedBox(height: 18),
                    AppTextField(
                      label: 'Name',
                      hint: 'Enter your name',
                      controller: _nameController,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Email',
                      style: text.labelMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _email,
                      style: text.bodyLarge,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'SECURITY',
                      style: text.labelSmall,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Change your password securely using a link sent '
                          'to your registered email address.',
                      style: text.bodySmall,
                    ),
                    const SizedBox(height: 18),
                    AppButton(
                      label: 'Change Password',
                      loading: _sendingResetEmail,
                      onPressed: _sendingResetEmail || _saving
                          ? null
                          : _changePassword,
                    ),
                  ],
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 16),
                Text(
                  _error!,
                  style: text.bodySmall?.copyWith(
                    color: colors.error,
                  ),
                ),
              ],
              const SizedBox(height: 24),
              AppButton(
                label: 'Save changes',
                loading: _saving,
                onPressed: _saving || _sendingResetEmail
                    ? null
                    : _save,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
