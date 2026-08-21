import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../models/user_model.dart';
import '../route.dart';
import '../utils/auth_storage.dart';
import '../utils/constants.dart';
import '../webservice/api.dart';
import '../webservice/dio_util.dart';

class ShopContact {
  final String name;
  final String phone;
  final String email;
  final String website;
  final double latitude;
  final double longitude;

  const ShopContact({
    required this.name,
    required this.phone,
    required this.email,
    required this.website,
    required this.latitude,
    required this.longitude,
  });
}

class MainController extends GetxController {
  final cache = GetStorage();
  late Api apiClient;

  /// Kaaawa location index in [shopContacts].
  static const int kaaawaShopIndex = 1;

  /// Shown when user selects Kaaawa: contact only during these hours.
  static const String kaaawaHoursMessage =
      'Hala Tree Cafe Kaaawa is open 7am to 4pm every day. '
      'You can only reach us during these hours.';

  static const List<ShopContact> shopContacts = [
    ShopContact(
      name: 'Hala Tree Cafe Waikiki',
      phone: '',
      email: '',
      website: '',
      latitude: 21.278432,
      longitude: -157.824195,
    ),
    // ShopContact(
    //   name: 'Hala Tree Cafe Kaaawa',
    //   phone: 'tel:+17815662669',
    //   email: 'mailto:info@halatreecafe.com',
    //   website: 'https://www.halatreecafe.com/',
    //   latitude: 21.559102,
    //   longitude: -157.862947,
    // ),
    ShopContact(
      name: 'Hala Tree Captain Cook',
      phone: 'tel:+18082385005',
      email: 'mailto:sales@halatreecoffee.com',
      website: 'https://halatreecoffee.com/',
      latitude: 19.482207,
      longitude: -155.898887,
    ),
  ];

  final selectedShopIndex = 0.obs;
  /// URL to load in the news WebView; empty when offline or on error.
  final newsUrl = ''.obs;
  final newsLoading = false.obs;
  WebViewController? newsWebViewController;
  /// True while fetching user location to select nearest shop.
  final locationLoading = false.obs;

  /// Cached user for loyalty points (synced with [Constants.userModel]).
  final Rxn<UserModel> currentUser = Rxn<UserModel>();

  /// True while loading / refreshing user data from [getuserdata].
  final userDataLoading = false.obs;

  ShopContact get selectedContact => shopContacts[selectedShopIndex.value];

  @override
  void onInit() {
    super.onInit();
    apiClient = Api(DioUtil(null).getDio(), baseUrl: DioUtil.mainUrl!);
    currentUser.value = Constants.userModel;
    initData();
  }

  void initData() async {
    getNewsData();
    ensureLocationAndSelectNearestShop();
    refreshUserData(silent: true);
  }

  /// Fetches latest profile and points via [Api.getuserdata]; updates [Constants.userModel].
  Future<void> refreshUserData({bool silent = false}) async {
    final email = cache.read(AuthStorage.emailKey)?.toString();
    final password = cache.read(AuthStorage.passwordKey)?.toString();
    if (email == null ||
        email.isEmpty ||
        password == null ||
        password.isEmpty) {
      if (!silent) {
        showToastMessage('Sign in to see your points');
      }
      return;
    }

    final online = await Constants.checkNetwork();
    if (!online) {
      if (!silent) showToastMessage('No internet connection');
      return;
    }

    userDataLoading.value = true;
    try {
      final res = await apiClient.getuserdata(Constants.userModel!.id??"0");
      if (res.message != 'success') {
        if (!silent) {
          showToastMessage(res.message ?? 'Could not refresh points');
        }
        return;
      }
      final user = res.user;
      if (user != null) {
        Constants.userModel = user;
        currentUser.value = user;
      }
    } catch (_) {
      if (!silent) {
        showToastMessage('Could not refresh points');
      }
    } finally {
      userDataLoading.value = false;
    }
  }

