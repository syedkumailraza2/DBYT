import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/theme.dart';
import '../../core/providers/auth_provider.dart';
import '../../widgets/widgets.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _usernameController;
  late TextEditingController _emailController;
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = false;
  bool _changePassword = false;

  @override
  void initState() {
    super.initState();
    final authProvider = context.read<AuthProvider>();
    _usernameController = TextEditingController(text: authProvider.user?.username ?? '');
    _emailController = TextEditingController(text: authProvider.user?.email ?? '');
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isLoading = true);

    final authProvider = context.read<AuthProvider>();
    final currentUser = authProvider.user;

    // Determine what changed
    String? newUsername;
    String? newEmail;
    String? newPassword;

    if (_usernameController.text.trim() != currentUser?.username) {
      newUsername = _usernameController.text.trim();
    }

    if (_emailController.text.trim() != currentUser?.email) {
      newEmail = _emailController.text.trim();
    }

    if (_changePassword && _newPasswordController.text.isNotEmpty) {
      newPassword = _newPasswordController.text;
    }

    // Check if anything changed
    if (newUsername == null && newEmail == null && newPassword == null) {
      setState(() => _isLoading = false);
      _showSnackBar('No changes to save', isError: false);
      return;
    }

    final success = await authProvider.updateProfile(
      username: newUsername,
      email: newEmail,
      password: newPassword,
    );

    if (mounted) {
      setState(() => _isLoading = false);

      if (success) {
        _showSnackBar('Profile updated successfully', isError: false);
        Navigator.pop(context);
      } else {
        _showSnackBar(authProvider.errorMessage ?? 'Update failed', isError: true);
      }
    }
  }

  void _showSnackBar(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: AppTextStyles.bodyMedium.copyWith(color: AppColors.white),
        ),
        backgroundColor: isError ? AppColors.ctaRed : AppColors.ctaGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  String? _validateUsername(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Username is required';
    }
    if (value.trim().length < 3) {
      return 'Username must be at least 3 characters';
    }
    return null;
  }

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email is required';
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value.trim())) {
      return 'Please enter a valid email';
    }
    return null;
  }

  String? _validateNewPassword(String? value) {
    if (!_changePassword) return null;
    if (value == null || value.isEmpty) {
      return 'Please enter new password';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (!_changePassword) return null;
    if (value != _newPasswordController.text) {
      return 'Passwords do not match';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        title: const Text('Edit Profile'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _handleSave,
            child: _isLoading
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.primaryTeal,
                    ),
                  )
                : Text(
                    'Save',
                    style: AppTextStyles.labelLarge.copyWith(
                      color: AppColors.primaryTeal,
                    ),
                  ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildProfileAvatar(),
              const SizedBox(height: 32),
              _buildSectionHeader('Account Information'),
              const SizedBox(height: 16),
              CustomTextField(
                label: 'Username',
                hint: 'Enter your username',
                controller: _usernameController,
                prefixIcon: Icons.person_outline,
                validator: _validateUsername,
              ),
              const SizedBox(height: 16),
              CustomTextField(
                label: 'Email',
                hint: 'Enter your email',
                controller: _emailController,
                prefixIcon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
                validator: _validateEmail,
              ),
              const SizedBox(height: 32),
              _buildPasswordSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileAvatar() {
    final username = context.watch<AuthProvider>().username ?? 'U';

    return Center(
      child: Stack(
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryTeal.withValues(alpha: 0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Center(
              child: Text(
                username[0].toUpperCase(),
                style: AppTextStyles.displayMedium.copyWith(
                  color: AppColors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primaryTeal,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.white, width: 2),
              ),
              child: Icon(
                Icons.camera_alt,
                size: 16,
                color: AppColors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: AppTextStyles.headlineSmall.copyWith(
        color: AppColors.primaryDark,
      ),
    );
  }

  Widget _buildPasswordSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildSectionHeader('Change Password'),
            Switch(
              value: _changePassword,
              onChanged: (value) {
                setState(() {
                  _changePassword = value;
                  if (!value) {
                    _currentPasswordController.clear();
                    _newPasswordController.clear();
                    _confirmPasswordController.clear();
                  }
                });
              },
              activeColor: AppColors.primaryTeal,
            ),
          ],
        ),
        if (_changePassword) ...[
          const SizedBox(height: 16),
          CustomTextField(
            label: 'New Password',
            hint: 'Enter new password',
            controller: _newPasswordController,
            prefixIcon: Icons.lock_outline,
            obscureText: true,
            validator: _validateNewPassword,
          ),
          const SizedBox(height: 16),
          CustomTextField(
            label: 'Confirm Password',
            hint: 'Confirm new password',
            controller: _confirmPasswordController,
            prefixIcon: Icons.lock_outline,
            obscureText: true,
            validator: _validateConfirmPassword,
          ),
        ],
      ],
    );
  }
}
