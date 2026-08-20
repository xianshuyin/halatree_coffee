import 'dart:io';
import 'package:dio/dio.dart';
class DioUtil {

  static final DioUtil _instance = DioUtil._init();
  static Dio? _dio;
  static BaseOptions _options = getDefOptions();
  static String? mainUrl;
  static String? version;

  factory DioUtil(String? url,) {
    if (url != null) {
      mainUrl = url;
    }
    return _instance;
  }

  getDio() {
    return _dio;
  }

  getUrl() {
    return mainUrl;
  }

  DioUtil._init() {

    _dio = Dio();
    _dio!.options = _options;
    // if(debugMode){
    //   _dio!.interceptors.add(PrettyDioLogger(
    //       requestHeader: false,
    //       requestBody: false,
    //       responseBody: false,
    //       responseHeader: false,
    //       error: true,
    //       compact: true,
    //       maxWidth: 90));
    // }
  }

  static BaseOptions getDefOptions() {
    BaseOptions options = BaseOptions();
    options.connectTimeout = const Duration(milliseconds:  30 * 1000);
    options.receiveTimeout = const Duration(milliseconds:300 * 1000);
    options.sendTimeout = const Duration(milliseconds:120 * 1000);



    Map<String, dynamic> headers = <String, dynamic>{};
    headers['Accept'] = 'application/json';
    // Live hosting (Imunify360) blocks Dart's default User-Agent.
    headers['User-Agent'] = Platform.isIOS
        ? 'Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Mobile/15E148'
        : 'Mozilla/5.0 (Linux; Android 13; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36';
    headers['Accept-Language'] = 'en-US,en;q=0.9';

    String? platform;
    if (Platform.isAndroid) {
      platform = "Android";
    } else if (Platform.isIOS) {
      platform = "iOS";
    }
    headers['Platform'] = platform;
    options.headers = headers;

    return options;
  }

  BaseOptions getOptionsWithJwt(String jwttoken){
    BaseOptions options = BaseOptions();
    options.connectTimeout = const Duration(milliseconds:  30 * 1000);
    options.receiveTimeout = const Duration(milliseconds:  60 * 1000);
    options.sendTimeout = const Duration(milliseconds:  60 * 1000);

    Map<String, dynamic> headers = <String, dynamic>{};
    headers['Content-Type'] = 'application/json';
    headers['Accept'] = '*/*';
    headers['Authorization'] = "Bearer $jwttoken";

    // String? platform;
    // if (Platform.isAndroid) {
    //   platform = "Android";
    // } else if (Platform.isIOS) {
    //   platform = "iOS";
    // }
    // headers['Platform'] = platform;
    options.headers = headers;
    return options;
  }

  setOptions(BaseOptions options) {
    _options = options;
    _dio!.options = _options;
  }
}
