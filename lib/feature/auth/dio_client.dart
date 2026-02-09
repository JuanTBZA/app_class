import 'dart:async';
import 'package:dio/dio.dart';
import '../../feature/auth/token_storage.dart';
import '../../feature/auth/auth_remote_ds.dart';

class DioClient {
  final Dio dio;
  DioClient._(this.dio);

  static DioClient create({
    required String baseUrl,
    required TokenStorage tokenStorage,
  }) {
    final options = BaseOptions(
      baseUrl: baseUrl,
      headers: {"Content-Type": "application/json"},
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
    );

    final dio = Dio(options);

    // Dio separado para refresh (para no caer en loop de interceptores)
    final refreshDio = Dio(options);
    final authRemote = AuthRemoteDataSource(refreshDio);

    dio.interceptors.add(
      AuthInterceptor(
        dio: dio,
        tokenStorage: tokenStorage,
        authRemote: authRemote,
      ),
    );

    return DioClient._(dio);
  }
}

class AuthInterceptor extends Interceptor {
  final Dio dio;
  final TokenStorage tokenStorage;
  final AuthRemoteDataSource authRemote;

  bool _isRefreshing = false;
  final List<void Function(String)> _waitQueue = [];

  AuthInterceptor({
    required this.dio,
    required this.tokenStorage,
    required this.authRemote,
  });

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    // No agregues access token en login ni refresh
    final isAuthEndpoint =
        options.path.contains("/auth/login") || options.path.contains("/auth/refresh-token");

    if (!isAuthEndpoint) {
      final access = await tokenStorage.getAccessToken();
      if (access != null && access.isNotEmpty) {
        options.headers["Authorization"] = "Bearer $access";
      }
    }

    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    final status = err.response?.statusCode;
    final is401 = status == 401;

    final path = err.requestOptions.path;
    final isAuthEndpoint =
        path.contains("/auth/login") || path.contains("/auth/refresh-token");

    if (!is401 || isAuthEndpoint) {
      return handler.next(err);
    }

    final refresh = await tokenStorage.getRefreshToken();
    if (refresh == null || refresh.isEmpty) {
      await tokenStorage.clear();
      return handler.next(err);
    }

    try {
      final res = await _refreshAndRetry(err.requestOptions, refresh);
      return handler.resolve(res);
    } catch (_) {
      await tokenStorage.clear();
      return handler.next(err);
    }
  }

  Future<Response<dynamic>> _refreshAndRetry(RequestOptions failed, String refreshToken) async {
    if (_isRefreshing) {
      return _waitForTokenAndRetry(failed);
    }

    _isRefreshing = true;
    try {
      final tokens = await authRemote.refreshToken(refreshToken: refreshToken);

      await tokenStorage.saveTokens(
        access: tokens.accessToken,
        refresh: tokens.refreshToken,
      );

      // suelta la cola
      for (final fn in _waitQueue) {
        fn(tokens.accessToken);
      }
      _waitQueue.clear();

      return _retry(failed, tokens.accessToken);
    } finally {
      _isRefreshing = false;
    }
  }

  Future<Response<dynamic>> _waitForTokenAndRetry(RequestOptions failed) {
    final completer = Completer<Response<dynamic>>();

    _waitQueue.add((newAccess) async {
      try {
        final res = await _retry(failed, newAccess);
        completer.complete(res);
      } catch (e) {
        completer.completeError(e);
      }
    });

    return completer.future;
  }

  Future<Response<dynamic>> _retry(RequestOptions failed, String accessToken) {
    final options = Options(
      method: failed.method,
      headers: Map<String, dynamic>.from(failed.headers)
        ..["Authorization"] = "Bearer $accessToken",
      responseType: failed.responseType,
      contentType: failed.contentType,
      followRedirects: failed.followRedirects,
      validateStatus: failed.validateStatus,
      receiveDataWhenStatusError: failed.receiveDataWhenStatusError,
      extra: failed.extra,
    );

    return dio.request(
      failed.path,
      data: failed.data,
      queryParameters: failed.queryParameters,
      options: options,
      cancelToken: failed.cancelToken,
      onReceiveProgress: failed.onReceiveProgress,
      onSendProgress: failed.onSendProgress,
    );
  }
}
