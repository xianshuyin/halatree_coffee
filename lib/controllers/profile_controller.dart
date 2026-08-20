import 'package:coffee/models/user_model.dart';
import 'package:coffee/route.dart';
import 'package:coffee/utils/auth_storage.dart';
import 'package:coffee/utils/color.dart';
import 'package:coffee/utils/constants.dart';
import 'package:coffee/utils/password_validator.dart';
import 'package:coffee/webservice/api.dart';
import 'package:coffee/webservice/dio_util.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:google_fonts/google_fonts.dart';

class ProfileController extends GetxController {
  final cache = GetStorage();
  late final Api api;

  final Rxn<UserModel> user = Rxn<UserModel>();

  @override
  void onInit() {
    super.onInit();
    api = Api(DioUtil(null).getDio(), baseUrl: DioUtil.mainUrl!);
    refreshFromConstants();
  }

  void refreshFromConstants() {
    user.value = Constants.userModel;
    user.refresh();
  }

  /// Password from [Constants.userModel] when the API returns it, otherwise the cached login password.
  String? get _expectedPassword {
    final fromModel = Constants.userModel?.password;
    if (fromModel != null && fromModel.isNotEmpty) return fromModel;
    final cached = cache.read(AuthStorage.passwordKey)?.toString();
    if (cached != null && cached.isNotEmpty) return cached;
    return null;
  }

  void onEditProfilePressed() {
    final expected = _expectedPassword;
    if (expected == null) {
      showToastMessage('Unable to verify your password. Please sign in again.');
      return;
    }

    Get.dialog<void>(
      _ConfirmPasswordDialog(
        expectedPassword: expected,
        prompt: 'Enter your account password to edit your profile.',
        onVerified: _openEditProfile,
      ),
    );
  }

  void onUpdatePasswordPressed() {
    final expected = _expectedPassword;
    if (expected == null) {
      showToastMessage('Unable to verify your password. Please sign in again.');
      return;
    }

    Get.dialog<void>(
      _ConfirmPasswordDialog(
        expectedPassword: expected,
        prompt: 'Enter your current password to continue.',
        onVerified: () async => _openNewPasswordDialog(expected),
      ),
    );
  }

  Future<void> _openEditProfile() async {
    await Get.toNamed(RouteName.profileEditView);
    // GetX does not always deliver `Get.back(result: …)` to `toNamed`'s future; sync from [Constants.userModel] whenever the edit route is popped.
    refreshFromConstants();
  }

  void _openNewPasswordDialog(String currentPassword) {
    Get.dialog<void>(
      _NewPasswordDialog(
        currentPassword: currentPassword,
        onSubmit: _submitNewPassword,
      ),
    );
  }

  Future<bool> _submitNewPassword(String newPassword) async {
    final userId = Constants.userModel?.id;
    if (userId == null || userId.isEmpty) {
      showToastMessage('Missing user id');
      return false;
    }

    final online = await Constants.checkNetwork();
    if (!online) {
      showToastMessage('No internet connection');
      return false;
    }

    print(userId);
    print(newPassword);
    try {
      final res = await api.updatepassword(userId, newPassword);
      if (res.message != 'success') {
        showToastMessage(res.message ?? 'Could not update password');
        return false;
      }

      _persistNewPassword(newPassword);
      showToastMessage('Password updated');
      return true;
    } catch (e) {
      print(e);
      showToastMessage('Could not update password. Please try again.');
      return false;
    }
  }

  void _persistNewPassword(String password) {
    cache.write(AuthStorage.passwordKey, password);
    final email = Constants.userModel?.email ?? cache.read(AuthStorage.emailKey)?.toString();
    if (email != null && email.isNotEmpty) {
      cache.write(AuthStorage.emailKey, email);
    }
    Constants.userModel?.password = password;
  }
}

class _ConfirmPasswordDialog extends StatefulWidget {
  final String expectedPassword;
  final String prompt;
  final Future<void> Function() onVerified;

