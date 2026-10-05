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
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _currentPasswordController =
  TextEditingController();
  final TextEditingController _newPasswordController =
  TextEditingController();
  final TextEditingController _confirmPasswordController =
  TextEditingController();

  bool _loading = true;
  bool _saving = false;
  String? _error;

  String _originalName = '';
  String _originalEmail = '';

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final user = await _userService.getUser();

    if (!mounted) return;

    if (user != null) {
      _nameController.text = user.name;
      _emailController.text = user.email;

      _originalName = user.name;
      _originalEmail = user.email;
    }

    setState(() {
      _loading = false;
    });
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final currentPassword = _currentPasswordController.text;
    final newPassword = _newPasswordController.text;
    final confirmPassword = _confirmPasswordController.text;

    setState(() {
      _error = null;
    });

    if (name.isEmpty) {
      setState(() {
        _error = 'Enter your name.';
      });
      return;
    }

    if (email.isEmpty) {
      setState(() {
        _error = 'Enter your email.';
      });
      return;
    }

    final emailChanged =
        email.toLowerCase() != _originalEmail.toLowerCase();

    final passwordChanged = newPassword.isNotEmpty;

    if (emailChanged || passwordChanged) {
      if (currentPassword.isEmpty) {
        setState(() {
          _error =
          'Enter your current password to change your email or password.';
        });
        return;
      }
    }

    if (passwordChanged) {
      if (newPassword.length < 6) {
        setState(() {
          _error = 'New password must be at least 6 characters.';
        });
        return;
      }

      if (newPassword != confirmPassword) {
        setState(() {
          _error = 'New passwords do not match.';
        });
        return;
      }
    }

    setState(() {
      _saving = true;
    });

    try {
      // Update name if changed.
      if (name != _originalName) {
        await _userService.updateName(name);
      }

      // Update email if changed.
      if (emailChanged) {
        await _userService.updateEmail(
          currentPassword: currentPassword,
          newEmail: email,
        );
      }

      // Update password if changed.
      if (passwordChanged) {
        await _userService.updatePassword(
          currentPassword: currentPassword,
          newPassword: newPassword,
        );
      }

      if (!mounted) return;

      Navigator.pop(context);
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;

      String message;

      switch (e.code) {
        case 'wrong-password':
        case 'invalid-credential':
          message = 'Current password is incorrect.';
          break;

        case 'email-already-in-use':
          message = 'This email is already in use.';
          break;

        case 'invalid-email':
          message = 'Please enter a valid email address.';
          break;

        case 'weak-password':
          message = 'New password is too weak.';
          break;

        case 'requires-recent-login':
          message = 'Please sign in again and try again.';
          break;

        default:
          message = e.message ?? 'Could not update your profile.';
      }

      setState(() {
        _saving = false;
        _error = message;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _saving = false;
        _error = 'Could not update your profile. Please try again.';
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = Theme.of(context).textTheme;

    if (_loading) {
      return Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: colors.gradient,
          ),
          child: const Center(
            child: CircularProgressIndicator(),
          ),
        ),
      );
    }

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: colors.gradient,
        ),
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
                      onTap: _saving
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

              // Personal information
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

                    AppTextField(
                      label: 'Email',
                      hint: 'Enter your email',
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Password
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'CHANGE PASSWORD',
                      style: text.labelSmall,
                    ),

                    const SizedBox(height: 8),

                    Text(
                      'Leave the new password fields empty if you do not want to change your password.',
                      style: text.bodySmall,
                    ),

                    const SizedBox(height: 18),

                    AppTextField(
                      label: 'Current Password',
                      hint: 'Enter your current password',
                      controller: _currentPasswordController,
                      obscureText: true,
                    ),

                    const SizedBox(height: 16),

                    AppTextField(
                      label: 'New Password',
                      hint: 'Enter your new password',
                      controller: _newPasswordController,
                      obscureText: true,
                    ),

                    const SizedBox(height: 16),

                    AppTextField(
                      label: 'Confirm New Password',
                      hint: 'Confirm your new password',
                      controller: _confirmPasswordController,
                      obscureText: true,
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
                onPressed: _save,
              ),
            ],
          ),
        ),
      ),
    );
  }
}