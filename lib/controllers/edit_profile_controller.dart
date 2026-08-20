import 'package:coffee/controllers/main_controller.dart';
import 'package:coffee/controllers/profile_controller.dart';
import 'package:coffee/models/user_model.dart';
import 'package:coffee/utils/auth_storage.dart';
import 'package:coffee/utils/constants.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

import '../webservice/api.dart';
import '../webservice/dio_util.dart';

class EditProfileController extends GetxController {
  final emailCtrl = TextEditingController();
  final userNameCtrl = TextEditingController();
  //final lastNameCtrl = TextEditingController();

  final formKey = GlobalKey<FormState>();
  final loading = false.obs;
  final cache = GetStorage();
  late final Api api;

  String? _userId;

  @override
  void onInit() {
    super.onInit();
    api = Api(DioUtil(null).getDio(), baseUrl: DioUtil.mainUrl!);
    final u = Constants.userModel;
    _userId = u?.id;
    emailCtrl.text = u?.email?.trim() ?? '';
    userNameCtrl.text = u?.user_name?.trim() ?? '';
    //lastNameCtrl.text = u?.last_name?.trim() ?? '';
  }

  @override
  void onClose() {
    emailCtrl.dispose();
    userNameCtrl.dispose();
    //lastNameCtrl.dispose();
    super.onClose();
  }

  Future<void> save() async {
    if (!(formKey.currentState?.validate() ?? false)) return;

    final id = _userId;
    if (id == null || id.isEmpty) {
      showToastMessage('Missing user id');
      return;
    }

    final online = await Constants.checkNetwork();
    if (!online) {
      showToastMessage('No internet connection');
      return;
    }

    final email = emailCtrl.text.trim();
    final userName = userNameCtrl.text.trim();
    //final lastName = lastNameCtrl.text.trim();

    loading.value = true;
    try {
      final res = await api.updateuserprofile(id, email, userName);
      if (res.message != 'success') {
        showToastMessage(res.message ?? 'Could not update profile');
        return;
      }

      final prev = Constants.userModel;
      final merged = _mergeUser(prev, res.user, email, userName);
      Constants.userModel = merged;

      cache.write(AuthStorage.emailKey, email);

      if (Get.isRegistered<MainController>()) {
        Get.find<MainController>().currentUser.value = merged;
      }

      if (Get.isRegistered<ProfileController>()) {
        Get.find<ProfileController>().refreshFromConstants();
      }

      final msg = res.message;
      showToastMessage(
        (msg != null && msg.isNotEmpty && msg != 'success') ? msg : 'Profile updated',
      );
      Get.back(result: true);
    } catch (_) {
      showToastMessage('Could not update profile. Please try again.');
    } finally {
      loading.value = false;
    }
  }

  UserModel _mergeUser(
    UserModel? previous,
    UserModel? fromApi,
    String email,
    String userName,
    //String lastName,
  ) {
    final u = fromApi ?? UserModel();
    u.id = fromApi?.id ?? previous?.id;
    u.email = fromApi?.email ?? email;
    u.user_name = fromApi?.user_name ?? userName;
   // u.last_name = fromApi?.last_name ?? lastName;
    u.total_points = fromApi?.total_points ?? previous?.total_points;
    u.password = fromApi?.password ?? previous?.password;
    return u;
  }
}
