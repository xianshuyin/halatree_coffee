import 'package:coffee/controllers/signup_controller.dart';
import 'package:coffee/utils/color.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

class SignupScreen extends GetView<SignupController> {
  const SignupScreen({super.key});

  static String? _emailValidator(String? value) {
    final s = value?.trim() ?? '';
    if (s.isEmpty) return 'Email is required';
    if (!s.contains('@')) return 'Enter a valid email';
    return null;
  }

  static String? _required(String? value, String label) {
    if (value == null || value.trim().isEmpty) return '$label is required';
    return null;
  }

  static String? _passwordValidator(String? value) {
    if (value == null || value.isEmpty) return 'Password is required';
    return null;
  }

  static String? _confirmValidator(String? value) {
    if (value == null || value.isEmpty) return 'Confirm your password';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: colorBackground,
      appBar: AppBar(
        title: Text('Sign up', style: GoogleFonts.roboto(fontWeight: FontWeight.w600)),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Form(
            key: controller.formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Create an account',
                  style: GoogleFonts.roboto(
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                    color: colorOnBackground,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Password must be at least 8 characters and include a letter and a number.',
                  style: GoogleFonts.roboto(fontSize: 13, color: colorOnSurface),
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: controller.emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  autocorrect: false,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  validator: _emailValidator,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: controller.userNameCtrl,
                  textCapitalization: TextCapitalization.words,
                  decoration: InputDecoration(
                    labelText: 'User name',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  validator: (v) => _required(v, 'User name'),
                ),
                // const SizedBox(height: 16),
                // TextFormField(
                //   controller: controller.lastNameCtrl,
                //   textCapitalization: TextCapitalization.words,
                //   decoration: InputDecoration(
                //     labelText: 'Last name',
                //     border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                //   ),
                //   validator: (v) => _required(v, 'Last name'),
                // ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: controller.passwordCtrl,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  validator: _passwordValidator,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: controller.confirmPasswordCtrl,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'Confirm password',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  validator: _confirmValidator,
                ),
                const SizedBox(height: 28),
                Obx(() {
                  final busy = controller.loading.value;
                  return FilledButton(
                    onPressed: busy ? null : controller.submit,
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      backgroundColor: colorPrimaryDark,
                      foregroundColor: colorOnPrimary,
                    ),
                    child: busy
                        ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text('Create account', style: GoogleFonts.roboto(fontWeight: FontWeight.w600)),
                  );
                }),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
