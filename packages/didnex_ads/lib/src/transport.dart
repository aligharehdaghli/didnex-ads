import 'dart:isolate';
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'models.dart';

abstract class DidnexTransport {
  Future<Map<String, dynamic>> postJson(
    Uri uri, {
    Map<String, dynamic>? body,
    Map<String, String> headers = const {},
    Duration timeout = const Duration(seconds: 5),
  });
  Future<Uint8List> imageBytes(
    Uri uri, {
    Duration timeout = const Duration(seconds: 5),
  });
  void close();
}

class DidnexHttpTransport implements DidnexTransport {
  final HttpClient _http = HttpClient()
    ..connectionTimeout = const Duration(seconds: 5);
  bool _closed = false;
  Future<Uint8List> _read(HttpClientResponse response, int maximum) async {
    if (response.contentLength > maximum)
      throw const DidnexAdException('response_too_large');
    final builder = BytesBuilder(copy: false);
    await for (final chunk in response) {
      if (builder.length + chunk.length > maximum)
        throw const DidnexAdException('response_too_large');
      builder.add(chunk);
    }
    return builder.takeBytes();
  }

  Future<Uint8List> _send(
    Uri uri, {
    required bool image,
    Map<String, dynamic>? body,
    Map<String, String> headers = const {},
    required Duration timeout,
  }) async {
    didnexHttpsUri(uri);
    if (_closed) throw const DidnexAdException('client_closed');
    HttpClientRequest? request;
    try {
      return await (() async {
        final outgoing = await _http.openUrl(image ? 'GET' : 'POST', uri);
        request = outgoing;
        outgoing.followRedirects = false;
        if (!image) outgoing.headers.contentType = ContentType.json;
        headers.forEach((key, value) => outgoing.headers.set(key, value));
        if (body != null) outgoing.write(jsonEncode(body));
        final response = await outgoing.close();
        if (response.statusCode < 200 || response.statusCode >= 300) {
          await response.drain<void>();
          throw DidnexAdException('http_error', response.statusCode);
        }
        return _read(response, image ? 20 * 1024 * 1024 : 65536);
      })()
          .timeout(timeout);
    } on TimeoutException {
      request?.abort();
      throw const DidnexAdException('request_timeout');
    } on DidnexAdException {
      rethrow;
    } catch (_) {
      throw const DidnexAdException('network_unavailable');
    }
  }

  @override
  Future<Map<String, dynamic>> postJson(
    Uri uri, {
    Map<String, dynamic>? body,
    Map<String, String> headers = const {},
    Duration timeout = const Duration(seconds: 5),
  }) async {
    final bytes = await _send(
      uri,
      image: false,
      body: body,
      headers: headers,
      timeout: timeout,
    );
    try {
      final data = bytes.length>32768 ? await Isolate.run(() => jsonDecode(utf8.decode(bytes))) : jsonDecode(utf8.decode(bytes));
      if (data is! Map<String, dynamic>) throw const FormatException();
      return data;
    } catch (_) {
      throw const DidnexAdException('invalid_json_response');
    }
  }

  @override
  Future<Uint8List> imageBytes(
    Uri uri, {
    Duration timeout = const Duration(seconds: 5),
  }) =>
      _send(uri, image: true, timeout: timeout);
  @override
  void close() {
    if (_closed) return;
    _closed = true;
    _http.close(force: true);
  }
}
