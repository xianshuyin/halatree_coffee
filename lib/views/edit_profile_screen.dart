import 'package:coffee/controllers/edit_profile_controller.dart';
import 'package:coffee/utils/color.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

class EditProfileScreen extends GetView<EditProfileController> {
  const EditProfileScreen({super.key});

  static String? _emailValidator(String? value) {
    final s = value?.trim() ?? '';
    if (s.isEmpty) return 'Email is required';
    if (!s.contains('@')) return 'Enter a valid email';
    return null;
  }

  static String? _requiredName(String? value, String label) {
    final s = value?.trim() ?? '';
    if (s.isEmpty) return '$label is required';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: colorBackground,
      appBar: AppBar(
        title: Text('Edit profile', style: GoogleFonts.roboto(fontWeight: FontWeight.w600)),
        actions: [
          Obx(() {
            final busy = controller.loading.value;
            return TextButton(
              onPressed: busy ? null : controller.save,
              child: busy
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text('Save', style: GoogleFonts.roboto(fontWeight: FontWeight.w600, color: colorPrimaryDark)),
            );
          }),
        ],
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
                  'Update your details',
                  style: GoogleFonts.roboto(
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                    color: colorOnBackground,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Changes apply to your Hala Tree account.',
                  style: GoogleFonts.roboto(fontSize: 14, color: colorOnSurface),
                ),
                const SizedBox(height: 28),
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
                    labelText: 'user name',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  validator: (v) => _requiredName(v, 'User name'),
                ),
                // const SizedBox(height: 16),
                // TextFormField(
                //   controller: controller.lastNameCtrl,
                //   textCapitalization: TextCapitalization.words,
                //   decoration: InputDecoration(
                //     labelText: 'Last name',
                //     border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                //   ),
                //   validator: (v) => _requiredName(v, 'Last name'),
                // ),
                const SizedBox(height: 28),
                Obx(() {
                  final busy = controller.loading.value;
                  return FilledButton(
                    onPressed: busy ? null : controller.save,
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
                        : Text('Save changes', style: GoogleFonts.roboto(fontWeight: FontWeight.w600)),
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