  /// Check/request location permission, get user position, and select nearest shop.
  /// If permission denied or location fails, defaults to first shop (index 0).
  Future<void> ensureLocationAndSelectNearestShop() async {
    final status = await Permission.locationWhenInUse.status;
    if (!status.isGranted) {
      if (status.isDenied) {
        final result = await Permission.locationWhenInUse.request();
        if (!result.isGranted) {
          selectShop(0);
          return;
        }
      } else if (status.isPermanentlyDenied) {
        // User chose "Don't ask again" – open app settings so they can enable location.
        await openAppSettings();
        selectShop(0);
        return;
      } else {
        selectShop(0);
        return;
      }
    }

    // Permission granted – check if location services (GPS) are on.
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      await Geolocator.openLocationSettings();
      // Still continue: getLastKnownPosition or default may apply when user returns.
    }

    locationLoading.value = true;
    try {
      Position? position;
      try {
        position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.medium,
            timeLimit: Duration(seconds: 15),
          ),
        );
      } catch (_) {
        position = null;
      }
      // Fallback: last known position (e.g. after emulator sets a mock location once)
      position ??= await Geolocator.getLastKnownPosition();
      // Fallback for emulator/no GPS: use first shop so app still works
      final lat = position?.latitude ?? shopContacts[0].latitude;
      final lon = position?.longitude ?? shopContacts[0].longitude;
      final index = _indexOfNearestShop(lat, lon);
      selectedShopIndex.value = index;
    } catch (_) {
      selectShop(0);
    } finally {
      locationLoading.value = false;
    }
  }

  int _indexOfNearestShop(double userLat, double userLon) {
    print(userLat);
    print(userLon);
    int nearest = 0;
    double minDist = double.infinity;
    for (int i = 0; i < shopContacts.length; i++) {
      final d = _haversineKm(
        userLat,
        userLon,
        shopContacts[i].latitude,
        shopContacts[i].longitude,
      );
      if (d < minDist) {
        minDist = d;
        nearest = i;
      }
    }
    return nearest;
  }

  static double _haversineKm(double lat1, double lon1, double lat2, double lon2) {
    const p = math.pi / 180;
    final a = 0.5 -
        math.cos((lat2 - lat1) * p) / 2 +
        math.cos(lat1 * p) *
            math.cos(lat2 * p) *
            (1 - math.cos((lon2 - lon1) * p)) /
            2;
    return 12742 * math.asin(math.sqrt(a));
  }

  void selectShop(int index) {
    selectedShopIndex.value = index;
  }

  Future<void> openUrl(String url) async {
    if(url.isEmpty){
      showToastMessage("Coming Soon");
      return;
    }
    final uri = Uri.parse(url);
    try {
      final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!launched) {
        // Common on iOS Simulator: no Phone/Mail app for tel:/mailto:
        final isTelOrMail = uri.scheme == 'tel' || uri.scheme == 'mailto';
        showToastMessage(
          isTelOrMail
              ? "Phone and email links need a real device (not supported on simulator)."
              : "Could not open link",
        );
      }
    } catch (e) {
      showToastMessage("Could not open link");
    }
  }

  void callUs() => openUrl(selectedContact.phone);
  void emailUs() => openUrl(selectedContact.email);
  void openWebsite() => openUrl(selectedContact.website);

  void getNewsData() async {
    debugPrint('[News] getNewsData() started');
    bool isNetwork = await Constants.checkNetwork();
    if (!isNetwork) {
      debugPrint('[News] No network – showing unavailable');
      newsUrl.value = '';
      return;
    }
    debugPrint('[News] Network OK, loading URL...');
    newsLoading.value = true;
    try {
      final url = '${baseUrl}getnewscontent';
      newsUrl.value = url;
      debugPrint('[News] Loading: $url');
      newsWebViewController = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setNavigationDelegate(
          NavigationDelegate(
            onNavigationRequest: (NavigationRequest request) async {
              final requestedUrl = request.url;
              if (requestedUrl == url || requestedUrl.startsWith(baseUrl)) {
                return NavigationDecision.navigate;
              }
              await openUrl(requestedUrl);
              return NavigationDecision.prevent;
            },
            onPageStarted: (url) => debugPrint('[News] WebView onPageStarted: $url'),
            onPageFinished: (url) {
              debugPrint('[News] WebView onPageFinished: $url');
              newsLoading.value = false;
            },
            onWebResourceError: (error) {
              debugPrint('[News] WebView onWebResourceError: isForMainFrame=${error.isForMainFrame}, '
                  'errorCode=${error.errorCode}, description=${error.description}');
              // Android often fires ERR_CACHE_MISS (-1) for the main frame even when the page
              // goes on to load (onPageFinished still fires). Ignore it so content can display.
              if (error.isForMainFrame != true) return;
              if (error.errorCode == -1 &&
                  error.description.toLowerCase().contains('err_cache_miss')) {
                return;
              }
              _showNewsUnavailable();
            },
            onHttpError: (error) {
              final uri = error.response?.uri;
              debugPrint('[News] WebView onHttpError: statusCode=${error.response?.statusCode}, uri=$uri');
              // Only show fallback if this is the main document (uri matches our news URL).
              // When uri is null it may be a subresource 404 – don't clear the WebView.
              if (uri != null && uri.toString() == url) {
                debugPrint('[News] WebView onHttpError is main doc – showing unavailable');
                _showNewsUnavailable();
              }
            },
          ),
        )
        ..loadRequest(Uri.parse(url));
    } catch (e, stack) {
      debugPrint('[News] getNewsData exception: $e');
      debugPrint('[News] stack: $stack');
      _showNewsUnavailable();
    } finally {
      debugPrint('[News] getNewsData() setup finished');
    }
  }

  void _showNewsUnavailable() {
    debugPrint('[News] _showNewsUnavailable() – clearing URL and controller');
    newsLoading.value = false;
    newsUrl.value = '';
    newsWebViewController = null;
  }

  /// Reload the news WebView if it is available.
  void reloadNews() {
    if (newsWebViewController != null && newsUrl.value.isNotEmpty) {
      newsWebViewController!.reload();
    } else {
      getNewsData();
    }
  }

  void openWaikiki() {
    showToastMessage("Opening soon, under construction");
  }

  void openKaaawa() {
    openUrl("https://www.clover.com/online-ordering/hala-tree-cafe-1");
  }

  void openShopOnline() {
    openUrl("https://www.halatreecoffee.com");
  }

  void openLoyaltyProgram() {
    openUrl("https://start.mylty.co/login?id=18240"); // TODO: replace with loyalty program URL
  }

  /// type `0`: Hala Tree (halatree) — [addcustomercredit]. type `1`: Clover — [deductcloverpoints].
  void enterPointAmountDialog(int type) {
    final user = Constants.userModel;
    if (user?.id == null || user!.id!.isEmpty) {
      showToastMessage('Sign in required');
      return;
    }

    final textController = TextEditingController();
    var submitting = false;

    Get.dialog(
      StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Enter Point Amount'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('Enter the amount of points you want to redeem'),
                const SizedBox(height: 12),
                TextField(
                  controller: textController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    hintText: 'Points',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: submitting ? null : () => Get.back(),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: submitting
                    ? null
                    : () async {
                        final raw = textController.text.trim();
                        final amount = int.tryParse(raw);
                        if (amount == null || amount <= 0) {
                          showToastMessage('Enter a valid point amount');
                          return;
                        }
                        final current = _parseUserPoints(user.total_points);
                        if (amount > current) {
                          showToastMessage(
                            'Enter an amount that does not exceed your current points ($current).',
                          );
                          return;
                        }

                        final online = await Constants.checkNetwork();
                        if (!online) {
                          showToastMessage('No internet connection');
                          return;
                        }

                        if (type == 1) {
                          final code = _generateCloverRedeemCode(user.id!);
                          Get.back();
                          _showCloverRedeemCodeDialog(raw, code);
                          return;
                        }

                        setDialogState(() => submitting = true);
                        var dialogClosed = false;
                        try {
                          final res = await apiClient.addcustomercredit(
                            user.id!,
                            raw,
                          );
                          if (res.message == 'success') {
                            final na = res.new_amount;
                            if (na != null && na.isNotEmpty) {
                              _applyTotalPoints(na);
                            } else {
                              await refreshUserData(silent: true);
                            }
                            dialogClosed = true;
                            Get.back();
                            showToastMessage("Redeem succeed");
                          } else {
                            showToastMessage(res.message ?? 'Redeem failed');
                          }
                        } catch (_) {
                          showToastMessage('Redeem failed. Please try again.');
                        } finally {
                          // Do not rebuild after Get.back(): setDialogState during pop
                          // trips ChangeNotifier / transition asserts (e.g. line ~381 TextField).
                          if (!dialogClosed && context.mounted) {
                            setDialogState(() => submitting = false);
                          }
                        }
                      },
                child: submitting
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Redeem'),
              ),
            ],
          );
        },
      ),
    ).whenComplete(() {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        textController.dispose();
      });
    });
  }

  int _parseUserPoints(String? s) => int.tryParse(s ?? '') ?? 0;

  void _applyTotalPoints(String newAmount) {
    final m = Constants.userModel;
    if (m == null) return;
    m.total_points = newAmount;
    Constants.userModel = m;
    currentUser.value = m;
    currentUser.refresh();
  }

  /// Six-digit suffix seeded from user id and current time.
  String _generateCloverRedeemCode(String userId) {
    final ts = DateTime.now().millisecondsSinceEpoch;
    final rnd = math.Random(ts ^ userId.hashCode);
    final six = rnd.nextInt(1000000).toString().padLeft(6, '0');
    return 'HALATREE-$six';
  }

  void _showCloverRedeemCodeDialog(String pointsStr, String redeemCode) {
    var loading = true;
    String? apiError;
    var deductionStarted = false;

    Get.dialog(
      StatefulBuilder(
        builder: (context, setDialogState) {
          if (!deductionStarted) {
            deductionStarted = true;
            Future<void> deduct() async {
              final online = await Constants.checkNetwork();
              if (!online) {
                apiError = 'No internet connection';
                loading = false;
                if (context.mounted) setDialogState(() {});
                return;
              }
              try {
                final u = Constants.userModel;
                final res = await apiClient.deductcloverpoints(
                  u?.id ?? '0',
                  pointsStr,
                  redeemCode,
                );
                if (res.message == 'success') {
                  final na = res.new_amount;
                  if (na != null && na.isNotEmpty) {
                    _applyTotalPoints(na);
                  } else {
                    await refreshUserData(silent: true);
                  }
                } else {
                  apiError = res.message ?? 'Could not redeem points';
                }
              } catch (_) {
                apiError = 'Could not redeem points';
              } finally {
                loading = false;
                if (context.mounted) setDialogState(() {});
              }
            }

            deduct();
          }

          return AlertDialog(
            title: const Text('Redeem code'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SelectableText(
                  redeemCode,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 16),
                if (loading)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(8),
                      child: CircularProgressIndicator(),
                    ),
                  ),
                if (!loading && apiError != null)
                  Text(
                    apiError!,
                    style: TextStyle(color: Theme.of(context).colorScheme.error),
                  ),
                if (!loading && apiError == null)
                  const Text('Your points have been updated.'),
              ],
            ),
            actions: [
              TextButton(
                onPressed: loading ? null : () => Get.back(),
                child: const Text('Close'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> confirmLogout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Log out'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Log out'),
          ),
        ],
      ),
    );
    if (confirmed == true) await performLogout();
  }

  Future<void> performLogout() async {
    cache.remove(AuthStorage.emailKey);
    cache.remove(AuthStorage.passwordKey);
    Constants.userModel = null;
    await Get.offAllNamed(RouteName.loginView);
    if (Get.isRegistered<MainController>()) {
      Get.delete<MainController>(force: true);
    }
  }

}