  const _ConfirmPasswordDialog({
    required this.expectedPassword,
    required this.prompt,
    required this.onVerified,
  });

  @override
  State<_ConfirmPasswordDialog> createState() => _ConfirmPasswordDialogState();
}

class _ConfirmPasswordDialogState extends State<_ConfirmPasswordDialog> {
  late final TextEditingController _pwdCtrl;
  bool _obscure = true;

  @override
  void initState() {
    super.initState();
    _pwdCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _pwdCtrl.dispose();
    super.dispose();
  }

  void _onContinue() {
    if (_pwdCtrl.text != widget.expectedPassword) {
      showToastMessage('Incorrect password');
      return;
    }
    Get.back<void>();
    widget.onVerified();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(
        'Confirm password',
        style: GoogleFonts.roboto(fontWeight: FontWeight.w600),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            widget.prompt,
            style: GoogleFonts.roboto(fontSize: 14, color: colorOnSurface),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _pwdCtrl,
            obscureText: _obscure,
            decoration: InputDecoration(
              labelText: 'Password',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              suffixIcon: IconButton(
                icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                onPressed: () => setState(() => _obscure = !_obscure),
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Get.back<void>(),
          child: Text('Cancel', style: GoogleFonts.roboto(color: colorOnSurface)),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: colorPrimaryDark,
            foregroundColor: colorOnPrimary,
          ),
          onPressed: _onContinue,
          child: Text('Continue', style: GoogleFonts.roboto(fontWeight: FontWeight.w600)),
        ),
      ],
    );
  }
}

class _NewPasswordDialog extends StatefulWidget {
  final String currentPassword;
  final Future<bool> Function(String newPassword) onSubmit;

  const _NewPasswordDialog({
    required this.currentPassword,
    required this.onSubmit,
  });

  @override
  State<_NewPasswordDialog> createState() => _NewPasswordDialogState();
}

class _NewPasswordDialogState extends State<_NewPasswordDialog> {
  late final TextEditingController _passwordCtrl;
  late final TextEditingController _confirmCtrl;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _passwordCtrl = TextEditingController();
    _confirmCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _onUpdate() async {
    if (_saving) return;

    final pwdError = PasswordValidator.validateSignupPassword(
      _passwordCtrl.text,
      _confirmCtrl.text,
    );
    if (pwdError != null) {
      showToastMessage(pwdError);
      return;
    }

    if (_passwordCtrl.text == widget.currentPassword) {
      showToastMessage('New password must be different from the current password');
      return;
    }

    setState(() => _saving = true);
    final ok = await widget.onSubmit(_passwordCtrl.text);
    if (!mounted) return;
    setState(() => _saving = false);
    if (ok) Get.back<void>();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(
        'Update password',
        style: GoogleFonts.roboto(fontWeight: FontWeight.w600),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Password must be at least 8 characters and include a letter and a number.',
              style: GoogleFonts.roboto(fontSize: 14, color: colorOnSurface),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _passwordCtrl,
              obscureText: _obscurePassword,
              decoration: InputDecoration(
                labelText: 'New password',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                suffixIcon: IconButton(
                  icon: Icon(_obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _confirmCtrl,
              obscureText: _obscureConfirm,
              decoration: InputDecoration(
                labelText: 'Confirm new password',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                suffixIcon: IconButton(
                  icon: Icon(_obscureConfirm ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                  onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Get.back<void>(),
          child: Text('Cancel', style: GoogleFonts.roboto(color: colorOnSurface)),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: colorPrimaryDark,
            foregroundColor: colorOnPrimary,
          ),
          onPressed: _saving ? null : _onUpdate,
          child: _saving
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: colorOnPrimary),
                )
              : Text('Update', style: GoogleFonts.roboto(fontWeight: FontWeight.w600)),
        ),
      ],
    );
  }
}
