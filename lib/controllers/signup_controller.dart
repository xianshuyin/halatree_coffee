import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

import '../route.dart';
import '../utils/auth_storage.dart';
import '../utils/constants.dart';
import '../utils/password_validator.dart';
import '../webservice/api.dart';
import '../webservice/dio_util.dart';

class SignupController extends GetxController {
  final emailCtrl = TextEditingController();
  final userNameCtrl = TextEditingController();
 // final lastNameCtrl = TextEditingController();
  final passwordCtrl = TextEditingController();
  final confirmPasswordCtrl = TextEditingController();
  final loading = false.obs;
  late final Api api;
  final cache = GetStorage();

  final formKey = GlobalKey<FormState>();

  @override
  void onInit() {
    super.onInit();
    api = Api(DioUtil(null).getDio(), baseUrl: DioUtil.mainUrl!);
  }

  @override
  void onClose() {
    emailCtrl.dispose();
    userNameCtrl.dispose();
   // lastNameCtrl.dispose();
    passwordCtrl.dispose();
    confirmPasswordCtrl.dispose();
    super.onClose();
  }

  Future<void> submit() async {
    if (!(formKey.currentState?.validate() ?? false)) return;

    final pwdError = PasswordValidator.validateSignupPassword(
      passwordCtrl.text,
      confirmPasswordCtrl.text,
    );
    if (pwdError != null) {
      showToastMessage(pwdError);
      return;
    }

    final online = await Constants.checkNetwork();
    if (!online) {
      showToastMessage('No internet connection');
      return;
    }

    loading.value = true;

    try {
      final res = await api.halatreeusersignup(
        emailCtrl.text.trim(),
        userNameCtrl.text.trim(),
        //lastNameCtrl.text.trim(),
        passwordCtrl.text,
      );
      if (res.message!="success") {
        showToastMessage(res.message ?? 'Sign up failed');
        return;
      }

      Constants.userModel = res.user;
      persistCredentials(res.user!.email??"", res.user!.password??"");
      showToastMessage(res.message ?? 'Account created');
      await Get.offAllNamed(RouteName.mainView);
    } catch (_) {
      showToastMessage('Sign up failed. Please try again.');
    } finally {
      loading.value = false;
    }
  }

  void persistCredentials(String email, String password) {
    cache.write(AuthStorage.emailKey, email);
    cache.write(AuthStorage.passwordKey, password);
  }
}
